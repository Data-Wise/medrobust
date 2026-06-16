# Feasibility smoke test for the bundled `nhanes_pa` exposure-side example.
# Mirrors the role of gesthtn's feasibility coverage: the dataset loads with the
# documented shape and strata, and the exposure-path bound_ne() runs and brackets
# its own naive estimate when the sensitivity region admits perfect classification
# (sn0/sp0 ranges include 1, psi_sn = 1).

have_data <- tryCatch({
  data("nhanes_pa", package = "medrobust", envir = environment())
  exists("nhanes_pa")
}, error = function(e) FALSE)

test_that("nhanes_pa has the documented shape, columns, and strata", {
  skip_if_not(have_data, "nhanes_pa not built (run inst/scripts/prepare_nhanes_pa.R)")
  expect_s3_class(nhanes_pa, "data.frame")
  expect_identical(names(nhanes_pa), c("A_star", "M", "Y", "C1", "C2", "C3"))
  expect_gt(nrow(nhanes_pa), 9000L)
  # every column is binary 0/1
  expect_true(all(vapply(nhanes_pa, function(x) all(x %in% 0:1), logical(1))))
  # 8 well-populated C1 x C2 x C3 strata (documented ~843-1588)
  strata <- as.vector(table(nhanes_pa$C1, nhanes_pa$C2, nhanes_pa$C3))
  expect_length(strata, 8L)
  expect_gt(min(strata), 700L)
  expect_lt(max(strata), 1700L)
})

test_that("exposure-path bound_ne() runs and returns a sane identified set (psi_sn = 1)", {
  skip_on_cran()
  skip_if_not(have_data, "nhanes_pa not built (run inst/scripts/prepare_nhanes_pa.R)")
  # Region admits perfect classification (sn0/sp0 include 1) at psi_sn = 1.
  region <- sensitivity_region(
    sn0_range = c(0.90, 1.00), sp0_range = c(0.90, 1.00),
    psi_sn_range = c(1.0, 1.0), psi_sp_range = c(1.0, 1.0)
  )
  b <- bound_ne(
    data = nhanes_pa, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = c("C1", "C2", "C3"), misclassified_variable = "exposure",
    sensitivity_region = region, n_grid = 12, grid_method = "regular",
    effect_scale = "OR", verbose = FALSE
  )
  # finite, correctly ordered identified sets on the OR scale
  expect_true(all(is.finite(c(b@NDE_lower, b@NDE_upper, b@NIE_lower, b@NIE_upper))))
  expect_lte(b@NDE_lower, b@NDE_upper)
  expect_lte(b@NIE_lower, b@NIE_upper)
  # the headline effect (NDE) brackets its own naive estimate when perfect
  # classification is admitted in-region; the naive accessor is lowercase $nde/$nie
  slack <- 0.02
  expect_lte(b@NDE_lower, b@naive_estimates$nde + slack)
  expect_gte(b@NDE_upper, b@naive_estimates$nde - slack)
})

test_that("the headline robustness finding holds: NDE CI crosses the null between psi_sn 1.5 and 2", {
  skip_on_cran()
  skip_if_not(have_data, "nhanes_pa not built (run inst/scripts/prepare_nhanes_pa.R)")
  # Pins the vignette narrative on the EXACT settings it renders: the Imbens--Manski
  # CI for the NDE excludes 1 under non-differential-to-mild reporting error
  # (psi_sn = 1.5) but covers 1 once differential reporting is allowed to grow
  # (psi_sn = 2). Asserted as a qualitative crossover with wide margins so the test
  # tracks the *finding*, not brittle decimals (measured 2026-06-15:
  # CI_lower 1.082 at psi=1.5, 0.872 at psi=2).
  Cnames <- c("C1", "C2", "C3")
  fit <- function(psi) {
    region <- sensitivity_region(
      sn0_range    = c(0.80, 0.95), sp0_range    = c(0.80, 0.95),
      psi_sn_range = c(1.0, psi),   psi_sp_range = c(1.0, 1.0)
    )
    bound_ne(
      data = nhanes_pa, exposure = "A_star", mediator = "M", outcome = "Y",
      confounders = Cnames, misclassified_variable = "exposure",
      sensitivity_region = region, n_grid = 50, effect_scale = "OR",
      ci_method = "analytic", use_adaptive_grid = TRUE, verbose = FALSE
    )
  }
  nde_ci <- function(b, k) as.numeric(b@analytic_ci[["NDE"]][[k]][[1]])

  b_mild <- fit(1.5)
  b_diff <- fit(2.0)

  # Robust to mild misclassification: NDE CI strictly excludes the null (OR = 1).
  expect_gt(nde_ci(b_mild, "ci_lower"), 1.0)
  # Not robust once reporting error is allowed to depend strongly on the outcome:
  # the NDE CI now brackets the null.
  expect_lt(nde_ci(b_diff, "ci_lower"), 1.0)
  expect_gt(nde_ci(b_diff, "ci_upper"), 1.0)

  # NIE is small and tight throughout -- inflammation carries little of the
  # association; the identified set sits in a narrow band just above the null.
  expect_lt(b_mild@NIE_upper - b_mild@NIE_lower, 0.05)
  expect_lt(b_diff@NIE_upper - b_diff@NIE_lower, 0.05)
  expect_true(all(c(b_mild@NIE_lower, b_diff@NIE_lower) > 0.95))
  expect_true(all(c(b_mild@NIE_upper, b_diff@NIE_upper) < 1.10))

  # Identified-set lower bound erodes monotonically toward the null as psi_sn grows.
  expect_gt(b_mild@NDE_lower, b_diff@NDE_lower)
})
