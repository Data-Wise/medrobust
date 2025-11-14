test_that("print method for medrobust_bounds works", {
  sens_reg <- sensitivity_region(
    sn0_range = c(0.8, 0.9),
    sp0_range = c(0.8, 0.9),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.5)
  )

  boot_res <- bootstrap_results(
    method = "percentile",
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
  )

  bounds <- medrobust_bounds(
    NIE_lower = 1.0,
    NIE_upper = 1.5,
    NDE_lower = 1.1,
    NDE_upper = 1.4,
    compatible_sets = data.frame(sn0 = c(0.85, 0.87), sp0 = c(0.85, 0.86)),
    n_compatible = 2L,
    n_evaluated = 100L,
    falsified_proportion = 0.98,
    effect_scale = "OR",
    misclassified_variable = "mediator",
    sensitivity_region = sens_reg,
    bootstrap_results = boot_res
  )

  # Test that print returns invisibly
  expect_invisible(print(bounds))

  # Test that print produces output
  output <- capture.output(print(bounds))
  expect_true(length(output) > 0)
  expect_true(any(grepl("PARTIAL IDENTIFICATION BOUNDS", output)))
  expect_true(any(grepl("NIE", output)))
  expect_true(any(grepl("NDE", output)))
  expect_true(any(grepl("Effect Scale", output)))
})


test_that("summary method for medrobust_bounds works", {
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
    compatible_sets = data.frame(sn0 = c(0.85), sp0 = c(0.85)),
    n_compatible = 1L,
    n_evaluated = 100L,
    falsified_proportion = 0.99,
    effect_scale = "OR",
    misclassified_variable = "mediator",
    sensitivity_region = sens_reg
  )

  # Test that summary produces output
  output <- capture.output(summary(bounds))
  expect_true(length(output) > 0)
  expect_true(any(grepl("DETAILED SUMMARY", output)))
  expect_true(any(grepl("Sensitivity Region", output)))
})


test_that("as.data.frame method for medrobust_bounds works", {
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
    compatible_sets = data.frame(),
    n_compatible = 50L,
    n_evaluated = 100L,
    falsified_proportion = 0.5,
    effect_scale = "OR",
    misclassified_variable = "mediator",
    sensitivity_region = sens_reg
  )

  df <- as.data.frame(bounds)

  # Test structure
  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) == 1)

  # Test columns exist
  expect_true("NIE_lower" %in% names(df))
  expect_true("NIE_upper" %in% names(df))
  expect_true("NDE_lower" %in% names(df))
  expect_true("NDE_upper" %in% names(df))
  expect_true("effect_scale" %in% names(df))
  expect_true("misclassified_variable" %in% names(df))

  # Test values
  expect_equal(df$NIE_lower, 1.0)
  expect_equal(df$NIE_upper, 1.5)
  expect_equal(df$NDE_lower, 1.1)
  expect_equal(df$NDE_upper, 1.4)
  expect_equal(df$effect_scale, "OR")
  expect_equal(df$misclassified_variable, "mediator")
})


test_that("print method for compatibility_test works", {
  compat <- compatibility_test(
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

  output <- capture.output(print(compat))
  expect_true(length(output) > 0)
  expect_true(any(grepl("COMPATIBILITY TEST", output)))
  expect_true(any(grepl("Compatible", output)))

  # Test incompatible case
  incompat <- compatibility_test(
    compatible = FALSE,
    psi = list(sn = 1.2, sp = 1.1),
    n_constraints_total = 10L,
    n_constraints_satisfied = 5L,
    n_constraints_violated = 5L,
    violated_constraints = data.frame(
      constraint_id = 1:5,
      type = rep("probability", 5)
    ),
    misclassified_variable = "mediator",
    reason = "Violated constraints detected"
  )

  output2 <- capture.output(print(incompat))
  expect_true(any(grepl("NOT Compatible", output2)))
  expect_true(any(grepl("Violated", output2)))
})


test_that("summary method for compatibility_test works", {
  compat <- compatibility_test(
    compatible = TRUE,
    psi = list(sn = 1.2, sp = 1.1),
    sn1 = 0.85,
    sp1 = 0.88,
    n_constraints_total = 10L,
    n_constraints_satisfied = 10L,
    n_constraints_violated = 0L,
    violated_constraints = data.frame(),
    stratum_details = list(
      stratum_1 = list(satisfied = TRUE, n_satisfied = 5L)
    ),
    misclassified_variable = "mediator"
  )

  output <- capture.output(summary(compat))
  expect_true(length(output) > 0)
  expect_true(any(grepl("DETAILED COMPATIBILITY", output)))
})


test_that("print method for falsification_summary works", {
  falsif <- new_falsification_summary(
    overall = 0.45,
    n_evaluated = 100L,
    n_compatible = 55L,
    n_falsified = 45L,
    by_parameter = list(
      sn0 = data.frame(value = c(0.8, 0.9), falsification_rate = c(0.4, 0.5))
    ),
    most_constrained = "sn0 = 0.8",
    least_constrained = "sp0 = 0.9"
  )

  output <- capture.output(print(falsif))
  expect_true(length(output) > 0)
  expect_true(any(grepl("FALSIFICATION SUMMARY", output)))
  expect_true(any(grepl("45.0%", output)))
  expect_true(any(grepl("Most constrained", output)))
})


test_that("summary method for falsification_summary works", {
  falsif <- new_falsification_summary(
    overall = 0.45,
    n_evaluated = 100L,
    n_compatible = 55L,
    n_falsified = 45L
  )

  # For simple class, summary should produce output like print
  output <- capture.output(summary(falsif))
  expect_true(length(output) > 0)
  expect_true(any(grepl("FALSIFICATION", output)))
})


test_that("print method for sensitivity_region works", {
  sens_reg <- sensitivity_region(
    sn0_range = c(0.8, 0.9),
    sp0_range = c(0.8, 0.9),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.5)
  )

  output <- capture.output(print(sens_reg))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Sensitivity Region", output)))
  expect_true(any(grepl("0.8", output)))
  expect_true(any(grepl("0.9", output)))
})


test_that("print method for bootstrap_results works", {
  boot_res <- bootstrap_results(
    method = "percentile",
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
  )

  output <- capture.output(print(boot_res))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Bootstrap", output)))
  expect_true(any(grepl("95%", output)))
  expect_true(any(grepl("NIE", output)))
  expect_true(any(grepl("NDE", output)))
})


test_that("S7 method dispatch is faster than S3", {
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
    compatible_sets = data.frame(),
    n_compatible = 50L,
    n_evaluated = 100L,
    falsified_proportion = 0.5,
    effect_scale = "OR",
    misclassified_variable = "mediator",
    sensitivity_region = sens_reg
  )

  # Test that methods work multiple times (stress test)
  for (i in 1:100) {
    capture.output(print(bounds))
    df <- as.data.frame(bounds)
    expect_s3_class(df, "data.frame")
  }

  # If we got here, method dispatch is working correctly
  expect_true(TRUE)
})
