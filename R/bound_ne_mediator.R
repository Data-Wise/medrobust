#' Bounds for Mediator Misclassification
#'
#' @description
#' Internal function implementing Algorithm 4.1 from the paper for
#' differential misclassification of the mediator.
#'
#' @inheritParams bound_ne
#' @keywords internal
#' @noRd
bound_ne_mediator <- function(data,
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
  A_name <- exposure
  M_star_name <- mediator
  Y_name <- outcome
  C_names <- confounders

  # Create parameter grid
  if (verbose) cat("Creating parameter grid...\n")
  param_grid <- create_parameter_grid(sensitivity_region, n_grid)
  n_total <- nrow(param_grid)

  # Compute naive estimates (for comparison)
  naive_estimates <- compute_naive_effects(data, A_name, M_star_name,
                                           Y_name, C_names, effect_scale)

  # Initialize storage for compatible sets and effects
  compatible_params <- list()
  nie_values <- numeric(0)
  nde_values <- numeric(0)

  # Setup parallel processing if requested
  if (parallel) {
    if (is.null(n_cores)) {
      n_cores <- parallel::detectCores() - 1
    }
    if (verbose) cat("Using", n_cores, "cores for parallel processing\n")

    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl))

    # Export necessary objects to cluster
    parallel::clusterExport(cl, c("data", "A_name", "M_star_name", "Y_name",
                                   "C_names", "effect_scale"),
                           envir = environment())

    # Load required packages on each worker
    parallel::clusterEvalQ(cl, {
      library(dplyr)
      library(medrobust)
    })
  }

  # Progress bar
  if (verbose) {
    pb <- txtProgressBar(min = 0, max = n_total, style = 3)
  }

  # Main loop over parameter grid
  evaluate_param_set <- function(i, param_row) {
    # Extract parameters
    sn0 <- param_row$sn0
    sp0 <- param_row$sp0
    psi_sn <- param_row$psi_sn
    psi_sp <- param_row$psi_sp

    # Compute sn1, sp1 from psi parameters
    sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
    sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))

    # Check if parameters are valid probabilities
    if (any(c(sn1, sp1) < 0 | c(sn1, sp1) > 1)) {
      return(NULL)
    }

    # Check informativeness condition
    if ((sn0 + sp0 - 1) <= 0.01 || (sn1 + sp1 - 1) <= 0.01) {
      return(NULL)
    }

    # Get unique covariate strata
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

    # Initialize storage for solved parameters
    solved_params <- list()
    compatible <- TRUE

    # Loop over exposure levels and strata
    for (a in c(0, 1)) {
      for (s in strata$stratum_id) {
        # Get data for this (a, stratum) combination
        data_as <- data |>
          dplyr::filter(!!sym(A_name) == a, stratum_id == s)

        if (nrow(data_as) < 5) {
          # Sparse stratum, skip
          compatible <- FALSE
          break
        }

        # Compute observed joint probabilities P(Y=y, M*=m* | A=a, C=c)
        obs_probs <- data_as |>
          dplyr::group_by(!!sym(Y_name), !!sym(M_star_name)) |>
          dplyr::summarise(n = n(), .groups = "drop") |>
          dplyr::mutate(prob = n / sum(n)) |>
          dplyr::select(-n)

        # Extract P_11, P_10, P_01, P_00
        P <- matrix(0, nrow = 2, ncol = 2)
        for (j in 1:nrow(obs_probs)) {
          y_val <- obs_probs[[Y_name]][j]
          m_val <- obs_probs[[M_star_name]][j]
          P[y_val + 1, m_val + 1] <- obs_probs$prob[j]
        }
        P_11 <- P[2, 2]
        P_10 <- P[2, 1]
        P_01 <- P[1, 2]
        P_00 <- P[1, 1]

        # Solve system of equations for (pi_a, gamma_a0, gamma_a1)
        # System:
        # P_11 = sn1 * gamma_a1 * pi_a + (1-sp1) * gamma_a0 * (1-pi_a)
        # P_10 = (1-sn1) * gamma_a1 * pi_a + sp1 * gamma_a0 * (1-pi_a)
        # P_01 = sn0 * (1-gamma_a1) * pi_a + (1-sp0) * (1-gamma_a0) * (1-pi_a)

        # This is a 3x3 linear system. We can solve it using matrix methods.
        # Rewrite as: A * theta = b
        # where theta = c(pi_a * gamma_a1, (1-pi_a) * gamma_a0, pi_a * (1-gamma_a1))

        A_mat <- matrix(c(
          sn1, (1-sp1), 0,
          (1-sn1), sp1, 0,
          0, 0, sn0
        ), nrow = 3, byrow = TRUE)
        A_mat[3, 3] <- sn0
        A_mat[3, 2] <- (1-sp0)

        b_vec <- c(P_11, P_10, P_01)

        # Solve system
        tryCatch({
          theta_sol <- solve(A_mat, b_vec)

          # Extract pi_a, gamma_a0, gamma_a1
          pi_gamma1 <- theta_sol[1]
          oneminuspi_gamma0 <- theta_sol[2]
          pi_oneminusgamma1 <- theta_sol[3]

          # Solve for pi_a
          pi_a <- pi_gamma1 + pi_oneminusgamma1

          # Check if valid probability
          if (pi_a < 0 || pi_a > 1) {
            compatible <- FALSE
            break
          }

          # Solve for gamma_a1, gamma_a0
          if (pi_a < 1e-6) {
            # pi_a essentially 0
            gamma_a1 <- 0.5  # Undefined, set to arbitrary value
            gamma_a0 <- oneminuspi_gamma0 / (1 - pi_a)
          } else if (pi_a > 1 - 1e-6) {
            # pi_a essentially 1
            gamma_a1 <- pi_gamma1 / pi_a
            gamma_a0 <- 0.5  # Undefined
          } else {
            gamma_a1 <- pi_gamma1 / pi_a
            gamma_a0 <- oneminuspi_gamma0 / (1 - pi_a)
          }

          # Check if valid probabilities
          if (any(c(gamma_a0, gamma_a1) < 0 | c(gamma_a0, gamma_a1) > 1)) {
            compatible <- FALSE
            break
          }

          # Store solved parameters
          solved_params[[paste0("a", a, "_s", s)]] <- list(
            pi_a = pi_a,
            gamma_a0 = gamma_a0,
            gamma_a1 = gamma_a1,
            stratum_id = s
          )

        }, error = function(e) {
          compatible <<- FALSE
        })

        if (!compatible) break
      }
      if (!compatible) break
    }

    # If compatible, compute NDE and NIE
    if (compatible) {
      effects <- compute_effects_from_params(
        solved_params = solved_params,
        data = data,
        C_names = C_names,
        effect_scale = effect_scale
      )

      return(list(
        compatible = TRUE,
        params = param_row,
        nie = effects$nie,
        nde = effects$nde,
        solved_params = solved_params
      ))
    } else {
      return(NULL)
    }
  }

  # Execute loop (parallel or sequential)
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

  # Extract compatible parameter sets
  compatible_sets <- do.call(rbind, lapply(results, function(x) x$params))
  compatible_sets$NIE <- sapply(results, function(x) x$nie)
  compatible_sets$NDE <- sapply(results, function(x) x$nde)

  # Compute falsification proportion
  n_compatible <- length(results)
  falsified_proportion <- 1 - (n_compatible / n_total)

  # Return results
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
