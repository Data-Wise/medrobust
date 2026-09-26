# medrobust: Robust Causal Mediation Analysis Under Differential Misclassification

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![Repo Status](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R-CMD-check](https://github.com/data-wise/medrobust/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/data-wise/medrobust/actions/workflows/R-CMD-check.yaml)
[![Website Status](https://github.com/data-wise/medrobust/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/data-wise/medrobust/actions/workflows/pkgdown.yaml)
[![R-hub](https://github.com/data-wise/medrobust/actions/workflows/rhub.yaml/badge.svg)](https://github.com/data-wise/medrobust/actions/workflows/rhub.yaml)
[![Codecov](https://codecov.io/gh/data-wise/medrobust/graph/badge.svg)](https://app.codecov.io/gh/data-wise/medrobust)
[![r-universe](https://data-wise.r-universe.dev/badges/medrobust)](https://data-wise.r-universe.dev/medrobust)
<!-- badges: end -->

## Overview

The `medrobust` package provides tools for conducting sensitivity analysis for causal mediation effects when the exposure or mediator is measured with **differential misclassification** (e.g., recall bias, outcome-dependent measurement error).

Unlike existing measurement error correction methods that assume non-differential error or require validation data, `medrobust` derives **partial identification bounds** that remain valid without gold-standard measurements.

Two bundled datasets illustrate each scenario: `gesthtn` (mediator misclassification, gestational hypertension) and `nhanes_pa` (exposure misclassification, self-reported physical inactivity).

> **Where this fits.** In the mediationverse pipeline you *fit* a mediation model with
> [medfit](https://data-wise.github.io/medfit/), quantify effects with
> [probmed](https://data-wise.github.io/probmed/) /
> [RMediation](https://data-wise.github.io/rmediation/), and then use **medrobust** to
> stress-test those conclusions against differential misclassification — the
> "how fragile is my estimate?" step. The whole stack loads together via the
> [mediationverse](https://data-wise.github.io/mediationverse/) umbrella package.

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
devtools::install_github("data-wise/medrobust")
```

### From r-universe (pre-built binaries)

No compiler needed — binaries for Windows, macOS, and Linux:

```r
install.packages(
  "medrobust",
  repos = c("https://data-wise.r-universe.dev", "https://cloud.r-project.org")
)
```

### From CRAN (coming soon)

```r
install.packages("medrobust")
```

## Quick Start

```r
library(medrobust)

# Simulate data with a known mediator-misclassification mechanism
sim <- simulate_dm_data(
  n = 8000,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 1
)

# Sensitivity region containing the (here non-differential) truth
sens_region <- list(
  sn0_range = c(0.80, 0.99),
  sp0_range = c(0.80, 0.99),
  psi_sn_range = c(0.8, 1.5),
  psi_sp_range = c(0.8, 1.5)
)

# Compute partial-identification bounds for mediator misclassification.
# The raw bound [L, U] is consistent but is NOT a confidence set; at finite n
# it can under-cover the truth, so we add Imbens-Manski confidence intervals
# in the same fit via ci_method = "analytic".
set.seed(1)
bounds <- bound_ne(
  data = sim@observed,
  exposure = "A",
  mediator = "M_star",
  outcome = "Y",
  confounders = "C1",
  misclassified_variable = "mediator",
  sensitivity_region = sens_region,
  n_grid = 10,
  ci_method = "analytic",
  ci_n_boot = 50   # fast demo; the default (200) gives more stable CI endpoints
)

# View results
print(bounds)
summary(bounds)
bounds@analytic_ci$NDE   # raw [L, U] plus Imbens-Manski confidence interval

# Visualize
sensitivity_plot(bounds, param = "psi_sn")
```

## Main Functions

| Function | Purpose |
|----------|---------|
| `bound_ne()` | Compute partial identification bounds for NDE and NIE |
| `bound_ci()` | Compute analytic Imbens–Manski confidence intervals for bounds |
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
```

Long-form articles are published on the [package website](https://data-wise.github.io/medrobust/articles/) (they are not installed as vignettes):

- [Getting Started with medrobust](https://data-wise.github.io/medrobust/articles/introduction.html)
- [Methodology: Partial Identification Under Differential Misclassification](https://data-wise.github.io/medrobust/articles/methodology.html)
- [Identification Mathematics](https://data-wise.github.io/medrobust/articles/identification-math.html)
- [Worked example: misclassified mediator (gestational hypertension)](https://data-wise.github.io/medrobust/articles/gesthtn-bounds.html)
- [Worked example: misclassified exposure (physical inactivity)](https://data-wise.github.io/medrobust/articles/nhanes_pa-bounds.html)

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
  note = {R package version 0.4.4},
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
