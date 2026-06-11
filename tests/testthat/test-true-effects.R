# Regression tests for compute_true_effects() (the simulator's @true_effects).
#
# Bug (fixed 2026-06-11): compute_true_effects() used a plug-in-mean-M estimand
# (it plugged E[M(a)] and mean-C into the nonlinear outcome model), inflating
# NDE_OR to ~1.500 vs the correct g-computation value ~1.480. The fix averages
# the OUTCOME over the M and C distributions (the g-formula). These tests pin the
# corrected behaviour against an INDEPENDENT brute-force potential-outcomes
# simulation, so they do not merely re-check the analytic formula against itself.

expit_ <- function(x) 1 / (1 + exp(-x))

# Brute-force potential-outcome oracle: simulate M and Y draws under the
# counterfactual (a, M(aprime)) using the actual confounder values, then average.
# Converges (in n) to the true g-computation but via independent random draws.
po_oracle <- function(Cvals, coefs, seed = 99) {
  set.seed(seed)
  n <- length(Cvals)
  draw_EY <- function(a, aprime) {
    pM <- expit_(coefs$bM + coefs$bAM * aprime + coefs$bC * Cvals)
    M  <- stats::rbinom(n, 1, pM)
    pY <- expit_(coefs$bY + coefs$tAY * a + coefs$tMY * M + coefs$tC * Cvals)
    mean(stats::rbinom(n, 1, pY))
  }
  e11 <- draw_EY(1, 1); e10 <- draw_EY(1, 0); e00 <- draw_EY(0, 0)
  o <- function(p) p / (1 - p)
  list(NDE_OR = o(e10) / o(e00), NIE_OR = o(e11) / o(e10))
}

test_that("true_effects use g-computation, matching a brute-force PO oracle (no misclass)", {
  skip_on_cran()
  coefs <- list(bM = -1.5, bY = -2.0, bAM = log(2.5),
                tAY = log(1.5), tMY = log(2.5), bC = 0.3, tC = 0.3)

  sim <- simulate_dm_data(
    n = 2e5,
    true_params = list(beta_AM = coefs$bAM, theta_AY = coefs$tAY, theta_MY = coefs$tMY),
    dm_params   = list(sn0 = 1, sp0 = 1, psi_sn = 1, psi_sp = 1),  # perfect classification
    misclass_type = "mediator", confounders = 1, seed = 42
  )
  te  <- sim@true_effects
  orc <- po_oracle(sim@observed$C1, coefs)

  # Corrected estimand agrees with the independent simulation oracle.
  expect_equal(te$NDE_OR, orc$NDE_OR, tolerance = 0.03)
  expect_equal(te$NIE_OR, orc$NIE_OR, tolerance = 0.03)

  # Regression guard: the old plug-in-mean bug produced NDE_OR ~ 1.500.
  # The g-computation value for this DGP is ~1.480; stay clearly below 1.492.
  expect_lt(te$NDE_OR, 1.492)
})

test_that("true_effects are internally consistent (TCE = NDE * NIE on OR scale)", {
  sim <- simulate_dm_data(
    n = 1e4,
    true_params = list(beta_AM = log(2), theta_AY = log(1.5), theta_MY = log(2)),
    dm_params   = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "mediator", confounders = 1, seed = 7
  )
  te <- sim@true_effects
  # On the OR scale the total effect decomposes multiplicatively.
  expect_equal(te$TCE_OR, te$NDE_OR * te$NIE_OR, tolerance = 1e-8)
})
