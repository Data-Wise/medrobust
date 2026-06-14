# SPEC — bound_ne robustness under severe misclassification

**Branch:** `feature/bound-ne-robust` (off `feature/cran-prep`)
**Date:** 2026-06-14
**Origin:** M2a coverage pilot (`docs/FINDING-pilot-2026-06-14.md` in the M2a repo) exposed two
failure modes at the high-misclassification baseline (`sn0 = sp0 = 0.70`), absent at low (0.90).

## Problem

1. **Bug (a) — lost reps.** ~10–15% of pilot replicates abort inside `bound_ne` with
   `stop("No compatible parameter sets found. Consider widening sensitivity_region.")`. Under
   severe misclassification the entire sensitivity grid is rejected as incompatible (recovered
   pi/gamma ∉ [0,1]); the 2×2 solve itself is well-conditioned (not a singularity). A hard error
   loses the rep instead of letting the simulation record it.
2. **Bug (b) — silent NA.** `@analytic_ci` endpoints come back NA on some reps with no signal.
   `.endpoint_se()` returns `sd(all-NA) = NA` (`R/bound_ci.R:170`) when resamples are infeasible;
   the NA propagates unguarded through `.imbens_manski_ci()` (`R/bound_ci.R:63–71`) into
   `ci_lower/ci_upper`. The outer `tryCatch(..., error=)` at `R/bound_ne.R:338` only catches
   *errors*, so an NA *return* lands silently in the result.

## Decision

Replace silent/aborting failure with **explicit, documented degradation**:
- Bug (a): return a valid `medrobust_bounds` object with **NA bounds + a machine-readable
  `reason`** and a signaled `medrobust_infeasible` condition — no `stop()`.
- Bug (b): **guard `is.finite`** on the endpoint SEs; emit documented NA CI endpoints with a
  per-effect `reason` rather than opaque NA.

## Changes

### FixA — graceful infeasible result (files: `R/s7-classes.R`, `R/bound_ne_mediator.R`, `R/bound_ne_exposure.R`, `R/bound_ne.R`)

- **`R/s7-classes.R`**: add to `medrobust_bounds` a property
  `reason = new_property(class = class_any, default = NULL)` (mirrors the existing `reason` on the
  `compatibility_test` class). Validator unchanged — NA bounds already pass since `NA > NA` is
  falsy; confirm `n_compatible = 0L` satisfies the non-negative / `<= n_evaluated` checks.
- **`R/bound_ne_mediator.R:331`** and **`R/bound_ne_exposure.R:249` and `:311`**: replace each
  `stop("No compatible parameter sets found...")` with a `return(list(...))` of NA bounds:
  `NIE_lower/upper = NA_real_`, `NDE_lower/upper = NA_real_`, `compatible_sets = data.frame()`,
  `n_compatible = 0L`, `n_evaluated = <count in scope>`, `falsified_proportion = 1.0`,
  `naive_estimates = naive_estimates`, `reason = "infeasible_no_compatible_sets"`. Match the exact
  key set the dispatcher already consumes at `R/bound_ne.R:316–333`.
- **`R/bound_ne.R`**: after the dispatcher returns and before/at the `medrobust_bounds(...)`
  constructor: if `bounds_result$n_compatible == 0`, `signalCondition(structure(list(message =
  "No compatible parameter sets found. Consider widening sensitivity_region.", call = match.call()),
  class = c("medrobust_infeasible", "condition")))`, then continue. Add
  `reason = bounds_result$reason` to the constructor call.
- **`R/s7-methods.R`** (cosmetic, optional): when `n_compatible == 0`, print a one-line
  `Infeasible: no compatible parameter sets (reason: ...)` banner.

### FixB — analytic-CI NA guard + infeasible short-circuit (file: `R/bound_ci.R`, owned solely by FixB)

- `.endpoint_se()` (~L162–171): count finite resamples; if `< 2` finite return `NA_real_` and make
  the failure count available for the reason string.
- Assembly (~L219–227): before `.imbens_manski_ci(...)`, guard
  `if (!is.finite(seL) || !is.finite(seU))` → set `ci_lower/ci_upper = NA_real_` and record a
  per-effect `reason` (e.g. `"endpoint_se_na: resamples infeasible"`).
- `.imbens_manski_ci()` (~L63–71): NA-safe — if any SE is NA/non-finite, return
  `c(lower = NA_real_, upper = NA_real_)` instead of `max(NA, ...)` → NaN math.
- Entry of `bound_ci()`: if the bounds object is infeasible (`n_compatible == 0`), short-circuit to
  an `analytic_ci` of NA endpoints with `reason = "infeasible_no_compatible_sets"` — skip resampling.

## Regression tests (`tests/testthat/`)

- `test-bound-ne-infeasible.R`: high-misclass + tight region forcing an empty grid → result is
  `medrobust_bounds`, bounds NA, `@reason == "infeasible_no_compatible_sets"`, `n_compatible == 0`,
  `medrobust_infeasible` condition signaled (`withCallingHandlers`). Assert it does **not** error.
- `test-bound-ci-na-guard.R`: scenario yielding NA endpoint SE → `@analytic_ci$NDE/$NIE` endpoints
  NA with a reason, `is.finite` guard fires, no crash.
- Sanity: a low-misclass case where the infeasible path is **not** triggered (finite bounds).

## Acceptance

- Pilot reproducer: `errors 0/N` (infeasible reps now NA-results); NA-CI reps carry a reason.
- `devtools::test()` green incl. the two new files.
- `R CMD check --as-cran`: 0 errors / 0 warnings; only the known new-submission/dev NOTEs.
- Additive only — no behavior change for feasible inputs.
