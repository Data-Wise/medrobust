# medrobust: Robust Causal Mediation Analysis Under Differential Misclassification

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Repo Status](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![R-CMD-check](https://github.com/data-wise/medrobust/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/data-wise/medrobust/actions/workflows/R-CMD-check.yaml)
[![Website Status](https://github.com/data-wise/medrobust/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/data-wise/medrobust/actions/workflows/pkgdown.yaml)
[![R-hub](https://github.com/data-wise/medrobust/actions/workflows/rhub.yaml/badge.svg)](https://github.com/data-wise/medrobust/actions/workflows/rhub.yaml)
[![Codecov](https://codecov.io/gh/data-wise/medrobust/graph/badge.svg)](https://codecov.io/gh/data-wise/medrobust)
<!-- badges: end -->

## Overview

The `medrobust` package provides tools for conducting sensitivity analysis for causal mediation effects when the exposure or mediator is measured with **differential misclassification** (e.g., recall bias, outcome-dependent measurement error).

Unlike existing measurement error correction methods that assume non-differential error or require validation data, `medrobust` derives **partial identification bounds** that remain valid without gold-standard measurements.

## Key Features

- **Partial identification bounds** for Natural Direct Effects (NDE) and Natural Indirect Effects (NIE)
- **Data-driven falsification** via testable implications
- **Sensitivity analysis** over user-specified ranges of misclassification parameters
- **Diagnostic tools** and publication-quality visualizations
- **Bootstrap inference** for confidence intervals (percentile and BCa methods)
- **Synthetic data generation** for power analysis and methods research
- **Modern S7 OOP system** for type safety, automatic validation, and robust error checking

## Mediationverse Ecosystem

**medrobust** is part of the **mediationverse** ecosystem for mediation analysis in R:

| Package | Purpose | Role |
|---------|---------|------|
| [**medfit**](https://github.com/data-wise/medfit) | Model fitting, extraction, bootstrap | Foundation |
| [**probmed**](https://github.com/data-wise/probmed) | Probabilistic effect size (P_med) | Application |
| [**RMediation**](https://github.com/data-wise/rmediation) | Confidence intervals (DOP, MBCO) | Application |
| **medrobust** (this) | Sensitivity analysis | Application |
| [**medsim**](https://github.com/data-wise/medsim) | Simulation infrastructure | Support |

See [Ecosystem Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md) for version compatibility and development guidelines.

## Installation

### Development version from GitHub

```r
# Install devtools if needed
if (!require("devtools")) install.packages("devtools")

# Install medrobust
devtools::install_github("data-wise/medrobust", build_vignettes = TRUE)
```

### From CRAN (coming soon)

```r
install.packages("medrobust")
```

## Quick Start

```r
library(medrobust)

# Load example data
data("arsenic_synthetic")

# Define sensitivity region for misclassification parameters
sens_region <- list(
  sn0_range = c(0.80, 0.90),      # Sensitivity when Y=0
  sp0_range = c(0.80, 0.90),      # Specificity when Y=0
  psi_sn_range = c(1.0, 2.0),     # Sensitivity odds ratio
  psi_sp_range = c(1.0, 1.0)      # Specificity odds ratio
)

# Compute partial identification bounds
bounds <- bound_ne(
  data = arsenic_synthetic,
  exposure = "A_star",              # Misclassified exposure
  mediator = "M",
  outcome = "Y",
  confounders = c("age", "smoking", "alcohol"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 50
)

# View results
print(bounds)
summary(bounds)

# Visualize sensitivity analysis
sensitivity_plot(bounds, param = "psi_sn", show_naive = TRUE)
```

## Main Functions

| Function | Purpose |
|----------|---------|
| `bound_ne()` | Compute partial identification bounds for NDE and NIE |
| `check_compatibility()` | Test if specific misclassification parameters are compatible with data |
| `sensitivity_plot()` | Generate publication-quality sensitivity analysis plots |
| `falsification_summary()` | Summarize which regions of sensitivity space are falsified |
| `simulate_dm_data()` | Generate synthetic data with differential misclassification |
| `extract_bounds()` | Extract bounds at specific parameter values |
| `compare_bounds()` | Compare bounds across multiple analyses |
| `power_analysis()` | Estimate sample size for target bound precision |

## Example Output

```r
# Partial Identification Bounds for Natural Effects

Misclassified Variable: exposure
Sample Size: n = 2500

Natural Indirect Effect (NIE):
  Lower Bound: 1.12 (95% CI: 1.05 - 1.18)
  Upper Bound: 1.45 (95% CI: 1.38 - 1.52)

Natural Direct Effect (NDE):
  Lower Bound: 1.08 (95% CI: 1.01 - 1.15)
  Upper Bound: 1.32 (95% CI: 1.25 - 1.39)

Falsification: 15.2% of sensitivity region empirically falsified
```

## Documentation

Detailed documentation and tutorials are available:

```r
# View main function documentation
?bound_ne

# Browse all package documentation
help(package = "medrobust")

# View vignettes
vignette("introduction", package = "medrobust")
vignette("mediator_misclass", package = "medrobust")
vignette("exposure_misclass", package = "medrobust")
vignette("interpretation", package = "medrobust")
```

## Methodological Background

This package implements methods from:

> Tofighi, D. (2025). "Partial Identification of Causal Mediation Effects Under Differential Misclassification." *Biostatistics*, XX(X), XXX-XXX.

The package handles two scenarios:

1. **Mediator Misclassification** (Section 4): When M is measured with error as M*, and error depends on Y
2. **Exposure Misclassification** (Section 5): When A is measured with error as A*, and error depends on Y

Both scenarios use testable implications to falsify incompatible misclassification parameters and derive sharp identification bounds for natural effects.

## Use Cases

### Applied Research
- **Epidemiology**: Disease mechanisms with self-reported exposures
- **Social Sciences**: Mediation with survey data subject to reporting bias
- **Clinical Research**: Treatment mechanisms with imperfect diagnostics

### Methodological Research
- Simulation studies comparing measurement error correction methods
- Power analysis for study design
- Teaching causal inference concepts

## Citation

If you use this package, please cite both the software and the paper:

```r
citation("medrobust")
```

```bibtex
@Article{tofighi2025medrobust,
  title = {Partial Identification of Causal Mediation Effects Under
           Differential Misclassification},
  author = {Davood Tofighi},
  journal = {Biostatistics},
  year = {2025},
  volume = {XX},
  pages = {XXX--XXX},
  doi = {10.1093/biostatistics/xxxxx},
}

@Manual{medrobust2025,
  title = {medrobust: Robust Causal Mediation Analysis Under
           Differential Misclassification},
  author = {Davood Tofighi},
  year = {2025},
  note = {R package version 0.1.0},
  url = {https://github.com/data-wise/medrobust},
}
```

## Getting Help

- **Bug reports and feature requests**: [GitHub Issues](https://github.com/data-wise/medrobust/issues)
- **Questions**: Email dtofighi@gmail.com or use [Stack Overflow](https://stackoverflow.com/) with tags `[r]` and `[medrobust]`

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This package is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

Development of this package was supported by [funding sources to be added].
