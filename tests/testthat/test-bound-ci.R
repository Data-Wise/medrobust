# Tests for the fast confidence-interval machinery (R/bound_ci.R):
# single-Psi primitives reproduce bound_ne; Imbens-Manski helper hits its limits;
# bound_ci returns well-formed, CI-widened envelopes for both paths.

test_that("Imbens-Manski helper hits the known limits", {
  # Delta = 0 -> two-sided z; Delta >> se -> one-sided z
  ci0 <- .imbens_manski_ci(1.2, 1.2, 0.05, 0.05, level = 0.95)
  expect_equal(unname(ci0["lower"]), 1.2 - qnorm(0.975) * 0.05, tolerance = 1e-3)
  ci1 <- .imbens_manski_ci(1.0, 2.0, 0.05, 0.05, level = 0.95)
  expect_equal(unname(ci1["lower"]), 1.0 - qnorm(0.95) * 0.05, tolerance = 1e-3)
  # CI always contains the point bounds
  expect_lte(ci1["lower"], 1.0); expect_gte(ci1["upper"], 2.0)
})

test_that("single-Psi primitives reproduce bound_ne (both paths)", {
  skip_on_cran()
  tp <- list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5))
  dm <- list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1)
  reg <- as_sensitivity_region(list(sn0_range = c(0.899, 0.901),
    sp0_range = c(0.899, 0.901), psi_sn_range = c(1, 1), psi_sp_range = c(1, 1)))

  # exposure
  se <- simulate_dm_data(n = 5000, true_params = tp, dm_params = dm,
    misclass_type = "exposure", confounders = 1, seed = 5)
  pe <- .effect_at_psi_exposure(se@observed, "A_star", "M", "Y", "C1", 0.9, 0.9, 1, 1, "OR")
  be <- bound_ne(se@observed, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = "C1", misclassified_variable = "exposure", sensitivity_region = reg,
    n_grid = 10, effect_scale = "OR", verbose = FALSE)
  expect_equal(pe$nde, (be@NDE_lower + be@NDE_upper) / 2, tolerance = 2e-3)
  expect_equal(pe$nie, (be@NIE_lower + be@NIE_upper) / 2, tolerance = 2e-3)

  # mediator
  sm <- simulate_dm_data(n = 5000, true_params = tp, dm_params = dm,
    misclass_type = "mediator", confounders = 1, seed = 5)
  pm <- .effect_at_psi_mediator(sm@observed, "A", "M_star", "Y", "C1", 0.9, 0.9, 1, 1, "OR")
  bm <- bound_ne(sm@observed, exposure = "A", mediator = "M_star", outcome = "Y",
    confounders = "C1", misclassified_variable = "mediator", sensitivity_region = reg,
    n_grid = 10, effect_scale = "OR", verbose = FALSE)
  expect_equal(pm$nde, (bm@NDE_lower + bm@NDE_upper) / 2, tolerance = 2e-3)
  expect_equal(pm$nie, (bm@NIE_lower + bm@NIE_upper) / 2, tolerance = 2e-3)
})

test_that("bound_ci returns well-formed CI-widened envelopes", {
  skip_on_cran()
  sim <- simulate_dm_data(n = 4000,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "exposure", confounders = 1, seed = 7)
  region <- as_sensitivity_region(list(sn0_range = c(0.85, 0.95),
    sp0_range = c(0.85, 0.95), psi_sn_range = c(1, 1), psi_sp_range = c(1, 1)))
  b <- bound_ne(sim@observed, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = "C1", misclassified_variable = "exposure", sensitivity_region = region,
    n_grid = 10, effect_scale = "OR", verbose = FALSE)
  ci <- bound_ci(b, sim@observed, "A_star", "M", "Y", "C1", "exposure",
                 n_boot = 60L, seed = 1)
  for (eff in c("NIE", "NDE")) {
    v <- ci[[eff]]
    expect_true(all(is.finite(v)))
    expect_lte(v["ci_lower"], v["lower"])   # CI widens below the lower bound
    expect_gte(v["ci_upper"], v["upper"])   # and above the upper bound
    expect_gt(v["se_lower"], 0); expect_gt(v["se_upper"], 0)
  }
})

test_that("bound_ne(ci_method='analytic') attaches @analytic_ci", {
  skip_on_cran()
  sim <- simulate_dm_data(n = 3000,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "exposure", confounders = 1, seed = 7)
  region <- as_sensitivity_region(list(sn0_range = c(0.85, 0.95),
    sp0_range = c(0.85, 0.95), psi_sn_range = c(1, 1), psi_sp_range = c(1, 1)))
  b <- bound_ne(sim@observed, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = "C1", misclassified_variable = "exposure", sensitivity_region = region,
    n_grid = 10, effect_scale = "OR", ci_method = "analytic", ci_n_boot = 50L, verbose = FALSE)
  expect_true(length(b@analytic_ci) > 0)
  expect_true(all(c("NIE", "NDE") %in% names(b@analytic_ci)))
  expect_lte(b@analytic_ci$NDE["ci_lower"], b@NDE_lower)
  expect_gte(b@analytic_ci$NDE["ci_upper"], b@NDE_upper)
  # default: no analytic CI computed
  b0 <- bound_ne(sim@observed, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = "C1", misclassified_variable = "exposure", sensitivity_region = region,
    n_grid = 10, effect_scale = "OR", verbose = FALSE)
  expect_equal(length(b0@analytic_ci), 0)
})
