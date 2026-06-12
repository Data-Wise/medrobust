# Exact-population recovery for the EXPOSURE (A*) path.
#
# Mirrors the package logic in bound_ne_exposure.R / evaluate_param_set():
#   1. recover the CONDITIONAL P(A=a | m,y,c) from observed P(A*|m,y,c) via the
#      Y-stratified 2x2 inverse (det = Sn_y + Sp_y - 1);
#   2. convert to the JOINT P(A=a, m, y | c) by multiplying the observed
#      P(M=m, Y=y | c) (M and Y are not misclassified here).
# Asserts both the conditional and the joint match truth to 1e-8, for a
# non-differential and a differential misclassification setting.

expit_ <- function(x) 1 / (1 + exp(-x))

# True structural probabilities under the exposure DGP (binary C, p=0.5).
dgp <- function(bM=-1.5, bY=-2.0, bAM=log(2.5), tAY=log(1.5), tMY=log(2.5),
                bC=0.3, tC=0.3, aC=0.3, a0=log(0.4/0.6)) {
  environment()
}

# True joint P(A=a, M=m, Y=y | C=c)
true_joint <- function(a, m, y, cc, p) {
  pA <- expit_(p$a0 + p$aC * cc); pA <- if (a == 1) pA else 1 - pA
  pM <- expit_(p$bM + p$bAM * a + p$bC * cc); pM <- if (m == 1) pM else 1 - pM
  pY <- expit_(p$bY + p$tAY * a + p$tMY * m + p$tC * cc); pY <- if (y == 1) pY else 1 - pY
  pA * pM * pY
}

check_exposure_recovery <- function(Sn1, Sp1, Sn0, Sp0, p = dgp()) {
  max_cond_err <- 0; max_joint_err <- 0
  for (cc in 0:1) {
    for (m in 0:1) for (y in 0:1) {
      # true joint and conditional P(A | m,y,c)
      j1 <- true_joint(1, m, y, cc, p); j0 <- true_joint(0, m, y, cc, p)
      Pmy <- j1 + j0                       # observed P(M=m, Y=y | c) (A marginalised)
      pA1 <- j1 / Pmy                      # true P(A=1 | m,y,c)
      pA0 <- j0 / Pmy
      Sn <- if (y == 1) Sn1 else Sn0; Sp <- if (y == 1) Sp1 else Sp0
      # observed conditional P(A* | m,y,c)
      Ps1 <- Sn * pA1 + (1 - Sp) * pA0
      Ps0 <- (1 - Sn) * pA1 + Sp * pA0
      # recover conditional via the package's Cramer inverse
      rec1 <- (Sp * Ps1 - (1 - Sp) * Ps0) / (Sn + Sp - 1)
      rec0 <- (Sn * Ps0 - (1 - Sn) * Ps1) / (Sn + Sp - 1)
      max_cond_err <- max(max_cond_err, abs(rec1 - pA1), abs(rec0 - pA0))
      # convert to joint (the fix) and compare to truth
      max_joint_err <- max(max_joint_err, abs(rec1 * Pmy - j1), abs(rec0 * Pmy - j0))
    }
  }
  c(cond = max_cond_err, joint = max_joint_err)
}

test_that("exposure conditional + joint recovery is exact (non-differential)", {
  e <- check_exposure_recovery(Sn1 = 0.9, Sp1 = 0.9, Sn0 = 0.9, Sp0 = 0.9)
  expect_lt(e["cond"], 1e-8)
  expect_lt(e["joint"], 1e-8)
})

test_that("exposure conditional + joint recovery is exact (differential)", {
  e <- check_exposure_recovery(Sn1 = 0.95, Sp1 = 0.85, Sn0 = 0.80, Sp0 = 0.92)
  expect_lt(e["cond"], 1e-8)
  expect_lt(e["joint"], 1e-8)
})

test_that("dropping the P(M,Y|c) weight (the bug) corrupts the joint", {
  # Demonstrates WHY the fix is needed: using the conditional as if it were the
  # joint (uniform M,Y marginal) does not reproduce the true joint.
  p <- dgp()
  rec_as_joint <- true_joint(1, 1, 1, 1, p) / (true_joint(1,1,1,1,p) + true_joint(0,1,1,1,p))
  expect_false(isTRUE(all.equal(rec_as_joint, true_joint(1, 1, 1, 1, p), tolerance = 1e-6)))
})
