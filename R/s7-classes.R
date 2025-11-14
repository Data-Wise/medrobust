#' S7 Class Definitions for medrobust Package
#'
#' @description
#' This file contains all S7 class definitions for the medrobust package,
#' replacing the previous S3 implementation with a modern, type-safe OOP system.
#'
#' @name s7-classes
#' @keywords internal
#' @importFrom S7 new_class new_property class_numeric class_character class_integer class_list class_data.frame class_logical class_call class_any

# =============================================================================
# Helper Classes
# =============================================================================

#' Sensitivity Region Class
#'
#' @description
#' Defines the sensitivity parameter space Theta_Psi for differential
#' misclassification analysis.
#'
#' @keywords internal
.sensitivity_region_class <- new_class(
  name = "sensitivity_region",
  package = "medrobust",
  properties = list(
    sn0_range = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 2) {
          "sn0_range must have length 2 (min, max)"
        } else if (value[1] < 0 || value[2] > 1) {
          "sn0_range values must be in [0, 1]"
        } else if (value[1] >= value[2]) {
          "sn0_range[1] must be < sn0_range[2]"
        }
      }
    ),
    sp0_range = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 2) {
          "sp0_range must have length 2 (min, max)"
        } else if (value[1] < 0 || value[2] > 1) {
          "sp0_range values must be in [0, 1]"
        } else if (value[1] >= value[2]) {
          "sp0_range[1] must be < sp0_range[2]"
        }
      }
    ),
    psi_sn_range = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 2) {
          "psi_sn_range must have length 2 (min, max)"
        } else if (value[1] <= 0) {
          "psi_sn_range values must be positive (odds ratios)"
        } else if (value[1] >= value[2]) {
          "psi_sn_range[1] must be < psi_sn_range[2]"
        }
      }
    ),
    psi_sp_range = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 2) {
          "psi_sp_range must have length 2 (min, max)"
        } else if (value[1] <= 0) {
          "psi_sp_range values must be positive (odds ratios)"
        } else if (value[1] >= value[2]) {
          "psi_sp_range[1] must be < psi_sp_range[2]"
        }
      }
    )
  )
)

#' Create Sensitivity Region
#'
#' @description
#' Constructor for sensitivity_region S7 objects. Issues a warning if the
#' region may be non-informative (Sn + Sp <= 1).
#'
#' @param sn0_range Numeric vector of length 2: [min, max] for baseline sensitivity
#' @param sp0_range Numeric vector of length 2: [min, max] for baseline specificity
#' @param psi_sn_range Numeric vector of length 2: [min, max] for sensitivity OR
#' @param psi_sp_range Numeric vector of length 2: [min, max] for specificity OR
#'
#' @return A sensitivity_region S7 object
#' @export
sensitivity_region <- function(sn0_range, sp0_range, psi_sn_range, psi_sp_range) {
  obj <- .sensitivity_region_class(
    sn0_range = sn0_range,
    sp0_range = sp0_range,
    psi_sn_range = psi_sn_range,
    psi_sp_range = psi_sp_range
  )

  # Issue warning if region may be non-informative
  if ((sn0_range[1] + sp0_range[1]) <= 1.01) {
    warning("Sensitivity region may be non-informative: min(Sn0) + min(Sp0) <= 1",
            call. = FALSE)
  }

  obj
}


#' Bootstrap Results Class
#'
#' @description
#' Stores bootstrap inference results for partial identification bounds.
#'
#' @export
bootstrap_results <- new_class(
  name = "bootstrap_results",
  package = "medrobust",
  properties = list(
    method = new_property(
      class = class_character,
      validator = function(value) {
        if (!value %in% c("percentile", "bca")) {
          "method must be 'percentile' or 'bca'"
        }
      }
    ),
    n_reps = new_property(class = class_integer),
    n_failed = new_property(class = class_integer, default = 0L),
    confidence_level = new_property(
      class = class_numeric,
      validator = function(value) {
        if (value <= 0 || value >= 1) {
          "confidence_level must be in (0, 1)"
        }
      }
    ),
    nie_lower_ci = new_property(class = class_numeric),
    nie_upper_ci = new_property(class = class_numeric),
    nde_lower_ci = new_property(class = class_numeric),
    nde_upper_ci = new_property(class = class_numeric),
    boot_nie_lower = new_property(class = class_numeric),
    boot_nie_upper = new_property(class = class_numeric),
    boot_nde_lower = new_property(class = class_numeric),
    boot_nde_upper = new_property(class = class_numeric),
    z0 = new_property(class = class_any, default = NULL),
    acceleration = new_property(class = class_any, default = NULL)
  ),
  validator = function(self) {
    if (self@n_failed > self@n_reps) {
      "@n_failed cannot exceed @n_reps"
    }
  }
)


# =============================================================================
# Main Result Classes
# =============================================================================

#' Medrobust Bounds Class
#'
#' @description
#' S7 class for storing partial identification bounds for natural direct
#' and indirect effects under differential misclassification.
#'
#' @export
medrobust_bounds <- new_class(
  name = "medrobust_bounds",
  package = "medrobust",
  properties = list(
    NIE_lower = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 1) {
          "NIE_lower must be a scalar"
        }
      }
    ),
    NIE_upper = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 1) {
          "NIE_upper must be a scalar"
        }
      }
    ),
    NDE_lower = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 1) {
          "NDE_lower must be a scalar"
        }
      }
    ),
    NDE_upper = new_property(
      class = class_numeric,
      validator = function(value) {
        if (length(value) != 1) {
          "NDE_upper must be a scalar"
        }
      }
    ),
    compatible_sets = new_property(class = class_data.frame),
    n_compatible = new_property(class = class_integer),
    n_evaluated = new_property(class = class_integer),
    falsified_proportion = new_property(
      class = class_numeric,
      validator = function(value) {
        if (value < 0 || value > 1) {
          "falsified_proportion must be in [0, 1]"
        }
      }
    ),
    effect_scale = new_property(
      class = class_character,
      validator = function(value) {
        if (!value %in% c("OR", "RR", "RD")) {
          "effect_scale must be 'OR', 'RR', or 'RD'"
        }
      }
    ),
    misclassified_variable = new_property(
      class = class_character,
      validator = function(value) {
        if (!value %in% c("exposure", "mediator")) {
          "misclassified_variable must be 'exposure' or 'mediator'"
        }
      }
    ),
    sensitivity_region = new_property(
      class = .sensitivity_region_class
    ),
    naive_estimates = new_property(class = class_list, default = NULL),
    bootstrap_results = new_property(
      class = class_any,
      default = NULL,
      validator = function(value) {
        if (!is.null(value)) {
          # Check if it's a bootstrap_results S7 object
          if (!inherits(value, c("bootstrap_results", "medrobust::bootstrap_results"))) {
            "bootstrap_results must be NULL or a bootstrap_results object"
          }
        }
      }
    ),
    data_summary = new_property(class = class_list, default = NULL),
    call = new_property(class = class_any, default = NULL)
  ),
  validator = function(self) {
    # Validate bound ordering
    if (self@NIE_lower > self@NIE_upper) {
      "@NIE_lower must be <= @NIE_upper"
    } else if (self@NDE_lower > self@NDE_upper) {
      "@NDE_lower must be <= @NDE_upper"
    } else if (self@n_compatible > self@n_evaluated) {
      "@n_compatible cannot exceed @n_evaluated"
    } else if (self@n_compatible < 0 || self@n_evaluated < 0) {
      "@n_compatible and @n_evaluated must be non-negative"
    }
  }
)


#' Compatibility Test Class
#'
#' @description
#' S7 class for storing results of compatibility tests for specific
#' misclassification parameter values.
#'
#' @export
compatibility_test <- new_class(
  name = "compatibility_test",
  package = "medrobust",
  properties = list(
    compatible = new_property(class = class_logical),
    psi = new_property(class = class_list),
    sn1 = new_property(class = class_any, default = NULL),
    sp1 = new_property(class = class_any, default = NULL),
    n_constraints_total = new_property(
      class = class_integer,
      default = 0L
    ),
    n_constraints_satisfied = new_property(
      class = class_integer,
      default = 0L
    ),
    n_constraints_violated = new_property(
      class = class_integer,
      default = 0L
    ),
    violated_constraints = new_property(
      class = class_data.frame,
      default = data.frame()
    ),
    implied_probabilities = new_property(
      class = class_list,
      default = NULL
    ),
    stratum_details = new_property(
      class = class_list,
      default = NULL
    ),
    misclassified_variable = new_property(
      class = class_character,
      validator = function(value) {
        if (!value %in% c("exposure", "mediator")) {
          "misclassified_variable must be 'exposure' or 'mediator'"
        }
      }
    ),
    reason = new_property(
      class = class_any,
      default = NULL
    )
  ),
  validator = function(self) {
    if (self@n_constraints_satisfied + self@n_constraints_violated !=
        self@n_constraints_total) {
      "Constraint counts don't add up correctly"
    } else if (!is.null(self@sn1) && (self@sn1 < 0 || self@sn1 > 1)) {
      "@sn1 must be in [0, 1]"
    } else if (!is.null(self@sp1) && (self@sp1 < 0 || self@sp1 > 1)) {
      "@sp1 must be in [0, 1]"
    }
  }
)


#' Falsification Summary Class
#'
#' @description
#' S7 class for storing falsification analysis results showing which
#' regions of the sensitivity space are empirically ruled out.
#'
#' @keywords internal
.falsification_summary_class <- new_class(
  name = "falsification_summary",
  package = "medrobust",
  properties = list(
    overall = new_property(
      class = class_numeric,
      validator = function(value) {
        if (value < 0 || value > 1) {
          "overall falsification rate must be in [0, 1]"
        }
      }
    ),
    n_evaluated = new_property(class = class_integer),
    n_compatible = new_property(class = class_integer),
    n_falsified = new_property(class = class_integer),
    by_parameter = new_property(class = class_list, default = NULL),
    joint_falsification = new_property(class = class_list, default = NULL),
    most_constrained = new_property(
      class = class_character,
      default = character(0)
    ),
    least_constrained = new_property(
      class = class_character,
      default = character(0)
    ),
    plot = new_property(class = class_any, default = NULL)
  ),
  validator = function(self) {
    if (self@n_compatible + self@n_falsified != self@n_evaluated) {
      "n_compatible + n_falsified must equal n_evaluated"
    } else if (self@n_compatible < 0 || self@n_falsified < 0) {
      "Counts must be non-negative"
    }
  }
)

#' Create Falsification Summary Object
#'
#' @description
#' Low-level constructor for falsification_summary S7 objects.
#' Most users should use the falsification_summary() function which analyzes bounds.
#'
#' @param overall Overall falsification rate
#' @param n_evaluated Number of parameter sets evaluated
#' @param n_compatible Number of compatible parameter sets
#' @param n_falsified Number of falsified parameter sets
#' @param by_parameter Parameter-specific falsification (optional)
#' @param joint_falsification Joint falsification patterns (optional)
#' @param most_constrained Most constrained parameters (optional)
#' @param least_constrained Least constrained parameters (optional)
#' @param plot ggplot2 object (optional)
#'
#' @return A falsification_summary S7 object
#' @export
new_falsification_summary <- function(overall, n_evaluated, n_compatible, n_falsified,
                                      by_parameter = NULL, joint_falsification = NULL,
                                      most_constrained = character(0),
                                      least_constrained = character(0),
                                      plot = NULL) {
  .falsification_summary_class(
    overall = overall,
    n_evaluated = as.integer(n_evaluated),
    n_compatible = as.integer(n_compatible),
    n_falsified = as.integer(n_falsified),
    by_parameter = by_parameter,
    joint_falsification = joint_falsification,
    most_constrained = most_constrained,
    least_constrained = least_constrained,
    plot = plot
  )
}


#' Simulated Data with Differential Misclassification Class
#'
#' @description
#' S7 class for storing simulated data with known differential misclassification,
#' used for power analysis and methods validation.
#'
#' @export
simulated_dm_data <- new_class(
  name = "simulated_dm_data",
  package = "medrobust",
  properties = list(
    observed = new_property(class = class_data.frame),
    truth = new_property(
      class = class_any,
      default = NULL,
      validator = function(value) {
        if (!is.null(value) && !is.data.frame(value)) {
          "truth must be NULL or a data.frame"
        }
      }
    ),
    true_effects = new_property(class = class_list, default = NULL),
    generation_params = new_property(
      class = class_list,
      validator = function(value) {
        required <- c("n", "true_params", "dm_params", "misclass_type")
        missing <- setdiff(required, names(value))
        if (length(missing) > 0) {
          paste("generation_params must contain:", paste(required, collapse = ", "))
        }
      }
    ),
    misclassification_applied = new_property(class = class_list, default = NULL)
  ),
  validator = function(self) {
    if (nrow(self@observed) < 10) {
      "observed data must have at least 10 rows"
    } else if (!is.null(self@truth) && nrow(self@truth) != nrow(self@observed)) {
      "truth and observed must have same number of rows"
    } else if (self@generation_params$n != nrow(self@observed)) {
      "generation_params$n must match nrow(observed)"
    }
  }
)


#' Power Analysis Result Class
#'
#' @description
#' S7 class for storing power analysis results for partial identification bounds.
#'
#' @export
power_analysis_result <- new_class(
  name = "power_analysis_result",
  package = "medrobust",
  properties = list(
    power_curve = new_property(
      class = class_data.frame,
      validator = function(value) {
        required_cols <- c("n", "power", "coverage", "mean_width", "median_width")
        missing <- setdiff(required_cols, names(value))
        if (length(missing) > 0) {
          paste("power_curve must have columns:", paste(required_cols, collapse = ", "))
        }
      }
    ),
    true_effect = new_property(class = class_numeric),
    target_power = new_property(
      class = class_numeric,
      validator = function(value) {
        if (value <= 0 || value >= 1) {
          "target_power must be in (0, 1)"
        }
      }
    ),
    target_width = new_property(class = class_numeric, default = NULL),
    recommended_n_power = new_property(class = class_integer, default = NA_integer_),
    recommended_n_width = new_property(class = class_integer, default = NA_integer_),
    simulation_params = new_property(
      class = class_list,
      validator = function(value) {
        required <- c("true_params", "dm_params", "sensitivity_region", "effect")
        missing <- setdiff(required, names(value))
        if (length(missing) > 0) {
          paste("simulation_params must contain:", paste(required, collapse = ", "))
        }
      }
    )
  ),
  validator = function(self) {
    if (any(self@power_curve$power < 0 | self@power_curve$power > 1)) {
      "power values must be in [0, 1]"
    } else if (any(self@power_curve$coverage < 0 | self@power_curve$coverage > 1)) {
      "coverage values must be in [0, 1]"
    } else if (any(self@power_curve$mean_width < 0, na.rm = TRUE)) {
      "mean_width values must be non-negative"
    }
  }
)


# =============================================================================
# Constructor Helper Functions
# =============================================================================

#' Create sensitivity_region object from list
#'
#' @param region_list List with sn0_range, sp0_range, psi_sn_range, psi_sp_range
#' @return sensitivity_region S7 object
#' @export
as_sensitivity_region <- function(region_list) {
  sensitivity_region(
    sn0_range = region_list$sn0_range,
    sp0_range = region_list$sp0_range,
    psi_sn_range = region_list$psi_sn_range,
    psi_sp_range = region_list$psi_sp_range
  )
}


#' Convert sensitivity_region to list
#'
#' @param x sensitivity_region S7 object
#' @param ... Additional arguments (ignored)
#' @return Named list
#' @exportS3Method base::as.list
as.list.sensitivity_region <- function(x, ...) {
  list(
    sn0_range = x@sn0_range,
    sp0_range = x@sp0_range,
    psi_sn_range = x@psi_sn_range,
    psi_sp_range = x@psi_sp_range
  )
}
