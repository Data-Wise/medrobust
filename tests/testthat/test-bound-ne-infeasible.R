# Regression tests for graceful degradation when the sensitivity grid admits NO
# compatible parameter set (SPEC-bound-ne-robust-2026-06-14, FixA).
#
# Under severe misclassification the entire grid can be rejected as incompatible.
# bound_ne() must then return a valid medrobust_bounds object with NA bounds, a
# machine-readable @reason, n_compatible == 0, and signal a 'medrobust_infeasible'
# condition -- it must NOT stop().
#
# Forcing an empty grid empirically (via realistic simulated data) is unreliable:
# the per-Y 2x2 solve is well-conditioned and recovers valid pi/gamma across the
# grid, so most regions stay fully compatible. A deterministic, fast trigger is a
# data set in which every (A, confounder-stratum) cell has < 5 rows, which the
# mediator dispatcher skips (R/bound_ne_mediator.R:83), rejecting every grid point
# and routing through the graceful-infeasible return.

# A tiny balanced data set: with one binary confounder and n = 16, each of the
# four (A in {0,1}) x (C1 in {0,1}) cells holds ~4 rows (< 5) -> all rejected.
.make_infeasible_data <- function() {
  set.seed(7)
  n <- 16L
  data.frame(
    A      = rep(c(0, 1), each = 8),
    C1     = rep(c(0, 1), times = 8),
    M_star = sample(0:1, n, replace = TRUE),
    Y      = sample(0:1, n, replace = TRUE)
  )
}

.infeasible_region <- list(
  sn0_range    = c(0.70, 0.90),
  sp0_range    = c(0.70, 0.90),
  psi_sn_range = c(1.0, 1.2),
  psi_sp_range = c(1.0, 1.2)
)

test_that("bound_ne degrades gracefully when no compatible set exists", {
  d <- .make_infeasible_data()

  signaled <- FALSE
  res <- suppressWarnings(withCallingHandlers(
    bound_ne(d, exposure = "A", mediator = "M_star", outcome = "Y",
             confounders = "C1", misclassified_variable = "mediator",
             sensitivity_region = .infeasible_region, n_grid = 10,
             effect_scale = "OR", grid_method = "regular", verbose = FALSE),
    medrobust_infeasible = function(c) signaled <<- TRUE
  ))

  # Does not error; returns the S7 bounds object. The S7 class vector is
  # c("medrobust::medrobust_bounds", "S7_object"), so match the namespaced name.
  expect_s3_class(res, "medrobust::medrobust_bounds")
  expect_true("medrobust::medrobust_bounds" %in% class(res))

  # Bounds are NA on the infeasible path.
  expect_true(is.na(res@NIE_lower))
  expect_true(is.na(res@NIE_upper))
  expect_true(is.na(res@NDE_lower))
  expect_true(is.na(res@NDE_upper))

  # Machine-readable reason and zero compatible sets.
  expect_identical(res@reason, "infeasible_no_compatible_sets")
  expect_identical(res@n_compatible, 0L)

  # The 'medrobust_infeasible' condition was signaled.
  expect_true(signaled)
})

test_that("bound_ne does not stop() on an empty grid", {
  d <- .make_infeasible_data()
  expect_no_error(suppressWarnings(suppressMessages(
    bound_ne(d, exposure = "A", mediator = "M_star", outcome = "Y",
             confounders = "C1", misclassified_variable = "mediator",
             sensitivity_region = .infeasible_region, n_grid = 10,
             effect_scale = "OR", grid_method = "regular", verbose = FALSE)
  )))
})

test_that("SANITY: a low-misclassification case yields finite bounds (no infeasible path)", {
  skip_on_cran()
  sim <- simulate_dm_data(
    n = 4000,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.90, sp0 = 0.90, psi_sn = 1, psi_sp = 1),
    misclass_type = "mediator", confounders = 1, seed = 7
  )
  region <- list(sn0_range = c(0.85, 0.95), sp0_range = c(0.85, 0.95),
                 psi_sn_range = c(1, 1), psi_sp_range = c(1, 1))

  signaled <- FALSE
  res <- withCallingHandlers(
    bound_ne(sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
             confounders = "C1", misclassified_variable = "mediator",
             sensitivity_region = region, n_grid = 10, effect_scale = "OR",
             grid_method = "regular", verbose = FALSE),
    medrobust_infeasible = function(c) signaled <<- TRUE
  )

  # Feasible: infeasible path NOT triggered.
  expect_false(signaled)
  expect_gt(res@n_compatible, 0L)
  expect_null(res@reason)

  # Bounds are finite and correctly ordered.
  expect_true(is.finite(res@NIE_lower) && is.finite(res@NIE_upper))
  expect_true(is.finite(res@NDE_lower) && is.finite(res@NDE_upper))
  expect_lte(res@NIE_lower, res@NIE_upper)
  expect_lte(res@NDE_lower, res@NDE_upper)
})
