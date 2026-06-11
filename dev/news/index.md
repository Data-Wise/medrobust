# Changelog

## medrobust (development version)

### Bug fixes (2026-06-11)

- **(critical)
  [`bound_ne()`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md)
  mediator solve mis-specified.** The 3×3 linear system in
  `bound_ne_mediator.R` built the `P01` (Y=0) equation with the Y=1
  parameterization, biasing recovery of the true conditional
  probabilities and therefore the NDE/NIE bounds (NDE overstated, NIE
  understated, by ~0.05–0.12 on the OR scale; worst under strong
  differential error). Replaced with two per-outcome 2×2 systems
  (manuscript §4.2), each solvable iff `Sn_y + Sp_y ≠ 1`. The exposure
  path (`bound_ne_exposure.R`) was audited and found CORRECT
  (closed-form 2×2 matrix inverse; verified to ~1e-16) — not affected.
- **[`simulate_dm_data()`](https://data-wise.github.io/medrobust/dev/reference/simulate_dm_data.md)
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

- [`bound_ne()`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md):
  Main function for computing partial identification bounds for Natural
  Direct Effects (NDE) and Natural Indirect Effects (NIE)
- Support for both exposure misclassification and mediator
  misclassification
- Data-driven falsification via testable implications
- [`check_compatibility()`](https://data-wise.github.io/medrobust/dev/reference/check_compatibility.md):
  Test specific misclassification parameters against observed data
- [`sensitivity_plot()`](https://data-wise.github.io/medrobust/dev/reference/sensitivity_plot.md):
  Publication-quality sensitivity analysis visualizations
- [`falsification_summary()`](https://data-wise.github.io/medrobust/dev/reference/falsification_summary.md):
  Diagnostic summaries of falsified parameter regions
- [`simulate_dm_data()`](https://data-wise.github.io/medrobust/dev/reference/simulate_dm_data.md):
  Generate synthetic data with differential misclassification
- [`extract_bounds()`](https://data-wise.github.io/medrobust/dev/reference/extract_bounds.md):
  Extract bounds at specific parameter values
- [`compare_bounds()`](https://data-wise.github.io/medrobust/dev/reference/compare_bounds.md):
  Compare bounds across multiple analyses
- Bootstrap confidence intervals for bounds

#### Documentation

- Comprehensive package documentation with roxygen2
- Getting started vignette
- Example datasets: `arsenic_synthetic` and `simulation_results`
- S3 methods for clean output:
  [`print.medrobust_bounds()`](https://data-wise.github.io/medrobust/dev/reference/print.medrobust_bounds.md)
  and
  [`summary.medrobust_bounds()`](https://data-wise.github.io/medrobust/dev/reference/summary.medrobust_bounds.md)

#### Testing

- Basic unit tests with testthat
- Input validation for all main functions

#### Notes

- This is the initial development version
- Core algorithms for testable implications and identification formulas
  require user implementation based on their Claude project “measurement
  error”
- Placeholder implementations are marked with TODO comments
