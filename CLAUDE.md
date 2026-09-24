# CLAUDE.md for medrobust Package

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 📦 STATUS — v0.4.1 released (2026-09-23), CRAN-submit-ready

> ⏸ **CRAN submission ON HOLD** until the associated manuscript is submitted (see `.STATUS` `blocked:`).

`dev`/`main` synced at **0.4.1** (release PRs #41 + #43; tag `v0.4.1` = `54812ec`). Strict
incoming check (`R CMD check --as-cran --run-donttest` on the tarball) clean: **0E/0W/1N**
(new-submission only). 0.4.1 = bug fixes (#34, #38, #39) + doc corrections + S3-leftover cleanup;
no new API. win-builder (devel/release/oldrelease) + r-hub re-run on the `v0.4.1` tag
2026-09-24: new-submission NOTE only (`cran-comments.md`). `dev` is ahead of `main` by PR #44
(help-page links), so cut **0.4.2** and re-check before `devtools::submit_cran()` from `main`. Acceptance unblocks **medsim**.
Authoritative state lives in `.STATUS`.

---

## ✅ RESOLVED — two correctness bugs fixed 2026-06-11 (branch `fix/true-effects-estimand`)

Smoke-testing the differential-misclassification simulations surfaced **two real bugs**, now
**both fixed and verified**. The manuscript §4.2 derivation was verified exact (population
recovery to 5e-17); the faults were in the implementation.

1. **`bound_ne_mediator.R` mediator SOLVE** — the mis-specified 3×3 system (whose `P01` row
   used the Y=1 parameterization `(1-pi)*g0` instead of the Y=0 form `(1-pi)*(1-g0)`) was
   replaced with **two per-Y-stratum 2×2 systems** (each solvable iff `Sn_y+Sp_y≠1`). Point
   test moved 1.601→1.495 (→1.480 as n→∞; residual is finite-sample, confirmed by an n-scaling
   sweep). `bound_ne_exposure.R` was audited and is **correct** (closed-form 2×2 inverse,
   verified to 1e-16) — never affected.
2. **`compute_true_effects()` (simulate_dm_data.R)** — replaced plug-in-mean-M/mean-C with
   **Monte-Carlo g-computation over the empirical confounder distribution**. `@true_effects`
   now returns NDE_OR=1.48025 / NIE_OR=1.19940 = oracle (was 1.500).
3. **`odds_to_prob()` (utilities_helpers.R)** — now maps infinite odds → probability 1, so
   perfect classification (`sn=1`/`sp=1`) no longer yields `NaN`.

**`compute_effects_from_params()` (utilities_helpers.R) is CORRECT — was NOT changed**
(verified: fed true params it returns the oracle).

**Verification status (all green):**
- `devtools::test()`: 157 pass / 0 fail / 1 skip (incl. new `test-recovery.R`,
  `test-true-effects.R`, `test-bound-contains-truth.R`).
- `devtools::check()` (`--as-cran`): 0 errors / 0 warnings / 2 benign NOTEs (new submission,
  dev-version string).
- New vignette `vignettes/identification-math.qmd` documents the derivation; registered in
  `_pkgdown.yml`.

**Authoritative docs:** the original fix-planning notes (`PLAN-fix-bound_ne-solve`,
`ISSUE-true-effects-estimand`, `START-HERE-fix-true-effects`, etc.) were **removed from
the repo on 2026-06-21** — they were tracked in the package root, which pkgdown renders to
public HTML; see git history for their content. Reference oracles live in
`dev-diagnostics/`. Downstream: regenerate manuscript M2a/M2b illustrative numbers and
scale sims (`n_grid≥50`) after merge.

**Remaining:** PR `fix/true-effects-estimand` → `main`. (Merged via PR #2, 2026-06-11.)

---

## ✅ RESOLVED — exposure NIE bound fixed (2026-06-11, branch `fix/exposure-nie`)

The **exposure (A\*) path's NIE bound** missed the truth (true 1.199 vs [0.980, 0.991]) while
its NDE bound was correct. **Root cause:** `bound_ne_exposure.R` recovers the **conditional**
`P(A=a | M,Y,C)`, but `compute_effects_from_joint_probs()` consumed those as the **joint**
`P(A,M,Y | C)`, dropping the observed `P(M,Y | C)` weight → the M,Y marginal became effectively
uniform → `P(M|A=1)` and `P(M|A=0)` collapsed toward the same shape → NIE driven to the null
(NDE survives because it fixes the mediator distribution at M(0) in both terms).

**Fix:** multiply the recovered conditional by the observed `P(M=m, Y=y | C)` (M and Y are not
misclassified in the exposure scenario) to form the joint, in `evaluate_param_set()`
(`R/bound_ne_exposure.R`, shared by the serial and parallel paths). The exposure *solve* was
already correct; only the NIE *assembly* was wrong. `compute_effects_from_joint_probs()` is
otherwise correct and was not changed structurally.

**Verified:** point test `dev-diagnostics/bne_point_test_exposure.R` recovers NDE 1.480 / NIE
1.199 within 0.01 (was NIE ~0.99); `smoke2_popcheck_both_paths.R` exposure NIE row now TRUE;
new tests `test-recovery-exposure.R`, `test-bound-contains-truth-exposure.R` pass; mediator path
unaffected. Oracle: `dev-diagnostics/oracle_exposure.R`.

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
| S7 Classes | snake_case | `medrobust_bounds`, `compatibility_test` |
| Properties | snake_case | `@lower_bound`, `@upper_bound` |

### Code Organization

```
R/
├── s7-classes.R              # S7 class definitions
├── s7-methods.R              # S7 print / summary / plot / as.data.frame / as.list methods (no legacy S3 file; see note below)
├── bound_ne.R                # Main bounds dispatch
├── bound_ne_exposure.R       # Exposure (A*) misclassification solve+bounds
├── bound_ne_mediator.R       # Mediator (M*) misclassification solve+bounds  (two per-Y 2×2 systems)
├── utilities_helpers.R       # compute_effects_from_params (g-computation; VERIFIED correct)
├── check_compatibility.R     # Falsification tests
├── simulate_dm_data.R        # Data generation  (compute_true_effects = g-computation)
└── visualization.R           # Sensitivity plots
```
(Filenames verified against `R/` on 2026-06-11; `s3_methods.R` removed 2026-09-23.)

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

- **Default branch**: `main` (renamed from `claude/check-measurement-error-...` on 2026-05-09)
- **Integration branch**: `dev` (created 2026-05-09; planning hub, no feature code)
- **Remote**: HTTPS via `gh auth setup-git`
- **CI**: R-CMD-check workflow (`.github/workflows/R-CMD-check.yaml`) added 2026-05-09 via PR #1
  - macOS + Ubuntu: full check including vignettes
  - Windows: package check only (vignette build skipped via `runner.os == 'Windows'` conditional due to quarto issues)
- **Branch protection on `main`**: PR required, no force-push, no deletions; no required status checks yet
- **Dependencies**: CRAN-only (S7, dplyr, ggplot2, stats, utils, rlang, parallel) — no `Remotes:` field needed
- **Quarto caches**: `.quarto/` is gitignored (local build cache, untracked 2026-09-23). `vignettes/articles/_freeze/` is **tracked on purpose** — `_quarto.yml` sets `freeze: auto`, so the committed results are reused instead of re-executing articles. Never gitignore `_freeze/`.
- **Agent-instruction files**: `CLAUDE.md` (source of truth) and `AGENTS.md` (a short pointer to `CLAUDE.md` for Codex — keep it a pointer, never copy content into it) both live at the root. Each is excluded twice: `.Rbuildignore` (keeps it out of the CRAN tarball) and the *pre-build* step in `.github/workflows/pkgdown.yaml`, which deletes **every root `.md` except README/NEWS/LICENSE/cran-comments** from the CI checkout (pkgdown publishes every root `.md`; no config exclude exists). New root planning docs are therefore kept off the site automatically, but still need an `.Rbuildignore` pattern.
- **Articles are pkgdown-only** (`^vignettes$` in `.Rbuildignore`, no `VignetteBuilder`): never write `vignette("...")` in roxygen, examples, README or articles — it fails in an installed package. Link the site article (`https://data-wise.github.io/medrobust/articles/<name>.html`, `\url{}` in Rd) instead. Fixed twice: README (#37), help pages (#44).
- **Site deploy mirrors the build**: `clean: true` on the gh-pages deploy removes orphaned pages (deleted help topics, renamed articles). It depends on `development: mode: release` in `_pkgdown.yml`; switching back to `auto` would make dev versions build into `docs/dev/` only, and `clean: true` would then wipe the released site at the root.

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

**Last Updated**: 2026-09-24 (pkgdown-only article-link rule, 0.4.2 before submit; tag re-checks recorded; v0.4.1 release; S7 tables, CRAN hold, Quarto + agent-file + pkgdown clean conventions; see `.STATUS`)
