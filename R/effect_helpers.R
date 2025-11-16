#' Additional Helper Functions for Effect Computation
#'
#' @description
#' Miscellaneous helper functions for computing causal effects.
#'
#' @name effect_helpers
#' @keywords internal
NULL

#' Check for Effect Reversal
#'
#' @description
#' Check if the bounds contain the null value (effect reversal possible).
#'
#' @param lower Lower bound
#' @param upper Upper bound
#' @param effect_scale Character string: "OR", "RR", or "RD"
#'
#' @return Logical indicating if bounds cross null
#' @keywords internal
bounds_cross_null <- function(lower, upper, effect_scale = "OR") {

  if (effect_scale %in% c("OR", "RR")) {
    # Null is 1 for multiplicative effects
    null_value <- 1
  } else if (effect_scale == "RD") {
    # Null is 0 for additive effects
    null_value <- 0
  } else {
    stop("Unknown effect_scale: ", effect_scale)
  }

  # Check if null is within bounds
  crosses_null <- (lower <= null_value) & (upper >= null_value)

  return(crosses_null)
}


#' Compute Bound Width
#'
#' @description
#' Compute the width of the identification bounds.
#'
#' @param lower Lower bound
#' @param upper Upper bound
#' @param effect_scale Character string: "OR", "RR", or "RD"
#' @param scale Character string: "absolute" or "relative"
#'
#' @return Numeric width
#' @keywords internal
compute_bound_width <- function(lower, upper,
                               effect_scale = "OR",
                               scale = "absolute") {

  scale <- match.arg(scale, c("absolute", "relative"))

  if (scale == "absolute") {
    # Simple difference
    width <- upper - lower

  } else if (scale == "relative") {
    # Width relative to point estimate (midpoint)
    if (effect_scale %in% c("OR", "RR")) {
      # Use geometric mean for multiplicative effects
      midpoint <- sqrt(lower * upper)
      width <- (upper - lower) / midpoint
    } else {
      # Use arithmetic mean for additive effects
      midpoint <- (lower + upper) / 2
      if (abs(midpoint) > 1e-6) {
        width <- (upper - lower) / abs(midpoint)
      } else {
        width <- upper - lower  # Fall back to absolute if midpoint ≈ 0
      }
    }
  }

  return(width)
}


#' Compute Bound Midpoint
#'
#' @description
#' Compute the midpoint of the bounds (point estimate).
#'
#' @param lower Lower bound
#' @param upper Upper bound
#' @param effect_scale Character string: "OR", "RR", or "RD"
#'
#' @return Numeric midpoint
#' @keywords internal
compute_bound_midpoint <- function(lower, upper, effect_scale = "OR") {

  if (effect_scale %in% c("OR", "RR")) {
    # Geometric mean for multiplicative effects
    midpoint <- sqrt(lower * upper)
  } else {
    # Arithmetic mean for additive effects
    midpoint <- (lower + upper) / 2
  }

  return(midpoint)
}


#' Classify Effect Direction
#'
#' @description
#' Classify the direction of the effect based on the bounds.
#'
#' @param lower Lower bound
#' @param upper Upper bound
#' @param effect_scale Character string: "OR", "RR", or "RD"
#'
#' @return Character string: "positive", "negative", "null", or "indeterminate"
#' @keywords internal
classify_effect_direction <- function(lower, upper, effect_scale = "OR") {

  crosses_null <- bounds_cross_null(lower, upper, effect_scale)

  if (crosses_null) {
    return("indeterminate")
  }

  if (effect_scale %in% c("OR", "RR")) {
    # For multiplicative effects
    if (upper < 1) {
      return("negative")
    } else if (lower > 1) {
      return("positive")
    } else {
      return("null")
    }
  } else {
    # For additive effects
    if (upper < 0) {
      return("negative")
    } else if (lower > 0) {
      return("positive")
    } else {
      return("null")
    }
  }
}


#' Format Effect Estimate for Reporting
#'
#' @description
#' Format an effect estimate as a string for tables/reports.
#'
#' @param estimate Numeric effect estimate (or bounds)
#' @param effect_scale Character string: "OR", "RR", or "RD"
#' @param digits Integer: number of decimal places
#' @param ci Optional: confidence interval (length 2 vector)
#'
#' @return Character string
#' @export
format_effect <- function(estimate,
                         effect_scale = "OR",
                         digits = 2,
                         ci = NULL) {

  effect_scale <- match.arg(effect_scale, c("OR", "RR", "RD"))

  # Format point estimate
  if (length(estimate) == 2) {
    # Bounds provided
    formatted <- paste0("[",
                       sprintf(paste0("%.", digits, "f"), estimate[1]),
                       ", ",
                       sprintf(paste0("%.", digits, "f"), estimate[2]),
                       "]")
  } else {
    # Single estimate
    formatted <- sprintf(paste0("%.", digits, "f"), estimate)

    # Add CI if provided
    if (!is.null(ci) && length(ci) == 2) {
      formatted <- paste0(formatted, " (",
                         sprintf(paste0("%.", digits, "f"), ci[1]), ", ",
                         sprintf(paste0("%.", digits, "f"), ci[2]), ")")
    }
  }

  return(formatted)
}


#' Compute Relative Precision
#'
#' @description
#' Compute the relative precision of bounds compared to a naive estimate.
#'
#' @param bounds_width Width of partial identification bounds
#' @param naive_ci_width Width of naive 95% CI
#'
#' @return Numeric: ratio of naive CI width to bounds width
#' @keywords internal
#' @noRd
compute_relative_precision <- function(bounds_width, naive_ci_width) {

  if (bounds_width <= 0) {
    return(Inf)
  }

  relative_precision <- naive_ci_width / bounds_width

  return(relative_precision)
}
