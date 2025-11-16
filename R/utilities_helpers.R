#' Utility Functions for medrobust Package
#'
#' @description
#' Internal helper functions used throughout the package.
#'
#' @keywords internal
#' @noRd

# Check if object is S7 object with specific class
# Handles namespaced S7 classes (e.g., "medrobust::medrobust_bounds")
is_s7_class <- function(x, class_name) {
  inherits(x, "S7_object") && any(grepl(class_name, class(x)))
}

# Convert probability to odds
prob_to_odds <- function(p) {
  p / (1 - p)
}

# Convert odds to probability
odds_to_prob <- function(odds) {
  odds / (1 + odds)
}

# Logit function
logit <- function(p) {
  log(p / (1 - p))
}

# Expit (inverse logit) function
expit <- function(x) {
  1 / (1 + exp(-x))
}

#' Validate Inputs
#' @keywords internal
validate_inputs <- function(data, exposure, mediator, outcome, confounders,
                           misclassified_variable, sensitivity_region, n_grid) {

  # Check data is data frame
  if (!is.data.frame(data)) {
    stop("'data' must be a data.frame")
  }

  # Check variable names exist
  required_vars <- c(exposure, mediator, outcome, confounders)
  missing_vars <- setdiff(required_vars, names(data))
  if (length(missing_vars) > 0) {
    stop("Variables not found in data: ", paste(missing_vars, collapse = ", "))
  }

  # Check variables are binary (for now)
  check_binary <- function(var_name) {
    vals <- unique(data[[var_name]])
    vals <- vals[!is.na(vals)]
    if (!all(vals %in% c(0, 1))) {
      stop("Variable '", var_name, "' must be binary (0/1). Found values: ",
           paste(vals, collapse = ", "))
    }
  }

  check_binary(exposure)
  check_binary(mediator)
  check_binary(outcome)

  # Check for missing values
  check_missing <- function(var_name) {
    if (any(is.na(data[[var_name]]))) {
      warning("Variable '", var_name, "' contains missing values. ",
              "These observations will be removed.")
    }
  }

  check_missing(exposure)
  check_missing(mediator)
  check_missing(outcome)

  # Check n_grid
  if (!is.numeric(n_grid) || n_grid < 10 || n_grid > 200) {
    stop("'n_grid' must be a numeric value between 10 and 200")
  }

  # Check sample size
  n <- nrow(data)
  if (n < 50) {
    warning("Sample size (n=", n, ") is very small. Results may be unstable.")
  }

  invisible(TRUE)
}

#' Validate Sensitivity Region
#' @keywords internal
validate_sensitivity_region <- function(sens_region) {
  # If it's a list, convert to S7 sensitivity_region object
  if (is.list(sens_region) && !inherits(sens_region, "S7_object")) {
    # Check that it has the required elements
    required_props <- c("sn0_range", "sp0_range", "psi_sn_range", "psi_sp_range")
    missing_props <- setdiff(required_props, names(sens_region))

    if (length(missing_props) > 0) {
      stop("sensitivity_region must contain: ",
           paste(missing_props, collapse = ", "))
    }

    # Convert to S7 object (which will validate via property validators)
    sens_region <- sensitivity_region(
      sn0_range = sens_region$sn0_range,
      sp0_range = sens_region$sp0_range,
      psi_sn_range = sens_region$psi_sn_range,
      psi_sp_range = sens_region$psi_sp_range
    )
  }

  # Check if it's an S7 object and has sensitivity_region in its class
  if (!inherits(sens_region, "S7_object") ||
      !any(grepl("sensitivity_region", class(sens_region)))) {
    stop("Input must be a sensitivity_region object or a named list with required fields.")
  }

  required_props <- c("sn0_range", "sp0_range", "psi_sn_range", "psi_sp_range")

  # Use S7-aware property name accessor
  prop_names <- S7::prop_names(sens_region)
  missing_props <- setdiff(required_props, prop_names)

  if (length(missing_props) > 0) {
    stop("sensitivity_region must contain properties: ",
         paste(missing_props, collapse = ", "))
  }

  # The S7 class validators handle type, length, and range checks.
  # We can add warnings for potentially problematic (but valid) values.
  for (prop in required_props) {
    range_vals <- S7::prop(sens_region, prop)

    if (prop %in% c("sn0_range", "sp0_range")) {
      if (any(range_vals < 0.5)) {
        warning("'", prop, "' includes values < 0.5 (worse than random guessing)", call. = FALSE)
      }
    }

    if (prop %in% c("psi_sn_range", "psi_sp_range")) {
      if (any(range_vals > 10)) {
        warning("'", prop, "' includes very large odds ratios (>10)", call. = FALSE)
      }
    }
  }

  return(sens_region)
}

#' Get Default Sensitivity Region
#' @keywords internal
get_default_sensitivity_region <- function() {
  list(
    sn0_range = c(0.70, 0.95),
    sp0_range = c(0.70, 0.95),
    psi_sn_range = c(0.5, 2.0),
    psi_sp_range = c(1.0, 1.0)  # Assume non-differential specificity by default
  )
}

#' Create Parameter Grid
#' @keywords internal
create_parameter_grid <- function(sens_region, n_grid) {

  # Handle both S7 objects and lists
  if (inherits(sens_region, "S7_object")) {
    sn0_range <- sens_region@sn0_range
    sp0_range <- sens_region@sp0_range
    psi_sn_range <- sens_region@psi_sn_range
    psi_sp_range <- sens_region@psi_sp_range
  } else {
    sn0_range <- sens_region$sn0_range
    sp0_range <- sens_region$sp0_range
    psi_sn_range <- sens_region$psi_sn_range
    psi_sp_range <- sens_region$psi_sp_range
  }

  sn0_seq <- seq(sn0_range[1], sn0_range[2], length.out = n_grid)
  sp0_seq <- seq(sp0_range[1], sp0_range[2], length.out = n_grid)
  psi_sn_seq <- seq(psi_sn_range[1], psi_sn_range[2], length.out = n_grid)
  psi_sp_seq <- seq(psi_sp_range[1], psi_sp_range[2], length.out = n_grid)

  grid <- expand.grid(
    sn0 = sn0_seq,
    sp0 = sp0_seq,
    psi_sn = psi_sn_seq,
    psi_sp = psi_sp_seq
  )

  return(grid)
}

#' Prepare Data
#' @keywords internal
prepare_data <- function(data, exposure, mediator, outcome,
                        confounders, stratify_by) {

  # Select relevant variables
  keep_vars <- c(exposure, mediator, outcome, confounders, stratify_by)
  data <- data[, keep_vars, drop = FALSE]

  # Remove missing values
  data <- na.omit(data)

  # Ensure binary variables are 0/1
  data[[exposure]] <- as.numeric(data[[exposure]])
  data[[mediator]] <- as.numeric(data[[mediator]])
  data[[outcome]] <- as.numeric(data[[outcome]])

  return(data)
}

#' Get Data Summary
#' @keywords internal
get_data_summary <- function(data, exposure, mediator, outcome, confounders) {

  n <- nrow(data)

  summary_list <- list(
    n = n,
    exposure_prev = mean(data[[exposure]]),
    mediator_prev = mean(data[[mediator]]),
    outcome_prev = mean(data[[outcome]]),
    exposure_by_outcome = table(data[[exposure]], data[[outcome]]),
    mediator_by_outcome = table(data[[mediator]], data[[outcome]]),
    exposure_by_mediator = table(data[[exposure]], data[[mediator]])
  )

  if (!is.null(confounders) && length(confounders) > 0) {
    summary_list$n_confounders <- length(confounders)
    summary_list$confounder_summary <- lapply(confounders, function(c_var) {
      if (is.numeric(data[[c_var]])) {
        c(mean = mean(data[[c_var]]), sd = sd(data[[c_var]]))
      } else {
        table(data[[c_var]])
      }
    })
    names(summary_list$confounder_summary) <- confounders
  }

  return(summary_list)
}

#' Check Data Quality
#' @keywords internal
check_data_quality <- function(data, exposure, mediator, outcome, verbose) {

  # Check for sparse cells
  tab_emy <- table(data[[exposure]], data[[mediator]], data[[outcome]])
  sparse_cells <- sum(tab_emy < 5)
  if (sparse_cells > 0 && verbose) {
    warning("Found ", sparse_cells, " sparse cells (n<5) in ExMxY table. ",
            "Results may be unstable.")
  }

  # Check for extreme prevalences
  prev_e <- mean(data[[exposure]])
  prev_m <- mean(data[[mediator]])
  prev_y <- mean(data[[outcome]])

  if (any(c(prev_e, prev_m, prev_y) < 0.05 | c(prev_e, prev_m, prev_y) > 0.95)) {
    if (verbose) {
      warning("Extreme prevalence detected (very rare or very common). ",
              "This can affect numerical stability.")
    }
  }

  invisible(TRUE)
}

#' Compute Naive Effects
#' @keywords internal
compute_naive_effects <- function(data, exposure, mediator, outcome,
                                 confounders, effect_scale) {

  # Fit mediator model
  if (is.null(confounders) || length(confounders) == 0) {
    med_formula <- as.formula(paste(mediator, "~", exposure))
  } else {
    med_formula <- as.formula(paste(mediator, "~", exposure, "+",
                                   paste(confounders, collapse = " + ")))
  }

  med_model <- glm(med_formula, data = data, family = binomial(link = "logit"))

  # Fit outcome model
  if (is.null(confounders) || length(confounders) == 0) {
    out_formula <- as.formula(paste(outcome, "~", exposure, "+", mediator))
  } else {
    out_formula <- as.formula(paste(outcome, "~", exposure, "+", mediator, "+",
                                   paste(confounders, collapse = " + ")))
  }

  out_model <- glm(out_formula, data = data, family = binomial(link = "logit"))

  # Extract coefficients
  beta_am <- coef(med_model)[exposure]
  theta_ay <- coef(out_model)[exposure]
  theta_my <- coef(out_model)[mediator]

  # Compute effects on log-odds scale
  nie_logodds <- beta_am * theta_my
  nde_logodds <- theta_ay

  # Convert to requested scale
  if (effect_scale == "OR") {
    nie <- exp(nie_logodds)
    nde <- exp(nde_logodds)
  } else if (effect_scale == "RR") {
    # Approximate conversion (exact would require more computation)
    nie <- exp(nie_logodds)
    nde <- exp(nde_logodds)
    warning("RR scale approximated as OR for naive estimates")
  } else if (effect_scale == "RD") {
    # Would require g-computation, not implemented for naive
    nie <- nie_logodds
    nde <- nde_logodds
    warning("RD scale not implemented for naive estimates, returning log-odds")
  }

  return(list(nie = nie, nde = nde))
}


#' =============================================================================
#' Effect Computation Functions
#' =============================================================================

#' Compute Effects from Solved Parameters (Mediator Misclassification)
#'
#' @description
#' Given solved causal parameters (pi_a, gamma_a0, gamma_a1) for each exposure
#' level and covariate stratum, compute NDE and NIE using g-computation.
#'
#' @param solved_params List of solved parameters from mediator misclassification
#' @param data Data frame with observations
#' @param C_names Character vector of confounder names
#' @param effect_scale Character string: "OR", "RR", or "RD"
#'
#' @return List with elements nie and nde
#' @keywords internal
compute_effects_from_params <- function(solved_params,
                                       data,
                                       C_names,
                                       effect_scale = "OR") {

  # Extract unique strata
  if (is.null(C_names) || length(C_names) == 0) {
    # No confounders - single stratum
    strata_weights <- data.frame(stratum_id = 1, weight = 1)
  } else {
    # Compute stratum weights (empirical distribution of C)
    strata_weights <- data |>
      dplyr::group_by(stratum_id) |>
      dplyr::summarise(n = n(), .groups = "drop") |>
      dplyr::mutate(weight = n / sum(n)) |>
      dplyr::select(stratum_id, weight)
  }

  # Initialize accumulators for counterfactual probabilities
  # We need: E[Y(a, M(a))], E[Y(a, M(a0))], E[Y(a0, M(a0))]

  E_Y_a_Ma <- 0      # E[Y(a, M(a))]
  E_Y_a_Ma0 <- 0     # E[Y(a, M(a0))]
  E_Y_a0_Ma0 <- 0    # E[Y(a0, M(a0))]

  # Loop over strata
  for (i in 1:nrow(strata_weights)) {
    s <- strata_weights$stratum_id[i]
    w <- strata_weights$weight[i]

    # Extract parameters for a=1 and a=0 in this stratum
    params_a1 <- solved_params[[paste0("a1_s", s)]]
    params_a0 <- solved_params[[paste0("a0_s", s)]]

    if (is.null(params_a1) || is.null(params_a0)) {
      next  # Skip if parameters not available for this stratum
    }

    pi_a1 <- params_a1$pi_a
    gamma_a1_0 <- params_a1$gamma_a0
    gamma_a1_1 <- params_a1$gamma_a1

    pi_a0 <- params_a0$pi_a
    gamma_a0_0 <- params_a0$gamma_a0
    gamma_a0_1 <- params_a0$gamma_a1

    # Compute E[Y(a=1, M(a=1)) | C=c]
    # = P(M(1)=1|C) * P(Y(1)=1|M=1,C) + P(M(1)=0|C) * P(Y(1)=1|M=0,C)
    # = pi_a1 * gamma_a1_1 + (1-pi_a1) * gamma_a1_0
    E_Y_a_Ma_c <- pi_a1 * gamma_a1_1 + (1 - pi_a1) * gamma_a1_0

    # Compute E[Y(a=1, M(a=0)) | C=c]
    # = P(M(0)=1|C) * P(Y(1)=1|M=1,C) + P(M(0)=0|C) * P(Y(1)=1|M=0,C)
    # = pi_a0 * gamma_a1_1 + (1-pi_a0) * gamma_a1_0
    E_Y_a_Ma0_c <- pi_a0 * gamma_a1_1 + (1 - pi_a0) * gamma_a1_0

    # Compute E[Y(a=0, M(a=0)) | C=c]
    # = pi_a0 * gamma_a0_1 + (1-pi_a0) * gamma_a0_0
    E_Y_a0_Ma0_c <- pi_a0 * gamma_a0_1 + (1 - pi_a0) * gamma_a0_0

    # Accumulate weighted averages
    E_Y_a_Ma <- E_Y_a_Ma + w * E_Y_a_Ma_c
    E_Y_a_Ma0 <- E_Y_a_Ma0 + w * E_Y_a_Ma0_c
    E_Y_a0_Ma0 <- E_Y_a0_Ma0 + w * E_Y_a0_Ma0_c
  }

  # Compute effects on different scales
  if (effect_scale == "OR") {
    # Convert probabilities to odds
    odds_a_Ma <- E_Y_a_Ma / (1 - E_Y_a_Ma + 1e-10)
    odds_a_Ma0 <- E_Y_a_Ma0 / (1 - E_Y_a_Ma0 + 1e-10)
    odds_a0_Ma0 <- E_Y_a0_Ma0 / (1 - E_Y_a0_Ma0 + 1e-10)

    # NIE = OR(a, M(a) vs M(a0))
    nie <- odds_a_Ma / (odds_a_Ma0 + 1e-10)

    # NDE = OR(a vs a0, M(a0))
    nde <- odds_a_Ma0 / (odds_a0_Ma0 + 1e-10)

  } else if (effect_scale == "RR") {
    # Risk ratios
    nie <- E_Y_a_Ma / (E_Y_a_Ma0 + 1e-10)
    nde <- E_Y_a_Ma0 / (E_Y_a0_Ma0 + 1e-10)

  } else if (effect_scale == "RD") {
    # Risk differences
    nie <- E_Y_a_Ma - E_Y_a_Ma0
    nde <- E_Y_a_Ma0 - E_Y_a0_Ma0

  } else {
    stop("Unknown effect_scale: ", effect_scale)
  }

  # Return effects
  return(list(
    nie = nie,
    nde = nde,
    E_Y_a_Ma = E_Y_a_Ma,
    E_Y_a_Ma0 = E_Y_a_Ma0,
    E_Y_a0_Ma0 = E_Y_a0_Ma0
  ))
}


#' Compute Effects from Joint Probabilities (Exposure Misclassification)
#'
#' @description
#' Given solved true joint probabilities P(A=a, M=m, Y=y | C=c), compute
#' NDE and NIE using g-computation.
#'
#' @param P_true_list List of true joint probabilities from exposure misclassification
#' @param data Data frame with observations
#' @param C_names Character vector of confounder names
#' @param effect_scale Character string: "OR", "RR", or "RD"
#'
#' @return List with elements nie and nde
#' @keywords internal
compute_effects_from_joint_probs <- function(P_true_list,
                                            data,
                                            C_names,
                                            effect_scale = "OR") {

  # Extract unique strata and compute weights
  if (is.null(C_names) || length(C_names) == 0) {
    strata_weights <- data.frame(stratum_id = 1, weight = 1)
  } else {
    strata_weights <- data |>
      dplyr::group_by(stratum_id) |>
      dplyr::summarise(n = n(), .groups = "drop") |>
      dplyr::mutate(weight = n / sum(n)) |>
      dplyr::select(stratum_id, weight)
  }

  # Initialize accumulators
  E_Y_a_Ma <- 0
  E_Y_a_Ma0 <- 0
  E_Y_a0_Ma0 <- 0

  # Loop over strata
  for (i in 1:nrow(strata_weights)) {
    s <- strata_weights$stratum_id[i]
    w <- strata_weights$weight[i]

    # Extract all joint probabilities for this stratum
    # P(A=a, M=m, Y=y | C=c)
    P_array <- array(0, dim = c(2, 2, 2))  # [A, M, Y]

    for (m in 0:1) {
      for (y in 0:1) {
        key <- paste0("m", m, "_y", y, "_s", s)
        if (key %in% names(P_true_list)) {
          probs <- P_true_list[[key]]
          P_array[2, m+1, y+1] <- probs["P_1"]  # A=1
          P_array[1, m+1, y+1] <- probs["P_0"]  # A=0
        }
      }
    }

    # Normalize to ensure probabilities sum to 1 within stratum
    total_prob <- sum(P_array)
    if (total_prob > 1e-6) {
      P_array <- P_array / total_prob
    } else {
      next  # Skip empty stratum
    }

    # Compute conditional probabilities needed for g-computation

    # 1. P(M=m | A=a, C=c)
    P_M_given_A <- array(0, dim = c(2, 2))  # [A, M]
    for (a in 0:1) {
      P_A <- sum(P_array[a+1, , ])
      if (P_A > 1e-6) {
        for (m in 0:1) {
          P_M_given_A[a+1, m+1] <- sum(P_array[a+1, m+1, ]) / P_A
        }
      }
    }

    # 2. P(Y=1 | A=a, M=m, C=c)
    P_Y1_given_AM <- array(0, dim = c(2, 2))  # [A, M]
    for (a in 0:1) {
      for (m in 0:1) {
        P_AM <- sum(P_array[a+1, m+1, ])
        if (P_AM > 1e-6) {
          P_Y1_given_AM[a+1, m+1] <- P_array[a+1, m+1, 2] / P_AM
        }
      }
    }

    # Compute counterfactual expectations

    # E[Y(a=1, M(a=1)) | C=c]
    # = sum_m P(M(1)=m|C) * P(Y(1)=1|M=m,C)
    # = sum_m P(M=m|A=1,C) * P(Y=1|A=1,M=m,C)
    E_Y_a_Ma_c <- sum(P_M_given_A[2, ] * P_Y1_given_AM[2, ])

    # E[Y(a=1, M(a=0)) | C=c]
    # = sum_m P(M(0)=m|C) * P(Y(1)=1|M=m,C)
    # = sum_m P(M=m|A=0,C) * P(Y=1|A=1,M=m,C)
    E_Y_a_Ma0_c <- sum(P_M_given_A[1, ] * P_Y1_given_AM[2, ])

    # E[Y(a=0, M(a=0)) | C=c]
    # = sum_m P(M=m|A=0,C) * P(Y=1|A=0,M=m,C)
    E_Y_a0_Ma0_c <- sum(P_M_given_A[1, ] * P_Y1_given_AM[1, ])

    # Accumulate weighted averages
    E_Y_a_Ma <- E_Y_a_Ma + w * E_Y_a_Ma_c
    E_Y_a_Ma0 <- E_Y_a_Ma0 + w * E_Y_a_Ma0_c
    E_Y_a0_Ma0 <- E_Y_a0_Ma0 + w * E_Y_a0_Ma0_c
  }

  # Compute effects on different scales
  if (effect_scale == "OR") {
    odds_a_Ma <- E_Y_a_Ma / (1 - E_Y_a_Ma + 1e-10)
    odds_a_Ma0 <- E_Y_a_Ma0 / (1 - E_Y_a_Ma0 + 1e-10)
    odds_a0_Ma0 <- E_Y_a0_Ma0 / (1 - E_Y_a0_Ma0 + 1e-10)

    nie <- odds_a_Ma / (odds_a_Ma0 + 1e-10)
    nde <- odds_a_Ma0 / (odds_a0_Ma0 + 1e-10)

  } else if (effect_scale == "RR") {
    nie <- E_Y_a_Ma / (E_Y_a_Ma0 + 1e-10)
    nde <- E_Y_a_Ma0 / (E_Y_a0_Ma0 + 1e-10)

  } else if (effect_scale == "RD") {
    nie <- E_Y_a_Ma - E_Y_a_Ma0
    nde <- E_Y_a_Ma0 - E_Y_a0_Ma0

  } else {
    stop("Unknown effect_scale: ", effect_scale)
  }

  return(list(
    nie = nie,
    nde = nde,
    E_Y_a_Ma = E_Y_a_Ma,
    E_Y_a_Ma0 = E_Y_a_Ma0,
    E_Y_a0_Ma0 = E_Y_a0_Ma0
  ))
}


#' Compute Total Causal Effect (TCE)
#'
#' @description
#' Compute the total causal effect: TCE = NDE + NIE (on appropriate scale)
#'
#' @param nie Natural Indirect Effect
#' @param nde Natural Direct Effect
#' @param effect_scale Character string: "OR", "RR", or "RD"
#'
#' @return Total causal effect
#' @keywords internal
compute_tce <- function(nie, nde, effect_scale = "OR") {

  if (effect_scale %in% c("OR", "RR")) {
    # Multiplicative scale: TCE = NDE * NIE
    tce <- nde * nie
  } else if (effect_scale == "RD") {
    # Additive scale: TCE = NDE + NIE
    tce <- nde + nie
  } else {
    stop("Unknown effect_scale: ", effect_scale)
  }

  return(tce)
}


#' Compute Proportion Mediated
#'
#' @description
#' Compute the proportion of the total effect that is mediated
#'
#' @param nie Natural Indirect Effect
#' @param nde Natural Direct Effect
#' @param effect_scale Character string: "OR", "RR", or "RD"
#'
#' @return Proportion mediated (PM)
#' @keywords internal
compute_proportion_mediated <- function(nie, nde, effect_scale = "OR") {

  tce <- compute_tce(nie, nde, effect_scale)

  if (effect_scale %in% c("OR", "RR")) {
    # For multiplicative effects:
    # PM = (NDE * NIE - NDE) / (NDE * NIE - 1)
    #    = (TCE - NDE) / (TCE - 1)
    #    = NDE * (NIE - 1) / (NDE * NIE - 1)

    if (abs(tce - 1) < 1e-6) {
      pm <- NA  # Undefined when TCE = 1 (no total effect)
    } else {
      pm <- (tce - nde) / (tce - 1)
    }

  } else if (effect_scale == "RD") {
    # For additive effects:
    # PM = NIE / TCE

    if (abs(tce) < 1e-6) {
      pm <- NA  # Undefined when TCE = 0
    } else {
      pm <- nie / tce
    }

  } else {
    stop("Unknown effect_scale: ", effect_scale)
  }

  return(pm)
}


#' Convert Effects Between Scales
#'
#' @description
#' Approximate conversion between OR, RR, and RD scales.
#' Note: Exact conversion generally requires knowing baseline risks.
#'
#' @param effect Numeric effect estimate
#' @param from_scale Character string: current scale
#' @param to_scale Character string: desired scale
#' @param baseline_risk Numeric: baseline outcome probability (needed for conversions)
#'
#' @return Converted effect estimate
#' @keywords internal
convert_effect_scale <- function(effect,
                                 from_scale = "OR",
                                 to_scale = "RR",
                                 baseline_risk = NULL) {

  if (from_scale == to_scale) {
    return(effect)
  }

  # Conversion requires baseline risk for most transformations
  if (is.null(baseline_risk)) {
    warning("Baseline risk not provided. Conversion may be inaccurate.")
    baseline_risk <- 0.5  # Default assumption
  }

  # OR to RR
  if (from_scale == "OR" && to_scale == "RR") {
    # RR ~= OR / (1 - p0 + p0 * OR)
    # where p0 is baseline risk
    rr <- effect / (1 - baseline_risk + baseline_risk * effect)
    return(rr)
  }

  # RR to OR
  if (from_scale == "RR" && to_scale == "OR") {
    # OR ~= RR * (1 - p0) / (1 - RR * p0)
    or <- effect * (1 - baseline_risk) / (1 - effect * baseline_risk + 1e-10)
    return(or)
  }

  # OR to RD
  if (from_scale == "OR" && to_scale == "RD") {
    # RD = p1 - p0
    # where p1 = p0 * OR / (1 - p0 + p0 * OR)
    p1 <- baseline_risk * effect / (1 - baseline_risk + baseline_risk * effect)
    rd <- p1 - baseline_risk
    return(rd)
  }

  # RD to OR
  if (from_scale == "RD" && to_scale == "OR") {
    # p1 = p0 + RD
    # OR = [p1 / (1-p1)] / [p0 / (1-p0)]
    p1 <- baseline_risk + effect
    p1 <- max(0.001, min(0.999, p1))  # Keep in valid range
    or <- (p1 / (1 - p1)) / (baseline_risk / (1 - baseline_risk) + 1e-10)
    return(or)
  }

  # RR to RD
  if (from_scale == "RR" && to_scale == "RD") {
    # p1 = RR * p0
    # RD = p1 - p0
    p1 <- effect * baseline_risk
    rd <- p1 - baseline_risk
    return(rd)
  }

  # RD to RR
  if (from_scale == "RD" && to_scale == "RR") {
    # p1 = p0 + RD
    # RR = p1 / p0
    p1 <- baseline_risk + effect
    rr <- p1 / (baseline_risk + 1e-10)
    return(rr)
  }

  stop("Unsupported conversion: ", from_scale, " to ", to_scale)
}
