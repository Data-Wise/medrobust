test_that("bound_ne validates sensitivity_region conversion", {
  # Create simple test data
  test_data <- data.frame(
    A = rbinom(100, 1, 0.5),
    M = rbinom(100, 1, 0.5),
    Y = rbinom(100, 1, 0.5),
    C = rbinom(100, 1, 0.5)
  )

  # Test that sensitivity_region can be passed as a list
  sens_region_list <- list(
    sn0_range = c(0.8, 0.9),
    sp0_range = c(0.8, 0.9),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.0)
  )

  # Test that sensitivity_region can be passed as S7 object
  sens_region_s7 <- sensitivity_region(
    sn0_range = c(0.8, 0.9),
    sp0_range = c(0.8, 0.9),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.0)
  )

  # Both should be accepted (we test by checking validate doesn't error)
  expect_error(
    validate_sensitivity_region(sens_region_list),
    NA
  )

  expect_error(
    validate_sensitivity_region(sens_region_s7),
    NA
  )
})


test_that("bound_ne rejects invalid inputs", {
  test_data <- data.frame(
    A = rbinom(100, 1, 0.5),
    M = rbinom(100, 1, 0.5),
    Y = rbinom(100, 1, 0.5)
  )

  sens_region <- list(
    sn0_range = c(0.8, 0.9),
    sp0_range = c(0.8, 0.9),
    psi_sn_range = c(1.0, 1.5),
    psi_sp_range = c(1.0, 1.0)
  )

  # Test missing variable (should fail during input validation)
  expect_error(
    bound_ne(
      data = test_data,
      exposure = "MISSING",
      mediator = "M",
      outcome = "Y",
      confounders = character(0),
      misclassified_variable = "exposure",
      sensitivity_region = sens_region,
      n_grid = 10
    ),
    "not found in data"
  )

  # Test invalid n_grid
  expect_error(
    bound_ne(
      data = test_data,
      exposure = "A",
      mediator = "M",
      outcome = "Y",
      confounders = character(0),
      misclassified_variable = "exposure",
      sensitivity_region = sens_region,
      n_grid = 5  # Too small
    ),
    "n_grid.*must be.*between 10 and 200"
  )

  # Test invalid misclassified_variable
  expect_error(
    bound_ne(
      data = test_data,
      exposure = "A",
      mediator = "M",
      outcome = "Y",
      confounders = character(0),
      misclassified_variable = "invalid",
      sensitivity_region = sens_region,
      n_grid = 10
    ),
    "should be one of"
  )
})
