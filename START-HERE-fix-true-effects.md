# START HERE — Fix `compute_true_effects()` (estimand mismatch)

**Branch:** `fix/true-effects-estimand` (already created & checked out)
**Why:** Smoke-testing the DM bounds sims showed coverage failing at psi=1 (where it
must hold). Root cause: `simulate_dm_data()@true_effects` computes natural effects with a
**plug-in-mean-M** formula instead of g-computation (averaging over M). The bounds target
the correct estimand, so coverage was checked against the wrong "truth."
Full diagnosis: `ISSUE-true-effects-estimand-2026-06-11.md`.

---

## 0. Setup (once)

```sh
cd ~/projects/r-packages/active/medrobust
git status                      # confirm branch: fix/true-effects-estimand
git log --oneline -1            # 97bae57 docs: log estimand-mismatch issue ...
```

Environment note: this repo uses `renv`, but the pinned lockfile won't restore under
**R 4.6** (old `Rcpp` fails to compile against R 4.6 headers). For dev work you only need
the runtime deps, which DO compile from source:

```r
# in R, from the package dir
install.packages(c("S7","dplyr","rlang","ggplot2","pkgload"))   # ~few min, source build
pkgload::load_all(".")          # load the package for interactive testing
```

(If/when you regenerate the lockfile, bump `Rcpp` to a current version first.)

---

## 1. The fix — `R/simulate_dm_data.R`, function `compute_true_effects()` (lines ~329–413)

**Replace the plug-in-mean block (lines ~355–365).** Currently:

```r
prob_M_a1  <- expit(baseline_M + beta_AM * 1 + C_mean_M)
E_Y_a1_Ma1 <- expit(baseline_Y + theta_AY * 1 + theta_MY * prob_M_a1 + ... )   # WRONG
prob_M_a0  <- expit(baseline_M + beta_AM * 0 + C_mean_M)
E_Y_a1_Ma0 <- expit(baseline_Y + theta_AY * 1 + theta_MY * prob_M_a0 + ... )   # WRONG
E_Y_a0_Ma0 <- expit(baseline_Y + theta_AY * 0 + theta_MY * prob_M_a0 + ... )   # WRONG
```

**Correct natural-effect g-computation** (binary M, binary outcome). For `E[Y(a, M(a'))]`,
average the outcome over the M(a') distribution, then over C:

```r
# helper: E[Y(a, M(aprime))]
EY <- function(a, aprime) {
  # integrate over the observed/known C distribution; here C binary p=0.5,
  # but use the actual confounder grid the DGP uses (see confounder_params).
  tot <- 0
  for (cval in c(0, 1)) {                 # generalize to the C support in use
    pc  <- 0.5                            # P(C = cval); match the DGP
    piM <- expit(baseline_M + beta_AM * aprime + beta_C * cval)        # P(M=1 | aprime, c)
    g1  <- expit(baseline_Y + theta_AY * a + theta_MY * 1 +
                 interaction_coef * a * 1 + theta_C * cval)            # P(Y=1 | a, M=1, c)
    g0  <- expit(baseline_Y + theta_AY * a + theta_MY * 0 +
                 interaction_coef * a * 0 + theta_C * cval)            # P(Y=1 | a, M=0, c)
    tot <- tot + pc * (piM * g1 + (1 - piM) * g0)
  }
  tot
}
E_Y_a1_Ma1 <- EY(1, 1)
E_Y_a1_Ma0 <- EY(1, 0)
E_Y_a0_Ma0 <- EY(0, 0)
```

Leave the OR/RR/RD and PM derivations below (lines ~367–410) unchanged — they consume
these three `E_Y_*` values.

**Notes / gotchas:**
- `beta_C`, `theta_C` are `confounder_params$effect_on_M` / `effect_on_Y` (already read
  near the top of the function as `C_mean_*` — you can reuse those vars or recompute).
- Don't keep using `C_mean_M`/`C_mean_Y` (those collapse C to its mean, the same Jensen
  error one level up). Average over the actual C support.
- Generalize the `for (cval in ...)` loop to whatever confounder grid the DGP supports
  (`confounders`, `confounder_params$type`).

---

## 2. Add a regression test (new file)

`tests/testthat/test-true-effects.R`:

```r
test_that("true_effects match empirical g-computation (no misclassification)", {
  sim <- simulate_dm_data(
    n = 2e5,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params   = list(sn0 = 1, sp0 = 1, psi_sn = 1, psi_sp = 1),  # no misclass
    misclass_type = "mediator", confounders = 1, seed = 42
  )
  te <- sim@true_effects
  d  <- sim@observed
  # empirical g-computation on the (error-free) data:
  emp <- gcomp_empirical(d, exposure = "A", mediator = "M_star",
                         outcome = "Y", confounders = "C1")  # or write inline
  expect_equal(te$NDE_OR, emp$NDE_OR, tolerance = 0.03)
  expect_equal(te$NIE_OR, emp$NIE_OR, tolerance = 0.03)
})
```

(With Sn=Sp=1 the surrogate equals the truth, so empirical g-comp on `M_star` == on `M`.)

---

## 3. Re-verify with the saved diagnostics

The scripts that found the bug are in `dev-diagnostics/` (NOT committed — dev only):

```sh
Rscript dev-diagnostics/diag_estimand_compare.R   # package vs correct truth — should now MATCH
Rscript dev-diagnostics/diag_analytic_bound.R     # analytic bound vs bound_ne vs (fixed) truth
```

- **Expected after fix:** `diag_estimand_compare.R` shows package NDE_OR ≈ correct NDE_OR
  (Δ ~ 0, was 0.02).
- **Then check the SECOND issue:** in `diag_analytic_bound.R`, does the **OR-scale NDE
  bound** now contain the corrected truth at large n with the true Ψ in-region?
  - If YES → the only problem was the estimand; proceed to sims.
  - If NO (gap persists) → open a focused issue on OR-scale NDE composition in
    `bound_ne` / `R/bound_ne_mediator.R`. NIE was fine; isolate to NDE.

---

## 4. When green

```sh
devtools::test()                 # full suite incl. new test
devtools::check()                # keep CRAN-clean (this pkg is P0, CRAN-bound)
git add R/simulate_dm_data.R tests/testthat/test-true-effects.R
git commit -m "fix: compute_true_effects uses g-computation (average over M), not plug-in mean"
# update NEWS.md; open PR fix/true-effects-estimand -> main
```

Then unblock the sims:
```sh
cd ~/projects/research/me-mediator-bounds && Rscript code/run_simulations.R   # small N first
# clear the 🔴 BLOCKER in me-mediator-bounds/.STATUS and me-exposure-recall/.STATUS
```

---

## Pointers
- Issue: `ISSUE-true-effects-estimand-2026-06-11.md`
- Research finding: `~/projects/research/me-mediator-bounds/02_Notes/FINDING-sim-coverage-2026-06-11.md`
- Bound spec (the correct estimand): manuscript §4.2, step 5 —
  `~/projects/research/me-mediator-bounds/03_Drafts/UNIFIED-SOURCE-manuscript.md`
- Sim drivers: `~/projects/research/me-{mediator-bounds,exposure-recall}/code/run_simulations.R`
