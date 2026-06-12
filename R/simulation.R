#' Simulate Data with Differential Misclassification
#'
#' @description
#' Generate synthetic data with known differential misclassification for
#' power analysis, simulation studies, and methods comparison.
#'
#' @param n Integer specifying the sample size.
#' @param true_params A named list of true data generating process parameters:
#'   \itemize{
#'     \item \code{beta_AM}: Effect of A on M (log-odds scale)
#'     \item \code{theta_AY}: Direct effect of A on Y (log-odds scale)
#'     \item \code{theta_MY}: Effect of M on Y (log-odds scale)
#'     \item \code{p_A}: Marginal probability of A=1
#'     \item \code{beta_C}: Vector of confounder effects (if any)
#'   }
#' @param dm_params A named list of differential misclassification parameters:
#'   \itemize{
#'     \item \code{sn0}: Sensitivity when Y=0
#'     \item \code{sp0}: Specificity when Y=0
#'     \item \code{psi_sn}: Sensitivity odds ratio
#'     \item \code{psi_sp}: Specificity odds ratio
#'   }
#' @param misclass_type Character string: "exposure" or "mediator" indicating
#'   which variable has misclassification.
#' @param confounders Integer specifying the number of binary confounders to
#'   generate. Default is 1.
#' @param seed Integer for random number generator seed for reproducibility.
#'   If NULL (default), no seed is set.
#'
#' @return A list containing:
#' \describe{
#'   \item{observed}{Data frame with misclassified variable (A* or M*) and
#'     other observed variables}
#'   \item{truth}{Data frame with true (unobserved) values before misclassification}
#'   \item{true_effects}{List with true NDE and NIE calculated from the DGP}
#'   \item{dgp_params}{List of all data generating parameters used}
#' }
#'
#' @details
#' The data generation follows these steps:
#' \enumerate{
#'   \item Generate confounders C (if any) from Bernoulli(0.5)
#'   \item Generate true exposure A ~ Bernoulli(expit(alpha_A + beta_C'C))
#'   \item Generate true mediator M ~ Bernoulli(expit(alpha_M + beta_AM*A + beta_C'C))
#'   \item Generate outcome Y ~ Bernoulli(expit(alpha_Y + theta_AY*A + theta_MY*M + beta_C'C))
#'   \item Apply differential misclassification to create X* (where X is A or M)
#' }
#'
#' The misclassification mechanism is:
#' \deqn{P(X*=1|X=1,Y=y) = sn0 * exp(psi_sn * y) / (1 + sn0*(exp(psi_sn * y) - 1))}
#' \deqn{P(X*=0|X=0,Y=y) = sp0 * exp(psi_sp * y) / (1 + sp0*(exp(psi_sp * y) - 1))}
#'
#' When psi_sn = psi_sp = 1, the error is non-differential.
#'
#' @examples
#' \donttest{
#' # Simulate data with exposure misclassification
#' set.seed(123)
#' sim_data <- simulate_dm_data(
#'   n = 1000,
#'   true_params = list(
#'     beta_AM = 0.5,
#'     theta_AY = 0.3,
#'     theta_MY = 0.8,
#'     p_A = 0.5
#'   ),
#'   dm_params = list(
#'     sn0 = 0.85,
#'     sp0 = 0.85,
#'     psi_sn = 1.5,
#'     psi_sp = 1.0
#'   ),
#'   misclass_type = "exposure",
#'   confounders = 2
#' )
#'
#' # View observed data
#' head(sim_data$observed)
#'
#' # Check true effects
#' print(sim_data$true_effects)
#'
#' # Analyze with medrobust
#' bounds <- bound_ne(
#'   data = sim_data$observed,
#'   exposure = "A_star",
#'   mediator = "M",
#'   outcome = "Y",
#'   confounders = c("C1", "C2"),
#'   misclassified_variable = "exposure",
#'   sensitivity_region = list(
#'     sn0_range = c(0.80, 0.90),
#'     sp0_range = c(0.80, 0.90),
#'     psi_sn_range = c(1.0, 2.0),
#'     psi_sp_range = c(1.0, 1.0)
#'   )
#' )
#' }
#'
#' @keywords internal
#' @noRd
simulate_dm_data_legacy <- function(n,
                            true_params,
                            dm_params,
                            misclass_type = c("exposure", "mediator"),
                            confounders = 1,
                            seed = NULL) {

  # Match arguments
  misclass_type <- match.arg(misclass_type)

  # Set seed if provided
  if (!is.null(seed)) set.seed(seed)

  # Validate parameters
  validate_simulation_params(true_params, dm_params, confounders)

  # Generate confounders
  C_data <- generate_confounders(n, confounders)

  # Generate true A, M, Y
  true_data <- generate_true_variables(n, true_params, C_data)

  # Apply differential misclassification
  if (misclass_type == "exposure") {
    observed_data <- apply_exposure_misclassification(true_data, dm_params)
  } else {
    observed_data <- apply_mediator_misclassification(true_data, dm_params)
  }

  # Compute true natural effects from DGP
  true_effects <- compute_true_effects_legacy(true_params)

  # Combine results
  result <- list(
    observed = cbind(observed_data, C_data),
    truth = cbind(true_data, C_data),
    true_effects = true_effects,
    dgp_params = list(
      true_params = true_params,
      dm_params = dm_params,
      misclass_type = misclass_type,
      n_confounders = confounders
    )
  )

  return(result)
}


#' Validate simulation parameters
#'
#' @keywords internal
#' @noRd
validate_simulation_params <- function(true_params, dm_params, confounders) {

  # Check true_params
  required_true <- c("beta_AM", "theta_AY", "theta_MY", "p_A")
  missing <- setdiff(required_true, names(true_params))
  if (length(missing) > 0) {
    stop("true_params missing: ", paste(missing, collapse = ", "))
  }

  # Check dm_params
  required_dm <- c("sn0", "sp0", "psi_sn", "psi_sp")
  missing <- setdiff(required_dm, names(dm_params))
  if (length(missing) > 0) {
    stop("dm_params missing: ", paste(missing, collapse = ", "))
  }

  # Check valid ranges
  if (dm_params$sn0 <= 0 || dm_params$sn0 > 1) {
    stop("sn0 must be in (0, 1]")
  }
  if (dm_params$sp0 <= 0 || dm_params$sp0 > 1) {
    stop("sp0 must be in (0, 1]")
  }

  invisible(TRUE)
}


#' Generate confounders
#'
#' @keywords internal
#' @noRd
generate_confounders <- function(n, n_conf) {

  if (n_conf == 0) {
    return(NULL)
  }

  conf_data <- replicate(n_conf, rbinom(n, 1, 0.5))
  colnames(conf_data) <- paste0("C", 1:n_conf)

  return(as.data.frame(conf_data))
}


#' Generate true variables from DGP
#'
#' @keywords internal
#' @noRd
generate_true_variables <- function(n, true_params, C_data) {

  # Extract parameters
  beta_AM <- true_params$beta_AM
  theta_AY <- true_params$theta_AY
  theta_MY <- true_params$theta_MY
  p_A <- true_params$p_A

  # Confounder effects
  if (!is.null(C_data)) {
    beta_C <- if ("beta_C" %in% names(true_params)) {
      true_params$beta_C
    } else {
      rep(0.2, ncol(C_data))  # Default weak confounding
    }
    C_effect <- as.matrix(C_data) %*% beta_C
  } else {
    C_effect <- 0
  }

  # Generate A
  A <- rbinom(n, 1, p_A)

  # Generate M | A, C
  logit_M <- beta_AM * A + C_effect
  p_M <- plogis(logit_M)
  M <- rbinom(n, 1, p_M)

  # Generate Y | A, M, C
  logit_Y <- theta_AY * A + theta_MY * M + C_effect
  p_Y <- plogis(logit_Y)
  Y <- rbinom(n, 1, p_Y)

  return(data.frame(A = A, M = M, Y = Y))
}


#' Apply exposure misclassification
#'
#' @keywords internal
#' @noRd
apply_exposure_misclassification <- function(true_data, dm_params) {

  n <- nrow(true_data)
  A <- true_data$A
  Y <- true_data$Y

  # Compute misclassification probabilities
  sn0 <- dm_params$sn0
  sp0 <- dm_params$sp0
  psi_sn <- dm_params$psi_sn
  psi_sp <- dm_params$psi_sp

  # Sensitivity: P(A*=1|A=1,Y)
  sn_y <- sn0 * exp(log(psi_sn) * Y)
  sn_y <- pmin(sn_y, 1)  # Bound by 1

  # Specificity: P(A*=0|A=0,Y)
  sp_y <- sp0 * exp(log(psi_sp) * Y)
  sp_y <- pmin(sp_y, 1)  # Bound by 1

  # Generate A* (vectorized)
  prob_A_star_1 <- ifelse(A == 1, sn_y, 1 - sp_y)
  A_star <- rbinom(n, 1, prob = prob_A_star_1)

  observed <- data.frame(
    A_star = A_star,
    M = true_data$M,
    Y = true_data$Y
  )

  return(observed)
}


#' Apply mediator misclassification
#'
#' @keywords internal
#' @noRd
apply_mediator_misclassification <- function(true_data, dm_params) {

  n <- nrow(true_data)
  M <- true_data$M
  Y <- true_data$Y

  # Compute misclassification probabilities
  sn0 <- dm_params$sn0
  sp0 <- dm_params$sp0
  psi_sn <- dm_params$psi_sn
  psi_sp <- dm_params$psi_sp

  # Sensitivity: P(M*=1|M=1,Y)
  sn_y <- sn0 * exp(log(psi_sn) * Y)
  sn_y <- pmin(sn_y, 1)

  # Specificity: P(M*=0|M=0,Y)
  sp_y <- sp0 * exp(log(psi_sp) * Y)
  sp_y <- pmin(sp_y, 1)

  # Generate M* (vectorized)
  prob_M_star_1 <- ifelse(M == 1, sn_y, 1 - sp_y)
  M_star <- rbinom(n, 1, prob = prob_M_star_1)

  observed <- data.frame(
    A = true_data$A,
    M_star = M_star,
    Y = true_data$Y
  )

  return(observed)
}


#' Compute true natural effects from DGP
#'
#' @keywords internal
#' @noRd
compute_true_effects_legacy <- function(true_params) {

  # TODO: Analytically compute NDE and NIE from the logistic DGP
  # This requires integration over the confounder distribution

  # PLACEHOLDER
  list(
    NIE = NA,
    NDE = NA,
    note = "True effects computation not yet implemented"
  )
}


#' Power Analysis for Bound Precision
#'
#' @description
#' Estimate the sample size needed to achieve a target precision (bound width)
#' for the partial identification interval.
#'
#' @param true_nie The true Natural Indirect Effect (on the scale specified).
#' @param sensitivity_region The sensitivity parameter region.
#' @param target_width The desired width of the identification interval.
#' @param alpha Significance level for confidence intervals. Default is 0.05.
#' @param n_sim Number of simulation replications for power calculation.
#'   Default is 1000.
#' @param ... Additional arguments passed to \code{simulate_dm_data}.
#'
#' @return A list containing:
#' \describe{
#'   \item{recommended_n}{Recommended sample size}
#'   \item{power_curve}{Data frame with sample sizes and corresponding widths}
#' }
#'
#' @examples
#' \donttest{
#' # Estimate sample size for target bound width
#' power_results <- power_analysis(
#'   true_nie = 1.3,
#'   sensitivity_region = list(
#'     sn0_range = c(0.8, 0.9),
#'     sp0_range = c(0.8, 0.9),
#'     psi_sn_range = c(1.0, 2.0),
#'     psi_sp_range = c(1.0, 1.0)
#'   ),
#'   target_width = 0.3
#' )
#' }
#'
#' @keywords internal
#' @noRd
power_analysis_legacy <- function(true_nie,
                          sensitivity_region,
                          target_width,
                          alpha = 0.05,
                          n_sim = 1000,
                          ...) {

  # TODO: Implement power analysis via simulation
  # Try multiple sample sizes and estimate bound width

  # PLACEHOLDER
  list(
    recommended_n = NA,
    power_curve = data.frame(n = integer(0), width = numeric(0)),
    note = "Power analysis not yet implemented"
  )
}


#' Compare Bounds Across Multiple Analyses
#'
#' @description
#' Compare partial identification bounds from multiple analyses (e.g., different
#' sensitivity regions, different datasets, different assumptions).
#'
#' @param bounds_list A named list of \code{medrobust_bounds} objects.
#' @param labels Optional character vector of labels for each analysis.
#'   If NULL, uses names from bounds_list.
#'
#' @return A data frame comparing the bounds, and optionally a plot.
#'
#' @examples
#' \donttest{
#' # Compare bounds under different sensitivity assumptions
#' sim <- simulate_dm_data(
#'   n = 600,
#'   true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
#'   dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
#'   misclass_type = "mediator", confounders = 1, seed = 1
#' )
#' args0 <- list(
#'   data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
#'   confounders = "C1", misclassified_variable = "mediator", n_grid = 10
#' )
#' set.seed(1)
#' bounds1 <- do.call(bound_ne, c(args0, list(sensitivity_region = list(
#'   sn0_range = c(0.82, 0.97), sp0_range = c(0.82, 0.97),
#'   psi_sn_range = c(0.85, 1.3), psi_sp_range = c(0.85, 1.3)))))
#' bounds2 <- do.call(bound_ne, c(args0, list(sensitivity_region = list(
#'   sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
#'   psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)))))
#'
#' comparison <- compare_bounds(
#'   list(conservative = bounds1, liberal = bounds2)
#' )
#' print(comparison)
#' }
#'
#' @export
compare_bounds <- function(bounds_list, labels = NULL) {

  if (!all(sapply(bounds_list, is_s7_class, "medrobust_bounds"))) {
    stop("All elements of bounds_list must be medrobust_bounds objects")
  }

  if (is.null(labels)) {
    labels <- names(bounds_list)
    if (is.null(labels)) {
      labels <- paste0("Analysis_", seq_along(bounds_list))
    }
  }

  # Extract bounds
  comparison <- data.frame(
    analysis = labels,
    NIE_lower = sapply(bounds_list, function(x) x@NIE_lower),
    NIE_upper = sapply(bounds_list, function(x) x@NIE_upper),
    NDE_lower = sapply(bounds_list, function(x) x@NDE_lower),
    NDE_upper = sapply(bounds_list, function(x) x@NDE_upper),
    falsified_prop = sapply(bounds_list, function(x) x@falsified_proportion)
  )

  return(comparison)
}
