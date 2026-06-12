# End-to-end test for the EXPOSURE (A*) path: the bound must contain the true
# NDE *and* NIE when the sensitivity region contains the true Psi.
#
# Regression guard for the 2026-06-11 exposure-NIE bug: the recovered conditional
# P(A|m,y,c) was treated as a joint, dropping the P(M,Y|c) weight and collapsing
# NIE toward the null (bound [0.980, 0.991] vs truth 1.199). NDE was unaffected.

test_that("exposure bound contains true NDE and NIE (OR), psi=1", {
  skip_on_cran()
  sim <- simulate_dm_data(
    n = 8e4,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params   = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "exposure", confounders = 1, seed = 21
  )
  te <- sim@true_effects
  region <- as_sensitivity_region(list(
    sn0_range = c(0.85, 0.95), sp0_range = c(0.85, 0.95),
    psi_sn_range = c(1, 1), psi_sp_range = c(1, 1)
  ))
  b <- bound_ne(
    data = sim@observed, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = "C1", misclassified_variable = "exposure",
    sensitivity_region = region, n_grid = 12, grid_method = "regular",
    effect_scale = "OR", parallel = TRUE, n_cores = 2, verbose = FALSE
  )
  slack <- 0.03
  expect_lte(b@NDE_lower, te$NDE_OR + slack)
  expect_gte(b@NDE_upper, te$NDE_OR - slack)
  # The decisive NIE check (pre-fix the whole bound sat below the truth):
  expect_lte(b@NIE_lower, te$NIE_OR + slack)
  expect_gte(b@NIE_upper, te$NIE_OR - slack)
  # NIE bound must not be a null-collapsed interval entirely below the truth.
  expect_gt(b@NIE_upper, 1.10)
})

test_that("exposure bound contains true NIE under differential error (psi=1.5)", {
  skip_on_cran()
  sim <- simulate_dm_data(
    n = 8e4,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params   = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1.5, psi_sp = 1),
    misclass_type = "exposure", confounders = 1, seed = 22
  )
  te <- sim@true_effects
  region <- as_sensitivity_region(list(
    sn0_range = c(0.85, 0.95), sp0_range = c(0.85, 0.95),
    psi_sn_range = c(1, 1.5), psi_sp_range = c(1, 1)
  ))
  b <- bound_ne(
    data = sim@observed, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = "C1", misclassified_variable = "exposure",
    sensitivity_region = region, n_grid = 12, grid_method = "regular",
    effect_scale = "OR", parallel = TRUE, n_cores = 2, verbose = FALSE
  )
  slack <- 0.04
  expect_lte(b@NIE_lower, te$NIE_OR + slack)
  expect_gte(b@NIE_upper, te$NIE_OR - slack)
})
