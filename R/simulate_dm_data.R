#' Simulate Data with Differential Misclassification
#'
#' @description
#' Generates synthetic data with known differential misclassification for
#' power analysis, methods validation, and simulation studies. Allows control
#' over true causal parameters and misclassification mechanisms.
#'
#' @param n Integer. Sample size. Default is 500.
#' @param true_params Named list of true causal parameters:
#'   \itemize{
#'     \item \code{beta_AM}: Effect of A on M (log-odds scale)
#'     \item \code{theta_AY}: Direct effect of A on Y (log-odds scale)
#'     \item \code{theta_MY}: Effect of M on Y (log-odds scale)
#'     \item \code{baseline_M}: Baseline probability of M when A=0 (optional)
#'     \item \code{baseline_Y}: Baseline probability of Y when A=0, M=0 (optional)
#'   }
#' @param dm_params Named list of misclassification parameters:
#'   \itemize{
#'     \item \code{sn0}: Baseline sensitivity (Y=0)
#'     \item \code{sp0}: Baseline specificity (Y=0)
#'     \item \code{psi_sn}: Differential sensitivity (odds ratio)
#'     \item \code{psi_sp}: Differential specificity (odds ratio)
#'   }
#' @param misclass_type Character string. Either "exposure" or "mediator" to
#'   indicate which variable is misclassified. Default is "exposure".
#' @param confounders Integer. Number of confounding variables to include.
#'   Default is 1. Set to 0 for no confounders.
#' @param confounder_params Named list controlling confounder generation:
#'   \itemize{
#'     \item \code{type}: "binary" or "continuous". Default is "binary".
#'     \item \code{effect_on_A}: Effect size on exposure (log-odds). Default is 0.3.
#'     \item \code{effect_on_M}: Effect size on mediator (log-odds). Default is 0.3.
#'     \item \code{effect_on_Y}: Effect size on outcome (log-odds). Default is 0.3.
#'   }
#' @param effect_modification Logical. Should there be effect modification
#'   (interaction between A and M on Y)? Default is FALSE.
#' @param interaction_coef Numeric. Interaction coefficient if effect_modification=TRUE.
#'   Default is 0.
#' @param seed Integer. Random seed for reproducibility. If NULL, no seed is set.
#' @param return_truth Logical. Should true (unobserved) values be returned?
#'   Default is TRUE.
#' @param return_params Logical. Should true causal effects be calculated and returned?
#'   Default is TRUE.
#'
#' @return An S7 object of class \code{simulated_dm_data} containing:
#'   \item{observed}{Data frame with observed (potentially misclassified) variables}
#'   \item{truth}{Data frame with true (unobserved) values (if return_truth=TRUE)}
#'   \item{true_effects}{List of true causal effects (if return_params=TRUE)}
#'   \item{generation_params}{Parameters used for data generation}
#'   \item{misclassification_applied}{Summary of applied misclassification}
#'
#' @examples
#' \donttest{
#' # Basic simulation with moderate effects and mild DM
#' sim_data <- simulate_dm_data(
#'   n = 500,
#'   true_params = list(
#'     beta_AM = 0.405,   # OR = 1.5
#'     theta_AY = 0.405,  # OR = 1.5
#'     theta_MY = 0.405   # OR = 1.5
#'   ),
#'   dm_params = list(
#'     sn0 = 0.85,
#'     sp0 = 0.85,
#'     psi_sn = 1.5,
#'     psi_sp = 1.0
#'   ),
#'   misclass_type = "exposure",
#'   seed = 12345
#' )
#'
#' # Use in analysis
#' set.seed(1)
#' bounds <- bound_ne(
#'   data = sim_data@observed,
#'   exposure = "A_star",
#'   mediator = "M",
#'   outcome = "Y",
#'   confounders = "C1",
#'   misclassified_variable = "exposure",
#'   sensitivity_region = list(
#'     sn0_range = c(0.80, 0.90),
#'     sp0_range = c(0.80, 0.90),
#'     psi_sn_range = c(1.0, 2.0),
#'     psi_sp_range = c(1.0, 1.0)
#'   ),
#'   n_grid = 10
#' )
#' }
#'
#' @seealso \code{\link{bound_ne}}, \code{\link{power_analysis}}
#'
#' @export
simulate_dm_data <- function(n = 500,
                             true_params = list(
                               beta_AM = 0.405,
                               theta_AY = 0.405,
                               theta_MY = 0.405
                             ),
                             dm_params = list(
                               sn0 = 0.85,
                               sp0 = 0.85,
                               psi_sn = 1.5,
                               psi_sp = 1.0
                             ),
                             misclass_type = c("exposure", "mediator"),
                             confounders = 1,
                             confounder_params = list(
                               type = "binary",
                               effect_on_A = 0.3,
                               effect_on_M = 0.3,
                               effect_on_Y = 0.3
                             ),
                             effect_modification = FALSE,
                             interaction_coef = 0,
                             seed = NULL,
                             return_truth = TRUE,
                             return_params = TRUE) {

  # Set seed if provided
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Match arguments
  misclass_type <- match.arg(misclass_type)

  # Validate inputs
  validate_simulation_inputs(n, true_params, dm_params, confounders)

  # Extract parameters with defaults
  beta_AM <- true_params$beta_AM
  theta_AY <- true_params$theta_AY
  theta_MY <- true_params$theta_MY
  baseline_M <- if (is.null(true_params$baseline_M)) -1.5 else true_params$baseline_M
  baseline_Y <- if (is.null(true_params$baseline_Y)) -2.0 else true_params$baseline_Y

  sn0 <- dm_params$sn0
  sp0 <- dm_params$sp0
  psi_sn <- dm_params$psi_sn
  psi_sp <- dm_params$psi_sp

  # Compute sn1 and sp1
  sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
  sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))

  # Validate that these are valid probabilities
  if (any(c(sn1, sp1) < 0 | c(sn1, sp1) > 1)) {
    stop("Invalid misclassification parameters: sn1 or sp1 outside [0,1]")
  }

  # Set defaults for confounder params
  conf_type <- if (is.null(confounder_params$type)) "binary" else confounder_params$type
  alpha_C <- if (is.null(confounder_params$effect_on_A)) 0.3 else confounder_params$effect_on_A
  beta_C <- if (is.null(confounder_params$effect_on_M)) 0.3 else confounder_params$effect_on_M
  theta_C <- if (is.null(confounder_params$effect_on_Y)) 0.3 else confounder_params$effect_on_Y

  # Initialize data frame
  data <- data.frame(id = 1:n)

  # Generate Confounders
  if (confounders > 0) {
    for (i in 1:confounders) {
      if (conf_type == "binary") {
        data[[paste0("C", i)]] <- rbinom(n, 1, prob = 0.5)
      } else if (conf_type == "continuous") {
        data[[paste0("C", i)]] <- rnorm(n, mean = 0, sd = 1)
      } else {
        stop("confounder_params$type must be 'binary' or 'continuous'")
      }
    }

    C_cols <- paste0("C", 1:confounders)
    C_sum_A <- rowSums(data[, C_cols, drop = FALSE]) * alpha_C
    C_sum_M <- rowSums(data[, C_cols, drop = FALSE]) * beta_C
    C_sum_Y <- rowSums(data[, C_cols, drop = FALSE]) * theta_C
  } else {
    C_sum_A <- 0
    C_sum_M <- 0
    C_sum_Y <- 0
  }

  # Generate True Exposure A
  alpha_0 <- logit(0.4)
  prob_A <- expit(alpha_0 + C_sum_A)
  data$A <- rbinom(n, 1, prob = prob_A)

  # Generate True Mediator M
  prob_M <- expit(baseline_M + beta_AM * data$A + C_sum_M)
  data$M <- rbinom(n, 1, prob = prob_M)

  # Generate Outcome Y
  if (effect_modification) {
    prob_Y <- expit(baseline_Y + theta_AY * data$A + theta_MY * data$M +
                      interaction_coef * data$A * data$M + C_sum_Y)
  } else {
    prob_Y <- expit(baseline_Y + theta_AY * data$A + theta_MY * data$M + C_sum_Y)
  }

  data$Y <- rbinom(n, 1, prob = prob_Y)

  # Apply Differential Misclassification
  if (misclass_type == "exposure") {
    data$A_star <- apply_differential_misclassification(
      true_var = data$A,
      outcome = data$Y,
      sn0 = sn0,
      sp0 = sp0,
      sn1 = sn1,
      sp1 = sp1
    )

    observed_data <- data
    observed_data$A <- NULL

    if (return_truth) {
      truth_data <- data
      truth_data$A_star <- NULL
    }

  } else if (misclass_type == "mediator") {
    data$M_star <- apply_differential_misclassification(
      true_var = data$M,
      outcome = data$Y,
      sn0 = sn0,
      sp0 = sp0,
      sn1 = sn1,
      sp1 = sp1
    )

    observed_data <- data
    observed_data$M <- NULL

    if (return_truth) {
      truth_data <- data
      truth_data$M_star <- NULL
    }
  }

  # Remove id column
  observed_data$id <- NULL
  if (return_truth) {
    truth_data$id <- NULL
  }

  # Compute True Causal Effects
  if (return_params) {
    true_effects <- compute_true_effects(
      beta_AM = beta_AM,
      theta_AY = theta_AY,
      theta_MY = theta_MY,
      baseline_M = baseline_M,
      baseline_Y = baseline_Y,
      interaction_coef = if (effect_modification) interaction_coef else 0,
      confounders = confounders,
      confounder_params = confounder_params,
      data = data
    )
  } else {
    true_effects <- NULL
  }

  # Compute Misclassification Summary
  if (misclass_type == "exposure") {
    misclass_summary <- summarize_misclassification(
      true_var = data$A,
      obs_var = data$A_star,
      outcome = data$Y,
      sn0 = sn0, sp0 = sp0, sn1 = sn1, sp1 = sp1
    )
  } else {
    misclass_summary <- summarize_misclassification(
      true_var = data$M,
      obs_var = data$M_star,
      outcome = data$Y,
      sn0 = sn0, sp0 = sp0, sn1 = sn1, sp1 = sp1
    )
  }

  # Return S7 object
  result <- simulated_dm_data(
    observed = observed_data,
    truth = if (return_truth) truth_data else NULL,
    true_effects = true_effects,
    generation_params = list(
      n = n,
      true_params = true_params,
      dm_params = dm_params,
      misclass_type = misclass_type,
      confounders = confounders,
      confounder_params = confounder_params,
      effect_modification = effect_modification,
      seed = seed
    ),
    misclassification_applied = misclass_summary
  )

  return(result)
}


#' Apply Differential Misclassification
#'
#' @keywords internal
#' @noRd
apply_differential_misclassification <- function(true_var, outcome,
                                                 sn0, sp0, sn1, sp1) {

  n <- length(true_var)

  # Vectorized approach: compute sensitivity and specificity for all observations
  sn_y <- ifelse(outcome == 1, sn1, sn0)
  sp_y <- ifelse(outcome == 1, sp1, sp0)

  # Compute probability of observing 1 for each observation
  # If true_var == 1, prob = sensitivity
  # If true_var == 0, prob = 1 - specificity
  prob_obs_1 <- ifelse(true_var == 1, sn_y, 1 - sp_y)

  # Generate all misclassified values at once (vectorized)
  obs_var <- rbinom(n, 1, prob = prob_obs_1)

  return(obs_var)
}


#' Compute True Causal Effects
#'
#' @keywords internal
#' @noRd
compute_true_effects <- function(beta_AM, theta_AY, theta_MY,
                                 baseline_M, baseline_Y,
                                 interaction_coef,
                                 confounders,
                                 confounder_params,
                                 data) {

  # Per-row confounder contributions to the M and Y linear predictors, matching
  # the DGP exactly (see data generation above: C_sum_M = rowSums(C) * beta_C and
  # C_sum_Y = rowSums(C) * theta_C). Kept as vectors (one entry per observation)
  # so we average the OUTCOME over the empirical C distribution, not the inputs.
  if (confounders > 0) {
    C_cols   <- paste0("C", seq_len(confounders))
    C_values <- data[, C_cols, drop = FALSE]
    beta_C   <- confounder_params$effect_on_M
    theta_C  <- confounder_params$effect_on_Y
    lpM_C <- rowSums(C_values) * beta_C
    lpY_C <- rowSums(C_values) * theta_C
  } else {
    lpM_C <- 0
    lpY_C <- 0
  }

  # Natural-effect g-computation (binary M, binary Y). For E[Y(a, M(aprime))]:
  # average the outcome over the M(aprime) distribution analytically (M binary),
  # then over the empirical C distribution by Monte Carlo across observations.
  # This is the g-formula; it avoids the plug-in-mean (Jensen) error of
  # collapsing M and C to their means before the nonlinear expit().
  EY <- function(a, aprime) {
    piM <- expit(baseline_M + beta_AM * aprime + lpM_C)            # P(M=1 | aprime, c_i)
    g1  <- expit(baseline_Y + theta_AY * a + theta_MY * 1 +
                   interaction_coef * a * 1 + lpY_C)               # P(Y=1 | a, M=1, c_i)
    g0  <- expit(baseline_Y + theta_AY * a + theta_MY * 0 +
                   interaction_coef * a * 0 + lpY_C)               # P(Y=1 | a, M=0, c_i)
    mean(piM * g1 + (1 - piM) * g0)                                # avg over M, then over C
  }
  E_Y_a1_Ma1 <- EY(1, 1)
  E_Y_a1_Ma0 <- EY(1, 0)
  E_Y_a0_Ma0 <- EY(0, 0)

  # OR scale
  odds_a1_Ma1 <- E_Y_a1_Ma1 / (1 - E_Y_a1_Ma1)
  odds_a1_Ma0 <- E_Y_a1_Ma0 / (1 - E_Y_a1_Ma0)
  odds_a0_Ma0 <- E_Y_a0_Ma0 / (1 - E_Y_a0_Ma0)

  NIE_OR <- odds_a1_Ma1 / odds_a1_Ma0
  NDE_OR <- odds_a1_Ma0 / odds_a0_Ma0
  TCE_OR <- odds_a1_Ma1 / odds_a0_Ma0

  # RR scale
  NIE_RR <- E_Y_a1_Ma1 / E_Y_a1_Ma0
  NDE_RR <- E_Y_a1_Ma0 / E_Y_a0_Ma0
  TCE_RR <- E_Y_a1_Ma1 / E_Y_a0_Ma0

  # RD scale
  NIE_RD <- E_Y_a1_Ma1 - E_Y_a1_Ma0
  NDE_RD <- E_Y_a1_Ma0 - E_Y_a0_Ma0
  TCE_RD <- E_Y_a1_Ma1 - E_Y_a0_Ma0

  # Proportion mediated
  PM_OR <- (TCE_OR - NDE_OR) / (TCE_OR - 1)
  PM_RR <- (TCE_RR - NDE_RR) / (TCE_RR - 1)
  PM_RD <- NIE_RD / TCE_RD

  effects <- list(
    E_Y_a1_Ma1 = E_Y_a1_Ma1,
    E_Y_a1_Ma0 = E_Y_a1_Ma0,
    E_Y_a0_Ma0 = E_Y_a0_Ma0,
    NIE_OR = NIE_OR,
    NDE_OR = NDE_OR,
    TCE_OR = TCE_OR,
    PM_OR = PM_OR,
    NIE_RR = NIE_RR,
    NDE_RR = NDE_RR,
    TCE_RR = TCE_RR,
    PM_RR = PM_RR,
    NIE_RD = NIE_RD,
    NDE_RD = NDE_RD,
    TCE_RD = TCE_RD,
    PM_RD = PM_RD,
    NIE = NIE_OR,
    NDE = NDE_OR,
    TCE = TCE_OR,
    PM = PM_OR
  )

  return(effects)
}


#' Summarize Misclassification
#'
#' @keywords internal
#' @noRd
summarize_misclassification <- function(true_var, obs_var, outcome,
                                       sn0, sp0, sn1, sp1) {

  Y0_indices <- outcome == 0
  Y1_indices <- outcome == 1

  # For Y=0
  if (sum(Y0_indices) > 0) {
    true_pos_Y0 <- sum(true_var[Y0_indices] == 1)
    true_neg_Y0 <- sum(true_var[Y0_indices] == 0)

    if (true_pos_Y0 > 0) {
      empirical_sn0 <- sum(true_var[Y0_indices] == 1 &
                            obs_var[Y0_indices] == 1) / true_pos_Y0
    } else {
      empirical_sn0 <- NA
    }

    if (true_neg_Y0 > 0) {
      empirical_sp0 <- sum(true_var[Y0_indices] == 0 &
                            obs_var[Y0_indices] == 0) / true_neg_Y0
    } else {
      empirical_sp0 <- NA
    }
  } else {
    empirical_sn0 <- NA
    empirical_sp0 <- NA
  }

  # For Y=1
  if (sum(Y1_indices) > 0) {
    true_pos_Y1 <- sum(true_var[Y1_indices] == 1)
    true_neg_Y1 <- sum(true_var[Y1_indices] == 0)

    if (true_pos_Y1 > 0) {
      empirical_sn1 <- sum(true_var[Y1_indices] == 1 &
                            obs_var[Y1_indices] == 1) / true_pos_Y1
    } else {
      empirical_sn1 <- NA
    }

    if (true_neg_Y1 > 0) {
      empirical_sp1 <- sum(true_var[Y1_indices] == 0 &
                            obs_var[Y1_indices] == 0) / true_neg_Y1
    } else {
      empirical_sp1 <- NA
    }
  } else {
    empirical_sn1 <- NA
    empirical_sp1 <- NA
  }

  misclass_rate <- mean(true_var != obs_var)
  confusion <- table(True = true_var, Observed = obs_var)

  summary <- list(
    specified = list(sn0 = sn0, sp0 = sp0, sn1 = sn1, sp1 = sp1),
    empirical = list(
      sn0 = empirical_sn0,
      sp0 = empirical_sp0,
      sn1 = empirical_sn1,
      sp1 = empirical_sp1
    ),
    misclassification_rate = misclass_rate,
    confusion_matrix = confusion
  )

  return(summary)
}


#' Validate Simulation Inputs
#'
#' @keywords internal
#' @noRd
validate_simulation_inputs <- function(n, true_params, dm_params, confounders) {

  if (n < 50) {
    warning("Sample size is very small (n < 50). Results may be unstable.")
  }

  required_true <- c("beta_AM", "theta_AY", "theta_MY")
  missing_true <- setdiff(required_true, names(true_params))
  if (length(missing_true) > 0) {
    stop("true_params must contain: ", paste(required_true, collapse = ", "))
  }

  required_dm <- c("sn0", "sp0", "psi_sn", "psi_sp")
  missing_dm <- setdiff(required_dm, names(dm_params))
  if (length(missing_dm) > 0) {
    stop("dm_params must contain: ", paste(required_dm, collapse = ", "))
  }

  if (any(c(dm_params$sn0, dm_params$sp0) < 0 |
          c(dm_params$sn0, dm_params$sp0) > 1)) {
    stop("sn0 and sp0 must be in [0, 1]")
  }

  if (any(c(dm_params$psi_sn, dm_params$psi_sp) <= 0)) {
    stop("psi_sn and psi_sp must be positive")
  }

  if (confounders < 0 || confounders > 10) {
    stop("confounders must be between 0 and 10")
  }

  invisible(TRUE)
}
