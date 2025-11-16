#' Print method for medrobust_bounds objects (S3 - Legacy)
#'
#' @description
#' Provides a clean, user-friendly display of partial identification bounds.
#' NOTE: This is a legacy S3 method. The package now uses S7 methods (see s7-methods.R).
#'
#' @param x An object of class \code{medrobust_bounds}.
#' @param digits Integer specifying the number of decimal places. Default is 3.
#' @param ... Additional arguments (not currently used).
#'
#' @return Invisibly returns the input object.
#'
#' @keywords internal
print.medrobust_bounds <- function(x, digits = 3, ...) {

  cat("\n")
  cat("=======================================================\n")
  cat("  Partial Identification Bounds for Natural Effects\n")
  cat("=======================================================\n\n")

  cat("Misclassified Variable:", x$misclassified_variable, "\n")
  cat("Sample Size: n =", x$data_summary$n, "\n")
  cat("Effect Scale:", x$effect_scale, "\n\n")

  cat("Natural Indirect Effect (NIE):\n")
  if (is.na(x$NIE_lower) || is.na(x$NIE_upper)) {
    cat("  Bounds: Not identified (all parameters falsified)\n")
  } else {
    cat("  Lower Bound:", format(round(x$NIE_lower, digits), nsmall = digits), "\n")
    cat("  Upper Bound:", format(round(x$NIE_upper, digits), nsmall = digits), "\n")

    if (!is.null(x$bootstrap_ci)) {
      ci_lower <- x$bootstrap_ci$NIE_lower_ci
      ci_upper <- x$bootstrap_ci$NIE_upper_ci
      cat("  95% CI for Lower:", sprintf("[%.2f, %.2f]", ci_lower[1], ci_lower[2]), "\n")
      cat("  95% CI for Upper:", sprintf("[%.2f, %.2f]", ci_upper[1], ci_upper[2]), "\n")
    }
  }

  cat("\nNatural Direct Effect (NDE):\n")
  if (is.na(x$NDE_lower) || is.na(x$NDE_upper)) {
    cat("  Bounds: Not identified (all parameters falsified)\n")
  } else {
    cat("  Lower Bound:", format(round(x$NDE_lower, digits), nsmall = digits), "\n")
    cat("  Upper Bound:", format(round(x$NDE_upper, digits), nsmall = digits), "\n")

    if (!is.null(x$bootstrap_ci)) {
      ci_lower <- x$bootstrap_ci$NDE_lower_ci
      ci_upper <- x$bootstrap_ci$NDE_upper_ci
      cat("  95% CI for Lower:", sprintf("[%.2f, %.2f]", ci_lower[1], ci_lower[2]), "\n")
      cat("  95% CI for Upper:", sprintf("[%.2f, %.2f]", ci_upper[1], ci_upper[2]), "\n")
    }
  }

  cat("\nFalsification:\n")
  cat(" ", sprintf("%.1f%% of sensitivity region empirically falsified\n",
                  x$falsified_proportion * 100))

  if (!is.null(x$compatible_sets) && nrow(x$compatible_sets) > 0) {
    cat(" ", sprintf("%d compatible parameter combinations found\n",
                    nrow(x$compatible_sets)))
  }

  cat("\n")
  cat("-------------------------------------------------------\n")
  cat("Use summary() for detailed diagnostics\n")
  cat("Use sensitivity_plot() for visualization\n")
  cat("=======================================================\n\n")

  invisible(x)
}


#' Summary method for medrobust_bounds objects (S3 - Legacy)
#'
#' @description
#' Provides detailed diagnostics and summary statistics for the bounds analysis.
#' NOTE: This is a legacy S3 method. The package now uses S7 methods (see s7-methods.R).
#'
#' @param object An object of class \code{medrobust_bounds}.
#' @param ... Additional arguments (not currently used).
#'
#' @return Invisibly returns a list with summary information.
#'
#' @keywords internal
summary.medrobust_bounds <- function(object, ...) {

  cat("\n")
  cat("====================================================================\n")
  cat("         Detailed Summary of Partial Identification Bounds\n")
  cat("====================================================================\n\n")

  # Basic information
  cat("ANALYSIS DETAILS\n")
  cat("----------------\n")
  cat("Misclassified Variable:", object$misclassified_variable, "\n")
  cat("Effect Scale:", object$effect_scale, "\n")
  cat("Sample Size:", object$data_summary$n, "\n\n")

  # Data summary
  cat("OBSERVED DATA SUMMARY\n")
  cat("---------------------\n")
  cat("P(A = 1):", sprintf("%.3f", object$data_summary$p_a), "\n")
  cat("P(M = 1):", sprintf("%.3f", object$data_summary$p_m), "\n")
  cat("P(Y = 1):", sprintf("%.3f", object$data_summary$p_y), "\n")

  if (object$data_summary$has_confounders) {
    cat("Confounders:", paste(object$data_summary$confounder_names, collapse = ", "), "\n")
  }
  cat("\n")

  # Bounds
  cat("PARTIAL IDENTIFICATION BOUNDS\n")
  cat("-----------------------------\n")

  if (!is.na(object$NIE_lower)) {
    nie_width <- object$NIE_upper - object$NIE_lower
    nde_width <- object$NDE_upper - object$NDE_lower

    cat("Natural Indirect Effect (NIE):\n")
    cat("  Lower Bound:", sprintf("%.3f", object$NIE_lower), "\n")
    cat("  Upper Bound:", sprintf("%.3f", object$NIE_upper), "\n")
    cat("  Width:", sprintf("%.3f", nie_width), "\n\n")

    cat("Natural Direct Effect (NDE):\n")
    cat("  Lower Bound:", sprintf("%.3f", object$NDE_lower), "\n")
    cat("  Upper Bound:", sprintf("%.3f", object$NDE_upper), "\n")
    cat("  Width:", sprintf("%.3f", nde_width), "\n\n")
  } else {
    cat("  No compatible parameters found - all falsified!\n\n")
  }

  # Falsification summary
  cat("FALSIFICATION ANALYSIS\n")
  cat("----------------------\n")
  cat("Falsified proportion:", sprintf("%.1f%%", object$falsified_proportion * 100), "\n")

  if (!is.null(object$compatible_sets) && nrow(object$compatible_sets) > 0) {
    cat("Compatible parameter combinations:", nrow(object$compatible_sets), "\n\n")

    cat("Compatible parameter ranges:\n")
    for (param in names(object$compatible_sets)) {
      vals <- object$compatible_sets[[param]]
      cat("  ", param, ":",
          sprintf("[%.3f, %.3f]", min(vals), max(vals)), "\n")
    }
  }
  cat("\n")

  # Bootstrap CI if available
  if (!is.null(object$bootstrap_ci)) {
    cat("BOOTSTRAP CONFIDENCE INTERVALS\n")
    cat("------------------------------\n")
    cat("NIE Lower Bound 95% CI:",
        sprintf("[%.3f, %.3f]",
                object$bootstrap_ci$NIE_lower_ci[1],
                object$bootstrap_ci$NIE_lower_ci[2]), "\n")
    cat("NIE Upper Bound 95% CI:",
        sprintf("[%.3f, %.3f]",
                object$bootstrap_ci$NIE_upper_ci[1],
                object$bootstrap_ci$NIE_upper_ci[2]), "\n")
    cat("NDE Lower Bound 95% CI:",
        sprintf("[%.3f, %.3f]",
                object$bootstrap_ci$NDE_lower_ci[1],
                object$bootstrap_ci$NDE_lower_ci[2]), "\n")
    cat("NDE Upper Bound 95% CI:",
        sprintf("[%.3f, %.3f]",
                object$bootstrap_ci$NDE_upper_ci[1],
                object$bootstrap_ci$NDE_upper_ci[2]), "\n")
    cat("\n")
  }

  cat("====================================================================\n\n")

  # Return summary info invisibly
  summary_info <- list(
    n = object$data_summary$n,
    bounds = list(
      NIE = c(lower = object$NIE_lower, upper = object$NIE_upper),
      NDE = c(lower = object$NDE_lower, upper = object$NDE_upper)
    ),
    falsified_proportion = object$falsified_proportion,
    n_compatible = ifelse(is.null(object$compatible_sets), 0,
                         nrow(object$compatible_sets))
  )

  invisible(summary_info)
}


#' Coerce to data frame (S3 - Legacy)
#'
#' @description
#' Extract bounds as a data frame for further analysis or export.
#' NOTE: This is a legacy S3 method. The package now uses S7 methods (see s7-methods.R).
#'
#' @param x An object of class \code{medrobust_bounds}.
#' @param row.names Optional row names (not used).
#' @param optional Logical (not used).
#' @param ... Additional arguments (not used).
#'
#' @return A data frame with one row containing the bounds.
#'
#' @keywords internal
as.data.frame.medrobust_bounds <- function(x, row.names = NULL,
                                          optional = FALSE, ...) {

  df <- data.frame(
    misclassified_variable = x@misclassified_variable,
    effect_scale = x@effect_scale,
    n = x@data_summary$n,
    NIE_lower = x@NIE_lower,
    NIE_upper = x@NIE_upper,
    NDE_lower = x@NDE_lower,
    NDE_upper = x@NDE_upper,
    falsified_proportion = x@falsified_proportion,
    stringsAsFactors = FALSE
  )

  return(df)
}
