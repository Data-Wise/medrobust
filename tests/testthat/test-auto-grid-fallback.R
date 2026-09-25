# auto_grid_search() returns NULL when all 16 corners of the region are
# compatible, meaning "use the regular grid". The exposure path falls back to the
# regular grid; the mediator path filtered the NULL to an empty list and reported
# the region as infeasible (NA bounds).

test_that("mediator path falls back to the regular grid when auto returns NULL", {
  d <- simulate_dm_data(
    n = 1500,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "mediator", confounders = 1, seed = 1
  )@observed
  region <- list(sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
                 psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5))
  prepared <- prepare_data(d, "A", "M_star", "Y", "C1", NULL)
  fit <- function(method) {
    bound_ne_mediator(prepared, "A", "M_star", "Y", "C1",
                      sensitivity_region = region, n_grid = 3, effect_scale = "OR",
                      parallel = FALSE, n_cores = NULL, cache = FALSE,
                      cache_dir = NULL, verbose = FALSE, grid_method = method)
  }
  auto <- fit("auto")
  regular <- fit("regular")
  expect_false(is.na(auto$NIE_lower))
  expect_equal(auto$NIE_lower, regular$NIE_lower)
  expect_equal(auto$NDE_upper, regular$NDE_upper)
  expect_equal(auto$n_evaluated, regular$n_evaluated)
})
