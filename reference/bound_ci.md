# Confidence intervals for partial-identification bounds (Imbens-Manski)

Computes a confidence interval for the partial-identification set
returned by
[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md).
The raw estimated bound \\\[\hat L, \hat U\]\\ is consistent but is
*not* a confidence set: when the identified set is narrow relative to
the sampling uncertainty of its endpoints, it under-covers the true
effect at small samples. `bound_ci()` widens the endpoints by their
standard errors using the Imbens & Manski (2004) construction, restoring
approximately nominal coverage of the true effect.

## Usage

``` r
bound_ci(
  bounds,
  data,
  exposure,
  mediator,
  outcome,
  confounders,
  misclassified_variable = c("exposure", "mediator"),
  n_boot = 200L,
  level = 0.95,
  seed = NULL
)
```

## Arguments

- bounds:

  A fitted `medrobust_bounds` object from
  [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md).

- data:

  The data frame passed to
  [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md).

- exposure, mediator, outcome, confounders:

  Column names, as in
  [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md).

- misclassified_variable:

  Either `"exposure"` or `"mediator"`; selects the recovery used to
  evaluate the effect at a single sensitivity parameter.

- n_boot:

  Number of resamples for the endpoint standard errors (default 200).

- level:

  Confidence level (default 0.95).

- seed:

  Optional integer seed for reproducibility.

## Value

A named list with elements `NIE` and `NDE`, each a numeric vector with
`lower`, `upper` (the point bounds), `se_lower`, `se_upper` (endpoint
SEs), and `ci_lower`, `ci_upper` (the Imbens-Manski confidence
interval).

## Details

Endpoint standard errors are obtained by re-evaluating the effect at the
fixed minimizing/maximizing sensitivity parameter on resampled data (one
evaluation per resample, with no grid search), which is far cheaper than
a full bootstrap of the whole grid.

## References

Imbens, G. W. and Manski, C. F. (2004). Confidence Intervals for
Partially Identified Parameters. *Econometrica*, 72(6), 1845-1857.

## See also

[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)

## Examples

``` r
# \donttest{
sim <- simulate_dm_data(
  n = 2000,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 1
)
bounds <- bound_ne(
  data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
  confounders = "C1", misclassified_variable = "mediator",
  sensitivity_region = list(
    sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
    psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)
  ),
  n_grid = 10, verbose = FALSE
)

# Widen the raw bounds [L, U] into Imbens-Manski confidence intervals
ci <- bound_ci(
  bounds, data = sim@observed, exposure = "A", mediator = "M_star",
  outcome = "Y", confounders = "C1", misclassified_variable = "mediator",
  n_boot = 50, seed = 1
)
ci$NDE
#>     lower     upper  se_lower  se_upper  ci_lower  ci_upper 
#> 1.3592882 1.6583075 0.1735582 0.1731216 1.0731786 1.9436975 
# }
```
