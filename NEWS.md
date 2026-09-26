# medrobust (development version)

## Bug fixes

* `grid_method = "adaptive"` refined around the compatible coarse points by
  widening Sn0/Sp0 by 10% and clamping only to [0, 1], so it evaluated values
  outside the user's sensitivity region (for example Sn0 = 1 in a region that
  stops at 0.99) and let them into the bounds. The refinement now stays inside
  the region, which can change the reported bounds.
* `falsification_summary()` computed each bin's falsification rate by spreading
  `n_evaluated` evenly over the bins and clipping the result to [0, 1], so bins
  the search never visited showed as 100% falsified, and a fit with points
  outside the region failed with "some 'x' not counted". Rates are now the share
  of the parameter sets evaluated in each bin that the data falsified (from
  `evaluated_sets`), with `NA` for empty bins; the per-bin counts are returned
  as `n_evaluated` and `n_compatible`. Sets on a range's upper edge are no
  longer dropped from the joint grid.

# medrobust 0.4.3 (2026-09-25)

## Bug fixes

* Bootstrap confidence intervals from `bound_ne(bootstrap = TRUE)` had zero
  width. The Latin hypercube search called `set.seed(42)` on the global
  random-number stream, so every bootstrap replicate drew the same resample.
  The search still uses a fixed design, but now restores the caller's RNG state,
  so `bound_ne()` no longer resets the random stream in your session.
* `compute_bound_se()`, `bootstrap_width_summary()` and
  `plot_bootstrap_distribution()` failed on the bootstrap results stored by
  `bound_ne()` (an S7 object). They now accept it, as well as the list from
  `compute_bootstrap_ci()`.
* `extract_falsified_region()` returned wrong sets under the default Latin
  hypercube search: it compared the compatible sets against a rebuilt regular
  grid they never lay on. `bound_ne()` now records every evaluated parameter set
  with its verdict (new `evaluated_sets` property), and
  `extract_falsified_region()` returns the ones the data falsified.
* With `grid_method = "auto"` on the mediator path, a region whose 16 corners
  were all compatible was reported as infeasible (`NA` bounds). It now falls
  back to the regular grid, as the exposure path already did.
* `test_multiple_hypotheses()` failed on an unnamed `psi_list`; unnamed entries
  are now labeled `H1`, `H2`, ....
* With `grid_method = "auto"` or `"binary"`, the 16 corners of the sensitivity
  region that the search probes first were evaluated and then discarded, so a
  compatible corner never entered the bounds. They now do. On the mediator path
  this can widen the reported bounds (in one test, the NIE lower bound moved
  from 1.124 to 1.098); the old bounds were too narrow.
* `n_evaluated`, and hence `falsified_proportion`, were estimates for the
  advanced search methods, and badly wrong on the mediator path: `"adaptive"`
  reported about 5.3 million evaluations for 10,081 (falsified proportion 0.998
  instead of 0.153), and `"binary"` and `"auto"` reported a falsified proportion
  of 0. Both are now counted from the recorded evaluations, on both paths.

## Documentation

* Help pages written with Markdown syntax (backticks, `[fn()]` links, `*emphasis*`)
  showed it literally, because roxygen Markdown is off in this package. They now
  use Rd markup. The `bound_ne()` references no longer contain the placeholder
  "[Author] (2025)".
* Examples added to the help pages of `bound_ci()`, `sensitivity_region()`,
  `as_sensitivity_region()`, `format_effect()`, `extract_bounds()`,
  `test_multiple_hypotheses()` and `new_falsification_summary()`.

# medrobust 0.4.2 (2026-09-24)

## Documentation

* The help pages for `gesthtn`, `nhanes_pa` and `heals_data` no longer call
  `vignette()`: the articles are published only on the package website, so
  those calls failed in an installed package. They now link to the website
  articles.

# medrobust 0.4.1 (2026-09-23)

## Bug fixes

* `check_compatibility()` can now report an incompatible result. Every
  `compatible = FALSE` verdict, and every call with `return_details = FALSE`,
  used to abort in the `compatibility_test` validator, because
  `implied_probabilities` and `stratum_details` were set to `NULL` but typed as
  lists. Both properties now accept a list or `NULL`, matching their declared
  `NULL` default (#34).
* `test_multiple_hypotheses()` read the `compatibility_test` result with `$`
  instead of `@`; it now returns its data frame of verdicts.
* `check_compatibility()` now tests the two mediator-path gamma constraints.
  Both gammas were computed with a numerator summed over the outcome, which
  equals the denominator, so they were identically 1: only `pi_a` was ever
  checked, and `implied_probabilities` reported `gamma_a0 = gamma_a1 = 1` for
  every compatible stratum with `pi_a` away from 0 and 1. A `psi` that
  `bound_ne()` rejects could therefore be reported compatible. The cut-off
  below which a gamma is treated as undefined is now fixed at 1e-6, as in
  `bound_ne()`, instead of following `tolerance`, so `tolerance = 0` no longer
  fails the check with a spurious "Matrix inversion failed" and a large
  `tolerance` no longer skips it (#39).

## Documentation

* `?as.data.frame.medrobust_bounds` now documents the columns
  `as.data.frame()` actually returns (including `NIE_width`/`NDE_width` and
  the bootstrap interval columns). It previously described an unused legacy
  method with an `n` column that was never produced.
* The README Quick Start ran against a dataset that does not ship
  (`arsenic_synthetic`); it now uses the maintained `bound_ne()` example, and
  the README links the website articles instead of `vignette()` calls
  (articles are published on the pkgdown site, not installed as vignettes).

# medrobust 0.4.0 (2026-06-15)

## New features

* New example dataset `nhanes_pa`: the exposure-side mirror of `gesthtn` — a
  pooled public-domain NHANES 2015–2018 sample (N = 9,906) illustrating
  partial-identification bounds when the **exposure** is differentially
  misclassified (self-reported physical inactivity) while the mediator
  (laboratory-measured hs-CRP) is error-free. The headline finding mirrors
  `gesthtn` from the other side: the natural direct effect is robust to mild
  differential reporting but its Imbens–Manski interval covers the null once
  reporting accuracy is allowed to depend strongly on the outcome. See
  `?nhanes_pa` and `vignette("nhanes_pa-bounds")`.

# medrobust 0.3.0 (2026-06-14)

## New features

* New example dataset `gesthtn`: a 5,000-row public-domain sample (NCHS Natality
  2021) illustrating partial-identification bounds for a differentially
  misclassified binary mediator (gestational hypertension on the birth
  certificate). See `?gesthtn` and `vignette("gesthtn-bounds")`.

## Robustness

* `bound_ne()` now **degrades gracefully** when no compatible parameter sets are
  found under severe misclassification. Instead of aborting with an error, it
  returns a `medrobust_bounds` object with `NA` bounds and a machine-readable
  `@reason` (`"infeasible_no_compatible_sets"`), and signals a
  `medrobust_infeasible` condition that callers (e.g. simulations) can capture —
  so an infeasible replicate is recorded rather than lost.
* New `@reason` property on `medrobust_bounds`; `print()` shows an infeasible
  banner when applicable.
* `bound_ci()` (analytic Imbens–Manski CIs) no longer returns **silent** `NA`
  endpoints: a non-finite endpoint standard error (too few feasible bootstrap
  resamples) now yields documented `NA` CI endpoints with a per-effect reason,
  and `.imbens_manski_ci()` is NA-safe. Confidence intervals for feasible inputs
  are unchanged.

# medrobust 0.2.1 (2026-06-12)

CRAN-preparation release (documentation only; no change to computed results).

* `DESCRIPTION`: explained the `BCa` acronym and added method references in the
  `authors (year) <doi:...>` / `<ISBN:...>` form (Manski, 2003; Imbens & Manski, 2004).
* Added `\value` documentation to all exported S7 classes (`medrobust_bounds`,
  `bootstrap_results`, `compatibility_test`, `power_analysis_result`, `simulated_dm_data`).
* Replaced `\dontrun{}` with `\donttest{}` for runnable examples and rewrote the example
  code so each executes against small simulated data; the computationally intensive
  `power_analysis()` example remains in `\dontrun{}`. Removed an example that wrote a file
  to the working directory.

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

# medrobust 0.1.0 (2025-06-01)

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
