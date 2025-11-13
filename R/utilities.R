#' Extract observed data distributions
#'
#' @description
#' Compute empirical joint and conditional distributions from observed data.
#'
#' @param data Data frame
#' @param exposure Name of exposure variable
#' @param mediator Name of mediator variable
#' @param outcome Name of outcome variable
#' @param confounders Names of confounder variables
#' @keywords internal
#' @noRd
extract_observed_data <- function(data, exposure, mediator, outcome, confounders) {

  # Sample size
  n <- nrow(data)

  # Marginal distributions
  p_a <- mean(data[[exposure]], na.rm = TRUE)
  p_m <- mean(data[[mediator]], na.rm = TRUE)
  p_y <- mean(data[[outcome]], na.rm = TRUE)

  # Joint distribution P(A,M,Y|C)
  # For simplicity, if no confounders, compute unconditional
  # Otherwise, need to stratify by confounder patterns

  if (length(confounders) == 0) {
    # No confounders - compute unconditional joint distribution
    joint_dist <- compute_joint_distribution(
      data[[exposure]],
      data[[mediator]],
      data[[outcome]]
    )
  } else {
    # With confounders - need stratified approach
    joint_dist <- compute_stratified_joint_distribution(
      data, exposure, mediator, outcome, confounders
    )
  }

  result <- list(
    n = n,
    p_a = p_a,
    p_m = p_m,
    p_y = p_y,
    joint_dist = joint_dist,
    has_confounders = length(confounders) > 0,
    confounder_names = confounders
  )

  return(result)
}


#' Compute joint distribution for binary variables
#'
#' @keywords internal
#' @noRd
compute_joint_distribution <- function(var1, var2, var3) {

  # Create all combinations
  combinations <- expand.grid(
    v1 = c(0, 1),
    v2 = c(0, 1),
    v3 = c(0, 1)
  )

  # Compute probabilities
  probs <- sapply(1:nrow(combinations), function(i) {
    mean(var1 == combinations$v1[i] &
         var2 == combinations$v2[i] &
         var3 == combinations$v3[i], na.rm = TRUE)
  })

  result <- cbind(combinations, prob = probs)
  return(result)
}


#' Compute stratified joint distribution with confounders
#'
#' @keywords internal
#' @noRd
#' @importFrom dplyr group_by summarise n
compute_stratified_joint_distribution <- function(data, exposure, mediator,
                                                  outcome, confounders) {

  # Create formula for grouping
  group_vars <- c(confounders, exposure, mediator, outcome)

  # Compute frequencies for each stratum
  result <- data %>%
    dplyr::group_by(across(all_of(group_vars))) %>%
    dplyr::summarise(count = dplyr::n(), .groups = "drop") %>%
    dplyr::mutate(prob = count / sum(count))

  return(as.data.frame(result))
}


#' Create grid over sensitivity parameter space
#'
#' @description
#' Creates a grid of parameter values spanning the sensitivity region Theta_Psi.
#'
#' @param sensitivity_region Named list with parameter ranges
#' @param n_grid Number of grid points per dimension
#' @keywords internal
#' @noRd
create_sensitivity_grid <- function(sensitivity_region, n_grid) {

  # Create sequences for each parameter
  sn0_seq <- seq(sensitivity_region$sn0_range[1],
                 sensitivity_region$sn0_range[2],
                 length.out = n_grid)

  sp0_seq <- seq(sensitivity_region$sp0_range[1],
                 sensitivity_region$sp0_range[2],
                 length.out = n_grid)

  psi_sn_seq <- seq(sensitivity_region$psi_sn_range[1],
                    sensitivity_region$psi_sn_range[2],
                    length.out = n_grid)

  psi_sp_seq <- seq(sensitivity_region$psi_sp_range[1],
                    sensitivity_region$psi_sp_range[2],
                    length.out = n_grid)

  # Create full grid
  grid <- expand.grid(
    sn0 = sn0_seq,
    sp0 = sp0_seq,
    psi_sn = psi_sn_seq,
    psi_sp = psi_sp_seq
  )

  return(grid)
}


#' Compute bootstrap confidence intervals
#'
#' @description
#' Bootstrap resampling to obtain confidence intervals for bounds.
#'
#' @keywords internal
#' @noRd
compute_bootstrap_ci <- function(data, bound_function, params, reps,
                                confidence_level, parallel, n_cores, verbose) {

  # Setup parallel backend if requested
  if (parallel) {
    if (is.null(n_cores)) {
      n_cores <- parallel::detectCores() - 1
    }
    # TODO: Setup parallel::makeCluster if needed
  }

  # Bootstrap loop
  bootstrap_results <- replicate(reps, {
    # Resample data
    boot_indices <- sample(1:nrow(data), replace = TRUE)
    boot_data <- data[boot_indices, ]

    # Update params with bootstrap data
    boot_params <- params
    boot_params$data <- boot_data
    boot_params$bootstrap <- FALSE  # Don't nest bootstrap
    boot_params$verbose <- FALSE

    # Compute bounds
    tryCatch({
      bounds <- do.call(bound_function, boot_params)
      c(NIE_lower = bounds$NIE_lower,
        NIE_upper = bounds$NIE_upper,
        NDE_lower = bounds$NDE_lower,
        NDE_upper = bounds$NDE_upper)
    }, error = function(e) {
      c(NIE_lower = NA, NIE_upper = NA, NDE_lower = NA, NDE_upper = NA)
    })
  }, simplify = FALSE)

  # Combine results
  bootstrap_matrix <- do.call(rbind, bootstrap_results)

  # Compute confidence intervals
  alpha <- 1 - confidence_level
  ci_lower <- alpha / 2
  ci_upper <- 1 - alpha / 2

  ci_results <- list(
    NIE_lower_ci = quantile(bootstrap_matrix[, "NIE_lower"], c(ci_lower, ci_upper), na.rm = TRUE),
    NIE_upper_ci = quantile(bootstrap_matrix[, "NIE_upper"], c(ci_lower, ci_upper), na.rm = TRUE),
    NDE_lower_ci = quantile(bootstrap_matrix[, "NDE_lower"], c(ci_lower, ci_upper), na.rm = TRUE),
    NDE_upper_ci = quantile(bootstrap_matrix[, "NDE_upper"], c(ci_lower, ci_upper), na.rm = TRUE),
    bootstrap_distribution = bootstrap_matrix
  )

  return(ci_results)
}


#' Convert between effect scales
#'
#' @keywords internal
#' @noRd
convert_effect_scale <- function(effect, from_scale, to_scale, baseline_prob = NULL) {

  if (from_scale == to_scale) return(effect)

  # TODO: Implement conversions between OR, RR, RD
  # This requires baseline probability for some conversions

  return(effect)
}
