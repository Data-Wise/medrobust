# Exact-population recovery tests for the mediator identification solve.
#
# Bug (fixed 2026-06-11): bound_ne_mediator.R recovered (pi, gamma) from a
# mis-specified 3x3 linear system whose P01 row mixed the Y=1 unknown
# (1-pi)*g0 into a slot that should hold the Y=0 quantity (1-pi)*(1-g0). The fix
# splits recovery into two per-Y-stratum 2x2 systems (manuscript Sec 4.2).
#
# These tests build the EXACT observed cells P(Y, M* | a, c) from a known DGP
# (no sampling) and assert the solve recovers the true (pi, g1, g0) to ~1e-8.
# The solve mirrored here is identical to the one in R/bound_ne_mediator.R; this
# guards the derivation so the 3x3 defect cannot silently return. It also covers
# a DIFFERENTIAL case (Sn1 != Sn0), which the previous 3x3 form mishandled.

expit_ <- function(x) 1 / (1 + exp(-x))

# True per-(a, c) causal parameters under the standard DGP.
true_parc <- function(a, cc,
                      bM = -1.5, bY = -2.0, bAM = log(2.5),
                      tAY = log(1.5), tMY = log(2.5), bC = 0.3, tC = 0.3) {
  list(
    pi = expit_(bM + bAM * a + bC * cc),
    g1 = expit_(bY + tAY * a + tMY * 1 + tC * cc),
    g0 = expit_(bY + tAY * a + tMY * 0 + tC * cc)
  )
}

# Exact observed joint P(Y = y, M* = m* | a, c) with outcome-dependent (Y) error.
obs_pop <- function(a, cc, Sn1, Sp1, Sn0, Sp0) {
  p <- true_parc(a, cc)
  M1Y1 <- p$pi * p$g1; M0Y1 <- (1 - p$pi) * p$g0
  M1Y0 <- p$pi * (1 - p$g1); M0Y0 <- (1 - p$pi) * (1 - p$g0)
  c(
    P11 = Sn1 * M1Y1 + (1 - Sp1) * M0Y1,   # Y=1, M*=1
    P10 = (1 - Sn1) * M1Y1 + Sp1 * M0Y1,   # Y=1, M*=0
    P01 = Sn0 * M1Y0 + (1 - Sp0) * M0Y0,   # Y=0, M*=1
    P00 = (1 - Sn0) * M1Y0 + Sp0 * M0Y0    # Y=0, M*=0
  )
}

# Two per-Y-stratum 2x2 systems (identical algebra to R/bound_ne_mediator.R).
solve_two_2x2 <- function(P, Sn1, Sp1, Sn0, Sp0) {
  A1 <- matrix(c(Sn1, 1 - Sp1, 1 - Sn1, Sp1), 2, 2, byrow = TRUE)
  A0 <- matrix(c(Sn0, 1 - Sp0, 1 - Sn0, Sp0), 2, 2, byrow = TRUE)
  xy1 <- solve(A1, c(P["P11"], P["P10"]))
  xy0 <- solve(A0, c(P["P01"], P["P00"]))
  x1 <- xy1[1]; x0 <- xy1[2]; z1 <- xy0[1]
  pi_a <- x1 + z1
  list(pi = unname(pi_a), g1 = unname(x1 / pi_a), g0 = unname(x0 / (1 - pi_a)))
}

recover_max_error <- function(Sn1, Sp1, Sn0, Sp0) {
  err <- 0
  for (cc in 0:1) for (a in 0:1) {
    P  <- obs_pop(a, cc, Sn1, Sp1, Sn0, Sp0)
    rp <- solve_two_2x2(P, Sn1, Sp1, Sn0, Sp0)
    tp <- true_parc(a, cc)
    err <- max(err, abs(tp$pi - rp$pi), abs(tp$g1 - rp$g1), abs(tp$g0 - rp$g0))
  }
  err
}

test_that("non-differential recovery is exact (Sn1 == Sn0)", {
  expect_lt(recover_max_error(Sn1 = 0.9, Sp1 = 0.9, Sn0 = 0.9, Sp0 = 0.9), 1e-8)
})

test_that("differential recovery is exact (Sn1 != Sn0, Sp1 != Sp0)", {
  # The mis-specified 3x3 form failed precisely in the differential regime.
  expect_lt(recover_max_error(Sn1 = 0.95, Sp1 = 0.85, Sn0 = 0.80, Sp0 = 0.92), 1e-8)
})

test_that("g-computation from recovered params matches the oracle effects", {
  Sn1 <- 0.9; Sp1 <- 0.9; Sn0 <- 0.9; Sp0 <- 0.9
  par <- list(list(), list())
  for (cc in 0:1) {
    ac <- list()
    for (a in 0:1) ac[[a + 1]] <- solve_two_2x2(obs_pop(a, cc, Sn1, Sp1, Sn0, Sp0),
                                                Sn1, Sp1, Sn0, Sp0)
    par[[cc + 1]] <- ac
  }
  # E[Y(a, M(aprime))] averaged over M (analytic) and C (P(C) = 0.5 each).
  EY <- function(a, aprime) {
    tot <- 0
    for (cc in 0:1) {
      p  <- par[[cc + 1]]
      pm <- p[[aprime + 1]]$pi
      tot <- tot + 0.5 * (pm * p[[a + 1]]$g1 + (1 - pm) * p[[a + 1]]$g0)
    }
    tot
  }
  o <- function(p) p / (1 - p)
  NDE_OR <- o(EY(1, 0)) / o(EY(0, 0))
  NIE_OR <- o(EY(1, 1)) / o(EY(1, 0))
  expect_equal(NDE_OR, 1.48025, tolerance = 1e-4)
  expect_equal(NIE_OR, 1.19941, tolerance = 1e-4)
})
