# extract_falsified_region() rebuilt a regular grid of ~n_evaluated^(1/4) points
# per dimension and anti-joined the compatible sets against it. Under the
# default LHS search the sampled points never lie on that grid, so every grid
# point came back as "falsified" (81 of 81 when all 100 samples were
# compatible). bound_ne() now records every evaluated set with its verdict.

efr_region <- list(sn0_range = c(0.6, 0.99), sp0_range = c(0.6, 0.99),
                   psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5))
efr_data <- function(type) {
  simulate_dm_data(
    n = 1500,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = type, confounders = 1, seed = 1
  )@observed
}
params <- c("sn0", "sp0", "psi_sn", "psi_sp")

expect_falsified_consistent <- function(fit) {
  fals <- extract_falsified_region(fit)
  expect_named(fals, params)
  expect_equal(nrow(fals), fit@n_evaluated - fit@n_compatible)
  overlap <- merge(fals, fit@compatible_sets[, params], by = params)
  expect_equal(nrow(overlap), 0L)
}

test_that("mediator path: falsified sets are the evaluated sets that failed (LHS)", {
  fit <- bound_ne(efr_data("mediator"), "A", "M_star", "Y", "C1",
                  misclassified_variable = "mediator", sensitivity_region = efr_region,
                  n_grid = 10, grid_method = "lhs", verbose = FALSE)
  expect_gt(fit@n_evaluated, fit@n_compatible)
  expect_falsified_consistent(fit)
})

test_that("exposure path: falsified sets are the evaluated sets that failed (LHS)", {
  fit <- suppressWarnings(bound_ne(efr_data("exposure"), "A_star", "M", "Y", "C1",
                  misclassified_variable = "exposure", sensitivity_region = efr_region,
                  n_grid = 10, grid_method = "lhs", verbose = FALSE))
  skip_if(is.na(fit@NIE_lower), "no compatible sets in this region")
  expect_falsified_consistent(fit)
})

test_that("regular grid records every grid point with its verdict", {
  prepared <- prepare_data(efr_data("mediator"), "A", "M_star", "Y", "C1", NULL)
  res <- bound_ne_mediator(prepared, "A", "M_star", "Y", "C1",
                           sensitivity_region = efr_region, n_grid = 3,
                           effect_scale = "OR", parallel = FALSE, n_cores = NULL,
                           cache = FALSE, cache_dir = NULL, verbose = FALSE,
                           grid_method = "regular")
  expect_equal(nrow(res$evaluated_sets), 81L)
  expect_equal(sum(res$evaluated_sets$compatible), res$n_compatible)
})

test_that("extract_falsified_region() explains objects without recorded sets", {
  fit <- bound_ne(efr_data("mediator"), "A", "M_star", "Y", "C1",
                  misclassified_variable = "mediator", sensitivity_region = efr_region,
                  n_grid = 10, grid_method = "lhs", verbose = FALSE)
  fit@evaluated_sets <- NULL
  expect_error(extract_falsified_region(fit), "evaluated")
})
