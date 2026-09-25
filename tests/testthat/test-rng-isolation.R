# latin_hypercube_search() called set.seed(42) on the global stream. Every
# bound_ne() call therefore reset the caller's RNG, and in compute_bootstrap_ci()
# each replicate drew the identical resample, so all bootstrap replicates were
# the same number and the percentile CIs had zero width.

rng_sim <- function() {
  simulate_dm_data(
    n = 1500,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "mediator", confounders = 1, seed = 1
  )@observed
}
rng_region <- list(sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
                   psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5))

test_that("bound_ne() leaves the caller's random-number stream intact", {
  d <- rng_sim()
  set.seed(123); expected <- runif(3)
  set.seed(123)
  invisible(bound_ne(d, "A", "M_star", "Y", "C1", misclassified_variable = "mediator",
                     sensitivity_region = rng_region, n_grid = 10,
                     grid_method = "lhs", verbose = FALSE))
  expect_identical(runif(3), expected)
})

test_that("the LHS design is still reproducible across calls", {
  d <- rng_sim()
  fit <- function() bound_ne(d, "A", "M_star", "Y", "C1",
                             misclassified_variable = "mediator",
                             sensitivity_region = rng_region, n_grid = 10,
                             grid_method = "lhs", verbose = FALSE)
  set.seed(1); a <- fit()
  set.seed(999); b <- fit()
  expect_identical(a@compatible_sets, b@compatible_sets)
})

test_that("bootstrap replicates differ from one another", {
  skip_on_cran()
  d <- rng_sim()
  set.seed(7)
  fit <- suppressWarnings(bound_ne(
    d, "A", "M_star", "Y", "C1", misclassified_variable = "mediator",
    sensitivity_region = rng_region, n_grid = 10, grid_method = "lhs",
    bootstrap = TRUE, bootstrap_reps = 5, verbose = FALSE
  ))
  br <- fit@bootstrap_results
  expect_length(unique(br@boot_nie_lower), 5L)
  expect_gt(diff(br@nie_lower_ci), 0)
})
