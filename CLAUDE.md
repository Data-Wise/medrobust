# CLAUDE.md for medrobust Package

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⚠️ ACTIVE FIX — two correctness bugs found 2026-06-11 (branch `fix/true-effects-estimand`)

Smoke-testing the differential-misclassification simulations surfaced **two real bugs**.
The manuscript §4.2 derivation is **verified exact** (population recovery to 5e-17); the
faults are in the implementation. **Do not trust `bound_ne()` numbers or the simulator's
`@true_effects` until these land.**

1. **`bound_ne_mediator.R` linear SOLVE is mis-specified** (~lines 114–125). The 3×3 system's
   third row encodes `P01` with the **Y=1 parameterization** (`(1-pi)*g0`) where it needs the
   **Y=0** form (`(1-pi)*(1-g0)`). Result: biased recovery of `(pi, gamma)` → bounds offset
   (NDE overstated, NIE understated; ~0.05–0.12 OR). **Fix:** replace the 3×3 with two clean
   2×2 systems (one per Y stratum). **`bound_ne_exposure.R` audited — NO bug** (uses the
   correct 2×2 matrix inverse; verified to 1e-16). Mediator-path only.
2. **`compute_true_effects()` (simulate_dm_data.R) uses plug-in-mean-M**, not g-computation —
   wrong simulation ground truth (NDE_OR 1.500 vs correct 1.480).

**`compute_effects_from_params()` (utilities_helpers.R) is CORRECT — do NOT change it**
(verified: fed true params it returns the oracle).

**Authoritative docs:**
- Fix plan + drop-in code + test strategy: `PLAN-fix-bound_ne-solve-2026-06-11.md`
- Diagnosis/derivation: `ISSUE-true-effects-estimand-2026-06-11.md`,
  `START-HERE-fix-true-effects.md`
- Verified reference oracles (gitignored): `dev-diagnostics/` —
  `popcheck_exact_recovery.R` (correct solve, 5e-17), `oracle_potential_outcomes.R`,
  `bne_point_test.R` (must return 1.480/1.199 after fix), `instrument_formula_vs_solve.R`
- Downstream impact: manuscripts M2a/M2b — research notes in
  `~/projects/research/me-mediator-bounds/02_Notes/INVESTIGATION-...md`

**Gate:** `devtools::check()` clean (CRAN P0) + new recovery/point tests pass + sims recover
nominal coverage, before merge to `main`.

---

## About This Package

**medrobust** provides tools for conducting sensitivity analysis for causal mediation effects when the exposure or mediator is measured with **differential misclassification**. It derives partial identification bounds that remain valid without requiring validation data.

### Core Mission

Enable robust causal inference for mediation effects in the presence of differential misclassification, providing uncertainty bounds and falsification tests without gold-standard measurements.

### Key Features

- Partial identification bounds for Natural Direct/Indirect Effects (NDE/NIE)
- Data-driven falsification via testable implications
- Sensitivity analysis over user-specified parameter ranges
- Bootstrap inference (percentile and BCa methods)
- S7 OOP system for type safety

---

## Common Development Commands

```r
# Install dependencies and check package
remotes::install_deps(dependencies = TRUE)
rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "error")

# Development workflow
devtools::load_all()
devtools::document()
devtools::test()
```

---

## Coding Standards

### R Version and Style

- **Minimum R version**: 4.1.0 (native pipe `|>` support)
- **OOP Framework**: S7 (modern object system)
- **Style**: tidyverse style guide with native pipe
- **Namespacing**: ALWAYS use explicit `package::function()` for non-base functions

### Naming Conventions

| Type | Convention | Examples |
|------|------------|----------|
| Functions | snake_case | `bound_ne()`, `check_compatibility()` |
| Internal | dot prefix | `.compute_bounds()`, `.validate_input()` |
| S7 Classes | CamelCase | `BoundsResult`, `SensitivityResult` |
| Properties | snake_case | `@lower_bound`, `@upper_bound` |

### Code Organization

```
R/
├── s7-classes.R              # S7 class definitions
├── s3_methods.R              # print / summary / plot methods
├── bound_ne.R                # Main bounds dispatch
├── bound_ne_exposure.R       # Exposure (A*) misclassification solve+bounds
├── bound_ne_mediator.R       # Mediator (M*) misclassification solve+bounds  ⚠️ solve bug (see top)
├── utilities_helpers.R       # compute_effects_from_params (g-computation; VERIFIED correct)
├── check_compatibility.R     # Falsification tests
├── simulate_dm_data.R        # Data generation  ⚠️ compute_true_effects estimand bug (see top)
└── visualization.R           # Sensitivity plots
```
(Filenames verified against `R/` on 2026-06-11.)

---

## Code Architecture

### S7 Classes

| Class | Purpose | Key Properties |
|-------|---------|----------------|
| `BoundsResult` | Partial ID bounds | `lower_bound`, `upper_bound`, `naive_estimate` |
| `SensitivityResult` | Sensitivity analysis | `param_grid`, `bounds_matrix`, `falsified_region` |
| `FalsificationResult` | Falsification tests | `testable_implications`, `falsified`, `p_value` |

### Core Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `bound_ne()` | Compute bounds | `BoundsResult` |
| `check_compatibility()` | Falsification tests | `FalsificationResult` |
| `sensitivity_plot()` | Visualization | ggplot2 plot |
| `simulate_dm_data()` | Data generation | data.frame |

### Misclassification Framework

**Two Scenarios:**
1. **Exposure misclassification**: A* = A + error, error depends on Y
2. **Mediator misclassification**: M* = M + error, error depends on Y

**Parameters:** sn0, sp0, psi_sn, psi_sp (sensitivity/specificity and odds ratios)

---

## Testing Strategy

### Coverage Targets

- **Target**: >85% overall, 100% for bounds computation
- Test bounds accuracy, falsification correctness, bootstrap reproducibility
- Test edge cases: empty sensitivity region, perfect classification

---

## Repository Infrastructure

- **Default branch**: `main` (renamed from `claude/check-measurement-error-...` on 2026-05-09)
- **Integration branch**: `dev` (created 2026-05-09; planning hub, no feature code)
- **Remote**: HTTPS via `gh auth setup-git`
- **CI**: R-CMD-check workflow (`.github/workflows/R-CMD-check.yaml`) added 2026-05-09 via PR #1
  - macOS + Ubuntu: full check including vignettes
  - Windows: package check only (vignette build skipped via `runner.os == 'Windows'` conditional due to quarto issues)
- **Branch protection on `main`**: PR required, no force-push, no deletions; no required status checks yet
- **Dependencies**: CRAN-only (S7, dplyr, ggplot2, stats, utils, rlang, parallel) — no `Remotes:` field needed

---

## Ecosystem Coordination

medrobust is an **application package** in the mediationverse ecosystem.

### Central Planning

Ecosystem coordination managed in `/Users/dt/mediation-planning/`:
- `ECOSYSTEM-COORDINATION.md` - Version matrix, release timeline
- `MONTHLY-CHECKLIST.md` - Health checks

### Related Packages

| Package | Repository | Purpose |
|---------|-----------|---------|
| medfit | https://github.com/data-wise/medfit | Foundation (optional naive estimates) |
| probmed | https://github.com/data-wise/probmed | P_med effect size |
| RMediation | https://github.com/data-wise/rmediation | Confidence intervals |
| medsim | https://github.com/data-wise/medsim | Simulation infrastructure |

### Integration with medfit (optional)

- Can use medfit for naive estimate computation
- Currently computes naive estimates independently
- Future: May use shared bootstrap infrastructure

---

## Key References

- Tofighi (2025): Partial identification under differential misclassification (*Biostatistics*, in preparation)
  - Manuscript source: `~/projects/research/measurement error/` (theory notes + `medrobust R package/` design notes)
- Manski (2003): Partial identification of probability distributions
- Carroll et al. (2006): Measurement error in nonlinear models

---

**Last Updated**: 2026-06-11 (added ACTIVE FIX section; corrected R/ file listing)
