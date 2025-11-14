#' S7 Methods for medrobust Classes
#'
#' @description
#' Generic methods (print, summary, format, etc.) for S7 classes in medrobust.
#'
#' @name s7-methods
#' @keywords internal

library(S7)

# =============================================================================
# Methods for medrobust_bounds
# =============================================================================

#' Print method for medrobust_bounds
#'
#' @param x A medrobust_bounds object
#' @param ... Additional arguments (ignored)
#' @export
method(print, medrobust_bounds) <- function(x, ...) {
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("PARTIAL IDENTIFICATION BOUNDS\n")
  cat(strrep("=", 70), "\n\n")

  # Effect scale
  cat("Effect Scale:", x@effect_scale, "\n")
  cat("Misclassified Variable:", x@misclassified_variable, "\n\n")

  # Bounds
  cat(strrep("-", 70), "\n")
  cat("NATURAL INDIRECT EFFECT (NIE)\n")
  cat(strrep("-", 70), "\n")
  cat(sprintf("  Lower Bound: %.4f\n", x@NIE_lower))
  cat(sprintf("  Upper Bound: %.4f\n", x@NIE_upper))
  cat(sprintf("  Width:       %.4f\n\n", x@NIE_upper - x@NIE_lower))

  cat(strrep("-", 70), "\n")
  cat("NATURAL DIRECT EFFECT (NDE)\n")
  cat(strrep("-", 70), "\n")
  cat(sprintf("  Lower Bound: %.4f\n", x@NDE_lower))
  cat(sprintf("  Upper Bound: %.4f\n", x@NDE_upper))
  cat(sprintf("  Width:       %.4f\n\n", x@NDE_upper - x@NDE_lower))

  # Sensitivity analysis summary
  cat(strrep("-", 70), "\n")
  cat("SENSITIVITY ANALYSIS\n")
  cat(strrep("-", 70), "\n")
  cat(sprintf("  Parameter sets evaluated: %d\n", x@n_evaluated))
  cat(sprintf("  Compatible sets:          %d (%.1f%%)\n",
              x@n_compatible, 100 * (1 - x@falsified_proportion)))
  cat(sprintf("  Falsified sets:           %d (%.1f%%)\n\n",
              x@n_evaluated - x@n_compatible, 100 * x@falsified_proportion))

  # Bootstrap CIs if available
  if (!is.null(x@bootstrap_results)) {
    cat(strrep("-", 70), "\n")
    cat("BOOTSTRAP CONFIDENCE INTERVALS\n")
    cat(strrep("-", 70), "\n")
    cat(sprintf("  Method: %s\n", x@bootstrap_results@method))
    cat(sprintf("  Replications: %d\n", x@bootstrap_results@n_reps))
    cat(sprintf("  Confidence Level: %.1f%%\n\n",
                100 * x@bootstrap_results@confidence_level))

    cat(sprintf("  NIE Lower: [%.4f, %.4f]\n",
                x@bootstrap_results@nie_lower_ci[1],
                x@bootstrap_results@nie_lower_ci[2]))
    cat(sprintf("  NIE Upper: [%.4f, %.4f]\n",
                x@bootstrap_results@nie_upper_ci[1],
                x@bootstrap_results@nie_upper_ci[2]))
    cat(sprintf("  NDE Lower: [%.4f, %.4f]\n",
                x@bootstrap_results@nde_lower_ci[1],
                x@bootstrap_results@nde_lower_ci[2]))
    cat(sprintf("  NDE Upper: [%.4f, %.4f]\n\n",
                x@bootstrap_results@nde_upper_ci[1],
                x@bootstrap_results@nde_upper_ci[2]))
  }

  cat(strrep("=", 70), "\n")
  cat("Use summary() for detailed diagnostics\n")
  cat(strrep("=", 70), "\n\n")

  invisible(x)
}


#' Summary method for medrobust_bounds
#'
#' @param object A medrobust_bounds object
#' @param ... Additional arguments (ignored)
#' @export
method(summary, medrobust_bounds) <- function(object, ...) {
  # Print basic info
  print(object)

  # Additional diagnostics
  cat("ADDITIONAL DIAGNOSTICS\n")
  cat(strrep("=", 70), "\n\n")

  # Sensitivity region
  cat("Sensitivity Region:\n")
  cat(sprintf("  Sn0:     [%.3f, %.3f]\n",
              object@sensitivity_region@sn0_range[1],
              object@sensitivity_region@sn0_range[2]))
  cat(sprintf("  Sp0:     [%.3f, %.3f]\n",
              object@sensitivity_region@sp0_range[1],
              object@sensitivity_region@sp0_range[2]))
  cat(sprintf("  ψ_Sn:    [%.3f, %.3f]\n",
              object@sensitivity_region@psi_sn_range[1],
              object@sensitivity_region@psi_sn_range[2]))
  cat(sprintf("  ψ_Sp:    [%.3f, %.3f]\n\n",
              object@sensitivity_region@psi_sp_range[1],
              object@sensitivity_region@psi_sp_range[2]))

  # Naive estimates if available
  if (!is.null(object@naive_estimates)) {
    cat("Naive Estimates (no measurement error correction):\n")
    cat(sprintf("  NIE: %.4f\n", object@naive_estimates$NIE))
    cat(sprintf("  NDE: %.4f\n\n", object@naive_estimates$NDE))
  }

  # Data summary if available
  if (!is.null(object@data_summary)) {
    cat("Data Summary:\n")
    cat(sprintf("  Sample size: %d\n", object@data_summary$n))
    if (!is.null(object@data_summary$n_strata)) {
      cat(sprintf("  Number of strata: %d\n", object@data_summary$n_strata))
    }
    cat("\n")
  }

  # Compatible sets preview
  if (nrow(object@compatible_sets) > 0) {
    cat("Compatible Parameter Sets (first 5):\n")
    print(head(object@compatible_sets, 5))
    cat("\n")
  }

  invisible(object)
}


#' Convert medrobust_bounds to data frame
#'
#' @param x A medrobust_bounds object
#' @param ... Additional arguments (ignored)
#' @export
method(as.data.frame, medrobust_bounds) <- function(x, ...) {
  result <- data.frame(
    effect = c("NIE", "NIE", "NDE", "NDE"),
    bound = c("lower", "upper", "lower", "upper"),
    value = c(x@NIE_lower, x@NIE_upper, x@NDE_lower, x@NDE_upper),
    width = c(
      x@NIE_upper - x@NIE_lower,
      x@NIE_upper - x@NIE_lower,
      x@NDE_upper - x@NDE_lower,
      x@NDE_upper - x@NDE_lower
    ),
    scale = x@effect_scale,
    stringsAsFactors = FALSE
  )

  # Add CIs if available
  if (!is.null(x@bootstrap_results)) {
    result$ci_lower <- c(
      x@bootstrap_results@nie_lower_ci[1],
      x@bootstrap_results@nie_upper_ci[1],
      x@bootstrap_results@nde_lower_ci[1],
      x@bootstrap_results@nde_upper_ci[1]
    )
    result$ci_upper <- c(
      x@bootstrap_results@nie_lower_ci[2],
      x@bootstrap_results@nie_upper_ci[2],
      x@bootstrap_results@nde_lower_ci[2],
      x@bootstrap_results@nde_upper_ci[2]
    )
  }

  return(result)
}


# =============================================================================
# Methods for compatibility_test
# =============================================================================

#' Print method for compatibility_test
#'
#' @param x A compatibility_test object
#' @param ... Additional arguments (ignored)
#' @export
method(print, compatibility_test) <- function(x, ...) {
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("COMPATIBILITY TEST\n")
  cat(strrep("=", 70), "\n\n")

  # Tested parameters
  cat("Tested Parameters:\n")
  cat("  Sn0:", sprintf("%.3f", x@psi$sn0), "\n")
  cat("  Sp0:", sprintf("%.3f", x@psi$sp0), "\n")
  cat("  ψ_Sn:", sprintf("%.3f", x@psi$psi_sn), "\n")
  cat("  ψ_Sp:", sprintf("%.3f", x@psi$psi_sp), "\n")

  if (!is.null(x@sn1) && !is.null(x@sp1)) {
    cat("  → Sn1:", sprintf("%.3f", x@sn1), "\n")
    cat("  → Sp1:", sprintf("%.3f", x@sp1), "\n")
  }

  cat("\n")
  cat(strrep("-", 70), "\n")

  # Result
  if (x@compatible) {
    cat("RESULT: COMPATIBLE ✓\n")
    cat(strrep("-", 70), "\n\n")

    cat("The specified misclassification parameters are consistent with\n")
    cat("the observed data. All testable implications are satisfied.\n\n")

    if (x@n_constraints_total > 0) {
      cat("Constraints satisfied:", x@n_constraints_satisfied, "/",
          x@n_constraints_total, "\n\n")
    }

    if (!is.null(x@implied_probabilities)) {
      cat("Implied true causal parameters have been successfully solved.\n")
      cat("Use summary() to see detailed results.\n")
    }

  } else {
    cat("RESULT: INCOMPATIBLE ✗\n")
    cat(strrep("-", 70), "\n\n")

    if (!is.null(x@reason)) {
      cat("Reason:", x@reason, "\n\n")
    } else {
      cat("The specified misclassification parameters are NOT consistent\n")
      cat("with the observed data. Some testable implications are violated.\n\n")

      if (x@n_constraints_total > 0) {
        cat("Constraints satisfied:", x@n_constraints_satisfied, "/",
            x@n_constraints_total, "\n")
        cat("Constraints violated:", x@n_constraints_violated, "\n\n")
      }

      if (nrow(x@violated_constraints) > 0) {
        cat("Violated Constraints:\n")
        print(head(x@violated_constraints, 10), row.names = FALSE)
        if (nrow(x@violated_constraints) > 10) {
          cat("... and", nrow(x@violated_constraints) - 10, "more\n")
        }
        cat("\n")
      }
    }
  }

  cat(strrep("=", 70), "\n\n")

  invisible(x)
}


#' Summary method for compatibility_test
#'
#' @param object A compatibility_test object
#' @param ... Additional arguments (ignored)
#' @export
method(summary, compatibility_test) <- function(object, ...) {
  # Print basic info
  print(object)

  # Additional details if available
  if (!is.null(object@stratum_details) && length(object@stratum_details) > 0) {
    cat("STRATUM-LEVEL DETAILS\n")
    cat(strrep("=", 70), "\n\n")

    for (stratum_name in names(object@stratum_details)) {
      detail <- object@stratum_details[[stratum_name]]
      cat("Stratum:", stratum_name, "\n")
      cat("  Compatible:", if (is.na(detail$compatible)) "NA" else detail$compatible, "\n")
      if (!is.null(detail$reason)) {
        cat("  Reason:", detail$reason, "\n")
      }
      if (!is.null(detail$n_obs)) {
        cat("  n =", detail$n_obs, "\n")
      }
      cat("\n")
    }
  }

  invisible(object)
}


# =============================================================================
# Methods for falsification_summary
# =============================================================================

#' Print method for falsification_summary
#'
#' @param x A falsification_summary object
#' @param digits Integer. Number of decimal places. Default is 3.
#' @param ... Additional arguments (ignored)
#' @export
method(print, falsification_summary) <- function(x, digits = 3, ...) {
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("FALSIFICATION SUMMARY\n")
  cat(strrep("=", 70), "\n\n")

  # Overall
  cat("Overall Falsification:\n")
  cat("  Total parameter sets evaluated:", x@n_evaluated, "\n")
  cat("  Compatible sets:", x@n_compatible,
      sprintf("(%.1f%%)\n", 100 * (1 - x@overall)))
  cat("  Falsified sets:", x@n_falsified,
      sprintf("(%.1f%%)\n\n", 100 * x@overall))

  # Interpretation
  if (x@overall > 0.8) {
    cat("  → High falsification: Data strongly constrain the parameter space\n")
    cat("     Bounds are relatively sharp given the sensitivity region.\n\n")
  } else if (x@overall > 0.5) {
    cat("  → Moderate falsification: Data provide meaningful constraints\n")
    cat("     Some regions of parameter space are ruled out.\n\n")
  } else if (x@overall > 0.2) {
    cat("  → Low falsification: Weak data constraints\n")
    cat("     Most of the sensitivity region remains compatible.\n\n")
  } else {
    cat("  → Very low falsification: Minimal data constraints\n")
    cat("     Consider narrowing the sensitivity region or collecting more data.\n\n")
  }

  # Parameter-specific
  if (!is.null(x@by_parameter)) {
    cat(strrep("-", 70), "\n")
    cat("Parameter-Specific Falsification:\n")
    cat(strrep("-", 70), "\n\n")

    param_table <- data.frame(
      Parameter = names(x@by_parameter),
      Mean_Falsification = sapply(x@by_parameter, function(p) {
        mean(p$falsification_rate)
      }),
      Min_Falsification = sapply(x@by_parameter, function(p) {
        min(p$falsification_rate)
      }),
      Max_Falsification = sapply(x@by_parameter, function(p) {
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

    if (length(x@most_constrained) > 0) {
      cat("Most constrained parameters:",
          paste(x@most_constrained, collapse = ", "), "\n")
    }
    if (length(x@least_constrained) > 0) {
      cat("Least constrained parameters:",
          paste(x@least_constrained, collapse = ", "), "\n")
    }
    cat("\n")
  }

  cat(strrep("=", 70), "\n\n")

  invisible(x)
}


#' Summary method for falsification_summary
#'
#' @param object A falsification_summary object
#' @param ... Additional arguments (ignored)
#' @export
method(summary, falsification_summary) <- function(object, ...) {
  print(object)
  invisible(object)
}


# =============================================================================
# Methods for sensitivity_region
# =============================================================================

#' Print method for sensitivity_region
#'
#' @param x A sensitivity_region object
#' @param ... Additional arguments (ignored)
#' @export
method(print, sensitivity_region) <- function(x, ...) {
  cat("\nSensitivity Region (Θ_ψ):\n")
  cat(strrep("-", 40), "\n")
  cat(sprintf("  Sn0:  [%.3f, %.3f]\n", x@sn0_range[1], x@sn0_range[2]))
  cat(sprintf("  Sp0:  [%.3f, %.3f]\n", x@sp0_range[1], x@sp0_range[2]))
  cat(sprintf("  ψ_Sn: [%.3f, %.3f]\n", x@psi_sn_range[1], x@psi_sn_range[2]))
  cat(sprintf("  ψ_Sp: [%.3f, %.3f]\n", x@psi_sp_range[1], x@psi_sp_range[2]))
  cat(strrep("-", 40), "\n\n")

  invisible(x)
}


# =============================================================================
# Methods for bootstrap_results
# =============================================================================

#' Print method for bootstrap_results
#'
#' @param x A bootstrap_results object
#' @param ... Additional arguments (ignored)
#' @export
method(print, bootstrap_results) <- function(x, ...) {
  cat("\nBootstrap Confidence Intervals\n")
  cat(strrep("-", 50), "\n")
  cat(sprintf("Method: %s\n", x@method))
  cat(sprintf("Replications: %d (failed: %d)\n", x@n_reps, x@n_failed))
  cat(sprintf("Confidence Level: %.1f%%\n\n", 100 * x@confidence_level))

  cat(sprintf("NIE Lower: [%.4f, %.4f]\n", x@nie_lower_ci[1], x@nie_lower_ci[2]))
  cat(sprintf("NIE Upper: [%.4f, %.4f]\n", x@nie_upper_ci[1], x@nie_upper_ci[2]))
  cat(sprintf("NDE Lower: [%.4f, %.4f]\n", x@nde_lower_ci[1], x@nde_lower_ci[2]))
  cat(sprintf("NDE Upper: [%.4f, %.4f]\n", x@nde_upper_ci[1], x@nde_upper_ci[2]))
  cat(strrep("-", 50), "\n\n")

  invisible(x)
}
