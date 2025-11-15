#' Bootstrap Confidence Intervals for Bounds
#'
#' @description
#' Compute bootstrap confidence intervals for partial identification bounds
#' using the percentile method or BCa (bias-corrected and accelerated) method.
#'
#' @inheritParams bound_ne
#' @param bootstrap_method Character string: "percentile" or "bca"
#'
#' @return List with bootstrap results
#' @keywords internal
#' @noRd
compute_bootstrap_ci <- function(data,
                                 exposure,
                                 mediator,
                                 outcome,
                                 confounders,
                                 misclassified_variable,
                                 sensitivity_region,
                                 n_grid,
                                 effect_scale,
                                 bootstrap_reps,
                                 confidence_level,
                                 parallel,
                                 n_cores,
                                 verbose,
                                 grid_method = "lhs",
                                 bootstrap_method = "percentile") {

  n <- nrow(data)
  alpha <- 1 - confidence_level

  # Storage for bootstrap estimates
  boot_nie_lower <- numeric(bootstrap_reps)
  boot_nie_upper <- numeric(bootstrap_reps)
  boot_nde_lower <- numeric(bootstrap_reps)
  boot_nde_upper <- numeric(bootstrap_reps)

  # Progress bar
  if (verbose) {
    cat("\nBootstrap Progress:\n")
    pb <- txtProgressBar(min = 0, max = bootstrap_reps, style = 3)
  }

  # Bootstrap function
  boot_iteration <- function(b) {
    # Draw bootstrap sample with replacement
    boot_indices <- sample(1:n, size = n, replace = TRUE)
    boot_data <- data[boot_indices, ]

    # Compute bounds on bootstrap sample
    tryCatch({
      boot_bounds <- bound_ne(
        data = boot_data,
        exposure = exposure,
        mediator = mediator,
        outcome = outcome,
        confounders = confounders,
        misclassified_variable = misclassified_variable,
        sensitivity_region = sensitivity_region,
        n_grid = n_grid,
        effect_scale = effect_scale,
        grid_method = grid_method,  # Use same method as main analysis
        bootstrap = FALSE,  # Don't bootstrap the bootstrap
        parallel = FALSE,   # Avoid nested parallelization
        verbose = FALSE     # Suppress output
      )

      return(c(
        nie_lower = boot_bounds$NIE_lower,
        nie_upper = boot_bounds$NIE_upper,
        nde_lower = boot_bounds$NDE_lower,
        nde_upper = boot_bounds$NDE_upper
      ))

    }, error = function(e) {
      # Return NA if bootstrap iteration fails
      return(c(nie_lower = NA, nie_upper = NA, nde_lower = NA, nde_upper = NA))
    })
  }

  # Execute bootstrap iterations
  if (parallel && bootstrap_reps >= 100) {
    # Parallel bootstrap
    if (is.null(n_cores)) {
      n_cores <- parallel::detectCores() - 1
    }

    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl))

    # Export necessary objects
    parallel::clusterExport(cl,
                           c("data", "exposure", "mediator", "outcome",
                             "confounders", "misclassified_variable",
                             "sensitivity_region", "n_grid", "effect_scale"),
                           envir = environment())

    # Load package on workers
    parallel::clusterEvalQ(cl, {
      library(medrobust)
      library(dplyr)
    })

    # Run parallel bootstrap
    boot_results <- parallel::parLapply(cl, 1:bootstrap_reps, function(b) {
      boot_iteration(b)
    })

  } else {
    # Sequential bootstrap
    boot_results <- lapply(1:bootstrap_reps, function(b) {
      if (verbose && b %% max(1, floor(bootstrap_reps/50)) == 0) {
        setTxtProgressBar(pb, b)
      }
      boot_iteration(b)
    })
  }

  if (verbose) close(pb)

  # Convert to matrix
  boot_matrix <- do.call(rbind, boot_results)

  # Remove failed iterations
  complete_rows <- complete.cases(boot_matrix)
  n_failed <- sum(!complete_rows)

  if (n_failed > 0) {
    warning(n_failed, " bootstrap iterations failed and were removed")
    boot_matrix <- boot_matrix[complete_rows, ]
  }

  if (nrow(boot_matrix) < 100) {
    warning("Fewer than 100 successful bootstrap iterations. ",
            "Results may be unreliable.")
  }

  # Extract bootstrap estimates
  boot_nie_lower <- boot_matrix[, "nie_lower"]
  boot_nie_upper <- boot_matrix[, "nie_upper"]
  boot_nde_lower <- boot_matrix[, "nde_lower"]
  boot_nde_upper <- boot_matrix[, "nde_upper"]

  # Compute confidence intervals
  if (bootstrap_method == "percentile") {
    # Percentile method
    ci_results <- list(
      nie_lower_ci = quantile(boot_nie_lower, probs = c(alpha/2, 1-alpha/2), na.rm = TRUE),
      nie_upper_ci = quantile(boot_nie_upper, probs = c(alpha/2, 1-alpha/2), na.rm = TRUE),
      nde_lower_ci = quantile(boot_nde_lower, probs = c(alpha/2, 1-alpha/2), na.rm = TRUE),
      nde_upper_ci = quantile(boot_nde_upper, probs = c(alpha/2, 1-alpha/2), na.rm = TRUE)
    )

  } else if (bootstrap_method == "bca") {
    # BCa method (bias-corrected and accelerated)
    ci_results <- compute_bca_ci(
      boot_estimates = boot_matrix,
      confidence_level = confidence_level,
      data = data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      misclassified_variable = misclassified_variable,
      sensitivity_region = sensitivity_region,
      n_grid = n_grid,
      effect_scale = effect_scale,
      verbose = verbose
    )

  } else {
    stop("Unknown bootstrap_method: ", bootstrap_method)
  }

  # Compile results
  results <- list(
    method = bootstrap_method,
    n_reps = nrow(boot_matrix),
    n_failed = n_failed,
    confidence_level = confidence_level,

    # NIE bounds CIs
    nie_lower_ci = ci_results$nie_lower_ci,
    nie_upper_ci = ci_results$nie_upper_ci,

    # NDE bounds CIs
    nde_lower_ci = ci_results$nde_lower_ci,
    nde_upper_ci = ci_results$nde_upper_ci,

    # Bootstrap distributions
    boot_nie_lower = boot_nie_lower,
    boot_nie_upper = boot_nie_upper,
    boot_nde_lower = boot_nde_lower,
    boot_nde_upper = boot_nde_upper
  )

  if (verbose) {
    cat("\n", strrep("-", 60), "\n")
    cat("Bootstrap Results (", bootstrap_reps, " replicates, ",
        n_failed, " failed)\n", sep = "")
    cat(strrep("-", 60), "\n")
    cat("\nNIE Lower Bound ", confidence_level*100, "% CI: [",
        sprintf("%.3f", ci_results$nie_lower_ci[1]), ", ",
        sprintf("%.3f", ci_results$nie_lower_ci[2]), "]\n", sep = "")
    cat("NIE Upper Bound ", confidence_level*100, "% CI: [",
        sprintf("%.3f", ci_results$nie_upper_ci[1]), ", ",
        sprintf("%.3f", ci_results$nie_upper_ci[2]), "]\n", sep = "")
    cat("\nNDE Lower Bound ", confidence_level*100, "% CI: [",
        sprintf("%.3f", ci_results$nde_lower_ci[1]), ", ",
        sprintf("%.3f", ci_results$nde_lower_ci[2]), "]\n", sep = "")
    cat("NDE Upper Bound ", confidence_level*100, "% CI: [",
        sprintf("%.3f", ci_results$nde_upper_ci[1]), ", ",
        sprintf("%.3f", ci_results$nde_upper_ci[2]), "]\n", sep = "")
    cat(strrep("-", 60), "\n\n")
  }

  return(results)
}


#' Compute BCa Confidence Intervals
#'
#' @description
#' Compute bias-corrected and accelerated (BCa) bootstrap confidence intervals.
#' This method adjusts for bias and skewness in the bootstrap distribution.
#'
#' @param boot_estimates Matrix of bootstrap estimates
#' @param confidence_level Confidence level
#' @param ... Additional arguments passed to bound_ne for jackknife
#'
#' @return List with BCa confidence intervals
#' @keywords internal
compute_bca_ci <- function(boot_estimates,
                          confidence_level,
                          data,
                          exposure,
                          mediator,
                          outcome,
                          confounders,
                          misclassified_variable,
                          sensitivity_region,
                          n_grid,
                          effect_scale,
                          verbose) {

  alpha <- 1 - confidence_level
  n <- nrow(data)

  if (verbose) {
    cat("Computing BCa adjustments (this may take a while)...\n")
  }

  # Step 1: Compute original estimates
  original_bounds <- bound_ne(
    data = data,
    exposure = exposure,
    mediator = mediator,
    outcome = outcome,
    confounders = confounders,
    misclassified_variable = misclassified_variable,
    sensitivity_region = sensitivity_region,
    n_grid = n_grid,
    effect_scale = effect_scale,
    grid_method = grid_method,
    bootstrap = FALSE,
    verbose = FALSE
  )

  theta_hat <- c(
    nie_lower = original_bounds$NIE_lower,
    nie_upper = original_bounds$NIE_upper,
    nde_lower = original_bounds$NDE_lower,
    nde_upper = original_bounds$NDE_upper
  )

  # Step 2: Compute bias correction (z0)
  # z0 = Phi^{-1}(proportion of bootstrap estimates < theta_hat)
  z0 <- sapply(1:4, function(j) {
    prop_less <- mean(boot_estimates[, j] < theta_hat[j], na.rm = TRUE)
    qnorm(prop_less)
  })

  # Step 3: Compute acceleration (a) via jackknife
  if (verbose) {
    cat("Computing jackknife estimates for acceleration...\n")
  }

  # For computational efficiency, use a subsample for jackknife if n > 200
  if (n > 200) {
    jackknife_n <- 200
    jackknife_indices <- sample(1:n, jackknife_n)
    if (verbose) {
      cat("Using subsample of", jackknife_n, "for jackknife\n")
    }
  } else {
    jackknife_indices <- 1:n
    jackknife_n <- n
  }

  jack_estimates <- matrix(NA, nrow = jackknife_n, ncol = 4)

  for (i in 1:jackknife_n) {
    # Leave-one-out sample
    jack_data <- data[-jackknife_indices[i], ]

    tryCatch({
      jack_bounds <- bound_ne(
        data = jack_data,
        exposure = exposure,
        mediator = mediator,
        outcome = outcome,
        confounders = confounders,
        misclassified_variable = misclassified_variable,
        sensitivity_region = sensitivity_region,
        n_grid = max(20, floor(n_grid/2)),  # Use coarser grid for speed
        effect_scale = effect_scale,
        grid_method = grid_method,
        bootstrap = FALSE,
        verbose = FALSE
      )

      jack_estimates[i, ] <- c(
        jack_bounds$NIE_lower,
        jack_bounds$NIE_upper,
        jack_bounds$NDE_lower,
        jack_bounds$NDE_upper
      )
    }, error = function(e) {
      # Leave as NA if iteration fails
    })
  }

  # Compute acceleration parameter
  jack_mean <- colMeans(jack_estimates, na.rm = TRUE)

  a <- sapply(1:4, function(j) {
    jack_vals <- jack_estimates[, j]
    jack_vals <- jack_vals[!is.na(jack_vals)]

    if (length(jack_vals) < 10) {
      return(0)  # Not enough data, set a=0
    }

    numerator <- sum((jack_mean[j] - jack_vals)^3)
    denominator <- 6 * sum((jack_mean[j] - jack_vals)^2)^(3/2)

    if (abs(denominator) < 1e-10) {
      return(0)
    }

    return(numerator / denominator)
  })

  # Step 4: Compute adjusted percentiles
  z_alpha_lower <- qnorm(alpha / 2)
  z_alpha_upper <- qnorm(1 - alpha / 2)

  adjusted_percentiles <- sapply(1:4, function(j) {
    # Lower percentile
    p_lower <- pnorm(z0[j] + (z0[j] + z_alpha_lower) /
                      (1 - a[j] * (z0[j] + z_alpha_lower)))

    # Upper percentile
    p_upper <- pnorm(z0[j] + (z0[j] + z_alpha_upper) /
                      (1 - a[j] * (z0[j] + z_alpha_upper)))

    c(lower = p_lower, upper = p_upper)
  })

  # Step 5: Compute BCa confidence intervals
  ci_results <- list(
    nie_lower_ci = quantile(boot_estimates[, 1],
                           probs = adjusted_percentiles[, 1], na.rm = TRUE),
    nie_upper_ci = quantile(boot_estimates[, 2],
                           probs = adjusted_percentiles[, 2], na.rm = TRUE),
    nde_lower_ci = quantile(boot_estimates[, 3],
                           probs = adjusted_percentiles[, 3], na.rm = TRUE),
    nde_upper_ci = quantile(boot_estimates[, 4],
                           probs = adjusted_percentiles[, 4], na.rm = TRUE)
  )

  # Add BCa parameters to output
  ci_results$z0 <- z0
  ci_results$acceleration <- a

  return(ci_results)
}


#' Compute Standard Errors for Bounds
#'
#' @description
#' Estimate standard errors for the lower and upper bounds using the
#' bootstrap distribution.
#'
#' @param bootstrap_results List returned by compute_bootstrap_ci
#'
#' @return Named vector of standard errors
#' @export
compute_bound_se <- function(bootstrap_results) {

  if (is.null(bootstrap_results)) {
    stop("bootstrap_results is NULL. Run bound_ne with bootstrap=TRUE first.")
  }

  se_results <- c(
    nie_lower_se = sd(bootstrap_results$boot_nie_lower, na.rm = TRUE),
    nie_upper_se = sd(bootstrap_results$boot_nie_upper, na.rm = TRUE),
    nde_lower_se = sd(bootstrap_results$boot_nde_lower, na.rm = TRUE),
    nde_upper_se = sd(bootstrap_results$boot_nde_upper, na.rm = TRUE)
  )

  return(se_results)
}


#' Compute Width of Bootstrap Distribution
#'
#' @description
#' Compute the mean, median, and range of bound widths from bootstrap samples.
#'
#' @param bootstrap_results List returned by compute_bootstrap_ci
#' @param effect Character string: "NIE" or "NDE"
#'
#' @return List with width statistics
#' @export
bootstrap_width_summary <- function(bootstrap_results, effect = "NIE") {

  if (is.null(bootstrap_results)) {
    stop("bootstrap_results is NULL. Run bound_ne with bootstrap=TRUE first.")
  }

  effect <- match.arg(effect, c("NIE", "NDE"))

  if (effect == "NIE") {
    widths <- bootstrap_results$boot_nie_upper - bootstrap_results$boot_nie_lower
  } else {
    widths <- bootstrap_results$boot_nde_upper - bootstrap_results$boot_nde_lower
  }

  # Remove any NA or negative widths
  widths <- widths[!is.na(widths) & widths >= 0]

  if (length(widths) == 0) {
    stop("No valid width estimates available")
  }

  summary_stats <- list(
    mean_width = mean(widths),
    median_width = median(widths),
    sd_width = sd(widths),
    min_width = min(widths),
    max_width = max(widths),
    iqr_width = IQR(widths),
    quantiles = quantile(widths, probs = c(0.25, 0.5, 0.75))
  )

  return(summary_stats)
}


#' Plot Bootstrap Distribution
#'
#' @description
#' Visualize the bootstrap distribution of bounds.
#'
#' @param bootstrap_results List returned by compute_bootstrap_ci
#' @param effect Character string: "NIE" or "NDE"
#' @param original_bounds Original bound estimates (optional)
#'
#' @return ggplot2 object
#' @export
plot_bootstrap_distribution <- function(bootstrap_results,
                                       effect = "NIE",
                                       original_bounds = NULL) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting")
  }

  effect <- match.arg(effect, c("NIE", "NDE"))

  # Extract bootstrap estimates
  if (effect == "NIE") {
    boot_lower <- bootstrap_results$boot_nie_lower
    boot_upper <- bootstrap_results$boot_nie_upper
    if (!is.null(original_bounds)) {
      orig_lower <- original_bounds$NIE_lower
      orig_upper <- original_bounds$NIE_upper
    }
  } else {
    boot_lower <- bootstrap_results$boot_nde_lower
    boot_upper <- bootstrap_results$boot_nde_upper
    if (!is.null(original_bounds)) {
      orig_lower <- original_bounds$NDE_lower
      orig_upper <- original_bounds$NDE_upper
    }
  }

  # Create data frame for plotting
  plot_data <- data.frame(
    lower = boot_lower,
    upper = boot_upper
  )

  # Remove NA values
  plot_data <- plot_data[complete.cases(plot_data), ]

  # Create plot
  p <- ggplot2::ggplot(plot_data) +
    ggplot2::geom_histogram(ggplot2::aes(x = lower),
                           fill = "steelblue", alpha = 0.6, bins = 30) +
    ggplot2::geom_histogram(ggplot2::aes(x = upper),
                           fill = "coral", alpha = 0.6, bins = 30) +
    ggplot2::labs(
      title = paste("Bootstrap Distribution of", effect, "Bounds"),
      x = "Effect Estimate",
      y = "Frequency",
      subtitle = paste0("Blue = Lower Bound, Red = Upper Bound (n=",
                       nrow(plot_data), " bootstrap samples)")
    ) +
    ggplot2::theme_bw()

  # Add vertical lines for original estimates if provided
  if (!is.null(original_bounds)) {
    p <- p +
      ggplot2::geom_vline(xintercept = orig_lower,
                         linetype = "dashed", color = "darkblue", size = 1) +
      ggplot2::geom_vline(xintercept = orig_upper,
                         linetype = "dashed", color = "darkred", size = 1)
  }

  return(p)
}
