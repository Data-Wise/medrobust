#' Global variables used in dplyr operations
#' @name globals
#' @keywords internal
NULL

utils::globalVariables(c(
  "stratum_id", "weight", "count", "lower", "upper",
  "param_value", "nie_lower", "nie_upper", "nde_lower", "nde_upper",
  "proportion", "category", "value", "falsification_rate",
  "parameter_label", "x", "y"
))
