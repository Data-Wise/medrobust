#' Bounds for Exposure Misclassification
#'
#' @description
#' Internal function implementing Algorithm 5.1 from the paper for
#' differential misclassification of the exposure.
#'
#' @inheritParams bound_ne
#' @keywords internal
#' @noRd
bound_ne_exposure <- function(data,
                              exposure,
                              mediator,
                              outcome,
                              confounders,
                              sensitivity_region,
                              n_grid,
                              effect_scale,
                              parallel,
                              n_cores,
                              cache,
                              cache_dir,
                              verbose) {

  # Extract variable names
  A_star_name <- exposure
  M_name <- mediator
  Y_name <- outcome
  C_names <- confounders

  # Create parameter grid
  if (verbose) cat("Creating parameter grid...\n")
  param_grid <- create_parameter_grid(sensitivity_region, n_grid)
  n_total <- nrow(param_grid)

  # Compute naive estimates
  naive_estimates <- compute_naive_effects(data, A_star_name, M_name,
                                           Y_name, C_names, effect_scale)

  # Initialize storage
  compatible_params <- list()
  nie_values <- numeric(0)
  nde_values <- numeric(0)

  # Setup parallel processing
  if (parallel) {
    if (is.null(n_cores)) {
      n_cores <- parallel::detectCores() - 1
    }
    if (verbose) cat("Using", n_cores, "cores for parallel processing\n")

    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl))

    parallel::clusterExport(cl, c("data", "A_star_name", "M_name", "Y_name",
                                   "C_names", "effect_scale"),
                           envir = environment())
    parallel::clusterEvalQ(cl, library(dplyr))
  }

  # Progress bar
  if (verbose) {
    pb <- txtProgressBar(min = 0, max = n_total, style = 3)
  }

  # Main evaluation function
  evaluate_param_set <- function(i, param_row) {
    # Extract parameters
    sn0 <- param_row$sn0
    sp0 <- param_row$sp0
    psi_sn <- param_row$psi_sn
    psi_sp <- param_row$psi_sp

    # Compute sn1, sp1
    sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
    sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))

    # Validate
    if (any(c(sn1, sp1) < 0 | c(sn1, sp1) > 1)) {
      return(NULL)
    }

    # Check informativeness
    if ((sn0 + sp0 - 1) <= 0.01 || (sn1 + sp1 - 1) <= 0.01) {
      return(NULL)
    }

    # Get strata
    if (is.null(C_names) || length(C_names) == 0) {
      strata <- data.frame(stratum_id = 1)
      data$stratum_id <- 1
    } else {
      data <- data |>
        dplyr::group_by(across(all_of(C_names))) |>
        dplyr::mutate(stratum_id = cur_group_id()) |>
        dplyr::ungroup()
      strata <- data |>
        dplyr::select(stratum_id, all_of(C_names)) |>
        dplyr::distinct()
    }

    # Initialize storage for implied true joint probabilities
    P_true_list <- list()
    compatible <- TRUE

    # Loop over (M, Y, stratum) combinations
    for (m in c(0, 1)) {
      for (y in c(0, 1)) {
        for (s in strata$stratum_id) {
          # Get observed data for this (M=m, Y=y, stratum=s) combination
          data_mys <- data |>
            dplyr::filter(!!sym(M_name) == m, !!sym(Y_name) == y, stratum_id == s)

          if (nrow(data_mys) < 5) {
            compatible <- FALSE
            break
          }

          # Compute observed P*(A*=a* | M=m, Y=y, C=c)
          obs_probs <- data_mys |>
            dplyr::group_by(!!sym(A_star_name)) |>
            dplyr::summarise(n = n(), .groups = "drop") |>
            dplyr::mutate(prob = n / sum(n))

          # Extract P*_1my and P*_0my
          P_star_1 <- obs_probs$prob[obs_probs[[A_star_name]] == 1]
          P_star_0 <- obs_probs$prob[obs_probs[[A_star_name]] == 0]

          if (length(P_star_1) == 0) P_star_1 <- 0
          if (length(P_star_0) == 0) P_star_0 <- 0

          # Select sensitivity/specificity based on Y
          sn_y <- if (y == 1) sn1 else sn0
          sp_y <- if (y == 1) sp1 else sp0

          # Check testable implications (Proposition 5.1)
          # Condition 1: P*_1my / P*_0my >= (1-sp_y) / sp_y
          if (P_star_0 > 1e-6) {
            if (P_star_1 / P_star_0 < (1 - sp_y) / sp_y - 1e-6) {
              compatible <- FALSE
              break
            }
          }

          # Condition 2: P*_0my / P*_1my >= (1-sn_y) / sn_y
          if (P_star_1 > 1e-6) {
            if (P_star_0 / P_star_1 < (1 - sn_y) / sn_y - 1e-6) {
              compatible <- FALSE
              break
            }
          }

          # Solve for true P_1my and P_0my using matrix inversion
          # P_1my = (sp_y * P*_1my - (1-sp_y) * P*_0my) / (sn_y + sp_y - 1)
          # P_0my = (sn_y * P*_0my - (1-sn_y) * P*_1my) / (sn_y + sp_y - 1)

          denom <- sn_y + sp_y - 1
          P_1my <- (sp_y * P_star_1 - (1 - sp_y) * P_star_0) / denom
          P_0my <- (sn_y * P_star_0 - (1 - sn_y) * P_star_1) / denom

          # Check non-negativity
          if (P_1my < -1e-6 || P_0my < -1e-6) {
            compatible <- FALSE
            break
          }

          # Ensure non-negative (numerical precision)
          P_1my <- max(0, P_1my)
          P_0my <- max(0, P_0my)

          # Store
          key <- paste0("m", m, "_y", y, "_s", s)
          P_true_list[[key]] <- c(P_1 = P_1my, P_0 = P_0my,
                                   stratum_id = s, M = m, Y = y)
        }
        if (!compatible) break
      }
      if (!compatible) break
    }

    # If compatible, compute effects
    if (compatible) {
      effects <- compute_effects_from_joint_probs(
        P_true_list = P_true_list,
        data = data,
        C_names = C_names,
        effect_scale = effect_scale
      )

      return(list(
        compatible = TRUE,
        params = param_row,
        nie = effects$nie,
        nde = effects$nde,
        P_true = P_true_list
      ))
    } else {
      return(NULL)
    }
  }

  # Execute loop
  if (parallel) {
    results <- parallel::parLapply(cl, 1:n_total, function(i) {
      evaluate_param_set(i, param_grid[i, ])
    })
  } else {
    results <- lapply(1:n_total, function(i) {
      if (verbose && i %% max(1, floor(n_total/100)) == 0) {
        setTxtProgressBar(pb, i)
      }
      evaluate_param_set(i, param_grid[i, ])
    })
  }

  if (verbose) close(pb)

  # Extract compatible results
  results <- Filter(Negate(is.null), results)

  if (length(results) == 0) {
    stop("No compatible parameter sets found. Consider widening sensitivity_region.")
  }

  # Extract bounds
  nie_values <- sapply(results, function(x) x$nie)
  nde_values <- sapply(results, function(x) x$nde)

  NIE_lower <- min(nie_values, na.rm = TRUE)
  NIE_upper <- max(nie_values, na.rm = TRUE)
  NDE_lower <- min(nde_values, na.rm = TRUE)
  NDE_upper <- max(nde_values, na.rm = TRUE)

  # Extract compatible sets
  compatible_sets <- do.call(rbind, lapply(results, function(x) x$params))
  compatible_sets$NIE <- sapply(results, function(x) x$nie)
  compatible_sets$NDE <- sapply(results, function(x) x$nde)

  # Falsification
  n_compatible <- length(results)
  falsified_proportion <- 1 - (n_compatible / n_total)

  return(list(
    NIE_lower = NIE_lower,
    NIE_upper = NIE_upper,
    NDE_lower = NDE_lower,
    NDE_upper = NDE_upper,
    compatible_sets = compatible_sets,
    n_compatible = n_compatible,
    n_evaluated = n_total,
    falsified_proportion = falsified_proportion,
    naive_estimates = naive_estimates
  ))
}
