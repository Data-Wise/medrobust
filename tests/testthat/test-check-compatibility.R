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

# Mediator gamma checks (#39). Both gamma estimates were computed as a sum over
# the same cells as their denominator, so they were identically 1 and only
# pi_a was ever tested.

# A = 0: every Y = 1 row has M_star = 0, so at Sn = Sp = 0.9
# P(M = 1, Y = 1) = -1/24 while pi_a = 7/24 is valid; gamma_a1 = -1/7
gamma_violation_data <- function() {
  rbind(
    data.frame(A = 0, Y = 1, M_star = rep(0, 10)),
    data.frame(A = 0, Y = 0, M_star = rep(c(0, 1), 10)),
    data.frame(A = 1, Y = rep(c(0, 1), each = 20), M_star = rep(c(0, 1), 20))
  )
}

# A = 0: P*(Y, M*) = (3/8, 1/8, 1/8, 3/8), so at Sn = Sp = 0.9 the solved
# cells give pi_a = 1/2, gamma_a1 = 13/16, gamma_a0 = 3/16
gamma_compatible_data <- function() {
  rbind(
    data.frame(A = 0, Y = 1, M_star = rep(c(1, 0), c(12, 4))),
    data.frame(A = 0, Y = 0, M_star = rep(c(1, 0), c(4, 12))),
    data.frame(A = 1, Y = rep(c(0, 1), each = 20), M_star = rep(c(0, 1), 20))
  )
}

test_that("a negative solved cell fails the mediator gamma check (#39)", {
  res <- check_compatibility(
    gamma_violation_data(), "A", "M_star", "Y",
    psi = psi_nd, misclassified_variable = "mediator"
  )
  expect_false(res@compatible)
  expect_identical(res@n_constraints_violated, 1L)
  expect_identical(res@violated_constraints$constraint, "gamma_a1 in [0,1]")
  expect_identical(res@violated_constraints$exposure, 0)
  expect_equal(res@violated_constraints$value, -1 / 7)
})

test_that("implied gamma is P(Y = 1 | M, a), not 1 (#39)", {
  res <- check_compatibility(
    gamma_compatible_data(), "A", "M_star", "Y",
    psi = psi_nd, misclassified_variable = "mediator"
  )
  expect_true(res@compatible)
  a0 <- res@implied_probabilities$a0_s1
  expect_equal(a0$pi_a, 1 / 2)
  expect_equal(a0$gamma_a1, 13 / 16)
  expect_equal(a0$gamma_a0, 3 / 16)
})

balanced_a1 <- function() {
  data.frame(A = 1, Y = rep(c(0, 1), each = 20), M_star = rep(c(0, 1), 20))
}

test_that("tolerance = 0 does not divide 0 by 0 in the gamma checks (#39)", {
  # A = 0 has no Y = 1 rows and 1 of 20 M_star = 1: pi_a solves to -1/16,
  # is flagged, and is clamped to 0, where gamma_a1 is undefined
  d <- rbind(data.frame(A = 0, Y = 0, M_star = rep(c(1, 0), c(1, 19))),
             balanced_a1())
  res <- check_compatibility(
    d, "A", "M_star", "Y", psi = psi_nd,
    misclassified_variable = "mediator", tolerance = 0
  )
  expect_false(res@compatible)
  expect_identical(res@n_constraints_violated, nrow(res@violated_constraints))
  expect_identical(res@violated_constraints$constraint, "pi_a in [0,1]")
  expect_false(grepl("inversion", res@stratum_details$a0_s1$reason))
})

test_that("a large tolerance does not switch off the gamma check (#39)", {
  # A = 0: pi_a = 1/40 is below tolerance = 0.05 but is a valid pi_a, and
  # gamma_a1 = -1; bound_ne() rejects the same psi
  d <- rbind(
    data.frame(A = 0, Y = 1, M_star = rep(0, 20)),
    data.frame(A = 0, Y = 0, M_star = rep(c(1, 0), c(12, 68))),
    balanced_a1()
  )
  res <- check_compatibility(
    d, "A", "M_star", "Y", psi = psi_nd,
    misclassified_variable = "mediator", tolerance = 0.05
  )
  expect_false(res@compatible)
  expect_identical(res@violated_constraints$constraint, "gamma_a1 in [0,1]")
  expect_equal(res@violated_constraints$value, -1)
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
