#' Bounds for Exposure Misclassification
#'
#' @description
#' Internal function implementing Algorithm 5.1 from the paper for
#' differential misclassification of the exposure.
#'
#' @inheritParams bound_ne
#' @keywords internal
#' @noRd
#' @importFrom rlang sym !!
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
                              verbose,
                              use_adaptive_grid = TRUE,
                              grid_method = "auto") {

  # Extract variable names
  A_star_name <- exposure
  M_name <- mediator
  Y_name <- outcome
  C_names <- confounders

  # Pre-compute observed probabilities (OPTIMIZATION 1)
  if (verbose) cat("Pre-computing observed probabilities...\n")
  precomputed <- precompute_observed_probs(data, A_star_name, M_name, Y_name,
                                           C_names, "exposure")

  # Compute naive estimates
  naive_estimates <- compute_naive_effects(data, A_star_name, M_name,
                                           Y_name, C_names, effect_scale)

  # Main evaluation function (OPTIMIZED with early termination and vectorization)
  evaluate_param_set <- function(i, param_row) {
    # Extract parameters
    sn0 <- param_row$sn0
    sp0 <- param_row$sp0
    psi_sn <- param_row$psi_sn
    psi_sp <- param_row$psi_sp

    # Compute sn1, sp1
    sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
    sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))

    # OPTIMIZATION: Early termination - validity check
    if (is.na(sn1) || is.na(sp1) || sn1 < 0 || sn1 > 1 || sp1 < 0 || sp1 > 1) {
      return(NULL)
    }

    # OPTIMIZATION: Early termination - informativeness check
    if ((sn0 + sp0 - 1) <= 0.01 || (sn1 + sp1 - 1) <= 0.01) {
      return(NULL)
    }

    # Use pre-computed strata and probabilities
    obs_probs <- precomputed$obs_probs
    strata <- precomputed$strata
    stratum_sizes <- precomputed$stratum_sizes

    # VECTORIZATION: Create all combinations upfront (avoid nested loops)
    m_vals <- c(0, 1)
    y_vals <- c(0, 1)
    combinations <- expand.grid(
      m = m_vals,
      y = y_vals,
      s = strata$stratum_id,
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )

    # Pre-compute sensitivity/specificity vectors
    combinations$sn_y <- ifelse(combinations$y == 1, sn1, sn0)
    combinations$sp_y <- ifelse(combinations$y == 1, sp1, sp0)
    combinations$denom <- combinations$sn_y + combinations$sp_y - 1

    # Vectorized stratum size check
    size_check <- vapply(seq_len(nrow(combinations)), function(i) {
      size_row <- stratum_sizes[
        stratum_sizes[[M_name]] == combinations$m[i] &
        stratum_sizes[[Y_name]] == combinations$y[i] &
        stratum_sizes$stratum_id == combinations$s[i], ]
      nrow(size_row) > 0 && size_row$n[1] >= 5
    }, logical(1))

    # Early termination if any stratum too small
    if (!all(size_check)) {
      return(NULL)
    }

    # Vectorized probability lookup (fastest approach using direct indexing)
    keys_1 <- paste0("m", combinations$m, "_y", combinations$y, "_s",
                     combinations$s, "_a1")
    keys_0 <- paste0("m", combinations$m, "_y", combinations$y, "_s",
                     combinations$s, "_a0")

    # Direct lookup with default 0 for missing keys
    # Use vapply to ensure correct length and handle missing keys
    P_star_1_vec <- vapply(keys_1, function(k) {
      val <- obs_probs[[k]]
      if (is.null(val) || is.na(val)) 0 else val
    }, numeric(1), USE.NAMES = FALSE)

    P_star_0_vec <- vapply(keys_0, function(k) {
      val <- obs_probs[[k]]
      if (is.null(val) || is.na(val)) 0 else val
    }, numeric(1), USE.NAMES = FALSE)

    # Vectorized testable implications check
    test1 <- (P_star_0_vec > 1e-6) &
             (P_star_1_vec / P_star_0_vec < (1 - combinations$sp_y) / combinations$sp_y - 1e-6)
    test2 <- (P_star_1_vec > 1e-6) &
             (P_star_0_vec / P_star_1_vec < (1 - combinations$sn_y) / combinations$sn_y - 1e-6)

    # Early termination if any implication violated
    if (any(test1) || any(test2)) {
      return(NULL)
    }

    # Vectorized solve for true probabilities
    P_1my_vec <- (combinations$sp_y * P_star_1_vec -
                  (1 - combinations$sp_y) * P_star_0_vec) / combinations$denom
    P_0my_vec <- (combinations$sn_y * P_star_0_vec -
                  (1 - combinations$sn_y) * P_star_1_vec) / combinations$denom

    # Vectorized non-negativity check
    if (any(P_1my_vec < -1e-6) || any(P_0my_vec < -1e-6)) {
      return(NULL)
    }

    # The solve recovers the CONDITIONAL P(A = a | M = m, Y = y, C = s) (obs_probs
    # is conditional on the M,Y,C cell), but compute_effects_from_joint_probs()
    # expects the JOINT P(A = a, M = m, Y = y | C = s). Since M and Y are NOT
    # misclassified in the exposure scenario, P(M = m, Y = y | C = s) is the
    # observed cell frequency; multiply to convert conditional -> joint. Omitting
    # this weight makes the M,Y marginal effectively uniform, which collapses
    # P(M | A=1) and P(M | A=0) toward the same shape and drives NIE toward the
    # null while leaving NDE (which fixes the mediator distribution at M(0))
    # largely intact.
    Pmy_vec <- vapply(seq_len(nrow(combinations)), function(i) {
      sz <- stratum_sizes[stratum_sizes[[M_name]] == combinations$m[i] &
                            stratum_sizes[[Y_name]] == combinations$y[i] &
                            stratum_sizes$stratum_id == combinations$s[i], ]
      n_s <- sum(stratum_sizes$n[stratum_sizes$stratum_id == combinations$s[i]])
      if (nrow(sz) == 0 || n_s == 0) 0 else sz$n[1] / n_s
    }, numeric(1))
    P_1my_vec <- P_1my_vec * Pmy_vec
    P_0my_vec <- P_0my_vec * Pmy_vec

    # Store results in list format (convert vectors to list)
    P_true_list <- lapply(seq_len(nrow(combinations)), function(i) {
      c(P_1 = max(0, P_1my_vec[i]),
        P_0 = max(0, P_0my_vec[i]),
        stratum_id = combinations$s[i],
        M = combinations$m[i],
        Y = combinations$y[i])
    })
    names(P_true_list) <- paste0("m", combinations$m, "_y", combinations$y,
                                  "_s", combinations$s)

    # If we got here, parameter set is compatible
    effects <- compute_effects_from_joint_probs(
      P_true_list = P_true_list,
      data = precomputed$data,
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
  }

  # OPTIMIZATION: Choose grid search strategy
  use_advanced_method <- (grid_method != "regular") &&
                        ((grid_method == "adaptive" && use_adaptive_grid && n_grid >= 10) ||
                         grid_method %in% c("auto", "lhs", "sobol", "binary"))

  if (use_advanced_method) {
    # Use advanced grid search algorithms
    if (grid_method == "adaptive" || (grid_method == "auto" && use_adaptive_grid && n_grid >= 10)) {
      # Adaptive grid refinement
      results <- adaptive_grid_search(
        sensitivity_region = sensitivity_region,
        evaluate_func = evaluate_param_set,
        n_grid_fine = n_grid,
        coarse_factor = min(5, ceiling(n_grid / 3)),
        verbose = verbose
      )
    } else if (grid_method == "lhs") {
      # Latin Hypercube Sampling
      target_samples <- ceiling(sqrt(n_grid^4))  # sqrt of full grid
      results <- latin_hypercube_search(
        sensitivity_region = sensitivity_region,
        evaluate_func = evaluate_param_set,
        n_samples = target_samples,
        verbose = verbose
      )
    } else if (grid_method == "sobol") {
      # Sobol sequence
      target_samples <- ceiling(sqrt(n_grid^4))
      results <- sobol_sequence_search(
        sensitivity_region = sensitivity_region,
        evaluate_func = evaluate_param_set,
        n_samples = target_samples,
        verbose = verbose
      )
    } else if (grid_method == "binary") {
      # Binary search on bounds
      results <- binary_search_bounds(
        sensitivity_region = sensitivity_region,
        evaluate_func = evaluate_param_set,
        verbose = verbose
      )
    } else {  # "auto"
      # Auto-select best method
      target_samples <- min(500, ceiling(sqrt(n_grid^4)))
      results <- auto_grid_search(
        sensitivity_region = sensitivity_region,
        evaluate_func = evaluate_param_set,
        target_samples = target_samples,
        verbose = verbose
      )

      # If auto returns NULL (all compatible), fall back to regular grid
      if (is.null(results)) {
        use_advanced_method <- FALSE
      }
    }

    if (use_advanced_method) {
      n_total_evaluated <- attr(results, "n_evaluated")
      if (is.null(n_total_evaluated)) n_total_evaluated <- length(results)

      # Check if any compatible sets were found
      if (length(results) == 0) {
        stop("No compatible parameter sets found. Consider widening sensitivity_region.")
      }
    }
  }

  if (!use_advanced_method) {
    # Standard grid search for small grids
    if (verbose) {
      cat("Creating parameter grid...\n")
      cat("Grid resolution:", n_grid, "points per dimension\n")
      cat("Total parameter sets:", n_grid^4, "\n")
    }

    param_grid <- create_parameter_grid(sensitivity_region, n_grid)
    n_total <- nrow(param_grid)

    # Setup parallel processing if requested
    if (parallel) {
      if (is.null(n_cores)) {
        n_cores <- parallel::detectCores() - 1
      }
      if (verbose) cat("Using", n_cores, "cores for parallel processing\n")

      cl <- parallel::makeCluster(n_cores)
      on.exit(parallel::stopCluster(cl), add = TRUE)

      # Export to workers
      parallel::clusterExport(cl, c("precomputed", "A_star_name", "M_name",
                                     "Y_name", "C_names", "effect_scale"),
                             envir = environment())
      parallel::clusterExport(cl, c("odds_to_prob", "prob_to_odds",
                                     "compute_effects_from_joint_probs"),
                             envir = asNamespace("medrobust"))
      parallel::clusterEvalQ(cl, {
        library(dplyr)
        library(rlang)
      })

      results <- parallel::parLapply(cl, 1:n_total, function(i) {
        evaluate_param_set(i, param_grid[i, ])
      })
    } else {
      # Sequential with progress bar
      if (verbose) {
        pb <- txtProgressBar(min = 0, max = n_total, style = 3)
      }

      results <- lapply(1:n_total, function(i) {
        if (verbose && i %% max(1, floor(n_total/100)) == 0) {
          setTxtProgressBar(pb, i)
        }
        evaluate_param_set(i, param_grid[i, ])
      })

      if (verbose) close(pb)
    }

    # Filter compatible results
    results <- Filter(Negate(is.null), results)
    n_total_evaluated <- n_total

    if (length(results) == 0) {
      stop("No compatible parameter sets found. Consider widening sensitivity_region.")
    }
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
  falsified_proportion <- 1 - (n_compatible / n_total_evaluated)

  return(list(
    NIE_lower = NIE_lower,
    NIE_upper = NIE_upper,
    NDE_lower = NDE_lower,
    NDE_upper = NDE_upper,
    compatible_sets = compatible_sets,
    n_compatible = n_compatible,
    n_evaluated = n_total_evaluated,
    falsified_proportion = falsified_proportion,
    naive_estimates = naive_estimates
  ))
}
