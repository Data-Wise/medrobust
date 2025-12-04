# CLAUDE.md for medrobust Package

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Package

**medrobust** provides tools for conducting sensitivity analysis for causal mediation effects when the exposure or mediator is measured with **differential misclassification** (e.g., recall bias, outcome-dependent measurement error). Unlike existing measurement error correction methods that assume non-differential error or require validation data, medrobust derives partial identification bounds that remain valid without gold-standard measurements.

### Core Mission

Enable robust causal inference for mediation effects in the presence of differential misclassification, providing researchers with tools to quantify uncertainty bounds and test falsification hypotheses without requiring validation data.

### Key Features

- **Partial identification bounds** for Natural Direct Effects (NDE) and Natural Indirect Effects (NIE)
- **Data-driven falsification** via testable implications
- **Sensitivity analysis** over user-specified ranges of misclassification parameters
- **Diagnostic tools** and publication-quality visualizations
- **Bootstrap inference** for confidence intervals (percentile and BCa methods)
- **Synthetic data generation** for power analysis and methods research
- **Modern S7 OOP system** for type safety and extensibility

### Key References

- Tofighi, D. (2025). Partial Identification of Causal Mediation Effects Under Differential Misclassification. *Biostatistics* (In preparation)

## Common Development Commands

### Package Building and Checking

```r
# Install package dependencies
install.packages(c("remotes", "rcmdcheck"))
remotes::install_deps(dependencies = TRUE)

# Check package (standard R CMD check)
rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "error")

# Build package
devtools::build()

# Install and reload package during development
devtools::load_all()
```

### Documentation

```r
# Generate documentation from roxygen2 comments
devtools::document()

# Build vignettes
devtools::build_vignettes()
```

### Testing and Linting

The package uses GitHub Actions for CI/CD with workflows defined in `.github/workflows/`:
- `R-CMD-check.yaml`: R package check on multiple OS and R versions
- `test-coverage.yaml`: Test coverage via covr
- `codecov.yaml`: Code coverage reporting

## Coding Standards

### R Version and Style

- **Minimum R version**: 4.1.0 (native pipe |> support)
- **OOP Framework**: S7 (modern object system)
- **Style**: tidyverse style guide with native pipe
- **Roxygen2**: Use roxygen2 for documentation (>= 7.2.0)
- **Clarity priority**: Code must be readable for both methodologists and applied users

### Naming Conventions

The package uses **snake_case** consistently following tidyverse conventions:

**Functions:**
- Main exports: `bound_ne()`, `check_compatibility()`, `sensitivity_plot()`
- Internal functions prefix with dot: `.compute_bounds()`, `.validate_input()`

**Arguments:**
- `exposure`, `mediator`, `outcome` for variable names
- `misclassified_variable` for specifying which variable has error
- `sensitivity_region` for parameter ranges
- `n_grid` for grid size in sensitivity analysis
- `n_boot` for number of bootstrap samples
- `ci_level` for confidence level (default: 0.95)

**S7 Classes:**
- CamelCase: `BoundsResult`, `SensitivityResult`, `FalsificationResult`
- Properties use snake_case: `@lower_bound`, `@upper_bound`, `@grid_values`

### Code Organization

```
R/
├── s7-classes.R              # S7 class definitions
├── s7-methods.R              # S7 methods (print, summary, plot)
├── s3_methods.R              # S3 compatibility methods
├── bound_ne.R                # Main bounds computation
├── bound_nie_exposure.R      # Exposure misclassification
├── bound_nie_mediator.R      # Mediator misclassification
├── check_compatibility.R     # Falsification tests
├── bootstrap.R               # Bootstrap infrastructure
├── sensitivity_plot.R        # Visualization functions
├── falsification_summary.R   # Falsification summary
├── simulate_dm_data.R        # Data generation
├── power_analysis.R          # Sample size calculations
├── effect_helpers.R          # Helper functions
└── data.R                    # Documentation for datasets
```

## Code Architecture

### S7 Object System

The package uses S7 for type-safe, modern object-oriented programming:

**Key S7 Classes:**

1. **`BoundsResult`** - Partial identification bounds for natural effects
   - Properties: `lower_bound`, `upper_bound`, `naive_estimate`, `sensitivity_grid`, etc.
   - Validation rules ensure bounds are consistent
   - Subclasses: `ExposureBoundsResult`, `MediatorBoundsResult`

2. **`SensitivityResult`** - Sensitivity analysis results
   - Properties: `param_grid`, `bounds_matrix`, `falsified_region`, etc.
   - Enables visualization via `sensitivity_plot()`

3. **`FalsificationResult`** - Falsification test results
   - Properties: `testable_implications`, `falsified`, `p_value`, etc.
   - Tracks which parameter combinations are data-incompatible

**S7 Generics:**

Key generics with methods for different result types:
- `print()`, `summary()`, `plot()` - Display methods
- `extract_bounds()` - Extract bounds at specific parameter values
- `compare_bounds()` - Compare across multiple analyses

### Core Function Hierarchy

**User-Facing Functions:**

1. **`bound_ne()`** - Main function for computing bounds
   - Dispatcher that calls exposure or mediator-specific functions
   - Returns `BoundsResult` object with bounds and diagnostics

2. **`check_compatibility()`** - Falsification tests
   - Tests if misclassification parameters are data-compatible
   - Returns `FalsificationResult` object

3. **`sensitivity_plot()`** - Visualization
   - Creates publication-quality plots
   - Supports various parameter combinations

4. **`simulate_dm_data()`** - Data generation
   - For power analysis and methods validation
   - Generates data with known misclassification structure

**Internal Computation Functions:**

- `.compute_bounds_exposure()`: Bounds when exposure is misclassified
- `.compute_bounds_mediator()`: Bounds when mediator is misclassified
- `.bootstrap_bounds()`: Bootstrap inference
- `.check_testable_implications()`: Falsification logic

### Key Dependencies

**Required:**
- **S7**: Modern object system
- **dplyr**: Data manipulation
- **ggplot2**: Visualization
- **stats**, **utils**: Base functionality
- **rlang**: Non-standard evaluation
- **parallel**: Bootstrap parallelization

**Suggested:**
- **mediation**: For comparison with naive estimates
- **boot**: Additional bootstrap methods
- **EValue**: Sensitivity analysis comparison
- **foreach**, **doParallel**: Enhanced parallelization

### Explicit Namespacing

**CRITICAL**: All non-base functions MUST use explicit namespacing:

```r
# CORRECT
dplyr::mutate(data, ...)
ggplot2::ggplot(data) + ggplot2::geom_point()
stats::glm(formula, data = data)

# INCORRECT
mutate(data, ...)
ggplot(data) + geom_point()
glm(formula, data = data)
```

This prevents namespace conflicts and makes dependencies explicit.

## Important Implementation Details

### Misclassification Framework

**Two Scenarios:**

1. **Exposure Misclassification**: A* = A + error, where error depends on Y
2. **Mediator Misclassification**: M* = M + error, where error depends on Y

**Misclassification Parameters:**

For binary variables:
- `sn0`: Sensitivity when Y=0 (P(A*=1|A=1, Y=0))
- `sp0`: Specificity when Y=0 (P(A*=0|A=0, Y=0))
- `psi_sn`: Sensitivity odds ratio (OR for sensitivity comparing Y=1 vs Y=0)
- `psi_sp`: Specificity odds ratio (OR for specificity comparing Y=1 vs Y=0)

**Differential Misclassification:**
- `psi_sn > 1`: Higher sensitivity when Y=1 (outcome-dependent)
- `psi_sp < 1`: Lower specificity when Y=1 (outcome-dependent)

### Bounds Computation

**Sharp Identification Bounds:**

For exposure misclassification:
```
NDE ∈ [NDE_lower(θ), NDE_upper(θ)]
NIE ∈ [NIE_lower(θ), NIE_upper(θ)]
```

where θ = (sn0, sp0, psi_sn, psi_sp) are misclassification parameters.

**Sensitivity Analysis:**
- Grid search over user-specified parameter ranges
- Each grid point yields bounds
- Union of bounds across sensitivity region

**Falsification:**
- Some θ values may be incompatible with observed data
- Testable implications used to exclude impossible parameters
- Reduces sensitivity region

### Bootstrap Inference

**Methods:**
- **Percentile**: Simple quantile method
- **BCa**: Bias-corrected and accelerated
- **Parametric**: Resample from estimated distribution

**Implementation:**
```r
bootstrap_bounds(
  data,
  bound_fn,              # Function to compute bounds
  n_boot = 1000,
  method = "percentile", # or "bca", "parametric"
  parallel = TRUE,
  ncores = NULL          # Auto-detect if NULL
)
```

**Memory Considerations:**
- Bootstrap distributions stored for diagnostics
- Large `n_boot` and `n_grid` can consume memory
- Consider saving to disk for very large analyses

## Statistical Assumptions & Diagnostics

### Key Assumptions

1. **No unmeasured confounding** (standard causal mediation assumptions):
   - {Y(a,m), M(a)} ⊥ A | C
   - Y(a,m) ⊥ M | A, C
   - Cross-world independence

2. **Misclassification model**:
   - Correct functional form for P(A*|A, Y, C)
   - Binary exposure/mediator (continuous extensions possible)
   - Outcome-dependent error (not confounder-dependent)

3. **Positivity**:
   - All treatment-covariate combinations observed
   - Sufficient overlap in propensity scores

### Diagnostics

**Check sensitivity region:**
```r
result <- bound_ne(...)

# Proportion falsified
summary(result)

# Visualize falsification
falsification_summary(result)
```

**Warning signs:**
- Large proportion of sensitivity region falsified → Check model specification
- Very wide bounds → Misclassification severely limits identification
- Bounds include null (1.0 for OR) → Cannot rule out no effect

### Common Pitfalls

1. **Ignoring differential misclassification**: Assuming non-differential error when it's differential biases estimates
2. **Overly narrow sensitivity region**: May miss plausible parameter values
3. **Confusing bounds with CIs**: Bounds reflect identification limits, not sampling uncertainty
4. **Small samples**: Bootstrap CIs may be wide; consider larger n

## Testing Strategy

### Unit Tests Should Cover

1. **Bounds Computation Accuracy**
   - Compare to hand-calculated examples
   - Verify bounds bracket naive estimate
   - Check monotonicity in sensitivity parameters

2. **Falsification Tests**
   - Testable implications correctly implemented
   - Known incompatible parameters correctly flagged
   - No false positives in falsification

3. **Bootstrap Methods**
   - Reproducibility with set.seed()
   - CI coverage in simulations
   - BCa vs percentile comparison

4. **S7 Validation**
   - Property type checking works
   - Validators catch invalid inputs
   - Class inheritance functions correctly

5. **Edge Cases**
   - Empty sensitivity region (all falsified)
   - Single parameter value (no grid)
   - Perfect classification (no misclassification)
   - Extreme odds ratios

6. **Data Generation**
   - Synthetic data has correct misclassification structure
   - Known bounds recovered from simulated data

### Test Organization

```
tests/
├── testthat/
│   ├── test-s7-classes.R           # S7 class validation
│   ├── test-bound-ne-exposure.R    # Exposure misclassification
│   ├── test-bound-ne-mediator.R    # Mediator misclassification
│   ├── test-falsification.R        # Testable implications
│   ├── test-bootstrap.R            # Bootstrap methods
│   ├── test-simulation.R           # Data generation
│   └── test-edge-cases.R           # Edge cases and errors
```

### Coverage Expectations

- **Target**: >85% test coverage
- **Critical paths**: 100% coverage for bounds computation
- **Bootstrap**: Coverage assessment via simulation studies

## Ecosystem Coordination

medrobust is an **application package** in the mediationverse ecosystem.

### Central Planning Documents

All ecosystem-wide coordination is managed in `/Users/dt/mediation-planning/`:

| Document | Purpose |
|----------|---------|
| `ECOSYSTEM-COORDINATION.md` | Version matrix, change propagation, release timeline |
| `MONTHLY-CHECKLIST.md` | Recurring ecosystem health checks |
| `templates/README-template.md` | Standardized README structure |
| `templates/NEWS-template.md` | Standardized NEWS.md format |

### Package Roles

| Package | Purpose | Role |
|---------|---------|------|
| [**medfit**](https://github.com/data-wise/medfit) | Model fitting, extraction, bootstrap | Foundation |
| [**probmed**](https://github.com/data-wise/probmed) | Probabilistic effect size (P_med) | Application |
| [**RMediation**](https://github.com/data-wise/rmediation) | Confidence intervals (DOP, MBCO) | Application |
| **medrobust** (this) | Sensitivity analysis | Application |
| [**medsim**](https://github.com/data-wise/medsim) | Simulation infrastructure | Support |

### What medrobust Provides

- **Partial identification bounds** for NDE/NIE under misclassification
- **Falsification tests** via testable implications
- **Sensitivity plots** for publication-ready visualizations
- **Bootstrap inference** for bounds

### Integration with medfit (optional)

- Can use medfit for naive estimate computation
- Currently computes naive estimates independently
- Future: May use shared bootstrap infrastructure

See [Ecosystem Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md) for guidelines.

## Additional Resources

### Key Publications

**Methodological Foundation:**
- Tofighi, D. (2025). Partial Identification of Causal Mediation Effects Under Differential Misclassification. *Biostatistics*. (In preparation)

**Related Work on Measurement Error:**
- Carroll, R. J., et al. (2006). *Measurement Error in Nonlinear Models*. Chapman & Hall/CRC.
- VanderWeele, T. J., & Vansteelandt, S. (2014). Mediation analysis with multiple mediators. *European Journal of Epidemiology*, 29(11), 801–810.

**Partial Identification:**
- Manski, C. F. (2003). *Partial Identification of Probability Distributions*. Springer.
- Gustafson, P. (2003). *Measurement Error and Misclassification in Statistics and Epidemiology*. Chapman & Hall/CRC.

### Package Website

- GitHub: <https://github.com/data-wise/medrobust>
- Issues: <https://github.com/data-wise/medrobust/issues>

## Development Roadmap

### Current Status (v0.1.0.9000)

- [x] S7 class architecture
- [x] Exposure misclassification bounds
- [x] Mediator misclassification bounds
- [x] Falsification tests
- [x] Bootstrap inference
- [x] Sensitivity plots
- [x] Data generation

### Future Enhancements

- [ ] Continuous mediator/exposure support
- [ ] Multiple mediators
- [ ] Time-varying exposures
- [ ] Integration with foundation package (if created)
- [ ] Expanded vignettes and tutorials
- [ ] Shiny app for interactive sensitivity analysis
- [ ] CRAN submission
