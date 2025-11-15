#' Pre-compute Observed Probabilities for Faster Evaluation
#'
#' @description
#' Pre-computes all observed conditional probabilities that are reused across
#' parameter sets. This eliminates redundant data aggregation operations.
#'
#' @param data Data frame with observed variables
#' @param A_name Exposure variable name
#' @param M_name Mediator variable name
#' @param Y_name Outcome variable name
#' @param C_names Confounder variable names
#' @param misclass_type Either "exposure" or "mediator"
#'
#' @return List containing pre-computed probabilities and strata information
#' @keywords internal
#' @noRd
precompute_observed_probs <- function(data, A_name, M_name, Y_name, C_names,
                                      misclass_type = "exposure") {

  # Create strata
  if (is.null(C_names) || length(C_names) == 0) {
    data$stratum_id <- 1
    strata <- data.frame(stratum_id = 1)
  } else {
    data <- data |>
      dplyr::group_by(across(all_of(C_names))) |>
      dplyr::mutate(stratum_id = cur_group_id()) |>
      dplyr::ungroup()
    strata <- data |>
      dplyr::select(stratum_id, all_of(C_names)) |>
      dplyr::distinct()
  }

  if (misclass_type == "exposure") {
    # Pre-compute P*(A*=a* | M=m, Y=y, C=c) for all combinations
    obs_probs <- data |>
      dplyr::group_by(!!sym(M_name), !!sym(Y_name), stratum_id, !!sym(A_name)) |>
      dplyr::summarise(n = n(), .groups = "drop_last") |>
      dplyr::mutate(prob = n / sum(n)) |>
      dplyr::ungroup() |>
      dplyr::select(-n)

    # Convert to list for fast lookup
    prob_list <- list()
    for (i in 1:nrow(obs_probs)) {
      m <- obs_probs[[M_name]][i]
      y <- obs_probs[[Y_name]][i]
      s <- obs_probs$stratum_id[i]
      a_star <- obs_probs[[A_name]][i]
      key <- paste0("m", m, "_y", y, "_s", s, "_a", a_star)
      prob_list[[key]] <- obs_probs$prob[i]
    }

    # Compute stratum sizes for M,Y combinations
    stratum_sizes <- data |>
      dplyr::group_by(!!sym(M_name), !!sym(Y_name), stratum_id) |>
      dplyr::summarise(n = n(), .groups = "drop")

  } else {  # mediator misclassification
    # Pre-compute P*(M*=m*, Y=y | A=a, C=c) for all combinations
    obs_probs <- data |>
      dplyr::group_by(!!sym(A_name), stratum_id, !!sym(Y_name), !!sym(M_name)) |>
      dplyr::summarise(n = n(), .groups = "drop_last") |>
      dplyr::mutate(prob = n / sum(n)) |>
      dplyr::ungroup() |>
      dplyr::select(-n)

    # Convert to matrix format for faster lookup
    prob_list <- list()
    for (i in 1:nrow(obs_probs)) {
      a <- obs_probs[[A_name]][i]
      s <- obs_probs$stratum_id[i]
      y <- obs_probs[[Y_name]][i]
      m_star <- obs_probs[[M_name]][i]
      key <- paste0("a", a, "_s", s)

      if (is.null(prob_list[[key]])) {
        prob_list[[key]] <- matrix(0, nrow = 2, ncol = 2)
      }
      prob_list[[key]][y + 1, m_star + 1] <- obs_probs$prob[i]
    }

    # Compute stratum sizes for A combinations
    stratum_sizes <- data |>
      dplyr::group_by(!!sym(A_name), stratum_id) |>
      dplyr::summarise(n = n(), .groups = "drop")
  }

  return(list(
    obs_probs = prob_list,
    strata = strata,
    stratum_sizes = stratum_sizes,
    data = data
  ))
}


#' Adaptive Grid Refinement for Partial Identification
#'
#' @description
#' Implements a two-stage grid search:
#' 1. Coarse grid to identify compatible regions
#' 2. Fine grid refinement only in compatible regions
#'
#' This dramatically reduces the number of evaluations needed.
#'
#' @param sensitivity_region Sensitivity parameter region
#' @param evaluate_func Function to evaluate compatibility at a parameter set
#' @param n_grid_fine Target fine grid resolution (default n_grid from bound_ne)
#' @param coarse_factor Coarseness factor for initial grid (default 5)
#' @param verbose Whether to print progress
#'
#' @return List with compatible parameter sets and bounds
#' @keywords internal
#' @noRd
adaptive_grid_search <- function(sensitivity_region, evaluate_func,
                                 n_grid_fine = 50, coarse_factor = 5,
                                 verbose = TRUE) {

  # Stage 1: Coarse grid
  n_grid_coarse <- max(3, ceiling(n_grid_fine / coarse_factor))

  if (verbose) {
    cat("\n=== Stage 1: Coarse grid search ===\n")
    cat("Grid resolution:", n_grid_coarse, "points per dimension\n")
    cat("Total evaluations:", n_grid_coarse^4, "\n")
  }

  coarse_grid <- create_parameter_grid(sensitivity_region, n_grid_coarse)

  # Evaluate coarse grid
  coarse_results <- vector("list", nrow(coarse_grid))
  for (i in 1:nrow(coarse_grid)) {
    if (verbose && i %% max(1, floor(nrow(coarse_grid)/20)) == 0) {
      cat(sprintf("  Progress: %d/%d (%.0f%%)\n", i, nrow(coarse_grid),
                  100 * i/nrow(coarse_grid)))
    }
    coarse_results[[i]] <- evaluate_func(i, coarse_grid[i, ])
  }

  # Filter to compatible sets
  coarse_compatible <- Filter(Negate(is.null), coarse_results)

  if (length(coarse_compatible) == 0) {
    stop("No compatible parameter sets found in coarse grid. ",
         "Consider widening sensitivity_region.")
  }

  if (verbose) {
    cat(sprintf("Compatible sets found: %d/%d (%.1f%%)\n",
                length(coarse_compatible), nrow(coarse_grid),
                100 * length(coarse_compatible)/nrow(coarse_grid)))
  }

  # If coarse grid is dense enough, just return it
  if (n_grid_coarse >= n_grid_fine * 0.8) {
    if (verbose) cat("Coarse grid is sufficient, skipping refinement.\n")
    return(coarse_compatible)
  }

  # Stage 2: Identify regions to refine
  if (verbose) {
    cat("\n=== Stage 2: Adaptive refinement ===\n")
  }

  # Extract compatible parameter values
  compatible_params <- do.call(rbind, lapply(coarse_compatible, function(x) x$params))

  # Convert S7 sensitivity_region to list if needed
  if (inherits(sensitivity_region, "S7_object")) {
    sensitivity_region <- as.list(sensitivity_region)
  }

  # For each parameter, find min/max of compatible region
  refined_regions <- list(
    sn0_range = range(compatible_params$sn0),
    sp0_range = range(compatible_params$sp0),
    psi_sn_range = range(compatible_params$psi_sn),
    psi_sp_range = range(compatible_params$psi_sp)
  )

  # Expand slightly to avoid edge effects
  expand_range <- function(range_vec, expansion = 0.1) {
    width <- diff(range_vec)
    if (width < 1e-10) {
      # Degenerate range, use original region
      return(range_vec)
    }
    c(max(range_vec[1] - expansion * width, 0),
      min(range_vec[2] + expansion * width, 1))
  }

  refined_regions$sn0_range <- expand_range(refined_regions$sn0_range)
  refined_regions$sp0_range <- expand_range(refined_regions$sp0_range)

  # For psi parameters, respect original bounds
  refined_regions$psi_sn_range <- pmax(refined_regions$psi_sn_range,
                                       sensitivity_region$psi_sn_range[1])
  refined_regions$psi_sn_range <- pmin(refined_regions$psi_sn_range,
                                       sensitivity_region$psi_sn_range[2])
  refined_regions$psi_sp_range <- pmax(refined_regions$psi_sp_range,
                                       sensitivity_region$psi_sp_range[1])
  refined_regions$psi_sp_range <- pmin(refined_regions$psi_sp_range,
                                       sensitivity_region$psi_sp_range[2])

  if (verbose) {
    cat("Refined search region:\n")
    cat(sprintf("  sn0: [%.3f, %.3f]\n", refined_regions$sn0_range[1],
                refined_regions$sn0_range[2]))
    cat(sprintf("  sp0: [%.3f, %.3f]\n", refined_regions$sp0_range[1],
                refined_regions$sp0_range[2]))
    cat(sprintf("  psi_sn: [%.3f, %.3f]\n", refined_regions$psi_sn_range[1],
                refined_regions$psi_sn_range[2]))
    cat(sprintf("  psi_sp: [%.3f, %.3f]\n", refined_regions$psi_sp_range[1],
                refined_regions$psi_sp_range[2]))
  }

  # Create fine grid over refined region
  fine_grid <- create_parameter_grid(refined_regions, n_grid_fine)

  # Remove parameter sets already evaluated in coarse grid
  coarse_params_df <- as.data.frame(coarse_grid)
  fine_params_df <- as.data.frame(fine_grid)

  # Find new parameter sets
  merge_key <- c("sn0", "sp0", "psi_sn", "psi_sp")
  already_eval <- merge(fine_params_df, coarse_params_df, by = merge_key,
                        all = FALSE)

  if (nrow(already_eval) > 0) {
    # Remove duplicates
    fine_grid <- dplyr::anti_join(fine_params_df, coarse_params_df, by = merge_key)
    fine_grid <- as.data.frame(fine_grid)
  }

  if (verbose) {
    cat("Fine grid evaluation points:", nrow(fine_grid), "\n")
  }

  # Evaluate fine grid
  fine_results <- vector("list", nrow(fine_grid))
  for (i in 1:nrow(fine_grid)) {
    if (verbose && i %% max(1, floor(nrow(fine_grid)/20)) == 0) {
      cat(sprintf("  Progress: %d/%d (%.0f%%)\n", i, nrow(fine_grid),
                  100 * i/nrow(fine_grid)))
    }
    fine_results[[i]] <- evaluate_func(i, fine_grid[i, ])
  }

  # Combine coarse and fine results
  fine_compatible <- Filter(Negate(is.null), fine_results)
  all_results <- c(coarse_compatible, fine_compatible)

  n_total_evaluated <- nrow(coarse_grid) + nrow(fine_grid)

  if (verbose) {
    cat(sprintf("\nTotal compatible sets: %d\n", length(all_results)))
    cat(sprintf("Total evaluations: %d (vs %d for full grid)\n",
                n_total_evaluated, n_grid_fine^4))
    cat(sprintf("Reduction: %.1f%%\n",
                100 * (1 - n_total_evaluated / n_grid_fine^4)))
  }

  # Return results with metadata
  attr(all_results, "n_evaluated") <- n_total_evaluated
  return(all_results)
}


#' Vectorized Probability Calculations for Exposure Misclassification
#'
#' @description
#' Optimized version that uses vectorized operations and pre-computed probabilities
#'
#' @keywords internal
#' @noRd
fast_check_exposure_compatibility <- function(param_row, precomputed) {

  # Extract parameters
  sn0 <- param_row$sn0
  sp0 <- param_row$sp0
  psi_sn <- param_row$psi_sn
  psi_sp <- param_row$psi_sp

  # Compute sn1, sp1
  sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
  sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))

  # Quick validity checks (early termination)
  if (is.na(sn1) || is.na(sp1) || sn1 < 0 || sn1 > 1 || sp1 < 0 || sp1 > 1) {
    return(NULL)
  }

  # Check informativeness (early termination)
  if ((sn0 + sp0 - 1) <= 0.01 || (sn1 + sp1 - 1) <= 0.01) {
    return(NULL)
  }

  obs_probs <- precomputed$obs_probs
  strata <- precomputed$strata
  stratum_sizes <- precomputed$stratum_sizes

  P_true_list <- list()

  # Vectorized loop over M, Y, stratum
  for (m in c(0, 1)) {
    for (y in c(0, 1)) {
      # Select sensitivity/specificity based on Y
      sn_y <- if (y == 1) sn1 else sn0
      sp_y <- if (y == 1) sp1 else sp0

      # Pre-compute denominatorfor matrix inversion
      denom <- sn_y + sp_y - 1

      for (s in strata$stratum_id) {
        # Check stratum size (early termination)
        size_row <- stratum_sizes[stratum_sizes$M == m &
                                    stratum_sizes$Y == y &
                                    stratum_sizes$stratum_id == s, ]
        if (nrow(size_row) == 0 || size_row$n[1] < 5) {
          return(NULL)  # Early termination
        }

        # Fast lookup of pre-computed probabilities
        key_1 <- paste0("m", m, "_y", y, "_s", s, "_a1")
        key_0 <- paste0("m", m, "_y", y, "_s", s, "_a0")

        P_star_1 <- obs_probs[[key_1]]
        P_star_0 <- obs_probs[[key_0]]

        if (is.null(P_star_1)) P_star_1 <- 0
        if (is.null(P_star_0)) P_star_0 <- 0

        # Check testable implications (early termination)
        if (P_star_0 > 1e-6) {
          if (P_star_1 / P_star_0 < (1 - sp_y) / sp_y - 1e-6) {
            return(NULL)  # Early termination
          }
        }

        if (P_star_1 > 1e-6) {
          if (P_star_0 / P_star_1 < (1 - sn_y) / sn_y - 1e-6) {
            return(NULL)  # Early termination
          }
        }

        # Solve for true probabilities (vectorized)
        P_1my <- (sp_y * P_star_1 - (1 - sp_y) * P_star_0) / denom
        P_0my <- (sn_y * P_star_0 - (1 - sn_y) * P_star_1) / denom

        # Check non-negativity (early termination)
        if (P_1my < -1e-6 || P_0my < -1e-6) {
          return(NULL)  # Early termination
        }

        # Store
        P_1my <- max(0, P_1my)
        P_0my <- max(0, P_0my)

        key <- paste0("m", m, "_y", y, "_s", s)
        P_true_list[[key]] <- c(P_1 = P_1my, P_0 = P_0my,
                                 stratum_id = s, M = m, Y = y)
      }
    }
  }

  # If we got here, parameter set is compatible
  effects <- compute_effects_from_joint_probs(
    P_true_list = P_true_list,
    data = precomputed$data,
    C_names = setdiff(names(precomputed$strata), "stratum_id"),
    effect_scale = "OR"  # Will be passed from parent
  )

  return(list(
    compatible = TRUE,
    params = param_row,
    nie = effects$nie,
    nde = effects$nde,
    P_true = P_true_list
  ))
}
