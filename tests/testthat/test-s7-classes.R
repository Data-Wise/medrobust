test_that("sensitivity_region validates ranges correctly", {
  # Valid sensitivity region
  expect_no_error(
    sensitivity_region(
      sn0_range = c(0.8, 0.9),
      sp0_range = c(0.8, 0.9),
      psi_sn_range = c(1.0, 1.5),
      psi_sp_range = c(1.0, 1.5)
    )
  )

  # Invalid: sn0_range out of bounds
  expect_error(
    sensitivity_region(
      sn0_range = c(-0.1, 0.9),
      sp0_range = c(0.8, 0.9),
      psi_sn_range = c(1.0, 1.5),
      psi_sp_range = c(1.0, 1.5)
    ),
    "sn0_range values must be in \\[0, 1\\]"
  )

  # Invalid: wrong order
  expect_error(
    sensitivity_region(
      sn0_range = c(0.9, 0.8),
      sp0_range = c(0.8, 0.9),
      psi_sn_range = c(1.0, 1.5),
      psi_sp_range = c(1.0, 1.5)
    ),
    "sn0_range\\[1\\] must be < sn0_range\\[2\\]"
  )

  # Invalid: psi_sn_range must be positive
  expect_error(
    sensitivity_region(
      sn0_range = c(0.8, 0.9),
      sp0_range = c(0.8, 0.9),
      psi_sn_range = c(0.0, 1.5),
      psi_sp_range = c(1.0, 1.5)
    ),
    "psi_sn_range values must be positive"
  )

  # Warning: non-informative region (Sn + Sp <= 1)
  expect_warning(
    sensitivity_region(
      sn0_range = c(0.3, 0.5),
      sp0_range = c(0.3, 0.5),
      psi_sn_range = c(1.0, 1.5),
      psi_sp_range = c(1.0, 1.5)
    ),
    "may be non-informative"
  )
})


test_that("bootstrap_results validates correctly", {
  # Valid bootstrap results
  expect_no_error(
    bootstrap_results(
      method = "percentile",
      n_reps = 1000L,
      n_failed = 10L,
      confidence_level = 0.95,
      nie_lower_ci = c(0.9, 1.1),
      nie_upper_ci = c(1.4, 1.6),
      nde_lower_ci = c(1.0, 1.2),
      nde_upper_ci = c(1.3, 1.5),
      boot_nie_lower = rep(1.0, 1000),
      boot_nie_upper = rep(1.5, 1000),
      boot_nde_lower = rep(1.1, 1000),
      boot_nde_upper = rep(1.4, 1000)
    )
  )

  # Invalid: method not in allowed values
  expect_error(
    bootstrap_results(
      method = "invalid_method",
      n_reps = 1000L,
      confidence_level = 0.95,
      nie_lower_ci = c(0.9, 1.1),
      nie_upper_ci = c(1.4, 1.6),
      nde_lower_ci = c(1.0, 1.2),
      nde_upper_ci = c(1.3, 1.5),
      boot_nie_lower = rep(1.0, 1000),
      boot_nie_upper = rep(1.5, 1000),
      boot_nde_lower = rep(1.1, 1000),
      boot_nde_upper = rep(1.4, 1000)
    ),
    "method must be 'percentile' or 'bca'"
  )

  # Invalid: confidence level out of range
  expect_error(
    bootstrap_results(
      method = "percentile",
      n_reps = 1000L,
      confidence_level = 1.5,
      nie_lower_ci = c(0.9, 1.1),
      nie_upper_ci = c(1.4, 1.6),
      nde_lower_ci = c(1.0, 1.2),
      nde_upper_ci = c(1.3, 1.5),
      boot_nie_lower = rep(1.0, 1000),
      boot_nie_upper = rep(1.5, 1000),
      boot_nde_lower = rep(1.1, 1000),
      boot_nde_upper = rep(1.4, 1000)
    ),
    "confidence_level must be in \\(0, 1\\)"
  )

  # Invalid: n_failed > n_reps
  expect_error(
    bootstrap_results(
      method = "percentile",
      n_reps = 1000L,
      n_failed = 1500L,
      confidence_level = 0.95,
      nie_lower_ci = c(0.9, 1.1),
      nie_upper_ci = c(1.4, 1.6),
      nde_lower_ci = c(1.0, 1.2),
      nde_upper_ci = c(1.3, 1.5),
      boot_nie_lower = rep(1.0, 1000),
      boot_nie_upper = rep(1.5, 1000),
      boot_nde_lower = rep(1.1, 1000),
      boot_nde_upper = rep(1.4, 1000)
    ),
    "n_failed cannot exceed"
  )
})


test_that("medrobust_bounds validates bound ordering", {
  sens_reg <- sensitivity_region(
    sn0_range = c(0.8, 0.9),
    sp0_range = c(0.8, 0.9),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.5)
  )

  # Valid bounds
  expect_no_error(
    medrobust_bounds(
      NIE_lower = 1.0,
      NIE_upper = 1.5,
      NDE_lower = 1.1,
      NDE_upper = 1.4,
      compatible_sets = data.frame(),
      n_compatible = 50L,
      n_evaluated = 100L,
      falsified_proportion = 0.5,
      effect_scale = "OR",
      misclassified_variable = "mediator",
      sensitivity_region = sens_reg
    )
  )

  # Invalid: NIE_lower > NIE_upper
  expect_error(
    medrobust_bounds(
      NIE_lower = 2.0,
      NIE_upper = 1.5,
      NDE_lower = 1.1,
      NDE_upper = 1.4,
      compatible_sets = data.frame(),
      n_compatible = 50L,
      n_evaluated = 100L,
      falsified_proportion = 0.5,
      effect_scale = "OR",
      misclassified_variable = "mediator",
      sensitivity_region = sens_reg
    ),
    "NIE_lower must be <= @NIE_upper"
  )

  # Invalid: NDE_lower > NDE_upper
  expect_error(
    medrobust_bounds(
      NIE_lower = 1.0,
      NIE_upper = 1.5,
      NDE_lower = 1.8,
      NDE_upper = 1.4,
      compatible_sets = data.frame(),
      n_compatible = 50L,
      n_evaluated = 100L,
      falsified_proportion = 0.5,
      effect_scale = "OR",
      misclassified_variable = "mediator",
      sensitivity_region = sens_reg
    ),
    "NDE_lower must be <= @NDE_upper"
  )

  # Invalid: n_compatible > n_evaluated
  expect_error(
    medrobust_bounds(
      NIE_lower = 1.0,
      NIE_upper = 1.5,
      NDE_lower = 1.1,
      NDE_upper = 1.4,
      compatible_sets = data.frame(),
      n_compatible = 150L,
      n_evaluated = 100L,
      falsified_proportion = 0.5,
      effect_scale = "OR",
      misclassified_variable = "mediator",
      sensitivity_region = sens_reg
    ),
    "n_compatible cannot exceed @n_evaluated"
  )

  # Invalid: effect_scale not in allowed values
  expect_error(
    medrobust_bounds(
      NIE_lower = 1.0,
      NIE_upper = 1.5,
      NDE_lower = 1.1,
      NDE_upper = 1.4,
      compatible_sets = data.frame(),
      n_compatible = 50L,
      n_evaluated = 100L,
      falsified_proportion = 0.5,
      effect_scale = "INVALID",
      misclassified_variable = "mediator",
      sensitivity_region = sens_reg
    ),
    "effect_scale must be 'OR', 'RR', or 'RD'"
  )

  # Invalid: misclassified_variable not in allowed values
  expect_error(
    medrobust_bounds(
      NIE_lower = 1.0,
      NIE_upper = 1.5,
      NDE_lower = 1.1,
      NDE_upper = 1.4,
      compatible_sets = data.frame(),
      n_compatible = 50L,
      n_evaluated = 100L,
      falsified_proportion = 0.5,
      effect_scale = "OR",
      misclassified_variable = "outcome",
      sensitivity_region = sens_reg
    ),
    "misclassified_variable must be 'exposure' or 'mediator'"
  )

  # Invalid: falsified_proportion out of range
  expect_error(
    medrobust_bounds(
      NIE_lower = 1.0,
      NIE_upper = 1.5,
      NDE_lower = 1.1,
      NDE_upper = 1.4,
      compatible_sets = data.frame(),
      n_compatible = 50L,
      n_evaluated = 100L,
      falsified_proportion = 1.5,
      effect_scale = "OR",
      misclassified_variable = "mediator",
      sensitivity_region = sens_reg
    ),
    "falsified_proportion must be in \\[0, 1\\]"
  )
})


test_that("compatibility_test validates correctly", {
  # Valid compatibility test
  expect_no_error(
    compatibility_test(
      compatible = TRUE,
      psi = list(sn = 1.2, sp = 1.1),
      sn1 = 0.85,
      sp1 = 0.88,
      n_constraints_total = 10L,
      n_constraints_satisfied = 10L,
      n_constraints_violated = 0L,
      violated_constraints = data.frame(),
      misclassified_variable = "mediator"
    )
  )

  # Invalid: constraint counts don't add up
  expect_error(
    compatibility_test(
      compatible = FALSE,
      psi = list(sn = 1.2, sp = 1.1),
      n_constraints_total = 10L,
      n_constraints_satisfied = 6L,
      n_constraints_violated = 5L,
      violated_constraints = data.frame(),
      misclassified_variable = "mediator"
    ),
    "Constraint counts don't add up"
  )

  # Invalid: sn1 out of range
  expect_error(
    compatibility_test(
      compatible = FALSE,
      psi = list(sn = 1.2, sp = 1.1),
      sn1 = 1.5,
      n_constraints_total = 10L,
      n_constraints_satisfied = 5L,
      n_constraints_violated = 5L,
      violated_constraints = data.frame(),
      misclassified_variable = "mediator"
    ),
    "sn1 must be in \\[0, 1\\]"
  )

  # Invalid: sp1 out of range
  expect_error(
    compatibility_test(
      compatible = FALSE,
      psi = list(sn = 1.2, sp = 1.1),
      sp1 = -0.1,
      n_constraints_total = 10L,
      n_constraints_satisfied = 5L,
      n_constraints_violated = 5L,
      violated_constraints = data.frame(),
      misclassified_variable = "mediator"
    ),
    "sp1 must be in \\[0, 1\\]"
  )
})


test_that("falsification_summary validates correctly", {
  # Valid falsification summary
  expect_no_error(
    new_falsification_summary(
      overall = 0.45,
      n_evaluated = 100L,
      n_compatible = 55L,
      n_falsified = 45L
    )
  )

  # Invalid: counts don't add up
  expect_error(
    new_falsification_summary(
      overall = 0.45,
      n_evaluated = 100L,
      n_compatible = 50L,
      n_falsified = 45L
    ),
    "n_compatible \\+ n_falsified must equal n_evaluated"
  )

  # Invalid: overall rate out of range
  expect_error(
    new_falsification_summary(
      overall = 1.5,
      n_evaluated = 100L,
      n_compatible = 55L,
      n_falsified = 45L
    ),
    "overall falsification rate must be in \\[0, 1\\]"
  )

  # Invalid: negative counts
  expect_error(
    new_falsification_summary(
      overall = 0.5,
      n_evaluated = 100L,
      n_compatible = -10L,
      n_falsified = 110L
    ),
    "Counts must be non-negative"
  )
})


test_that("S7 property access works correctly", {
  sens_reg <- sensitivity_region(
    sn0_range = c(0.8, 0.9),
    sp0_range = c(0.8, 0.9),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.5)
  )

  bounds <- medrobust_bounds(
    NIE_lower = 1.0,
    NIE_upper = 1.5,
    NDE_lower = 1.1,
    NDE_upper = 1.4,
    compatible_sets = data.frame(sn0 = 0.85, sp0 = 0.85),
    n_compatible = 50L,
    n_evaluated = 100L,
    falsified_proportion = 0.5,
    effect_scale = "OR",
    misclassified_variable = "mediator",
    sensitivity_region = sens_reg
  )

  # Test @ operator for property access
  expect_equal(bounds@NIE_lower, 1.0)
  expect_equal(bounds@NIE_upper, 1.5)
  expect_equal(bounds@NDE_lower, 1.1)
  expect_equal(bounds@NDE_upper, 1.4)
  expect_equal(bounds@effect_scale, "OR")
  expect_equal(bounds@misclassified_variable, "mediator")
  expect_equal(bounds@n_compatible, 50L)
  expect_equal(bounds@n_evaluated, 100L)
  expect_equal(bounds@falsified_proportion, 0.5)

  # Test nested S7 object access
  expect_equal(bounds@sensitivity_region@sn0_range, c(0.8, 0.9))
  expect_equal(bounds@sensitivity_region@sp0_range, c(0.8, 0.9))
})


test_that("as_sensitivity_region converter works", {
  # Create from list (S3 style)
  region_list <- list(
    sn0_range = c(0.7, 0.9),
    sp0_range = c(0.75, 0.95),
    psi_sn_range = c(1.0, 2.0),
    psi_sp_range = c(1.0, 1.8)
  )

  sens_reg <- as_sensitivity_region(region_list)

  # Verify it's an S7 object with correct class
  expect_true(inherits(sens_reg, "sensitivity_region"))

  # Verify properties
  expect_equal(sens_reg@sn0_range, c(0.7, 0.9))
  expect_equal(sens_reg@sp0_range, c(0.75, 0.95))
  expect_equal(sens_reg@psi_sn_range, c(1.0, 2.0))
  expect_equal(sens_reg@psi_sp_range, c(1.0, 1.8))

  # Test round-trip conversion
  back_to_list <- as.list(sens_reg)
  expect_equal(back_to_list$sn0_range, region_list$sn0_range)
  expect_equal(back_to_list$sp0_range, region_list$sp0_range)
  expect_equal(back_to_list$psi_sn_range, region_list$psi_sn_range)
  expect_equal(back_to_list$psi_sp_range, region_list$psi_sp_range)
})


test_that("simulated_dm_data validates correctly", {
  # Valid simulation data
  obs_data <- data.frame(
    A_star = rbinom(100, 1, 0.5),
    M = rbinom(100, 1, 0.5),
    Y = rbinom(100, 1, 0.5),
    C1 = rbinom(100, 1, 0.5)
  )

  truth_data <- data.frame(
    A = rbinom(100, 1, 0.5),
    M = rbinom(100, 1, 0.5),
    Y = rbinom(100, 1, 0.5),
    C1 = rbinom(100, 1, 0.5)
  )

  gen_params <- list(
    n = 100,
    true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
    dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
    misclass_type = "exposure",
    confounders = 1,
    confounder_params = list(type = "binary"),
    effect_modification = FALSE,
    seed = 123
  )

  expect_no_error(
    simulated_dm_data(
      observed = obs_data,
      truth = truth_data,
      generation_params = gen_params
    )
  )

  # Invalid: too few rows
  expect_error(
    simulated_dm_data(
      observed = obs_data[1:5, ],
      truth = NULL,
      generation_params = gen_params
    ),
    "observed data must have at least 10 rows"
  )

  # Invalid: mismatched dimensions
  expect_error(
    simulated_dm_data(
      observed = obs_data,
      truth = truth_data[1:50, ],
      generation_params = gen_params
    ),
    "truth and observed must have same number of rows"
  )

  # Invalid: n mismatch
  gen_params_wrong <- gen_params
  gen_params_wrong$n <- 200
  expect_error(
    simulated_dm_data(
      observed = obs_data,
      truth = NULL,
      generation_params = gen_params_wrong
    ),
    "generation_params\\$n must match nrow\\(observed\\)"
  )

  # Invalid: missing required generation_params
  expect_error(
    simulated_dm_data(
      observed = obs_data,
      truth = NULL,
      generation_params = list(n = 100)
    ),
    "generation_params must contain"
  )
})


test_that("power_analysis_result validates correctly", {
  # Valid power analysis result
  power_df <- data.frame(
    n = c(100, 200, 300),
    power = c(0.5, 0.7, 0.85),
    coverage = c(0.95, 0.94, 0.96),
    mean_width = c(0.8, 0.6, 0.5),
    median_width = c(0.75, 0.55, 0.48),
    sd_width = c(0.1, 0.08, 0.07),
    mean_lower = c(1.0, 1.0, 1.0),
    mean_upper = c(1.8, 1.6, 1.5)
  )

  sim_params <- list(
    true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
    dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
    sensitivity_region = list(
      sn0_range = c(0.8, 0.9),
      sp0_range = c(0.8, 0.9),
      psi_sn_range = c(1.0, 2.0),
      psi_sp_range = c(1.0, 1.0)
    ),
    effect = "NIE",
    misclass_type = "exposure",
    n_sim = 100,
    seed = 123
  )

  expect_no_error(
    power_analysis_result(
      power_curve = power_df,
      true_effect = 1.5,
      target_power = 0.80,
      target_width = 0.3,
      recommended_n_power = 300L,
      recommended_n_width = 300L,
      simulation_params = sim_params
    )
  )

  # Invalid: power values out of range
  power_df_invalid <- power_df
  power_df_invalid$power[1] <- 1.5
  expect_error(
    power_analysis_result(
      power_curve = power_df_invalid,
      true_effect = 1.5,
      target_power = 0.80,
      simulation_params = sim_params
    ),
    "power values must be in \\[0, 1\\]"
  )

  # Invalid: coverage out of range
  power_df_invalid2 <- power_df
  power_df_invalid2$coverage[1] <- -0.1
  expect_error(
    power_analysis_result(
      power_curve = power_df_invalid2,
      true_effect = 1.5,
      target_power = 0.80,
      simulation_params = sim_params
    ),
    "coverage values must be in \\[0, 1\\]"
  )

  # Invalid: negative width
  power_df_invalid3 <- power_df
  power_df_invalid3$mean_width[1] <- -0.5
  expect_error(
    power_analysis_result(
      power_curve = power_df_invalid3,
      true_effect = 1.5,
      target_power = 0.80,
      simulation_params = sim_params
    ),
    "mean_width values must be non-negative"
  )

  # Invalid: target_power out of range
  expect_error(
    power_analysis_result(
      power_curve = power_df,
      true_effect = 1.5,
      target_power = 1.5,
      simulation_params = sim_params
    ),
    "target_power must be in \\(0, 1\\)"
  )

  # Invalid: missing required columns
  power_df_incomplete <- power_df[, 1:3]
  expect_error(
    power_analysis_result(
      power_curve = power_df_incomplete,
      true_effect = 1.5,
      target_power = 0.80,
      simulation_params = sim_params
    ),
    "power_curve must have columns"
  )

  # Invalid: missing required simulation_params
  expect_error(
    power_analysis_result(
      power_curve = power_df,
      true_effect = 1.5,
      target_power = 0.80,
      simulation_params = list(effect = "NIE")
    ),
    "simulation_params must contain"
  )
})
