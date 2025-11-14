#' Utility Functions for medrobust Package
#'
#' @description
#' Internal helper functions used throughout the package.
#'
#' @keywords internal
#' @noRd

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

  required_elements <- c("sn0_range", "sp0_range", "psi_sn_range", "psi_sp_range")
  missing_elements <- setdiff(required_elements, names(sens_region))

  if (length(missing_elements) > 0) {
    stop("sensitivity_region must contain: ",
         paste(required_elements, collapse = ", "))
  }

  # Validate each range
  for (elem in required_elements) {
    range_vals <- sens_region[[elem]]

    if (!is.numeric(range_vals) || length(range_vals) != 2) {
      stop("'", elem, "' must be a numeric vector of length 2")
    }

    if (range_vals[1] >= range_vals[2]) {
      stop("'", elem, "' must have min < max")
    }

    # Check bounds for probabilities
    if (elem %in% c("sn0_range", "sp0_range")) {
      if (any(range_vals < 0 | range_vals > 1)) {
        stop("'", elem, "' must be in [0, 1]")
      }
      if (any(range_vals < 0.5)) {
        warning("'", elem, "' includes values < 0.5 (worse than random guessing)")
      }
    }

    # Check bounds for psi parameters
    if (elem %in% c("psi_sn_range", "psi_sp_range")) {
      if (any(range_vals <= 0)) {
        stop("'", elem, "' must be positive (odds ratio)")
      }
      if (range_vals[2] > 10) {
        warning("'", elem, "' includes very large odds ratios (>10)")
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

  sn0_seq <- seq(sens_region$sn0_range[1], sens_region$sn0_range[2],
                 length.out = n_grid)
  sp0_seq <- seq(sens_region$sp0_range[1], sens_region$sp0_range[2],
                 length.out = n_grid)
  psi_sn_seq <- seq(sens_region$psi_sn_range[1], sens_region$psi_sn_range[2],
                    length.out = n_grid)
  psi_sp_seq <- seq(sens_region$psi_sp_range[1], sens_region$psi_sp_range[2],
                    length.out = n_grid)

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
    warning("Found ", sparse_cells, " sparse cells (n<5) in E×M×Y table. ",
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
