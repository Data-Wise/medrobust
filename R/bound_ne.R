#' Partial Identification Bounds for Natural Effects Under Differential Misclassification
#'
#' @description
#' Computes partial identification bounds for the Natural Direct Effect (NDE) and
#' Natural Indirect Effect (NIE) when either the exposure or mediator is subject
#' to differential misclassification. The method does not require validation data.
#'
#' @param data A data frame containing the observed variables.
#' @param exposure Character string. Name of the exposure variable (A or A*).
#' @param mediator Character string. Name of the mediator variable (M or M*).
#' @param outcome Character string. Name of the outcome variable (Y).
#' @param confounders Character vector. Names of confounding variables.
#' @param misclassified_variable Character string. Either "exposure" or "mediator"
#'   to indicate which variable is subject to misclassification.
#' @param sensitivity_region A named list defining the sensitivity region Theta_Psi.
#'   Should contain: \code{sn0_range}, \code{sp0_range}, \code{psi_sn_range},
#'   \code{psi_sp_range}. Each element should be a numeric vector of length 2
#'   giving the minimum and maximum values. If NULL, default ranges are used.
#' @param n_grid Integer. Number of grid points per parameter dimension. Default is 50.
#' @param effect_scale Character string. Scale for reporting effects: "OR" (odds ratio),
#'   "RR" (risk ratio), or "RD" (risk difference). Default is "OR".
#' @param confidence_level Numeric. Confidence level for confidence intervals. Default is 0.95.
#' @param ci_method Character. `"none"` (default) or `"analytic"`. If `"analytic"`,
#'   attaches Imbens-Manski confidence intervals (see [bound_ci()]) to the result's
#'   `@analytic_ci` slot.
#' @param ci_n_boot Integer. Resamples for the analytic CI endpoint SEs. Default 200.
#' @param bootstrap Logical. Whether to compute bootstrap confidence intervals. Default is FALSE.
#' @param bootstrap_reps Integer. Number of bootstrap replicates if bootstrap=TRUE. Default is 1000.
#' @param bootstrap_method Character string. Bootstrap CI method: "percentile" (default) or "bca"
#'   (bias-corrected and accelerated). The percentile method is faster and adequate for most
#'   applications. BCa provides second-order accurate intervals but requires jackknife estimation,
#'   which is computationally intensive for large datasets.
#' @param parallel Logical. Whether to use parallel processing. Default is FALSE.
#' @param n_cores Integer. Number of cores for parallel processing. If NULL, uses
#'   detectCores() - 1. Default is NULL.
#' @param cache Logical. Whether to cache intermediate results. Default is FALSE.
#' @param cache_dir Character string. Directory for cache files. If NULL, uses temp directory.
#' @param verbose Logical. Whether to print progress messages. Default is TRUE.
#' @param stratify_by Character vector. Additional variables to stratify by (advanced use).
#' @param use_adaptive_grid Logical. Whether to use adaptive grid refinement for large grids
#'   (n_grid >= 20). This dramatically reduces computation time by focusing on compatible
#'   regions. Default is TRUE.
#' @param grid_method Character string specifying grid search algorithm:
#'   \itemize{
#'     \item \code{"lhs"} (default): Latin Hypercube Sampling - space-filling design
#'       that reduces evaluations by 99\% while maintaining broad coverage. Best for
#'       most applications (McKay et al., 1979).
#'     \item \code{"auto"}: Automatically selects best method based on a 16-point probe
#'       of the parameter space.
#'     \item \code{"regular"}: Exhaustive regular grid (n_grid^4 evaluations). Use for
#'       exact bounds when computational budget allows.
#'     \item \code{"sobol"}: Sobol low-discrepancy sequences (Sobol, 1967). Similar to
#'       LHS but better for high-dimensional problems.
#'     \item \code{"adaptive"}: Two-stage coarse-to-fine refinement. Effective when
#'       falsification rate is high.
#'     \item \code{"binary"}: Binary search on parameter boundaries. Efficient when
#'       compatibility is monotonic in parameters.
#'   }
#'
#' @return An object of class \code{medrobust_bounds} containing:
#'   \item{NIE_lower}{Lower bound for Natural Indirect Effect}
#'   \item{NIE_upper}{Upper bound for Natural Indirect Effect}
#'   \item{NDE_lower}{Lower bound for Natural Direct Effect}
#'   \item{NDE_upper}{Upper bound for Natural Direct Effect}
#'   \item{compatible_sets}{Data frame of compatible parameter sets}
#'   \item{falsified_proportion}{Proportion of sensitivity region falsified}
#'   \item{effect_scale}{Scale used for reporting}
#'   \item{n_evaluated}{Number of parameter sets evaluated}
#'   \item{n_compatible}{Number of compatible parameter sets}
#'   \item{computation_time}{Time taken for computation}
#'   \item{call}{Original function call}
#'   \item{data_summary}{Summary statistics of the data}
#'   \item{bootstrap_results}{Bootstrap results if bootstrap=TRUE}
#'
#' @details
#' This function implements the partial identification approach described in
#' [Author] (2025). The method derives bounds on causal mediation effects by
#' specifying a plausible range for misclassification parameters and using
#' testable implications to rule out empirically inconsistent values.
#'
#' The sensitivity region Theta_Psi is defined by four parameters:
#' \itemize{
#'   \item \code{sn0}: Baseline sensitivity (probability of correct classification
#'     when Y=0)
#'   \item \code{sp0}: Baseline specificity
#'   \item \code{psi_sn}: Differential sensitivity parameter (odds ratio)
#'   \item \code{psi_sp}: Differential specificity parameter (odds ratio)
#' }
#'
#' Non-differential misclassification corresponds to psi_sn = psi_sp = 1.
#'
#' @examples
#' \donttest{
#' # Simulate data with a known mediator-misclassification mechanism
#' sim <- simulate_dm_data(
#'   n = 8000,
#'   true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
#'   dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
#'   misclass_type = "mediator", confounders = 1, seed = 1
#' )
#'
#' # Sensitivity region containing the (here non-differential) truth
#' sens_region <- list(
#'   sn0_range = c(0.80, 0.99),
#'   sp0_range = c(0.80, 0.99),
#'   psi_sn_range = c(0.8, 1.5),
#'   psi_sp_range = c(0.8, 1.5)
#' )
#'
#' # Compute partial-identification bounds for mediator misclassification.
#' # The raw bound [L, U] is consistent but is NOT a confidence set; at finite n
#' # it can under-cover the truth, so we add Imbens-Manski confidence intervals
#' # in the same fit via ci_method = "analytic".
#' set.seed(1)
#' bounds <- bound_ne(
#'   data = sim@observed,
#'   exposure = "A",
#'   mediator = "M_star",
#'   outcome = "Y",
#'   confounders = "C1",
#'   misclassified_variable = "mediator",
#'   sensitivity_region = sens_region,
#'   n_grid = 10,
#'   ci_method = "analytic", ci_n_boot = 50
#' )
#'
#' # View results
#' print(bounds)
#' summary(bounds)
#' bounds@analytic_ci$NDE   # raw [L, U] plus Imbens-Manski confidence interval
#'
#' # Visualize
#' sensitivity_plot(bounds, param = "psi_sn")
#' }
#'
#' @references
#' [Author] (2025). Partial Identification of Causal Mediation Effects Under
#' Differential Misclassification. \emph{Biostatistics}.
#'
#' McKay, M. D., Beckman, R. J., & Conover, W. J. (1979). A comparison of three
#' methods for selecting values of input variables in the analysis of output from
#' a computer code. \emph{Technometrics}, 21(2), 239-245.
#'
#' Sobol', I. M. (1967). On the distribution of points in a cube and the approximate
#' evaluation of integrals. \emph{USSR Computational Mathematics and Mathematical
#' Physics}, 7(4), 86-112.
#'
#' @seealso \code{\link{check_compatibility}}, \code{\link{sensitivity_plot}},
#'   \code{\link{falsification_summary}}
#'
#' @export
bound_ne <- function(data,
                     exposure,
                     mediator,
                     outcome,
                     confounders = NULL,
                     misclassified_variable = c("exposure", "mediator"),
                     sensitivity_region = NULL,
                     n_grid = 50,
                     effect_scale = c("OR", "RR", "RD"),
                     confidence_level = 0.95,
                     ci_method = c("none", "analytic"),
                     ci_n_boot = 200L,
                     bootstrap = FALSE,
                     bootstrap_reps = 1000,
                     bootstrap_method = c("percentile", "bca"),
                     parallel = FALSE,
                     n_cores = NULL,
                     cache = FALSE,
                     cache_dir = NULL,
                     verbose = TRUE,
                     stratify_by = NULL,
                     use_adaptive_grid = TRUE,
                     grid_method = c("lhs", "auto", "regular", "adaptive", "sobol", "binary")) {

  # Match arguments
  grid_method <- match.arg(grid_method)
  bootstrap_method <- match.arg(bootstrap_method)
  ci_method <- match.arg(ci_method)

  # Record start time
  start_time <- Sys.time()

  # Match other arguments
  misclassified_variable <- match.arg(misclassified_variable)
  effect_scale <- match.arg(effect_scale)

  # Validate inputs
  if (verbose) cat("Validating inputs...\n")
  validate_inputs(data, exposure, mediator, outcome, confounders,
                  misclassified_variable, sensitivity_region, n_grid)

  # Set default sensitivity region if not provided
  if (is.null(sensitivity_region)) {
    if (verbose) cat("Using default sensitivity region...\n")
    sensitivity_region <- get_default_sensitivity_region()
  }

  # Validate sensitivity region
  sensitivity_region <- validate_sensitivity_region(sensitivity_region)

  # Prepare data
  if (verbose) cat("Preparing data...\n")
  prepared_data <- prepare_data(data, exposure, mediator, outcome,
                                confounders, stratify_by)

  # Get data summary
  data_summary <- get_data_summary(prepared_data, exposure, mediator,
                                   outcome, confounders)

  # Check for common issues
  check_data_quality(prepared_data, exposure, mediator, outcome, verbose)

  # Dispatch to appropriate method
  if (verbose) {
    cat("\nComputing bounds for", misclassified_variable, "misclassification...\n")
    cat("Grid resolution:", n_grid, "points per dimension\n")
    cat("Total parameter sets to evaluate:", n_grid^4, "\n\n")
  }

  if (misclassified_variable == "mediator") {
    bounds_result <- bound_ne_mediator(
      data = prepared_data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      sensitivity_region = sensitivity_region,
      n_grid = n_grid,
      effect_scale = effect_scale,
      parallel = parallel,
      n_cores = n_cores,
      cache = cache,
      cache_dir = cache_dir,
      verbose = verbose,
      use_adaptive_grid = use_adaptive_grid,
      grid_method = grid_method
    )
  } else {
    bounds_result <- bound_ne_exposure(
      data = prepared_data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      sensitivity_region = sensitivity_region,
      n_grid = n_grid,
      effect_scale = effect_scale,
      parallel = parallel,
      n_cores = n_cores,
      cache = cache,
      cache_dir = cache_dir,
      verbose = verbose,
      use_adaptive_grid = use_adaptive_grid,
      grid_method = grid_method
    )
  }

  # Add bootstrap CIs if requested
  if (bootstrap) {
    if (verbose) cat("\nComputing bootstrap confidence intervals...\n")
    bootstrap_results <- compute_bootstrap_ci(
      data = data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      misclassified_variable = misclassified_variable,
      sensitivity_region = sensitivity_region,
      n_grid = n_grid,
      effect_scale = effect_scale,
      bootstrap_reps = bootstrap_reps,
      confidence_level = confidence_level,
      parallel = parallel,
      n_cores = n_cores,
      verbose = verbose,
      grid_method = grid_method,
      bootstrap_method = bootstrap_method
    )
    bounds_result$bootstrap_results <- bootstrap_results
  }

  # Compute elapsed time
  end_time <- Sys.time()
  computation_time <- difftime(end_time, start_time, units = "secs")

  # Convert sensitivity_region to S7 class if needed
  if (!inherits(sensitivity_region, "S7_object") ||
      !any(grepl("sensitivity_region", class(sensitivity_region)))) {
    sens_region_s7 <- as_sensitivity_region(sensitivity_region)
  } else {
    sens_region_s7 <- sensitivity_region
  }

  # Convert bootstrap results to S7 class if available
  bootstrap_s7 <- NULL
  if (bootstrap && !is.null(bootstrap_results)) {
    bootstrap_s7 <- bootstrap_results(
      method = bootstrap_results$method,
      n_reps = as.integer(bootstrap_results$n_reps),
      n_failed = as.integer(bootstrap_results$n_failed),
      confidence_level = bootstrap_results$confidence_level,
      nie_lower_ci = bootstrap_results$nie_lower_ci,
      nie_upper_ci = bootstrap_results$nie_upper_ci,
      nde_lower_ci = bootstrap_results$nde_lower_ci,
      nde_upper_ci = bootstrap_results$nde_upper_ci,
      boot_nie_lower = bootstrap_results$boot_nie_lower,
      boot_nie_upper = bootstrap_results$boot_nie_upper,
      boot_nde_lower = bootstrap_results$boot_nde_lower,
      boot_nde_upper = bootstrap_results$boot_nde_upper,
      z0 = bootstrap_results$z0,
      acceleration = bootstrap_results$acceleration
    )
  }

  # Construct S7 output object
  output <- medrobust_bounds(
    NIE_lower = bounds_result$NIE_lower,
    NIE_upper = bounds_result$NIE_upper,
    NDE_lower = bounds_result$NDE_lower,
    NDE_upper = bounds_result$NDE_upper,
    compatible_sets = bounds_result$compatible_sets,
    n_compatible = as.integer(bounds_result$n_compatible),
    n_evaluated = as.integer(bounds_result$n_evaluated),
    falsified_proportion = bounds_result$falsified_proportion,
    effect_scale = effect_scale,
    misclassified_variable = misclassified_variable,
    sensitivity_region = sens_region_s7,
    naive_estimates = bounds_result$naive_estimates,
    bootstrap_results = bootstrap_s7,
    data_summary = c(data_summary, list(computation_time = as.numeric(computation_time))),
    call = match.call()
  )

  # Analytic (Imbens-Manski) confidence intervals, if requested
  if (ci_method == "analytic" && output@n_compatible > 0) {
    if (verbose) cat("\nComputing analytic (Imbens-Manski) confidence intervals...\n")
    output@analytic_ci <- tryCatch(
      bound_ci(output, data, exposure, mediator, outcome, confounders,
               misclassified_variable = misclassified_variable,
               n_boot = ci_n_boot, level = confidence_level),
      error = function(e) NULL)
  }

  if (verbose) {
    cat("\n" , strrep("=", 60), "\n")
    cat("COMPUTATION COMPLETE\n")
    cat(strrep("=", 60), "\n")
    cat("Time elapsed:", round(computation_time, 2), "seconds\n")
    cat("Compatible parameter sets:", bounds_result$n_compatible, "/",
        bounds_result$n_evaluated,
        sprintf("(%.1f%%)\n", 100 * bounds_result$n_compatible / bounds_result$n_evaluated))
    cat("\nNIE Bounds (", effect_scale, " scale): [",
        sprintf("%.3f", bounds_result$NIE_lower), ", ",
        sprintf("%.3f", bounds_result$NIE_upper), "]\n", sep = "")
    cat("NDE Bounds (", effect_scale, " scale): [",
        sprintf("%.3f", bounds_result$NDE_lower), ", ",
        sprintf("%.3f", bounds_result$NDE_upper), "]\n", sep = "")
    cat(strrep("=", 60), "\n\n")
  }

  return(output)
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
