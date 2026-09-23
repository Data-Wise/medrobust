# check_compatibility() must be able to return compatible = FALSE (#34).
# Before the fix, every incompatible result -- and every result built with
# return_details = FALSE -- aborted in the compatibility_test validator,
# because implied_probabilities / stratum_details were NULL but typed <list>.

# Exposure data: four (M, Y) cells of 20 rows, A_star split 50/50 in each
exposure_data <- function(zero_cell = FALSE) {
  d <- data.frame(
    A_star = rep(c(0, 1), 40),
    M = rep(c(0, 0, 1, 1), each = 20),
    Y = rep(c(0, 1), each = 40)
  )
  # All A_star = 1 in (M = 1, Y = 1): violates P*_0 / P*_1 >= (1 - Sn1) / Sn1
  if (zero_cell) d$A_star[d$M == 1 & d$Y == 1] <- 1
  d
}

# Mediator data: for A = 0 no row has M_star = 1, so the solved pi_a is negative
mediator_data <- function() {
  data.frame(
    A = rep(c(0, 1), each = 20),
    M_star = c(rep(0, 20), rep(c(0, 1), 10)),
    Y = c(rep(c(0, 1), 10), rep(c(0, 0, 1, 1), 5))
  )
}

psi_nd <- list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1)

test_that("an incompatible exposure psi returns compatible = FALSE", {
  res <- check_compatibility(
    exposure_data(zero_cell = TRUE), "A_star", "M", "Y",
    psi = psi_nd, misclassified_variable = "exposure"
  )
  expect_false(res@compatible)
  expect_gt(res@n_constraints_violated, 0L)
  expect_null(res@implied_probabilities)
  expect_type(res@stratum_details, "list")
  expect_no_error(capture.output(print(res), summary(res)))
})

test_that("an incompatible mediator psi returns compatible = FALSE", {
  res <- check_compatibility(
    mediator_data(), "A", "M_star", "Y",
    psi = psi_nd, misclassified_variable = "mediator"
  )
  expect_false(res@compatible)
  expect_gt(res@n_constraints_violated, 0L)
  expect_null(res@implied_probabilities)
})

test_that("the non-informative early exit returns compatible = FALSE", {
  res <- check_compatibility(
    exposure_data(), "A_star", "M", "Y",
    psi = list(sn0 = 0.4, sp0 = 0.5, psi_sn = 1, psi_sp = 1),
    misclassified_variable = "exposure"
  )
  expect_false(res@compatible)
  expect_match(res@reason, "Non-informative")
  expect_null(res@stratum_details)
})

test_that("a compatible psi still carries implied probabilities", {
  res <- check_compatibility(
    exposure_data(), "A_star", "M", "Y",
    psi = psi_nd, misclassified_variable = "exposure"
  )
  expect_true(res@compatible)
  expect_type(res@implied_probabilities, "list")
  expect_gt(length(res@implied_probabilities), 0L)
})

test_that("return_details = FALSE no longer errors", {
  res <- check_compatibility(
    exposure_data(), "A_star", "M", "Y",
    psi = psi_nd, misclassified_variable = "exposure",
    return_details = FALSE
  )
  expect_true(res@compatible)
  expect_null(res@stratum_details)
})

test_that("test_multiple_hypotheses reports compatible and incompatible psi", {
  out <- test_multiple_hypotheses(
    exposure_data(), "A_star", "M", "Y", confounders = NULL,
    psi_list = list(
      nondifferential = psi_nd,
      noninformative = list(sn0 = 0.4, sp0 = 0.5, psi_sn = 1, psi_sp = 1)
    ),
    misclassified_variable = "exposure"
  )
  expect_s3_class(out, "data.frame")
  expect_identical(out$hypothesis, c("nondifferential", "noninformative"))
  expect_identical(out$compatible, c(TRUE, FALSE))
})

test_that("implied_probabilities and stratum_details still reject non-lists", {
  make <- function(...) {
    compatibility_test(
      compatible = FALSE, psi = psi_nd,
      misclassified_variable = "exposure", reason = "test", ...
    )
  }
  expect_no_error(make(implied_probabilities = NULL, stratum_details = NULL))
  expect_error(make(implied_probabilities = 1), "must be a list or NULL")
  expect_error(make(stratum_details = "x"), "must be a list or NULL")
})
