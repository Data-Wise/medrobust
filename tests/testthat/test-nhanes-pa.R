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
