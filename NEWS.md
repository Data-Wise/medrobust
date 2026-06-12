# medrobust 0.2.0 (2026-06-12)

This release fixes three correctness bugs in the differential-misclassification bounds and
adds confidence intervals for the partial-identification bounds.

## New features (2026-06-12)

* **`bound_ci()` — confidence intervals for the partial-identification bounds.** The raw
  estimated bound `[L̂, Û]` is consistent but is not a confidence set; when the identified
  set is narrow relative to endpoint sampling uncertainty it under-covers the true effect at
  small samples (e.g. exposure NDE coverage ~0.09 at n=500). `bound_ci()` applies the
  Imbens & Manski (2004) construction, widening the endpoints by standard errors obtained by
  re-evaluating the effect at the fixed optimal sensitivity parameter on resampled data (no
  grid search per replicate). This restores approximately nominal coverage at small n
  (exposure NDE 0.09→0.95, NIE 0.12→0.93; mediator NDE 0.19→0.96, NIE 0.39→0.99 at n=500),
  for both the exposure and mediator paths. See the *Identification Mathematics* vignette.

## Bug fixes (2026-06-11)

* **(critical) `bound_ne()` mediator solve mis-specified.** The 3×3 linear system in
  `bound_ne_mediator.R` built the `P01` (Y=0) equation with the Y=1 parameterization,
  biasing recovery of the true conditional probabilities and therefore the NDE/NIE bounds
  (NDE overstated, NIE understated, by ~0.05–0.12 on the OR scale; worst under strong
  differential error). Replaced with two per-outcome 2×2 systems (manuscript §4.2), each
  solvable iff `Sn_y + Sp_y ≠ 1`. The exposure path (`bound_ne_exposure.R`) was audited and
  found CORRECT (closed-form 2×2 matrix inverse; verified to ~1e-16) — not affected.
* **`simulate_dm_data()` true effects.** `compute_true_effects()` computed natural effects by
  plugging E[M] (and mean-C) into the nonlinear outcome model rather than averaging the
  outcome over the mediator and confounder distributions (g-computation). This biased the
  simulation ground truth (`NDE_OR` ~1.500 vs the correct ~1.480). Corrected to Monte-Carlo
  g-computation over the empirical confounder distribution; affects the simulator's
  `@true_effects` only (the bounds themselves already targeted the correct estimand).
* **`odds_to_prob()` boundary.** Perfect classification (`sn = 1` or `sp = 1`) produced
  infinite odds and a downstream `NaN`; the helper now maps infinite odds to probability 1,
  so no-misclassification settings (e.g. `sn0 = sp0 = 1`) work correctly.
* Added regression tests: exact-population recovery at the true Ψ (non-differential and
  differential), agreement of `@true_effects` with an independent potential-outcome oracle,
  and bound-contains-truth on large-n simulated data.
* Added the *Identification Mathematics* vignette documenting the estimand, the mediator
  two-2×2 identification, the exposure closed form, and the finite-sample convergence
  evidence.

## Bug fixes (exposure NIE, 2026-06-11)

* **(critical) Exposure (A\*) NIE bound was incorrect — fixed.** With
  `misclassified_variable = "exposure"`, the NIE bound did not contain the true NIE even at the
  population limit with the true Ψ in-region (true 1.199 vs bound [0.980, 0.991]); the NDE bound
  was fine. Root cause: `bound_ne_exposure.R` recovers the **conditional** `P(A=a | M,Y,C)`, but
  the downstream g-computation (`compute_effects_from_joint_probs`) consumed those values as the
  **joint** `P(A,M,Y | C)`, dropping the observed `P(M,Y | C)` weight. That made the mediator
  marginal effectively uniform, collapsing `P(M|A=1)` and `P(M|A=0)` toward the same shape and
  driving NIE toward the null while leaving NDE (which fixes the mediator distribution at M(0))
  intact. Fix: multiply the recovered conditional by the observed `P(M=m, Y=y | C)` (M and Y are
  not misclassified in the exposure scenario) to form the joint. The exposure *solve*
  (class-probability inverse) was already correct; only the NIE *assembly* was wrong. Point test
  now recovers NDE 1.480 / NIE 1.199 within 0.01; mediator path unaffected.

## Ecosystem Notes

* Part of the mediationverse ecosystem for mediation analysis
* Optionally integrates with medfit for naive estimates
* See [Ecosystem Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md) for guidelines

---

# medrobust 0.1.0

## Initial Release (2025-Q2)

### Major Features

* `bound_ne()`: Main function for computing partial identification bounds for Natural Direct Effects (NDE) and Natural Indirect Effects (NIE)
* Support for both exposure misclassification and mediator misclassification
* Data-driven falsification via testable implications
* `check_compatibility()`: Test specific misclassification parameters against observed data
* `sensitivity_plot()`: Publication-quality sensitivity analysis visualizations
* `falsification_summary()`: Diagnostic summaries of falsified parameter regions
* `simulate_dm_data()`: Generate synthetic data with differential misclassification
* `extract_bounds()`: Extract bounds at specific parameter values
* `compare_bounds()`: Compare bounds across multiple analyses
* Bootstrap confidence intervals for bounds

### Documentation

* Comprehensive package documentation with roxygen2
* Getting started vignette
* Example datasets: `arsenic_synthetic` and `simulation_results`
* S3 methods for clean output: `print.medrobust_bounds()` and `summary.medrobust_bounds()`

### Testing

* Basic unit tests with testthat
* Input validation for all main functions

### Notes

* This is the initial development version
* Core algorithms for testable implications and identification formulas require user implementation based on their Claude project "measurement error"
* Placeholder implementations are marked with TODO comments
