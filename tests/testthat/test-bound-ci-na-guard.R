# Regression tests for the analytic-CI NA guard (SPEC-bound-ne-robust-2026-06-14,
# FixB). When endpoint-SE resampling cannot produce >= 2 finite resamples, the
# Imbens-Manski construction would otherwise propagate NA -> NaN math silently.
# bound_ci() must instead emit documented NA CI endpoints with a per-effect reason
# and complete without error.

# Reuse the deterministic infeasible data set: every (A, stratum) cell < 5 rows,
# so the grid is empty and bound_ci() short-circuits before resampling.
.make_infeasible_data_ci <- function() {
  set.seed(7)
  n <- 16L
  data.frame(
    A      = rep(c(0, 1), each = 8),
    C1     = rep(c(0, 1), times = 8),
    M_star = sample(0:1, n, replace = TRUE),
    Y      = sample(0:1, n, replace = TRUE)
  )
}

.infeasible_region_ci <- list(
  sn0_range    = c(0.70, 0.90),
  sp0_range    = c(0.70, 0.90),
  psi_sn_range = c(1.0, 1.2),
  psi_sp_range = c(1.0, 1.2)
)

test_that("bound_ci short-circuits on an infeasible bounds object with NA endpoints + reason", {
  d <- .make_infeasible_data_ci()
  b <- suppressWarnings(suppressMessages(
    bound_ne(d, exposure = "A", mediator = "M_star", outcome = "Y",
             confounders = "C1", misclassified_variable = "mediator",
             sensitivity_region = .infeasible_region_ci, n_grid = 10,
             effect_scale = "OR", grid_method = "regular", verbose = FALSE)
  ))
  expect_identical(b@n_compatible, 0L)

  ci <- NULL
  expect_no_error(
    ci <- bound_ci(b, d, "A", "M_star", "Y", "C1",
                   misclassified_variable = "mediator", n_boot = 30L, seed = 1)
  )

  # Both effects: CI endpoints are NA.
  expect_true(is.na(ci$NDE["ci_lower"]) && is.na(ci$NDE["ci_upper"]))
  expect_true(is.na(ci$NIE["ci_lower"]) && is.na(ci$NIE["ci_upper"]))

  # Each carries a machine-readable reason.
  expect_identical(ci$NDE_reason, "infeasible_no_compatible_sets")
  expect_identical(ci$NIE_reason, "infeasible_no_compatible_sets")
})

test_that(".imbens_manski_ci is NA-safe when an endpoint SE is non-finite", {
  # A non-finite SE must yield NA endpoints, not NaN from max(NA, ...) / uniroot.
  expect_no_error(ci <- .imbens_manski_ci(1.0, 2.0, NA_real_, 0.05, level = 0.95))
  expect_true(is.na(ci["lower"]) && is.na(ci["upper"]))

  expect_no_error(ci2 <- .imbens_manski_ci(1.0, 2.0, 0.05, Inf, level = 0.95))
  expect_true(is.na(ci2["lower"]) && is.na(ci2["upper"]))
})

test_that(".endpoint_se returns NA with a failed-resample count when resamples are infeasible", {
  # An eval_fn that always fails -> all resamples NA -> < 2 finite -> NA SE.
  eval_fn <- function(d) NULL
  df <- data.frame(x = 1:10)
  se <- .endpoint_se(eval_fn, df, which = "nde", n_boot = 8L, seed = 1)
  expect_true(is.na(se))
  expect_equal(attr(se, "n_failed"), 8L)
})

test_that("bound_ne(ci_method='analytic') does not attach a CI on the infeasible path and does not error", {
  d <- .make_infeasible_data_ci()
  expect_no_error(
    b <- suppressWarnings(suppressMessages(
      bound_ne(d, exposure = "A", mediator = "M_star", outcome = "Y",
               confounders = "C1", misclassified_variable = "mediator",
               sensitivity_region = .infeasible_region_ci, n_grid = 10,
               effect_scale = "OR", ci_method = "analytic", ci_n_boot = 20L,
               grid_method = "regular", verbose = FALSE)
    ))
  )
  # Analytic CI is skipped when there are no compatible sets (n_compatible == 0).
  expect_identical(b@n_compatible, 0L)
  expect_equal(length(b@analytic_ci), 0L)
})
