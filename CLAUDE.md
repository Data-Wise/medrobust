# CLAUDE.md for medrobust Package

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
├── s7-methods.R              # S7 methods (print, summary, plot)
├── bound_ne.R                # Main bounds computation
├── bound_nie_exposure.R      # Exposure misclassification
├── bound_nie_mediator.R      # Mediator misclassification
├── check_compatibility.R     # Falsification tests
├── bootstrap.R               # Bootstrap infrastructure
└── sensitivity_plot.R        # Visualization
```

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

**Last Updated**: 2026-05-09
