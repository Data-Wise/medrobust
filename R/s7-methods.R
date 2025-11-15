#' S7 Methods for medrobust Classes
#'
#' @description
#' Generic methods (print, summary, format, etc.) for S7 classes in medrobust.
#'
#' @name s7-methods
#' @keywords internal
NULL

#' @importFrom S7 method method<-
NULL

# =============================================================================
# Methods for medrobust_bounds
# =============================================================================

#' Print method for medrobust_bounds
#'
#' @param x A medrobust_bounds object
#' @param ... Additional arguments (ignored)
#' @noRd
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
#' @noRd
#' @export
method(summary, medrobust_bounds) <- function(object, ...) {
  # Print basic info
  print(object)

  # Additional diagnostics
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("DETAILED SUMMARY\n")
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
#' @noRd
#' @export
method(as.data.frame, medrobust_bounds) <- function(x, ...) {
  # Create wide-format data frame with one row
  result <- data.frame(
    NIE_lower = x@NIE_lower,
    NIE_upper = x@NIE_upper,
    NDE_lower = x@NDE_lower,
    NDE_upper = x@NDE_upper,
    NIE_width = x@NIE_upper - x@NIE_lower,
    NDE_width = x@NDE_upper - x@NDE_lower,
    effect_scale = x@effect_scale,
    misclassified_variable = x@misclassified_variable,
    n_compatible = x@n_compatible,
    n_evaluated = x@n_evaluated,
    falsified_proportion = x@falsified_proportion,
    stringsAsFactors = FALSE
  )

  # Add bootstrap CIs if available
  if (!is.null(x@bootstrap_results)) {
    result$NIE_lower_ci_lower <- x@bootstrap_results@nie_lower_ci[1]
    result$NIE_lower_ci_upper <- x@bootstrap_results@nie_lower_ci[2]
    result$NIE_upper_ci_lower <- x@bootstrap_results@nie_upper_ci[1]
    result$NIE_upper_ci_upper <- x@bootstrap_results@nie_upper_ci[2]
    result$NDE_lower_ci_lower <- x@bootstrap_results@nde_lower_ci[1]
    result$NDE_lower_ci_upper <- x@bootstrap_results@nde_lower_ci[2]
    result$NDE_upper_ci_lower <- x@bootstrap_results@nde_upper_ci[1]
    result$NDE_upper_ci_upper <- x@bootstrap_results@nde_upper_ci[2]
    result$bootstrap_method <- x@bootstrap_results@method
    result$bootstrap_n_reps <- x@bootstrap_results@n_reps
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
#' @noRd
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
    cat("RESULT: Compatible ✓\n")
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
    cat("RESULT: NOT Compatible ✗\n")
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
#' @noRd
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(summary, compatibility_test) <- function(object, ...) {
  # Print basic info
  print(object)

  # Additional details if available
  if (!is.null(object@stratum_details) && length(object@stratum_details) > 0) {
    cat("\n")
    cat(strrep("=", 70), "\n")
    cat("DETAILED COMPATIBILITY ANALYSIS\n")
    cat(strrep("=", 70), "\n\n")

    cat("STRATUM-LEVEL DETAILS\n")
    cat(strrep("-", 70), "\n\n")

    for (stratum_name in names(object@stratum_details)) {
      detail <- object@stratum_details[[stratum_name]]
      cat("Stratum:", stratum_name, "\n")
      if (!is.null(detail$satisfied)) {
        cat("  Satisfied:", detail$satisfied, "\n")
      }
      if (!is.null(detail$n_satisfied)) {
        cat("  Constraints satisfied:", detail$n_satisfied, "\n")
      }
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
#' @noRd
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(print, .falsification_summary_class) <- function(x, digits = 3, ...) {
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
#' @noRd
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(summary, .falsification_summary_class) <- function(object, ...) {
  print(object)
  invisible(object)
}


# =============================================================================
# Methods for sensitivity_region
# =============================================================================

#' Print method for sensitivity_region
#'
#' @param x A sensitivity_region object
#' @noRd
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(print, .sensitivity_region_class) <- function(x, ...) {
  cat("\nSensitivity Region (Θ_ψ):\n")
  cat(strrep("-", 40), "\n")
  cat(sprintf("  Sn0:  [%.3f, %.3f]\n", x@sn0_range[1], x@sn0_range[2]))
  cat(sprintf("  Sp0:  [%.3f, %.3f]\n", x@sp0_range[1], x@sp0_range[2]))
  cat(sprintf("  ψ_Sn: [%.3f, %.3f]\n", x@psi_sn_range[1], x@psi_sn_range[2]))
  cat(sprintf("  ψ_Sp: [%.3f, %.3f]\n", x@psi_sp_range[1], x@psi_sp_range[2]))
  cat(strrep("-", 40), "\n\n")

  invisible(x)
}


#' as.list method for sensitivity_region
#'
#' @param x A sensitivity_region object
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(as.list, .sensitivity_region_class) <- function(x, ...) {
  list(
    sn0_range = x@sn0_range,
    sp0_range = x@sp0_range,
    psi_sn_range = x@psi_sn_range,
    psi_sp_range = x@psi_sp_range
  )
}


# =============================================================================
# Methods for bootstrap_results
# =============================================================================

#' Print method for bootstrap_results
#'
#' @noRd
#' @param x A bootstrap_results object
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(print, bootstrap_results) <- function(x, ...) {
  cat("\nBootstrap Confidence Intervals\n")
  cat(strrep("-", 50), "\n")
  cat(sprintf("Method: %s\n", x@method))
  cat(sprintf("Replications: %d (failed: %d)\n", x@n_reps, x@n_failed))
  cat(sprintf("Confidence Level: %.0f%%\n\n", 100 * x@confidence_level))

  cat(sprintf("NIE Lower: [%.4f, %.4f]\n", x@nie_lower_ci[1], x@nie_lower_ci[2]))
  cat(sprintf("NIE Upper: [%.4f, %.4f]\n", x@nie_upper_ci[1], x@nie_upper_ci[2]))
  cat(sprintf("NDE Lower: [%.4f, %.4f]\n", x@nde_lower_ci[1], x@nde_lower_ci[2]))
  cat(sprintf("NDE Upper: [%.4f, %.4f]\n", x@nde_upper_ci[1], x@nde_upper_ci[2]))
  cat(strrep("-", 50), "\n\n")

  invisible(x)
}

# =============================================================================
# Methods for simulated_dm_data
# =============================================================================

#' Print method for simulated_dm_data
#'
#' @noRd
#' @param x A simulated_dm_data object
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(print, simulated_dm_data) <- function(x, ...) {
  
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("SIMULATED DATA WITH DIFFERENTIAL MISCLASSIFICATION\n")
  cat(strrep("=", 70), "\n\n")
  
  # Sample size
  cat("Sample size: n =", nrow(x@observed), "\n")
  cat("Misclassified variable:", 
      tools::toTitleCase(x@generation_params$misclass_type), "\n\n")
  
  # Misclassification parameters
  cat(strrep("-", 70), "\n")
  cat("MISCLASSIFICATION PARAMETERS\n")
  cat(strrep("-", 70), "\n\n")
  
  dm <- x@generation_params$dm_params
  cat("Specified:\n")
  cat("  Sn0:", sprintf("%.3f", dm$sn0), "\n")
  cat("  Sp0:", sprintf("%.3f", dm$sp0), "\n")
  cat("  ψ_Sn:", sprintf("%.3f", dm$psi_sn), "\n")
  cat("  ψ_Sp:", sprintf("%.3f", dm$psi_sp), "\n\n")
  
  if (!is.null(x@misclassification_applied)) {
    emp <- x@misclassification_applied$empirical
    cat("Empirical (from simulated data):\n")
    cat("  Sn0:", sprintf("%.3f", emp$sn0), "\n")
    cat("  Sp0:", sprintf("%.3f", emp$sp0), "\n")
    cat("  Sn1:", sprintf("%.3f", emp$sn1), "\n")
    cat("  Sp1:", sprintf("%.3f", emp$sp1), "\n")
    cat("  Overall misclassification rate:", 
        sprintf("%.1f%%\n\n", 100 * x@misclassification_applied$misclassification_rate))
  }
  
  # True causal effects
  if (!is.null(x@true_effects)) {
    cat(strrep("-", 70), "\n")
    cat("TRUE CAUSAL EFFECTS\n")
    cat(strrep("-", 70), "\n\n")
    
    cat("Odds Ratio Scale:\n")
    cat("  NIE:", sprintf("%.3f", x@true_effects$NIE_OR), "\n")
    cat("  NDE:", sprintf("%.3f", x@true_effects$NDE_OR), "\n")
    cat("  TCE:", sprintf("%.3f", x@true_effects$TCE_OR), "\n")
    cat("  PM:", sprintf("%.3f", x@true_effects$PM_OR), "\n\n")
    
    cat("Risk Ratio Scale:\n")
    cat("  NIE:", sprintf("%.3f", x@true_effects$NIE_RR), "\n")
    cat("  NDE:", sprintf("%.3f", x@true_effects$NDE_RR), "\n")
    cat("  TCE:", sprintf("%.3f", x@true_effects$TCE_RR), "\n\n")
    
    cat("Risk Difference Scale:\n")
    cat("  NIE:", sprintf("%.3f", x@true_effects$NIE_RD), "\n")
    cat("  NDE:", sprintf("%.3f", x@true_effects$NDE_RD), "\n")
    cat("  TCE:", sprintf("%.3f", x@true_effects$TCE_RD), "\n\n")
  }
  
  # Data preview
  cat(strrep("-", 70), "\n")
  cat("DATA PREVIEW\n")
  cat(strrep("-", 70), "\n\n")
  
  cat("Observed data (first 6 rows):\n")
  print(head(x@observed))
  
  if (!is.null(x@truth)) {
    cat("\nTrue data (first 6 rows):\n")
    print(head(x@truth))
  }
  
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("Use x@observed for analysis with bound_ne()\n")
  cat("Use x@true_effects to check if true effects are in bounds\n")
  cat(strrep("=", 70), "\n\n")
  
  invisible(x)
}


#' Summary method for simulated_dm_data
#'
#' @param object A simulated_dm_data object
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(summary, simulated_dm_data) <- function(object, ...) {
  
  print(object)
  
  # Additional diagnostics
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("ADDITIONAL DIAGNOSTICS\n")
  cat(strrep("=", 70), "\n\n")
  
  # Variable distributions
  cat("Variable Distributions (Observed Data):\n\n")
  
  for (var in names(object@observed)) {
    if (is.numeric(object@observed[[var]])) {
      vals <- unique(object@observed[[var]])
      if (length(vals) <= 10) {
        # Categorical/binary
        tab <- table(object@observed[[var]])
        prop <- prop.table(tab)
        cat(var, ":\n")
        print(data.frame(Value = names(tab), Count = as.numeric(tab), 
                        Proportion = as.numeric(prop)))
        cat("\n")
      } else {
        # Continuous
        cat(var, ": mean =", sprintf("%.3f", mean(object@observed[[var]])),
            ", sd =", sprintf("%.3f", sd(object@observed[[var]])), "\n\n")
      }
    }
  }
  
  # Confusion matrix
  if (!is.null(object@misclassification_applied$confusion_matrix)) {
    cat("\nConfusion Matrix (True vs. Observed):\n")
    print(object@misclassification_applied$confusion_matrix)
    cat("\n")
  }
  
  invisible(object)
}


# =============================================================================
# Methods for power_analysis_result
# =============================================================================

#' Print method for power_analysis_result
#'
#' @param x A power_analysis_result object
#' @param ... Additional arguments (ignored)
#' @noRd
#' @export
method(print, power_analysis_result) <- function(x, ...) {
  
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("POWER ANALYSIS RESULTS\n")
  cat(strrep("=", 70), "\n\n")
  
  cat("Effect:", x@simulation_params$effect, "\n")
  cat("True effect value:", sprintf("%.3f", x@true_effect), "\n")
  cat("Misclassified variable:", 
      tools::toTitleCase(x@simulation_params$misclass_type), "\n\n")
  
  cat(strrep("-", 70), "\n")
  cat("POWER CURVE\n")
  cat(strrep("-", 70), "\n\n")
  
  print(x@power_curve, row.names = FALSE)
  
  cat("\n")
  cat(strrep("-", 70), "\n")
  cat("RECOMMENDATIONS\n")
  cat(strrep("-", 70), "\n\n")
  
  if (!is.na(x@recommended_n_power)) {
    cat("To achieve power ≥", x@target_power, ":\n")
    cat("  Recommended sample size: n =", x@recommended_n_power, "\n\n")
  } else {
    cat("Target power", x@target_power, "not achieved at any tested sample size\n")
    cat("  Consider: larger sample sizes or stronger effects\n\n")
  }
  
  if (!is.null(x@target_width) && !is.na(x@recommended_n_width)) {
    cat("To achieve bound width ≤", x@target_width, ":\n")
    cat("  Recommended sample size: n =", x@recommended_n_width, "\n\n")
  } else if (!is.null(x@target_width)) {
    cat("Target width", x@target_width, "not achieved at any tested sample size\n")
    cat("  Consider: larger sample sizes or narrower sensitivity region\n\n")
  }
  
  cat(strrep("=", 70), "\n")
  cat("Use plot() to visualize power and width curves\n")
  cat(strrep("=", 70), "\n\n")
  
  invisible(x)
}


#' Plot method for power_analysis_result
#'
#' @param x A power_analysis_result object
#' @param ... Additional arguments (ignored)
#' @importFrom ggplot2 ggplot aes geom_line geom_point geom_hline geom_ribbon
#' @importFrom ggplot2 scale_y_continuous labs theme_bw
#' @noRd
#' @export
method(plot, power_analysis_result) <- function(x, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 required for plotting")
  }
  
  # Power curve
  p1 <- ggplot2::ggplot(x@power_curve, 
                       ggplot2::aes(x = n, y = power)) +
    ggplot2::geom_line(linewidth = 1, color = "steelblue") +
    ggplot2::geom_point(size = 3, color = "steelblue") +
    ggplot2::geom_hline(yintercept = x@target_power, 
                       linetype = "dashed", color = "red") +
    ggplot2::scale_y_continuous(limits = c(0, 1), 
                               labels = function(x) paste0(100*x, "%")) +
    ggplot2::labs(
      title = "Power Curve",
      subtitle = paste("Target power =", x@target_power),
      x = "Sample Size",
      y = "Power (Proportion Rejecting Null)"
    ) +
    ggplot2::theme_bw()
  
  # Width curve
  p2 <- ggplot2::ggplot(x@power_curve, 
                       ggplot2::aes(x = n, y = median_width)) +
    ggplot2::geom_line(linewidth = 1, color = "coral") +
    ggplot2::geom_point(size = 3, color = "coral") +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = median_width - sd_width,
                                     ymax = median_width + sd_width),
                        alpha = 0.2, fill = "coral") +
    ggplot2::labs(
      title = "Bound Width",
      subtitle = "Median ± SD across simulations",
      x = "Sample Size",
      y = paste("Bound Width (", x@simulation_params$effect, ")")
    ) +
    ggplot2::theme_bw()
  
  if (!is.null(x@target_width)) {
    p2 <- p2 + ggplot2::geom_hline(yintercept = x@target_width,
                                   linetype = "dashed", color = "red")
  }
  
  # Coverage curve
  p3 <- ggplot2::ggplot(x@power_curve,
                       ggplot2::aes(x = n, y = coverage)) +
    ggplot2::geom_line(linewidth = 1, color = "darkgreen") +
    ggplot2::geom_point(size = 3, color = "darkgreen") +
    ggplot2::geom_hline(yintercept = 0.95, linetype = "dashed", color = "red") +
    ggplot2::scale_y_continuous(limits = c(0, 1),
                               labels = function(x) paste0(100*x, "%")) +
    ggplot2::labs(
      title = "Coverage Rate",
      subtitle = "Proportion of bounds containing true effect",
      x = "Sample Size",
      y = "Coverage"
    ) +
    ggplot2::theme_bw()
  
  # Combine plots
  if (requireNamespace("gridExtra", quietly = TRUE)) {
    combined <- gridExtra::grid.arrange(p1, p2, p3, ncol = 1)
  } else if (requireNamespace("patchwork", quietly = TRUE)) {
    combined <- p1 / p2 / p3
  } else {
    combined <- list(power = p1, width = p2, coverage = p3)
    message("Install 'gridExtra' or 'patchwork' to display combined plot")
  }
  
  return(combined)
}
