# Changelog

## medrobust 0.4.0 (2026-06-15)

### New features

- New example dataset `nhanes_pa`: the exposure-side mirror of `gesthtn`
  — a pooled public-domain NHANES 2015–2018 sample (N = 9,906)
  illustrating partial-identification bounds when the **exposure** is
  differentially misclassified (self-reported physical inactivity) while
  the mediator (laboratory-measured hs-CRP) is error-free. The headline
  finding mirrors `gesthtn` from the other side: the natural direct
  effect is robust to mild differential reporting but its Imbens–Manski
  interval covers the null once reporting accuracy is allowed to depend
  strongly on the outcome. See
  [`?nhanes_pa`](https://data-wise.github.io/medrobust/reference/nhanes_pa.md)
  and
  [`vignette("nhanes_pa-bounds")`](https://data-wise.github.io/medrobust/articles/nhanes_pa-bounds.md).

## medrobust 0.3.0 (2026-06-14)

### New features

- New example dataset `gesthtn`: a 5,000-row public-domain sample (NCHS
  Natality
  2021. illustrating partial-identification bounds for a differentially
        misclassified binary mediator (gestational hypertension on the
        birth certificate). See
        [`?gesthtn`](https://data-wise.github.io/medrobust/reference/gesthtn.md)
        and
        [`vignette("gesthtn-bounds")`](https://data-wise.github.io/medrobust/articles/gesthtn-bounds.md).

### Robustness

- [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
  now **degrades gracefully** when no compatible parameter sets are
  found under severe misclassification. Instead of aborting with an
  error, it returns a `medrobust_bounds` object with `NA` bounds and a
  machine-readable `@reason` (`"infeasible_no_compatible_sets"`), and
  signals a `medrobust_infeasible` condition that callers
  (e.g. simulations) can capture — so an infeasible replicate is
  recorded rather than lost.
- New `@reason` property on `medrobust_bounds`;
  [`print()`](https://rdrr.io/r/base/print.html) shows an infeasible
  banner when applicable.
- [`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md)
  (analytic Imbens–Manski CIs) no longer returns **silent** `NA`
  endpoints: a non-finite endpoint standard error (too few feasible
  bootstrap resamples) now yields documented `NA` CI endpoints with a
  per-effect reason, and `.imbens_manski_ci()` is NA-safe. Confidence
  intervals for feasible inputs are unchanged.

## medrobust 0.2.1 (2026-06-12)

CRAN-preparation release (documentation only; no change to computed
results).

- `DESCRIPTION`: explained the `BCa` acronym and added method references
  in the `authors (year) <doi:...>` / `<ISBN:...>` form (Manski, 2003;
  Imbens & Manski, 2004).
- Added `\value` documentation to all exported S7 classes
  (`medrobust_bounds`, `bootstrap_results`, `compatibility_test`,
  `power_analysis_result`, `simulated_dm_data`).
- Replaced `\dontrun{}` with `\donttest{}` for runnable examples and
  rewrote the example code so each executes against small simulated
  data; the computationally intensive
  [`power_analysis()`](https://data-wise.github.io/medrobust/reference/power_analysis.md)
  example remains in `\dontrun{}`. Removed an example that wrote a file
  to the working directory.

## medrobust 0.2.0 (2026-06-12)

This release fixes three correctness bugs in the
differential-misclassification bounds and adds confidence intervals for
the partial-identification bounds.

### New features (2026-06-12)

- **[`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md)
  — confidence intervals for the partial-identification bounds.** The
  raw estimated bound `[L̂, Û]` is consistent but is not a confidence
  set; when the identified set is narrow relative to endpoint sampling
  uncertainty it under-covers the true effect at small samples
  (e.g. exposure NDE coverage ~0.09 at n=500).
  [`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md)
  applies the Imbens & Manski (2004) construction, widening the
  endpoints by standard errors obtained by re-evaluating the effect at
  the fixed optimal sensitivity parameter on resampled data (no grid
  search per replicate). This restores approximately nominal coverage at
  small n (exposure NDE 0.09→0.95, NIE 0.12→0.93; mediator NDE
  0.19→0.96, NIE 0.39→0.99 at n=500), for both the exposure and mediator
  paths. See the *Identification Mathematics* vignette.

### Bug fixes (2026-06-11)

- **(critical)
  [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
  mediator solve mis-specified.** The 3×3 linear system in
  `bound_ne_mediator.R` built the `P01` (Y=0) equation with the Y=1
  parameterization, biasing recovery of the true conditional
  probabilities and therefore the NDE/NIE bounds (NDE overstated, NIE
  understated, by ~0.05–0.12 on the OR scale; worst under strong
  differential error). Replaced with two per-outcome 2×2 systems
  (manuscript §4.2), each solvable iff `Sn_y + Sp_y ≠ 1`. The exposure
  path (`bound_ne_exposure.R`) was audited and found CORRECT
  (closed-form 2×2 matrix inverse; verified to ~1e-16) — not affected.
- **[`simulate_dm_data()`](https://data-wise.github.io/medrobust/reference/simulate_dm_data.md)
  true effects.** `compute_true_effects()` computed natural effects by
  plugging E\[M\] (and mean-C) into the nonlinear outcome model rather
  than averaging the outcome over the mediator and confounder
  distributions (g-computation). This biased the simulation ground truth
  (`NDE_OR` ~1.500 vs the correct ~1.480). Corrected to Monte-Carlo
  g-computation over the empirical confounder distribution; affects the
  simulator’s `@true_effects` only (the bounds themselves already
  targeted the correct estimand).
- **`odds_to_prob()` boundary.** Perfect classification (`sn = 1` or
  `sp = 1`) produced infinite odds and a downstream `NaN`; the helper
  now maps infinite odds to probability 1, so no-misclassification
  settings (e.g. `sn0 = sp0 = 1`) work correctly.
- Added regression tests: exact-population recovery at the true Ψ
  (non-differential and differential), agreement of `@true_effects` with
  an independent potential-outcome oracle, and bound-contains-truth on
  large-n simulated data.
- Added the *Identification Mathematics* vignette documenting the
  estimand, the mediator two-2×2 identification, the exposure closed
  form, and the finite-sample convergence evidence.

### Bug fixes (exposure NIE, 2026-06-11)

- **(critical) Exposure (A\*) NIE bound was incorrect — fixed.** With
  `misclassified_variable = "exposure"`, the NIE bound did not contain
  the true NIE even at the population limit with the true Ψ in-region
  (true 1.199 vs bound \[0.980, 0.991\]); the NDE bound was fine. Root
  cause: `bound_ne_exposure.R` recovers the **conditional**
  `P(A=a | M,Y,C)`, but the downstream g-computation
  (`compute_effects_from_joint_probs`) consumed those values as the
  **joint** `P(A,M,Y | C)`, dropping the observed `P(M,Y | C)` weight.
  That made the mediator marginal effectively uniform, collapsing
  `P(M|A=1)` and `P(M|A=0)` toward the same shape and driving NIE toward
  the null while leaving NDE (which fixes the mediator distribution at
  M(0)) intact. Fix: multiply the recovered conditional by the observed
  `P(M=m, Y=y | C)` (M and Y are not misclassified in the exposure
  scenario) to form the joint. The exposure *solve* (class-probability
  inverse) was already correct; only the NIE *assembly* was wrong. Point
  test now recovers NDE 1.480 / NIE 1.199 within 0.01; mediator path
  unaffected.

### Ecosystem Notes

- Part of the mediationverse ecosystem for mediation analysis
- Optionally integrates with medfit for naive estimates
- See [Ecosystem
  Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md)
  for guidelines

------------------------------------------------------------------------

## medrobust 0.1.0

### Initial Release (2025-Q2)

#### Major Features

- [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md):
  Main function for computing partial identification bounds for Natural
  Direct Effects (NDE) and Natural Indirect Effects (NIE)
- Support for both exposure misclassification and mediator
  misclassification
- Data-driven falsification via testable implications
- [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md):
  Test specific misclassification parameters against observed data
- [`sensitivity_plot()`](https://data-wise.github.io/medrobust/reference/sensitivity_plot.md):
  Publication-quality sensitivity analysis visualizations
- [`falsification_summary()`](https://data-wise.github.io/medrobust/reference/falsification_summary.md):
  Diagnostic summaries of falsified parameter regions
- [`simulate_dm_data()`](https://data-wise.github.io/medrobust/reference/simulate_dm_data.md):
  Generate synthetic data with differential misclassification
- [`extract_bounds()`](https://data-wise.github.io/medrobust/reference/extract_bounds.md):
  Extract bounds at specific parameter values
- [`compare_bounds()`](https://data-wise.github.io/medrobust/reference/compare_bounds.md):
  Compare bounds across multiple analyses
- Bootstrap confidence intervals for bounds

#### Documentation

- Comprehensive package documentation with roxygen2
- Getting started vignette
- Example datasets: `arsenic_synthetic` and `simulation_results`
- S3 methods for clean output:
  [`print.medrobust_bounds()`](https://data-wise.github.io/medrobust/reference/print.medrobust_bounds.md)
  and
  [`summary.medrobust_bounds()`](https://data-wise.github.io/medrobust/reference/summary.medrobust_bounds.md)

#### Testing

- Basic unit tests with testthat
- Input validation for all main functions

#### Notes

- This is the initial development version
- Core algorithms for testable implications and identification formulas
  require user implementation based on their Claude project “measurement
  error”
- Placeholder implementations are marked with TODO comments
