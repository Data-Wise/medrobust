#' Power Analysis for Partial Identification Bounds
#'
#' @description
#' Conducts simulation-based power analysis to determine the sample size
#' needed to achieve a target bound width or to rule out the null hypothesis
#' with high probability.
#'
#' @param true_params Named list of true causal parameters (see \code{\link{simulate_dm_data}})
#' @param dm_params Named list of misclassification parameters
#' @param sensitivity_region Named list defining Theta_Psi for bound_ne
#' @param misclass_type Character string. "exposure" or "mediator"
#' @param sample_sizes Integer vector. Sample sizes to evaluate. Default is
#'   seq(100, 1000, by = 100).
#' @param target_width Numeric. Target bound width. If specified, finds minimum
#'   sample size to achieve this width with high probability. Default is NULL.
#' @param target_power Numeric. Target power for rejecting null. Default is 0.80.
#' @param alpha Numeric. Significance level. Default is 0.05.
#' @param effect Character string. Which effect to power for: "NIE" or "NDE".
#'   Default is "NIE".
#' @param n_sim Integer. Number of simulation replicates per sample size.
#'   Default is 100.
#' @param n_grid Integer. Grid resolution for bound_ne. Default is 30.
#' @param confounders Integer. Number of confounders. Default is 1.
#' @param parallel Logical. Use parallel processing? Default is TRUE.
#' @param n_cores Integer. Number of cores. Default is NULL (auto-detect).
#' @param verbose Logical. Print progress? Default is TRUE.
#' @param seed Integer. Random seed. Default is 12345.
#'
#' @return An S7 object of class \code{power_analysis_result} containing:
#'   \item{power_curve}{Data frame with power by sample size}
#'   \item{true_effect}{True effect value}
#'   \item{target_power}{Target power level}
#'   \item{target_width}{Target bound width (if specified)}
#'   \item{recommended_n_power}{Recommended sample size for target power}
#'   \item{recommended_n_width}{Recommended sample size for target width}
#'   \item{simulation_params}{Parameters used for simulation}
#'
#' @examples
#' \dontrun{
#' # Power analysis for exposure DM with moderate effects
#' power_result <- power_analysis(
#'   true_params = list(beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405),
#'   dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
#'   sensitivity_region = list(
#'     sn0_range = c(0.80, 0.90),
#'     sp0_range = c(0.80, 0.90),
#'     psi_sn_range = c(1.0, 2.0),
#'     psi_sp_range = c(1.0, 1.0)
#'   ),
#'   misclass_type = "exposure",
#'   sample_sizes = c(200, 400, 600, 800, 1000),
#'   target_width = 0.3,
#'   target_power = 0.80,
#'   n_sim = 100
#' )
#'
#' print(power_result)
#' plot(power_result)
#' }
#'
#' @seealso \code{\link{simulate_dm_data}}, \code{\link{bound_ne}}
#'
#' @importFrom parallel detectCores makeCluster stopCluster clusterExport clusterEvalQ parLapply
#' @export
power_analysis <- function(true_params,
                          dm_params,
                          sensitivity_region,
                          misclass_type = c("exposure", "mediator"),
                          sample_sizes = seq(100, 1000, by = 100),
                          target_width = NULL,
                          target_power = 0.80,
                          alpha = 0.05,
                          effect = c("NIE", "NDE"),
                          n_sim = 100,
                          n_grid = 30,
                          confounders = 1,
                          parallel = TRUE,
                          n_cores = NULL,
                          verbose = TRUE,
                          seed = 12345) {

  # Match arguments
  misclass_type <- match.arg(misclass_type)
  effect <- match.arg(effect)

  # Set master seed
  set.seed(seed)

  if (verbose) {
    cat("\n")
    cat(strrep("=", 70), "\n")
    cat("POWER ANALYSIS FOR PARTIAL IDENTIFICATION BOUNDS\n")
    cat(strrep("=", 70), "\n\n")
    cat("Sample sizes:", paste(sample_sizes, collapse = ", "), "\n")
    cat("Simulations per sample size:", n_sim, "\n")
    cat("Target power:", target_power, "\n")
    if (!is.null(target_width)) {
      cat("Target bound width:", target_width, "\n")
    }
    cat("\n")
  }

  # Compute true effect for reference
  sim_large <- simulate_dm_data(
    n = 10000,
    true_params = true_params,
    dm_params = dm_params,
    misclass_type = misclass_type,
    confounders = confounders,
    seed = seed
  )

  true_effect_value <- sim_large@true_effects[[effect]]
  null_value <- 1

  if (verbose) {
    cat("True", effect, "=", sprintf("%.3f", true_effect_value), "\n\n")
  }

  # Create function to run simulations for one sample size
  run_one_n <- function(n_idx) {
    n <- sample_sizes[n_idx]

    if (verbose) {
      cat("Sample size n =", n, "...\n")
    }

    sim_results <- run_power_simulations(
      n = n,
      n_sim = n_sim,
      true_params = true_params,
      dm_params = dm_params,
      sensitivity_region = sensitivity_region,
      misclass_type = misclass_type,
      confounders = confounders,
      effect = effect,
      true_effect_value = true_effect_value,
      null_value = null_value,
      n_grid = n_grid,
      parallel = parallel,
      n_cores = n_cores,
      verbose = verbose,
      seed = seed + n_idx
    )

    if (verbose) {
      cat("  Power:", sprintf("%.3f", sim_results$power), "\n")
      cat("  Coverage:", sprintf("%.3f", sim_results$coverage), "\n")
      cat("  Median width:", sprintf("%.3f", sim_results$median_width), "\n\n")
    }

    data.frame(
      n = n,
      power = sim_results$power,
      coverage = sim_results$coverage,
      mean_width = sim_results$mean_width,
      median_width = sim_results$median_width,
      sd_width = sim_results$sd_width,
      mean_lower = sim_results$mean_lower,
      mean_upper = sim_results$mean_upper
    )
  }

  # Run all sample sizes (use lapply instead of for loop)
  results_list <- lapply(seq_along(sample_sizes), run_one_n)

  # Combine results (more efficient than rbind in loop)
  power_curve <- do.call(rbind, results_list)

  # Find recommended sample size
  if (!is.null(target_width)) {
    adequate_n <- power_curve$n[power_curve$median_width <= target_width]
    if (length(adequate_n) > 0) {
      recommended_n_width <- as.integer(min(adequate_n))
    } else {
      recommended_n_width <- NA_integer_
    }
  } else {
    recommended_n_width <- NA_integer_
  }

  # Find n for target power
  adequate_power_n <- power_curve$n[power_curve$power >= target_power]
  if (length(adequate_power_n) > 0) {
    recommended_n_power <- as.integer(min(adequate_power_n))
  } else {
    recommended_n_power <- NA_integer_
  }

  # Return S7 object
  result <- power_analysis_result(
    power_curve = power_curve,
    true_effect = true_effect_value,
    target_power = target_power,
    target_width = target_width,
    recommended_n_power = recommended_n_power,
    recommended_n_width = recommended_n_width,
    simulation_params = list(
      true_params = true_params,
      dm_params = dm_params,
      sensitivity_region = sensitivity_region,
      misclass_type = misclass_type,
      effect = effect,
      n_sim = n_sim,
      seed = seed
    )
  )

  return(result)
}


#' Run Power Simulations for One Sample Size
#'
#' @keywords internal
#' @noRd
run_power_simulations <- function(n, n_sim, true_params, dm_params,
                                  sensitivity_region, misclass_type,
                                  confounders, effect, true_effect_value,
                                  null_value, n_grid, parallel, n_cores,
                                  verbose, seed) {

  # Simulation function
  run_one_sim <- function(sim_idx) {
    # Generate data
    sim_data <- simulate_dm_data(
      n = n,
      true_params = true_params,
      dm_params = dm_params,
      misclass_type = misclass_type,
      confounders = confounders,
      seed = seed + sim_idx * 1000,
      return_truth = FALSE,
      return_params = FALSE
    )

    # Get variable names
    if (misclass_type == "exposure") {
      exposure_var <- "A_star"
      mediator_var <- "M"
    } else {
      exposure_var <- "A"
      mediator_var <- "M_star"
    }

    confounder_vars <- if (confounders > 0) {
      paste0("C", 1:confounders)
    } else {
      NULL
    }

    # Compute bounds
    # Note: Disable parallel in bound_ne to avoid nested parallelism issues
    tryCatch({
      bounds <- bound_ne(
        data = sim_data@observed,
        exposure = exposure_var,
        mediator = mediator_var,
        outcome = "Y",
        confounders = confounder_vars,
        misclassified_variable = misclass_type,
        sensitivity_region = sensitivity_region,
        n_grid = n_grid,
        effect_scale = "OR",
        grid_method = "lhs",  # Use LHS for speed
        bootstrap = FALSE,
        verbose = FALSE
      )

      # Extract bounds for specified effect
      if (effect == "NIE") {
        lower <- bounds@NIE_lower
        upper <- bounds@NIE_upper
      } else {
        lower <- bounds@NDE_lower
        upper <- bounds@NDE_upper
      }

      # Check coverage and power
      covers <- (true_effect_value >= lower) && (true_effect_value <= upper)
      rejects <- (lower > null_value) || (upper < null_value)
      width <- upper - lower

      c(covers = as.numeric(covers),
        rejects = as.numeric(rejects),
        width = width,
        lower = lower,
        upper = upper,
        success = 1)

    }, error = function(e) {
      c(covers = NA_real_,
        rejects = NA_real_,
        width = NA_real_,
        lower = NA_real_,
        upper = NA_real_,
        success = 0)
    })
  }

  # Run simulations (parallel or sequential)
  if (parallel && n_sim >= 10) {
    if (is.null(n_cores)) {
      n_cores <- max(1, parallel::detectCores() - 1)
    }

    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)

    # Export objects
    parallel::clusterExport(cl,
                           c("n", "true_params", "dm_params", "sensitivity_region",
                             "misclass_type", "confounders", "effect",
                             "true_effect_value", "null_value", "n_grid", "seed"),
                           envir = environment())

    # Load package
    parallel::clusterEvalQ(cl, {
      library(medrobust)
    })

    sim_results <- parallel::parLapply(cl, 1:n_sim, run_one_sim)

  } else {
    sim_results <- lapply(1:n_sim, run_one_sim)
  }

  # Vectorized extraction - convert list to matrix
  results_matrix <- do.call(rbind, sim_results)

  # Extract columns
  covers_truth <- results_matrix[, "covers"]
  rejects_null <- results_matrix[, "rejects"]
  widths <- results_matrix[, "width"]
  lower_bounds <- results_matrix[, "lower"]
  upper_bounds <- results_matrix[, "upper"]
  success <- results_matrix[, "success"]

  # Filter valid results (vectorized)
  valid <- success == 1 & !is.na(covers_truth)
  n_valid <- sum(valid)
  n_failed <- n_sim - n_valid

  # Only warn if both: (1) >30% failed AND (2) at least 10 failures (avoid warnings for small n_sim in tests)
  if (n_valid < n_sim * 0.7 && n_failed >= 10) {
    warning("More than 30% of simulations failed for n=", n, " (",
            n_failed, " failures)")
  }

  # Compute summary statistics (vectorized operations)
  if (n_valid > 0) {
    power <- mean(rejects_null[valid])
    coverage <- mean(covers_truth[valid])
    mean_width <- mean(widths[valid])
    median_width <- median(widths[valid])
    sd_width <- sd(widths[valid])
    mean_lower <- mean(lower_bounds[valid])
    mean_upper <- mean(upper_bounds[valid])
  } else {
    # All simulations failed
    power <- NA_real_
    coverage <- NA_real_
    mean_width <- NA_real_
    median_width <- NA_real_
    sd_width <- NA_real_
    mean_lower <- NA_real_
    mean_upper <- NA_real_
  }

  list(
    power = power,
    coverage = coverage,
    mean_width = mean_width,
    median_width = median_width,
    sd_width = sd_width,
    mean_lower = mean_lower,
    mean_upper = mean_upper,
    n_valid = n_valid
  )
}
