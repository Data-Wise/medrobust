test_that("power_analysis runs successfully with minimal parameters", {
  # Skip on CRAN to avoid long-running tests
  skip_on_cran()

  # Define minimal test parameters
  true_params <- list(
    beta_AM = 0.4,
    theta_AY = 0.4,
    theta_MY = 0.4
  )

  dm_params <- list(
    sn0 = 0.85,
    sp0 = 0.85,
    psi_sn = 1.5,
    psi_sp = 1.0
  )

  sensitivity_region <- list(
    sn0_range = c(0.80, 0.90),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(1.0, 2.0),
    psi_sp_range = c(1.0, 1.0)
  )

  # Run power analysis with minimal settings
  result <- power_analysis(
    true_params = true_params,
    dm_params = dm_params,
    sensitivity_region = sensitivity_region,
    misclass_type = "exposure",
    sample_sizes = c(200),  # Only 1 sample size for speed
    n_sim = 10,  # Minimal simulations for testing
    n_grid = 10,  # Small grid for speed
    parallel = FALSE,  # Disable parallel for simpler testing
    verbose = FALSE
  )

  # Test that result is the correct class (S7 objects have package prefix)
  expect_true(inherits(result, "medrobust::power_analysis_result"))

  # Test that result has required components (access properties directly)
  expect_true(!is.null(result@power_curve))
  expect_true(!is.null(result@true_effect))
  expect_true(!is.null(result@target_power))
  expect_true(!is.null(result@simulation_params))

  # Test that power_curve is a data frame
  expect_s3_class(result@power_curve, "data.frame")

  # Test that power_curve has expected columns
  expect_true("n" %in% colnames(result@power_curve))
  expect_true("power" %in% colnames(result@power_curve))
  expect_true("mean_width" %in% colnames(result@power_curve))
  expect_true("median_width" %in% colnames(result@power_curve))

  # Test that we have results for the sample size
  expect_equal(nrow(result@power_curve), 1)

  # Test that power is between 0 and 1 (handle NA values)
  power_vals <- result@power_curve$power[!is.na(result@power_curve$power)]
  if (length(power_vals) > 0) {
    expect_true(all(power_vals >= 0 & power_vals <= 1))
  }

  # Test that median_width is positive (handle NA values)
  width_vals <- result@power_curve$median_width[!is.na(result@power_curve$median_width)]
  if (length(width_vals) > 0) {
    expect_true(all(width_vals > 0))
  }
})

test_that("power_analysis validates input parameters", {
  skip_on_cran()

  # Test that invalid misclass_type is caught
  expect_error(
    power_analysis(
      true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
      dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
      sensitivity_region = list(
        sn0_range = c(0.80, 0.90),
        sp0_range = c(0.80, 0.90),
        psi_sn_range = c(1.0, 2.0),
        psi_sp_range = c(1.0, 1.0)
      ),
      misclass_type = "invalid",
      sample_sizes = c(200),
      n_sim = 10,
      n_grid = 10,
      parallel = FALSE,
      verbose = FALSE
    )
  )

  # Test that invalid effect is caught
  expect_error(
    power_analysis(
      true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
      dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
      sensitivity_region = list(
        sn0_range = c(0.80, 0.90),
        sp0_range = c(0.80, 0.90),
        psi_sn_range = c(1.0, 2.0),
        psi_sp_range = c(1.0, 1.0)
      ),
      effect = "invalid",
      sample_sizes = c(200),
      n_sim = 10,
      n_grid = 10,
      parallel = FALSE,
      verbose = FALSE
    )
  )
})

test_that("power_analysis returns correct structure for mediator misclassification", {
  skip_on_cran()

  true_params <- list(
    beta_AM = 0.3,
    theta_AY = 0.3,
    theta_MY = 0.3
  )

  dm_params <- list(
    sn0 = 0.85,
    sp0 = 0.85,
    psi_sn = 1.3,
    psi_sp = 1.0
  )

  sensitivity_region <- list(
    sn0_range = c(0.80, 0.90),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.0)
  )

  result <- power_analysis(
    true_params = true_params,
    dm_params = dm_params,
    sensitivity_region = sensitivity_region,
    misclass_type = "mediator",  # Test mediator misclassification
    sample_sizes = c(200),  # Single sample size
    n_sim = 10,
    n_grid = 10,
    parallel = FALSE,
    verbose = FALSE
  )

  # Test basic structure (S7 objects have package prefix)
  expect_true(inherits(result, "medrobust::power_analysis_result"))
  expect_equal(nrow(result@power_curve), 1)
})

test_that("power_analysis with target_width works", {
  skip_on_cran()

  true_params <- list(
    beta_AM = 0.4,
    theta_AY = 0.4,
    theta_MY = 0.4
  )

  dm_params <- list(
    sn0 = 0.85,
    sp0 = 0.85,
    psi_sn = 1.5,
    psi_sp = 1.0
  )

  sensitivity_region <- list(
    sn0_range = c(0.80, 0.90),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(1.0, 2.0),
    psi_sp_range = c(1.0, 1.0)
  )

  result <- power_analysis(
    true_params = true_params,
    dm_params = dm_params,
    sensitivity_region = sensitivity_region,
    sample_sizes = c(200),
    target_width = 0.3,  # Specify target width
    n_sim = 10,
    n_grid = 10,
    parallel = FALSE,
    verbose = FALSE
  )

  # Test that target_width is stored
  expect_equal(result@target_width, 0.3)

  # Test that recommended_n_width exists (may be NA if target not achieved)
  expect_true(!is.null(result@recommended_n_width))
})

test_that("power_analysis seed produces reproducible results", {
  skip_on_cran()

  params <- list(
    true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
    dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
    sensitivity_region = list(
      sn0_range = c(0.80, 0.90),
      sp0_range = c(0.80, 0.90),
      psi_sn_range = c(1.0, 2.0),
      psi_sp_range = c(1.0, 1.0)
    ),
    sample_sizes = c(200),
    n_sim = 10,
    n_grid = 10,
    parallel = FALSE,
    verbose = FALSE,
    seed = 42
  )

  # Run twice with same seed
  result1 <- do.call(power_analysis, params)
  result2 <- do.call(power_analysis, params)

  # Results should be identical
  expect_equal(result1@power_curve$power, result2@power_curve$power)
  expect_equal(result1@power_curve$median_width, result2@power_curve$median_width)
})
