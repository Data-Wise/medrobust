#' Summarize Falsification Results
#'
#' @description
#' Provides a detailed summary of which regions of the sensitivity parameter
#' space are empirically falsified by the data. Helps understand which
#' assumptions about misclassification are most constrained by the observed data.
#'
#' @param bounds_object An object of class \code{medrobust_bounds} returned by
#'   \code{\link{bound_ne}}
#' @param by_parameter Logical. If TRUE, breaks down falsification by each
#'   parameter dimension. Default is TRUE.
#' @param n_bins Integer. Number of bins for discretizing parameters when
#'   computing falsification rates. Default is 10.
#' @param plot Logical. If TRUE, generates visualization of falsification patterns.
#'   Default is TRUE.
#'
#' @return A list of class \code{falsification_summary} containing:
#'   \item{overall}{Overall falsification rate}
#'   \item{by_parameter}{Parameter-specific falsification rates (if by_parameter=TRUE)}
#'   \item{joint_falsification}{2D falsification patterns}
#'   \item{most_constrained}{Parameters that are most falsified}
#'   \item{least_constrained}{Parameters that are least falsified}
#'   \item{plot}{ggplot2 object (if plot=TRUE)}
#'
#' @details
#' This function analyzes the compatible parameter sets to understand which
#' regions of the sensitivity space are ruled out by the testable implications.
#' High falsification rates indicate that the data are informative about that
#' particular parameter.
#'
#' The falsification analysis is useful for:
#' \itemize{
#'   \item Understanding which misclassification assumptions are most constrained
#'   \item Identifying whether bounds are wide due to weak data vs. wide sensitivity region
#'   \item Guiding choice of sensitivity parameters for future studies
#'   \item Assessing whether additional data would meaningfully narrow bounds
#' }
#'
#' @examples
#' \dontrun{
#' bounds <- bound_ne(...)
#'
#' falsif <- falsification_summary(bounds)
#' print(falsif)
#'
#' # View falsification plot
#' falsif$plot
#' }
#'
#' @seealso \code{\link{bound_ne}}, \code{\link{check_compatibility}}
#'
#' @export
falsification_summary <- function(bounds_object,
                                  by_parameter = TRUE,
                                  n_bins = 10,
                                  plot = TRUE) {

  if (!is_s7_class(bounds_object, "medrobust_bounds")) {
    stop("bounds_object must be of class 'medrobust_bounds'")
  }

  # Extract compatible sets and sensitivity region (use @ for S7 objects)
  compat <- bounds_object@compatible_sets
  sens_region <- bounds_object@sensitivity_region

  if (is.null(compat) || nrow(compat) == 0) {
    stop("No compatible parameter sets found")
  }

  # Overall falsification
  overall_falsif <- bounds_object@falsified_proportion
  n_evaluated <- bounds_object@n_evaluated
  n_compatible <- bounds_object@n_compatible
  n_falsified <- n_evaluated - n_compatible

  # Parameter-specific falsification
  param_falsif <- NULL
  most_constrained <- character(0)
  least_constrained <- character(0)

  if (by_parameter) {
    param_falsif <- compute_parameter_falsification(
      compat = compat,
      sens_region = sens_region,
      n_bins = n_bins,
      n_evaluated = n_evaluated
    )

    # Identify most/least constrained
    avg_falsif <- sapply(param_falsif, function(x) mean(x$falsification_rate))
    most_constrained <- names(sort(avg_falsif, decreasing = TRUE))[1:2]
    least_constrained <- names(sort(avg_falsif, decreasing = FALSE))[1:2]
  }

  # Joint falsification patterns (2D)
  joint_falsif <- compute_joint_falsification(
    compat = compat,
    sens_region = sens_region,
    n_bins = n_bins,
    n_evaluated = n_evaluated
  )

  # Generate plot
  plot_obj <- NULL
  if (plot) {
    # Create temporary result list for plot_falsification
    temp_result <- list(
      overall = overall_falsif,
      n_evaluated = n_evaluated,
      n_compatible = n_compatible,
      n_falsified = n_falsified,
      by_parameter = param_falsif,
      joint_falsification = joint_falsif,
      most_constrained = most_constrained,
      least_constrained = least_constrained
    )
    plot_obj <- plot_falsification(temp_result, bounds_object)
  }

  # Return S7 falsification_summary object
  return(.falsification_summary_class(
    overall = overall_falsif,
    n_evaluated = as.integer(n_evaluated),
    n_compatible = as.integer(n_compatible),
    n_falsified = as.integer(n_falsified),
    by_parameter = param_falsif,
    joint_falsification = joint_falsif,
    most_constrained = most_constrained,
    least_constrained = least_constrained,
    plot = plot_obj
  ))
}


#' Compute Parameter-Specific Falsification Rates
#'
#' @keywords internal
#' @noRd
compute_parameter_falsification <- function(compat, sens_region, n_bins, n_evaluated) {

  params <- c("sn0", "sp0", "psi_sn", "psi_sp")
  param_falsif <- list()

  for (param in params) {
    # Create bins
    param_range <- sens_region[[paste0(param, "_range")]]
    breaks <- seq(param_range[1], param_range[2], length.out = n_bins + 1)
    bin_centers <- (breaks[-1] + breaks[-(n_bins + 1)]) / 2

    # Count compatible sets in each bin
    compat_counts <- hist(compat[[param]], breaks = breaks, plot = FALSE)$counts

    # Total possible in each bin (assuming uniform grid)
    # This is approximate - exact count would require recreating full grid
    total_per_bin <- n_evaluated / n_bins

    falsif_rate <- 1 - (compat_counts / total_per_bin)
    falsif_rate[falsif_rate < 0] <- 0  # Correct for approximation errors
    falsif_rate[falsif_rate > 1] <- 1

    param_falsif[[param]] <- data.frame(
      bin_center = bin_centers,
      n_compatible = compat_counts,
      falsification_rate = falsif_rate
    )
  }

  return(param_falsif)
}


#' Compute Joint Falsification Patterns
#'
#' @keywords internal
#' @noRd
compute_joint_falsification <- function(compat, sens_region, n_bins, n_evaluated) {

  # Focus on key parameter pairs
  param_pairs <- list(
    c("psi_sn", "sn0"),
    c("psi_sn", "psi_sp"),
    c("sn0", "sp0")
  )

  joint_falsif <- list()

  for (pair in param_pairs) {
    param1 <- pair[1]
    param2 <- pair[2]

    # Create 2D bins
    range1 <- sens_region[[paste0(param1, "_range")]]
    range2 <- sens_region[[paste0(param2, "_range")]]

    breaks1 <- seq(range1[1], range1[2], length.out = n_bins + 1)
    breaks2 <- seq(range2[1], range2[2], length.out = n_bins + 1)

    # Compute 2D histogram
    h2d <- hist2d(compat[[param1]], compat[[param2]],
                  breaks1 = breaks1, breaks2 = breaks2)

    # Compute falsification rate
    total_per_cell <- n_evaluated / (n_bins^2)  # Approximate
    falsif_rate_2d <- 1 - (h2d$counts / total_per_cell)
    falsif_rate_2d[falsif_rate_2d < 0] <- 0
    falsif_rate_2d[falsif_rate_2d > 1] <- 1

    joint_falsif[[paste0(param1, "_", param2)]] <- list(
      param1 = param1,
      param2 = param2,
      bin_centers1 = (breaks1[-1] + breaks1[-(n_bins + 1)]) / 2,
      bin_centers2 = (breaks2[-1] + breaks2[-(n_bins + 1)]) / 2,
      falsification_rate = falsif_rate_2d
    )
  }

  return(joint_falsif)
}


#' Helper: 2D Histogram
#'
#' @keywords internal
#' @noRd
hist2d <- function(x, y, breaks1, breaks2) {
  # Simple 2D histogram
  n_bins1 <- length(breaks1) - 1
  n_bins2 <- length(breaks2) - 1

  counts <- matrix(0, nrow = n_bins1, ncol = n_bins2)

  for (i in 1:length(x)) {
    bin1 <- findInterval(x[i], breaks1)
    bin2 <- findInterval(y[i], breaks2)

    if (bin1 > 0 && bin1 <= n_bins1 && bin2 > 0 && bin2 <= n_bins2) {
      counts[bin1, bin2] <- counts[bin1, bin2] + 1
    }
  }

  return(list(counts = counts))
}


#' Plot Falsification Summary
#'
#' @keywords internal
#' @noRd
plot_falsification <- function(falsif_summary, bounds_object) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    warning("ggplot2 not available. Skipping plot.")
    return(NULL)
  }

  # Create multi-panel plot
  plots <- list()

  # 1. Overall falsification bar
  overall_data <- data.frame(
    category = c("Compatible", "Falsified"),
    proportion = c(1 - falsif_summary$overall, falsif_summary$overall),
    count = c(falsif_summary$n_compatible, falsif_summary$n_falsified)
  )

  p_overall <- ggplot2::ggplot(overall_data,
                               ggplot2::aes(x = "", y = proportion, fill = category)) +
    ggplot2::geom_bar(stat = "identity", width = 1) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_manual(values = c("Compatible" = "steelblue",
                                          "Falsified" = "coral")) +
    ggplot2::labs(
      title = "Overall Falsification",
      subtitle = sprintf("%.1f%% of sensitivity region falsified",
                        100 * falsif_summary$overall),
      x = "",
      y = "Proportion"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "bottom")

  plots$overall <- p_overall

  # 2. Parameter-specific falsification
  if (!is.null(falsif_summary$by_parameter)) {
    param_data_list <- lapply(names(falsif_summary$by_parameter), function(param) {
      df <- falsif_summary$by_parameter[[param]]
      df$parameter <- param
      df
    })

    param_data <- do.call(rbind, param_data_list)

    param_labels <- c(
      "sn0" = "Sn₀",
      "sp0" = "Sp₀",
      "psi_sn" = "ψ_Sn",
      "psi_sp" = "ψ_Sp"
    )

    param_data$parameter_label <- param_labels[param_data$parameter]

    p_params <- ggplot2::ggplot(param_data,
                                ggplot2::aes(x = bin_center,
                                            y = falsification_rate,
                                            color = parameter_label)) +
      ggplot2::geom_line(size = 1) +
      ggplot2::geom_point(size = 2) +
      ggplot2::facet_wrap(~ parameter_label, scales = "free_x", nrow = 2) +
      ggplot2::scale_y_continuous(labels = scales::percent_format()) +
      ggplot2::labs(
        title = "Parameter-Specific Falsification Rates",
        subtitle = "Proportion of sensitivity region falsified at each parameter value",
        x = "Parameter Value",
        y = "Falsification Rate"
      ) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        legend.position = "none",
        strip.text = ggplot2::element_text(size = 12, face = "bold")
      )

    plots$by_parameter <- p_params
  }

  # 3. Joint falsification heatmap (first pair)
  if (!is.null(falsif_summary$joint_falsification) &&
      length(falsif_summary$joint_falsification) > 0) {

    joint <- falsif_summary$joint_falsification[[1]]

    # Convert to long format for ggplot
    heatmap_data <- expand.grid(
      x = joint$bin_centers1,
      y = joint$bin_centers2
    )
    heatmap_data$falsification_rate <- as.vector(joint$falsification_rate)

    param_labels <- c(
      "sn0" = "Sn₀", "sp0" = "Sp₀",
      "psi_sn" = "ψ_Sn", "psi_sp" = "ψ_Sp"
    )

    p_joint <- ggplot2::ggplot(heatmap_data,
                               ggplot2::aes(x = x, y = y, fill = falsification_rate)) +
      ggplot2::geom_tile() +
      ggplot2::scale_fill_gradient2(
        low = "white", mid = "orange", high = "red",
        midpoint = 0.5,
        labels = scales::percent_format(),
        name = "Falsification\nRate"
      ) +
      ggplot2::labs(
        title = "Joint Falsification Pattern",
        subtitle = paste("2D falsification rates for",
                        param_labels[joint$param1], "and",
                        param_labels[joint$param2]),
        x = param_labels[joint$param1],
        y = param_labels[joint$param2]
      ) +
      ggplot2::theme_bw() +
      ggplot2::theme(legend.position = "right")

    plots$joint <- p_joint
  }

  # Combine plots if gridExtra available
  if (requireNamespace("gridExtra", quietly = TRUE) && length(plots) > 1) {
    combined_plot <- gridExtra::grid.arrange(
      grobs = plots,
      ncol = 1
    )
    return(combined_plot)
  } else {
    return(plots)
  }
}


#' Print Method for falsification_summary
#'
#' @param x An object of class \code{falsification_summary}
#' @param digits Integer. Number of decimal places. Default is 3.
#' @param ... Additional arguments (currently unused)
#'
#' @return Invisibly returns the input object
#' @export
print.falsification_summary <- function(x, digits = 3, ...) {

  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("FALSIFICATION SUMMARY\n")
  cat(strrep("=", 70), "\n\n")

  # Overall
  cat("Overall Falsification:\n")
  cat("  Total parameter sets evaluated:", x$n_evaluated, "\n")
  cat("  Compatible sets:", x$n_compatible,
      sprintf("(%.1f%%)\n", 100 * (1 - x$overall)))
  cat("  Falsified sets:", x$n_falsified,
      sprintf("(%.1f%%)\n\n", 100 * x$overall))

  # Interpretation
  if (x$overall > 0.8) {
    cat("  → High falsification: Data strongly constrain the parameter space\n")
    cat("     Bounds are relatively sharp given the sensitivity region.\n\n")
  } else if (x$overall > 0.5) {
    cat("  → Moderate falsification: Data provide meaningful constraints\n")
    cat("     Some regions of parameter space are ruled out.\n\n")
  } else if (x$overall > 0.2) {
    cat("  → Low falsification: Weak data constraints\n")
    cat("     Most of the sensitivity region remains compatible.\n\n")
  } else {
    cat("  → Very low falsification: Minimal data constraints\n")
    cat("     Consider narrowing the sensitivity region or collecting more data.\n\n")
  }

  # Parameter-specific
  if (!is.null(x$by_parameter)) {
    cat(strrep("-", 70), "\n")
    cat("Parameter-Specific Falsification:\n")
    cat(strrep("-", 70), "\n\n")

    param_table <- data.frame(
      Parameter = names(x$by_parameter),
      Mean_Falsification = sapply(x$by_parameter, function(p) {
        mean(p$falsification_rate)
      }),
      Min_Falsification = sapply(x$by_parameter, function(p) {
        min(p$falsification_rate)
      }),
      Max_Falsification = sapply(x$by_parameter, function(p) {
        max(p$falsification_rate)
      })
    )

    param_table$Mean_Falsification <- sprintf(paste0("%.", digits, "f"),
                                              param_table$Mean_Falsification)
    param_table$Min_Falsification <- sprintf(paste0("%.", digits, "f"),
                                            param_table$Min_Falsification)
    param_table$Max_Falsification <- sprintf(paste0("%.", digits, "f"),
                                            param_table$Max_Falsification)

    print(param_table, row.names = FALSE)
    cat("\n")

    if (!is.null(x$most_constrained)) {
      cat("Most constrained parameters:",
          paste(x$most_constrained, collapse = ", "), "\n")
    }
    if (!is.null(x$least_constrained)) {
      cat("Least constrained parameters:",
          paste(x$least_constrained, collapse = ", "), "\n")
    }
    cat("\n")
  }

  # Recommendations
  cat(strrep("-", 70), "\n")
  cat("RECOMMENDATIONS\n")
  cat(strrep("-", 70), "\n\n")

  if (x$overall < 0.3) {
    cat("• Bounds are wide primarily due to weak data constraints\n")
    cat("• Consider:\n")
    cat("  - Narrowing sensitivity region using external information\n")
    cat("  - Collecting validation data for a subsample\n")
    cat("  - Increasing sample size\n")
  } else if (x$overall > 0.7) {
    cat("• Data are highly informative about misclassification\n")
    cat("• Bounds are narrow relative to the sensitivity region\n")
    cat("• Current sensitivity assumptions appear appropriate\n")
  } else {
    cat("• Moderate falsification suggests balance between data and assumptions\n")
    cat("• Refine sensitivity region if expert knowledge available\n")
  }

  cat("\n")
  cat(strrep("=", 70), "\n")

  if (!is.null(x$plot)) {
    cat("Use x$plot to view falsification visualization\n")
    cat(strrep("=", 70), "\n")
  }

  cat("\n")

  invisible(x)
}


#' Extract Compatible Parameter Sets
#'
#' @description
#' Extract the compatible parameter sets from a bounds analysis.
#'
#' @param bounds_object An object of class \code{medrobust_bounds}
#'
#' @return A data frame containing compatible parameter sets
#' @export
extract_bounds <- function(bounds_object) {

  if (!is_s7_class(bounds_object, "medrobust_bounds")) {
    stop("bounds_object must be of class 'medrobust_bounds'")
  }

  return(bounds_object@compatible_sets)
}


#' Extract Falsified Region
#'
#' @description
#' Extract the subset of the sensitivity region that is empirically falsified.
#'
#' @param bounds_object An object of class \code{medrobust_bounds}
#'
#' @return A data frame containing parameter sets that were falsified
#' @export
extract_falsified_region <- function(bounds_object) {

  if (!is_s7_class(bounds_object, "medrobust_bounds")) {
    stop("bounds_object must be of class 'medrobust_bounds'")
  }

  # Get all evaluated parameter sets
  # This requires recreating the full grid
  param_grid <- create_parameter_grid(
    bounds_object@sensitivity_region,
    n_grid = round(bounds_object@n_evaluated^(1/4))  # Approximate
  )

  # Get compatible sets
  compat <- bounds_object@compatible_sets[, c("sn0", "sp0", "psi_sn", "psi_sp")]

  # Find falsified sets (those in grid but not in compatible)
  falsified <- dplyr::anti_join(param_grid, compat,
                        by = c("sn0", "sp0", "psi_sn", "psi_sp"))

  return(falsified)
}


#' Test Multiple Hypotheses
#'
#' @description
#' Test multiple hypotheses about misclassification parameters simultaneously.
#'
#' @param data Data frame
#' @param exposure Character string
#' @param mediator Character string
#' @param outcome Character string
#' @param confounders Character vector
#' @param psi_list List of parameter sets to test
#' @param misclassified_variable Character string
#'
#' @return Data frame with test results for each hypothesis
#' @export
test_multiple_hypotheses <- function(data,
                                     exposure,
                                     mediator,
                                     outcome,
                                     confounders,
                                     psi_list,
                                     misclassified_variable) {

  results <- lapply(seq_along(psi_list), function(i) {
    psi <- psi_list[[i]]

    test_result <- check_compatibility(
      data = data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      psi = psi,
      misclassified_variable = misclassified_variable,
      return_details = FALSE
    )

    data.frame(
      hypothesis = names(psi_list)[i],
      sn0 = psi$sn0,
      sp0 = psi$sp0,
      psi_sn = psi$psi_sn,
      psi_sp = psi$psi_sp,
      compatible = test_result$compatible,
      n_violated = test_result$n_constraints_violated
    )
  })

  results_df <- do.call(rbind, results)

  return(results_df)
}
