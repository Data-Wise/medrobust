PASTE THIS INTO THE ACTIVE CLAUDE CODE SESSION (cwd = ~/projects/r-packages/active/medrobust)

---

We're on branch `fix/true-effects-estimand` (pushed to origin). Two correctness bugs were
found in the differential-misclassification path; ONE is already fixed and verified, ONE
remains. Read these first, in order:
- PLAN-fix-bound_ne-solve-2026-06-11.md   (authoritative plan + drop-in code + test strategy)
- ISSUE-true-effects-estimand-2026-06-11.md  (diagnosis)
- The verified reference oracles in dev-diagnostics/ (gitignored): popcheck_exact_recovery.R,
  oracle_potential_outcomes.R, bne_point_test.R, verify_fix.R, instrument_formula_vs_solve.R

STATUS:
- [DONE, committed b71ac24] bound_ne_mediator.R solve fixed: the mis-specified 3x3 system was
  replaced with two 2x2 systems (one per Y stratum). Point test confirms NDE_OR 1.601->1.495,
  NIE_OR 1.121->1.200 (oracle 1.480/1.199). Do NOT re-do this.
- [DONE, audited] bound_ne_exposure.R is CORRECT (standard 2x2 matrix inverse). Do NOT change.
- [DO NOT TOUCH] compute_effects_from_params() in utilities_helpers.R is verified correct.

YOUR TASKS:

1. FIX THE ESTIMAND BUG in R/simulate_dm_data.R, function compute_true_effects() (~lines 355-365).
   It currently plugs E[M(a)] into the outcome linear predictor (plug-in mean). Replace with
   proper g-computation: average the outcome over the M distribution AND over the C support:
       E[Y(a, M(aprime))] = sum_c P(c) * sum_m P(M=m | aprime, c) * P(Y=1 | a, m, c)
   For binary M and binary C this is: piM*g1 + (1-piM)*g0, summed over c with weights P(c).
   Use the actual confounder support/weights the DGP uses (do NOT collapse C to its mean).
   The exact closed form is in START-HERE-fix-true-effects.md section 1.

2. ADD TESTS in tests/testthat/:
   a. test-true-effects.R: at Sn=Sp=1 (no misclassification), @true_effects$NDE_OR and NIE_OR
      must equal an empirical g-computation on a large sample, tolerance ~0.03.
   b. test-recovery.R: port dev-diagnostics/popcheck_exact_recovery.R logic — build EXACT
      population cells from a known DGP, solve at the true Psi, assert recovered (pi,g1,g0)
      equals truth within 1e-8 and g-comp NDE/NIE equals the oracle within 1e-6. Include a
      DIFFERENTIAL case (Sn1 != Sn0) since the new 2x2 solve must handle it.
   c. test-bound-contains-truth.R: large-n simulated data, true Psi interior to a dense-grid
      sensitivity region, assert the bound CONTAINS the oracle effect on OR, RR, and RD scales.

3. VERIFY:
   - Rscript dev-diagnostics/bne_point_test.R  -> should return ~1.480/1.199 on OR after the
     estimand fix lands (currently 1.495 because the simulator truth is still the buggy one;
     once compute_true_effects is fixed, truth and bound should agree).
   - devtools::test()  (all green, incl. new tests)
   - devtools::check() CLEAN  (CRAN compliance is standing P0 for this package)

4. WRAP UP:
   - Update NEWS.md (move the bug-fix bullets from "in progress" to done).
   - Update .STATUS: clear the `blocked:` line once check() is clean and tests pass.
   - Open PR fix/true-effects-estimand -> main.

NOTE ON ENV: this repo's renv lockfile won't restore under R 4.6 (old Rcpp won't compile).
For dev, just: install.packages(c("S7","dplyr","rlang","ggplot2","pkgload")); pkgload::load_all(".")

DOWNSTREAM: after merge, the manuscripts M2a/M2b sims can run (scripts in
~/projects/research/me-{mediator-bounds,exposure-recall}/code/run_simulations.R) and the
illustrative numbers in their drafts must be regenerated.
