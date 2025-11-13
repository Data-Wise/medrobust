#' Compute Partial Identification Bounds for Natural Effects
#'
#' @description
#' Main function for computing partial identification bounds for Natural Direct
#' Effects (NDE) and Natural Indirect Effects (NIE) under differential
#' misclassification of either the exposure or mediator.
#'
#' @param data A data frame containing the observed variables.
#' @param exposure Character string specifying the name of the exposure variable
#'   (A or A*). Should be binary (0/1).
#' @param mediator Character string specifying the name of the mediator variable
#'   (M or M*). Should be binary (0/1).
#' @param outcome Character string specifying the name of the outcome variable
#'   (Y). Should be binary (0/1).
#' @param confounders Character vector of confounder variable names.
#' @param misclassified_variable Character string: either "exposure" or "mediator"
#'   indicating which variable is subject to differential misclassification.
#' @param sensitivity_region A named list defining the sensitivity parameter space
#'   Theta_Psi. Should contain:
#'   \itemize{
#'     \item \code{sn0_range}: Numeric vector of length 2 for sensitivity when Y=0
#'     \item \code{sp0_range}: Numeric vector of length 2 for specificity when Y=0
#'     \item \code{psi_sn_range}: Numeric vector of length 2 for sensitivity odds ratio
#'     \item \code{psi_sp_range}: Numeric vector of length 2 for specificity odds ratio
#'   }
#' @param n_grid Integer specifying the number of grid points for discretizing
#'   the sensitivity parameter space. Default is 50.
#' @param effect_scale Character string specifying the scale for reporting effects:
#'   "OR" (odds ratio, default), "RR" (risk ratio), or "RD" (risk difference).
#' @param confidence_level Numeric value between 0 and 1 for bootstrap confidence
#'   interval coverage. Default is 0.95.
#' @param bootstrap Logical indicating whether to compute bootstrap confidence
#'   intervals. Default is FALSE.
#' @param bootstrap_reps Integer specifying the number of bootstrap replicates.
#'   Default is 1000.
#' @param parallel Logical indicating whether to use parallel processing.
#'   Default is FALSE.
#' @param n_cores Integer specifying number of cores for parallel processing.
#'   If NULL (default), uses \code{parallel::detectCores() - 1}.
#' @param cache Logical indicating whether to cache intermediate results.
#'   Default is FALSE.
#' @param cache_dir Character string specifying directory for cache files.
#'   If NULL, uses a temporary directory.
#' @param verbose Logical indicating whether to print progress messages.
#'   Default is TRUE.
#'
#' @return An S3 object of class \code{medrobust_bounds} containing:
#' \describe{
#'   \item{NIE_lower}{Lower bound for Natural Indirect Effect}
#'   \item{NIE_upper}{Upper bound for Natural Indirect Effect}
#'   \item{NDE_lower}{Lower bound for Natural Direct Effect}
#'   \item{NDE_upper}{Upper bound for Natural Direct Effect}
#'   \item{compatible_sets}{Data frame of parameters in compatible set Theta_C}
#'   \item{falsified_proportion}{Proportion of Theta_Psi empirically falsified}
#'   \item{call}{The original function call}
#'   \item{data_summary}{Summary statistics from the observed data}
#'   \item{effect_scale}{Scale used for effect measures}
#'   \item{misclassified_variable}{Which variable has misclassification}
#'   \item{bootstrap_ci}{Bootstrap confidence intervals (if requested)}
#' }
#'
#' @details
#' This function implements the partial identification approach for natural
#' effects under differential misclassification. The method:
#' \enumerate{
#'   \item Discretizes the sensitivity parameter space Theta_Psi into a grid
#'   \item For each grid point, checks testable implications to determine
#'         compatibility with observed data
#'   \item For compatible parameters, computes implied bounds on NDE and NIE
#'   \item Returns the union of bounds across all compatible parameters
#' }
#'
#' The sensitivity parameters capture outcome-dependent misclassification:
#' \itemize{
#'   \item \code{sn0}: Sensitivity when Y=0, P(X*=1|X=1,Y=0)
#'   \item \code{sp0}: Specificity when Y=0, P(X*=0|X=0,Y=0)
#'   \item \code{psi_sn}: Sensitivity odds ratio, OR[X*=1|X=1,Y=1 vs Y=0]
#'   \item \code{psi_sp}: Specificity odds ratio, OR[X*=0|X=0,Y=1 vs Y=0]
#' }
#'
#' @references
#' Tofighi, D. (2025). "Partial Identification of Causal Mediation Effects
#' Under Differential Misclassification." \emph{Biostatistics}, XX(X), XXX-XXX.
#'
#' @examples
#' \dontrun{
#' # Load example data
#' data("arsenic_synthetic")
#'
#' # Define sensitivity region
#' sens_region <- list(
#'   sn0_range = c(0.80, 0.90),
#'   sp0_range = c(0.80, 0.90),
#'   psi_sn_range = c(1.0, 2.0),
#'   psi_sp_range = c(1.0, 1.0)
#' )
#'
#' # Compute bounds
#' bounds <- bound_ne(
#'   data = arsenic_synthetic,
#'   exposure = "A_star",
#'   mediator = "M",
#'   outcome = "Y",
#'   confounders = c("age", "smoking", "alcohol"),
#'   misclassified_variable = "exposure",
#'   sensitivity_region = sens_region,
#'   n_grid = 50
#' )
#'
#' # View results
#' print(bounds)
#' summary(bounds)
#' }
#'
#' @export
#' @importFrom stats qnorm
#' @importFrom utils head
bound_ne <- function(data,
                     exposure,
                     mediator,
                     outcome,
                     confounders,
                     misclassified_variable = c("exposure", "mediator"),
                     sensitivity_region,
                     n_grid = 50,
                     effect_scale = c("OR", "RR", "RD"),
                     confidence_level = 0.95,
                     bootstrap = FALSE,
                     bootstrap_reps = 1000,
                     parallel = FALSE,
                     n_cores = NULL,
                     cache = FALSE,
                     cache_dir = NULL,
                     verbose = TRUE) {

  # Match arguments
  misclassified_variable <- match.arg(misclassified_variable)
  effect_scale <- match.arg(effect_scale)

  # Input validation
  validate_inputs(data, exposure, mediator, outcome, confounders,
                  sensitivity_region, n_grid, confidence_level)

  if (verbose) {
    message("Computing partial identification bounds for natural effects...")
    message("Misclassified variable: ", misclassified_variable)
    message("Sample size: n = ", nrow(data))
  }

  # Route to appropriate implementation
  if (misclassified_variable == "mediator") {
    result <- bound_ne_mediator(
      data = data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      sensitivity_region = sensitivity_region,
      n_grid = n_grid,
      effect_scale = effect_scale,
      verbose = verbose
    )
  } else {
    result <- bound_ne_exposure(
      data = data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      sensitivity_region = sensitivity_region,
      n_grid = n_grid,
      effect_scale = effect_scale,
      verbose = verbose
    )
  }

  # Bootstrap confidence intervals if requested
  if (bootstrap) {
    if (verbose) message("Computing bootstrap confidence intervals...")
    result$bootstrap_ci <- compute_bootstrap_ci(
      data = data,
      bound_function = bound_ne,
      params = as.list(match.call()[-1]),
      reps = bootstrap_reps,
      confidence_level = confidence_level,
      parallel = parallel,
      n_cores = n_cores,
      verbose = verbose
    )
  }

  # Store metadata
  result$call <- match.call()
  result$effect_scale <- effect_scale
  result$misclassified_variable <- misclassified_variable

  # Set class
  class(result) <- "medrobust_bounds"

  if (verbose) message("Done!")

  return(result)
}


#' Validate inputs for bound_ne function
#'
#' @keywords internal
#' @noRd
validate_inputs <- function(data, exposure, mediator, outcome, confounders,
                           sensitivity_region, n_grid, confidence_level) {

  # Check data is a data frame
  if (!is.data.frame(data)) {
    stop("'data' must be a data frame")
  }

  # Check all variables exist in data
  all_vars <- c(exposure, mediator, outcome, confounders)
  missing_vars <- setdiff(all_vars, names(data))
  if (length(missing_vars) > 0) {
    stop("Variables not found in data: ", paste(missing_vars, collapse = ", "))
  }

  # Check variables are binary (0/1)
  check_binary <- function(var_name) {
    vals <- unique(data[[var_name]])
    vals <- vals[!is.na(vals)]
    if (!all(vals %in% c(0, 1))) {
      stop(var_name, " must be binary (0/1), found values: ",
           paste(vals, collapse = ", "))
    }
  }

  check_binary(exposure)
  check_binary(mediator)
  check_binary(outcome)

  # Check sensitivity_region structure
  required_params <- c("sn0_range", "sp0_range", "psi_sn_range", "psi_sp_range")
  missing_params <- setdiff(required_params, names(sensitivity_region))
  if (length(missing_params) > 0) {
    stop("sensitivity_region must contain: ", paste(required_params, collapse = ", "))
  }

  # Check range validity
  for (param in required_params) {
    range_vals <- sensitivity_region[[param]]
    if (length(range_vals) != 2) {
      stop(param, " must be a numeric vector of length 2")
    }
    if (range_vals[1] > range_vals[2]) {
      stop(param, " must have lower bound <= upper bound")
    }
  }

  # Check n_grid
  if (!is.numeric(n_grid) || n_grid < 1) {
    stop("'n_grid' must be a positive integer")
  }

  # Check confidence_level
  if (!is.numeric(confidence_level) || confidence_level <= 0 || confidence_level >= 1) {
    stop("'confidence_level' must be between 0 and 1")
  }

  invisible(TRUE)
}
