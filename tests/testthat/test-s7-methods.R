test_that("medrobust_bounds methods work correctly", {
  skip_on_cran()

  # Create test data with larger sample
  set.seed(123)
  sim_data <- simulate_dm_data(
    n = 500,
    true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
    dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
    misclass_type = "exposure",
    confounders = 0
  )

  bounds <- bound_ne(
    data = sim_data@observed,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = NULL,
    misclassified_variable = "exposure",
    sensitivity_region = list(
      sn0_range = c(0.70, 0.95),
      sp0_range = c(0.70, 0.95),
      psi_sn_range = c(1.0, 2.5),
      psi_sp_range = c(0.8, 1.2)
    ),
    n_grid = 10,
    bootstrap = FALSE,
    verbose = FALSE
  )

  # Test print
  expect_silent(capture.output(print(bounds)))

  # Test summary
  expect_silent(capture.output(summary(bounds)))

  # Test as.data.frame
  df <- as.data.frame(bounds)
  expect_s3_class(df, "data.frame")
  expect_true("NIE_lower" %in% names(df))

  # Test as.list
  lst <- as.list(bounds)
  expect_type(lst, "list")
  expect_true("NIE_lower" %in% names(lst))
})


test_that("power_analysis_result methods work correctly", {
  skip_on_cran()

  # Create test power analysis result
  result <- power_analysis(
    true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
    dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
    sensitivity_region = list(
      sn0_range = c(0.80, 0.90),
      sp0_range = c(0.80, 0.90),
      psi_sn_range = c(1.0, 2.0),
      psi_sp_range = c(1.0, 1.0)
    ),
    misclass_type = "exposure",
    sample_sizes = c(200),
    n_sim = 5,
    n_grid = 10,
    parallel = FALSE,
    verbose = FALSE
  )

  # Test print
  expect_silent(capture.output(print(result)))

  # Test summary
  expect_silent(capture.output(summary(result)))

  # Test as.data.frame
  df <- as.data.frame(result)
  expect_s3_class(df, "data.frame")
  expect_true("n" %in% names(df))

  # Test as.list
  lst <- as.list(result)
  expect_type(lst, "list")
  expect_true("power_curve" %in% names(lst))
})

test_that("medrobust_bounds plot method works", {
  skip_on_cran()
  
  # Create test data
  set.seed(123)
  sim_data <- simulate_dm_data(
    n = 500,
    true_params = list(beta_AM = 0.4, theta_AY = 0.4, theta_MY = 0.4),
    dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
    misclass_type = "exposure",
    confounders = 0
  )
  
  bounds <- bound_ne(
    data = sim_data@observed,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = NULL,
    misclassified_variable = "exposure",
    sensitivity_region = list(
      sn0_range = c(0.70, 0.95),
      sp0_range = c(0.70, 0.95),
      psi_sn_range = c(1.0, 2.5),
      psi_sp_range = c(0.8, 1.2)
    ),
    n_grid = 10,
    bootstrap = FALSE,
    verbose = FALSE
  )
  
  # Test plot method exists and returns ggplot
  skip_if_not_installed("ggplot2")
  p <- plot(bounds)
  expect_s3_class(p, "ggplot")
  expect_true("gg" %in% class(p))
})
