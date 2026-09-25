# CLAUDE.md for medrobust Package

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 📦 STATUS — v0.4.3 released (2026-09-25), pre-submit checks to re-run

> ⏸ **CRAN submission ON HOLD** until the associated manuscript is submitted (see `.STATUS` `blocked:`).

`main` = tag `v0.4.3` (release PR #49, merge `fdc3e50`). 0.4.3 supersedes 0.4.2, whose bootstrap CIs had
zero width (#47); it also fixes evaluation counts and dropped probe corners in the advanced grid
searches (#48). Local tarball check on `dev` before the release: 1 NOTE (new submission).
Next: re-run the pre-submit checks on the `v0.4.3` tag (local tarball, win-builder ×3, r-hub) and
replace the `v0.4.2` results in `cran-comments.md`; then `devtools::submit_cran()` from `main` once the hold lifts.
Acceptance unblocks **medsim**.
Authoritative state lives in `.STATUS`.

---

## Verified invariants — do not regress

The identification math is verified exact against oracles in `dev-diagnostics/` (population
recovery to 5e-17; target NDE_OR 1.48025 / NIE_OR 1.19940). Keep these properties when editing:

- **Mediator solve** (`R/bound_ne_mediator.R`): two per-Y-stratum 2×2 systems, each solvable iff
  `Sn_y + Sp_y != 1`. The Y=0 row uses `(1-pi)*(1-g0)`, not the Y=1 form `(1-pi)*g0`.
- **Exposure solve** (`R/bound_ne_exposure.R`) returns the *conditional* `P(A=a | M,Y,C)`.
  `evaluate_param_set()` must multiply it by the observed `P(M=m, Y=y | C)` to form the joint
  before `compute_effects_from_joint_probs()`; skipping that weight drives the NIE to the null
  while the NDE still looks right.
- **`compute_effects_from_params()`** and **`compute_true_effects()`** use Monte-Carlo
  g-computation over the empirical confounder distribution; both reproduce the oracle.
- **`odds_to_prob()`** maps infinite odds to probability 1, so `sn = 1` / `sp = 1` is valid.

Regression tests: `test-recovery*.R`, `test-true-effects.R`, `test-bound-contains-truth*.R`.

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
- **Namespacing**: call non-base functions as `package::function()`

### Naming Conventions

| Type | Convention | Examples |
|------|------------|----------|
| Functions | snake_case | `bound_ne()`, `check_compatibility()` |
| Internal | dot prefix for new helpers (most existing ones are unprefixed, marked `@keywords internal`) | `.imbens_manski_ci()`, `.endpoint_se_exposure()` |
| S7 Classes | snake_case | `medrobust_bounds`, `compatibility_test` |
| Properties | snake_case (effect bounds keep their `NIE_`/`NDE_` prefix) | `@NIE_lower`, `@n_compatible` |

### Code Organization

```
R/
├── s7-classes.R / s7-methods.R   # S7 classes; print/summary/plot/as.data.frame/as.list methods
├── bound_ne.R                    # bound_ne() dispatch
├── bound_ne_exposure.R           # exposure (A*) solve + bounds
├── bound_ne_mediator.R           # mediator (M*) solve + bounds
├── bound_ci.R, bootstrap.R       # Imbens–Manski and bootstrap CIs
├── check_compatibility.R         # falsification tests
├── falsification_summary.R, power_analysis.R
├── utilities_helpers.R           # compute_effects_from_params(), joint-prob effects
├── simulate_dm_data.R, simulation.R
├── data.R, gesthtn.R, nhanes_pa.R  # dataset docs
├── visualization.R
└── zzz.R                         # S7::methods_register() at load
```

**S7 + base generics:** S7 objects carry the class `medrobust::<name>`, so a `NAMESPACE` `S3method(generic, <bare name>)` never dispatches. Define methods only with `method(generic, Class)` in `s7-methods.R` (registered at load by `S7::methods_register()` in `zzz.R`); document them with a standalone `@name generic.class` block on `NULL`, in Rd syntax, with no `\usage`.

---

## Code Architecture

### S7 Classes

All defined in `R/s7-classes.R` with `package = "medrobust"`, so their S3 class is
`medrobust::<name>` (see the S7 + base generics note above). Names are snake_case.

| Class | Purpose | Key properties |
|-------|---------|----------------|
| `medrobust_bounds` | Partial-ID bounds from `bound_ne()` | `NIE_lower`/`NIE_upper`, `NDE_lower`/`NDE_upper`, `compatible_sets`, `n_compatible`, `falsified_proportion`, `analytic_ci`, `bootstrap_results`, `reason` |
| `compatibility_test` | One falsification test from `check_compatibility()` | `compatible`, `psi`, `n_constraints_*`, `violated_constraints`, `implied_probabilities`, `stratum_details`, `reason` |
| `sensitivity_region` | Parameter ranges (`sensitivity_region()`) | `sn0_range`, `sp0_range`, `psi_sn_range`, `psi_sp_range` |
| `bootstrap_results` | Bootstrap CIs for bound endpoints | CI vectors, `method`, `n_reps` |
| `falsification_summary` | Summary over a parameter grid | — |
| `simulated_dm_data` | Output of `simulate_dm_data()` | `observed`, `true_effects`, … |
| `power_analysis_result` | Falsification power analysis | — |

### Core Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `bound_ne()` | Compute bounds | `medrobust_bounds` |
| `bound_ci()` | Imbens–Manski CIs for bounds | list |
| `check_compatibility()` | Falsification test | `compatibility_test` |
| `sensitivity_plot()` | Visualization | ggplot2 plot |
| `simulate_dm_data()` | Data generation | `simulated_dm_data` (data in `@observed`) |

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

- **Branches**: `main` (default, PR-only) ← `dev` (integration) ← `feature/*`/`fix/*` worktrees
- **Remote**: HTTPS via `gh auth setup-git`
- **CI**: `.github/workflows/R-CMD-check.yaml` on macOS, Ubuntu, Windows (release R); `--as-cran` except
  on Windows. `pkgdown.yaml` builds and deploys the site; `rhub.yaml` is manual (`workflow_dispatch`).
- **Branch protection on `main`**: PR required, no force-push, no deletions; required check `ubuntu-latest (release)` with strict up-to-date, so a release PR may need `gh pr update-branch`
- **Dependencies**: CRAN-only (S7, dplyr, ggplot2, stats, utils, rlang, parallel) — no `Remotes:` field needed
- **Quarto caches**: `.quarto/` is gitignored (local build cache, untracked 2026-09-23). `vignettes/articles/_freeze/` is **tracked on purpose** — `_quarto.yml` sets `freeze: auto`, so the committed results are reused instead of re-executing articles. Never gitignore `_freeze/`.
- **Agent-instruction files**: `CLAUDE.md` (source of truth) and `AGENTS.md` (a short pointer to `CLAUDE.md` for Codex — keep it a pointer, never copy content into it) both live at the root. Each is excluded twice: `.Rbuildignore` (keeps it out of the CRAN tarball) and the *pre-build* step in `.github/workflows/pkgdown.yaml`, which deletes **every root `.md` except README/NEWS/LICENSE/cran-comments** from the CI checkout (pkgdown publishes every root `.md`; no config exclude exists). New root planning docs are therefore kept off the site automatically, but still need an `.Rbuildignore` pattern.
- **Articles are pkgdown-only** (`^vignettes$` in `.Rbuildignore`, no `VignetteBuilder`): never write `vignette("...")` in roxygen, examples, README or articles — it fails in an installed package. Link the site article (`https://data-wise.github.io/medrobust/articles/<name>.html`, `\url{}` in Rd) instead.
- **Site deploy mirrors the build**: `clean: true` on the gh-pages deploy removes orphaned pages (deleted help topics, renamed articles). It depends on `development: mode: release` in `_pkgdown.yml`; switching back to `auto` would make dev versions build into `docs/dev/` only, and `clean: true` would then wipe the released site at the root.

---

## Ecosystem Coordination

medrobust is an **application package** in the mediationverse ecosystem.

### Central Planning

Ecosystem coordination managed in `~/projects/r-packages/mediation-planning/`:
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

**Last Updated**: 2026-09-25 (history: `git log -- CLAUDE.md`; project state: `.STATUS`)
