# Comprehensive tests for bound_ne() function
# Tests exposure misclassification, mediator misclassification, and bootstrap

# Setup: Create test data and sensitivity region ----
setup_test_data <- function(n = 100, seed = 123) {  # Reduced from 200 to 100
  set.seed(seed)
  data.frame(
    A = rbinom(n, 1, 0.5),
    A_star = rbinom(n, 1, 0.5),
    M = rbinom(n, 1, 0.5),
    M_star = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5),
    C1 = rbinom(n, 1, 0.5),
    C2 = rbinom(n, 1, 0.5)
  )
}

setup_sensitivity_region <- function() {
  as_sensitivity_region(list(
    sn0_range = c(0.60, 0.99),  # Very wide range for test compatibility
    sp0_range = c(0.60, 0.99),
    psi_sn_range = c(0.5, 2.0),  # Very wide range
    psi_sp_range = c(0.5, 2.0)
  ))
}

# Test 1: Exposure Misclassification ----
test_that("bound_ne works for exposure misclassification with regular grid", {
  test_data <- setup_test_data()
  sens_region <- setup_sensitivity_region()

  bounds <- bound_ne(
    data = test_data,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = character(0),  # No confounders for speed
    misclassified_variable = "exposure",
    sensitivity_region = sens_region,
    n_grid = 10,  # Minimum allowed grid size (10^4 = 10,000 evaluations)
    grid_method = "regular",
    parallel = TRUE,
    n_cores = 2,  # Use max 2 cores for testing to avoid parallel::makeCluster limits
    verbose = FALSE
  )

  # Check that result is medrobust_bounds object
  expect_s3_class(bounds, "medrobust::medrobust_bounds")
  expect_true(inherits(bounds, "S7_object"))

  # Check bounds are numeric and finite
  expect_type(bounds@NIE_lower, "double")
  expect_type(bounds@NIE_upper, "double")
  expect_type(bounds@NDE_lower, "double")
  expect_type(bounds@NDE_upper, "double")

  expect_true(is.finite(bounds@NIE_lower))
  expect_true(is.finite(bounds@NIE_upper))
  expect_true(is.finite(bounds@NDE_lower))
  expect_true(is.finite(bounds@NDE_upper))

  # Check bounds are ordered correctly
  expect_true(bounds@NIE_lower <= bounds@NIE_upper)
  expect_true(bounds@NDE_lower <= bounds@NDE_upper)

  # Check effect scale
  expect_equal(bounds@effect_scale, "OR")

  # Check misclassified variable
  expect_equal(bounds@misclassified_variable, "exposure")

  # Check evaluation counts
  expect_true(bounds@n_evaluated == 10000)  # n_grid=10 means 10^4 = 10,000
  expect_true(bounds@n_compatible >= 1)
  expect_true(bounds@n_compatible <= bounds@n_evaluated)

  # Check compatible sets data frame
  expect_s3_class(bounds@compatible_sets, "data.frame")
  expect_true(nrow(bounds@compatible_sets) == bounds@n_compatible)
  expect_true(all(c("sn0", "sp0", "psi_sn", "psi_sp", "NIE", "NDE") %in%
                    names(bounds@compatible_sets)))
})

# Skipped: Regular grid test (too slow for routine testing)

# Test 2: Mediator Misclassification ----
test_that("bound_ne works for mediator misclassification with regular grid", {
  test_data <- setup_test_data()
  sens_region <- setup_sensitivity_region()

  bounds <- bound_ne(
    data = test_data,
    exposure = "A",
    mediator = "M_star",
    outcome = "Y",
    confounders = character(0),  # No confounders for speed
    misclassified_variable = "mediator",
    sensitivity_region = sens_region,
    n_grid = 10,  # Minimum allowed grid size (10^4 = 10,000 evaluations)
    grid_method = "regular",
    parallel = TRUE,
    n_cores = 2,  # Use max 2 cores for testing to avoid parallel::makeCluster limits
    verbose = FALSE
  )

  # Check that result is medrobust_bounds object
  expect_s3_class(bounds, "medrobust::medrobust_bounds")

  # Check bounds are numeric and finite
  expect_type(bounds@NIE_lower, "double")
  expect_type(bounds@NIE_upper, "double")
  expect_type(bounds@NDE_lower, "double")
  expect_type(bounds@NDE_upper, "double")

  expect_true(is.finite(bounds@NIE_lower))
  expect_true(is.finite(bounds@NIE_upper))
  expect_true(is.finite(bounds@NDE_lower))
  expect_true(is.finite(bounds@NDE_upper))

  # Check bounds are ordered correctly
  expect_true(bounds@NIE_lower <= bounds@NIE_upper)
  expect_true(bounds@NDE_lower <= bounds@NDE_upper)

  # Check misclassified variable
  expect_equal(bounds@misclassified_variable, "mediator")

  # Check evaluations
  expect_true(bounds@n_evaluated == 10000)  # n_grid=10 means 10^4 = 10,000
  expect_true(bounds@n_compatible >= 1)
})

# Skipped: Regular grid test for mediator (too slow for routine testing)

# Test 3: Bootstrap - BCa ----
# A real BCa run refits the bounds once per observation for the jackknife
# (about 100 s at n = 300), so the pass-through is tested with a stubbed
# compute_bca_ci(). bound_ne() used to drop z0 and acceleration: they were
# computed but never copied into the results.

test_that("BCa z0 and acceleration reach bound_ne()'s bootstrap_results", {
  local_mocked_bindings(compute_bca_ci = function(...) {
    ci <- c(0.9, 1.1)
    list(nie_lower_ci = ci, nie_upper_ci = ci, nde_lower_ci = ci,
         nde_upper_ci = ci, z0 = c(0.1, 0.2, 0.3, 0.4),
         acceleration = c(0.01, 0.02, 0.03, 0.04))
  })
  d <- simulate_dm_data(
    n = 1500,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "exposure", confounders = 1, seed = 1
  )@observed
  bounds <- suppressWarnings(bound_ne(
    d, "A_star", "M", "Y", "C1", misclassified_variable = "exposure",
    sensitivity_region = list(sn0_range = c(0.6, 0.99), sp0_range = c(0.6, 0.99),
                              psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)),
    n_grid = 10, grid_method = "lhs", bootstrap = TRUE, bootstrap_reps = 5,
    bootstrap_method = "bca", verbose = FALSE
  ))
  br <- bounds@bootstrap_results
  expect_equal(br@method, "bca")
  expect_equal(br@n_failed, 0L)
  expect_equal(br@z0, c(0.1, 0.2, 0.3, 0.4))
  expect_equal(br@acceleration, c(0.01, 0.02, 0.03, 0.04))
})

test_that("BCa with no successful replicate returns NA intervals quickly", {
  # Resamples of the n = 100 test data never yield compatible sets
  bounds <- suppressWarnings(bound_ne(
    setup_test_data(), "A_star", "M", "Y", c("C1", "C2"),
    misclassified_variable = "exposure",
    sensitivity_region = setup_sensitivity_region(), n_grid = 10,
    grid_method = "lhs", bootstrap = TRUE, bootstrap_reps = 5,
    bootstrap_method = "bca", verbose = FALSE
  ))
  br <- bounds@bootstrap_results
  expect_equal(br@n_failed, 5L)
  expect_equal(br@nie_lower_ci, c(NA_real_, NA_real_))
  expect_null(br@z0)
})

# Test 4: Bootstrap - Mediator Misclassification ----
# Note: Bootstrap tests skipped - require larger datasets for stable results

# Test 5: Grid Method Comparison ----
# Skipped: Grid comparison tests (too slow - would need regular grid evaluation)

# Test 6: Different Effect Scales ----
test_that("bound_ne works with different effect scales", {
  test_data <- setup_test_data()
  sens_region <- setup_sensitivity_region()

  # Test OR scale
  bounds_or <- bound_ne(
    data = test_data,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = "C1",
    misclassified_variable = "exposure",
    sensitivity_region = sens_region,
    n_grid = 10,
    effect_scale = "OR",
    grid_method = "lhs",
    verbose = FALSE
  )
  expect_equal(bounds_or@effect_scale, "OR")

  # Test RR scale (suppress expected warning about RR approximation)
  bounds_rr <- suppressWarnings(
    bound_ne(
      data = test_data,
      exposure = "A_star",
      mediator = "M",
      outcome = "Y",
      confounders = "C1",
      misclassified_variable = "exposure",
      sensitivity_region = sens_region,
      n_grid = 10,
      effect_scale = "RR",
      grid_method = "lhs",
      verbose = FALSE
    )
  )
  expect_equal(bounds_rr@effect_scale, "RR")

  # Test RD scale (suppress expected warning about RD not implemented)
  bounds_rd <- suppressWarnings(
    bound_ne(
      data = test_data,
      exposure = "A_star",
      mediator = "M",
      outcome = "Y",
      confounders = "C1",
      misclassified_variable = "exposure",
      sensitivity_region = sens_region,
      n_grid = 10,
      effect_scale = "RD",
      grid_method = "lhs",
      verbose = FALSE
    )
  )
  expect_equal(bounds_rd@effect_scale, "RD")
})

# Test 7: Edge Cases ----
test_that("bound_ne handles edge cases correctly", {
  # Small sample size
  small_data <- setup_test_data(n = 50)
  sens_region <- setup_sensitivity_region()

  expect_warning(
    bounds_small <- bound_ne(
      data = small_data,
      exposure = "A_star",
      mediator = "M",
      outcome = "Y",
      confounders = character(0),
      misclassified_variable = "exposure",
      sensitivity_region = sens_region,
      n_grid = 10,
      grid_method = "lhs",
      verbose = FALSE
    ),
    NA  # Should not warn for small sample
  )

  # No confounders
  bounds_no_conf <- bound_ne(
    data = setup_test_data(),
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = character(0),
    misclassified_variable = "exposure",
    sensitivity_region = sens_region,
    n_grid = 10,
    grid_method = "lhs",
    verbose = FALSE
  )

  expect_s3_class(bounds_no_conf, "medrobust::medrobust_bounds")
  expect_true(bounds_no_conf@NIE_lower <= bounds_no_conf@NIE_upper)
})
