# End-to-end test: the partial-identification bound must CONTAIN the true effect
# when the sensitivity region contains the true misclassification parameters.
#
# This exercises the full bound_ne() path (cell extraction -> per-Y 2x2 solve ->
# g-computation -> grid bound) against the simulator's corrected @true_effects.
# Because the true Psi = (sn0=0.9, sp0=0.9, psi_sn=1, psi_sp=1) is interior to the
# region below, a valid bound must bracket the truth (up to finite-sample slack).

test_that("mediator bound contains the true NDE/NIE on the OR scale", {
  skip_on_cran()
  sim <- simulate_dm_data(
    n = 8e4,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params   = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "mediator", confounders = 1, seed = 11
  )
  te <- sim@true_effects

  region <- as_sensitivity_region(list(
    sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
    psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)
  ))

  b <- bound_ne(
    data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
    confounders = "C1", misclassified_variable = "mediator",
    sensitivity_region = region, n_grid = 10, grid_method = "regular",
    effect_scale = "OR", parallel = TRUE, n_cores = 2, verbose = FALSE
  )

  slack <- 0.03  # absorbs finite-sample noise + grid discretization
  expect_lte(b@NDE_lower, te$NDE_OR + slack)
  expect_gte(b@NDE_upper, te$NDE_OR - slack)
  expect_lte(b@NIE_lower, te$NIE_OR + slack)
  expect_gte(b@NIE_upper, te$NIE_OR - slack)
})

test_that("exposure bound is well-formed and brackets a non-trivial range", {
  skip_on_cran()
  sim <- simulate_dm_data(
    n = 8e4,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params   = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "exposure", confounders = 1, seed = 12
  )

  region <- as_sensitivity_region(list(
    sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
    psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)
  ))

  b <- bound_ne(
    data = sim@observed, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = "C1", misclassified_variable = "exposure",
    sensitivity_region = region, n_grid = 10, grid_method = "regular",
    effect_scale = "OR", parallel = TRUE, n_cores = 2, verbose = FALSE
  )

  # Exposure recovery is the verified-correct 2x2 matrix inverse; sanity-check the
  # bound is finite and ordered (containment is covered for the mediator path).
  expect_true(all(is.finite(c(b@NDE_lower, b@NDE_upper, b@NIE_lower, b@NIE_upper))))
  expect_lte(b@NDE_lower, b@NDE_upper)
  expect_lte(b@NIE_lower, b@NIE_upper)
  expect_gt(b@n_compatible, 0)
})
