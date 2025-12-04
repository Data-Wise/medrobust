# medrobust (development version)

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
