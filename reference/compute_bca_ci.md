# Compute BCa Confidence Intervals

Compute bias-corrected and accelerated (BCa) bootstrap confidence
intervals. This method adjusts for bias and skewness in the bootstrap
distribution.

## Usage

``` r
compute_bca_ci(
  boot_estimates,
  confidence_level,
  data,
  exposure,
  mediator,
  outcome,
  confounders,
  misclassified_variable,
  sensitivity_region,
  n_grid,
  effect_scale,
  grid_method = "lhs",
  verbose
)
```

## Arguments

- boot_estimates:

  Matrix of bootstrap estimates

- confidence_level:

  Confidence level

- data:

  Data frame with observations

- exposure:

  Name of exposure variable

- mediator:

  Name of mediator variable

- outcome:

  Name of outcome variable

- confounders:

  Vector of confounder names

- misclassified_variable:

  Which variable is misclassified

- sensitivity_region:

  Sensitivity region specification

- n_grid:

  Grid resolution

- effect_scale:

  Effect scale ("OR", "RR", or "RD")

- grid_method:

  Grid search method

- verbose:

  Logical for verbose output

## Value

List with BCa confidence intervals
