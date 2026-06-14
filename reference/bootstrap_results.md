# Bootstrap Results Class

Stores bootstrap inference results for partial identification bounds.

## Usage

``` r
bootstrap_results(
  method = character(0),
  n_reps = integer(0),
  n_failed = 0L,
  confidence_level = integer(0),
  nie_lower_ci = integer(0),
  nie_upper_ci = integer(0),
  nde_lower_ci = integer(0),
  nde_upper_ci = integer(0),
  boot_nie_lower = integer(0),
  boot_nie_upper = integer(0),
  boot_nde_lower = integer(0),
  boot_nde_upper = integer(0),
  z0 = NULL,
  acceleration = NULL
)
```

## Arguments

- method:

  Character: "percentile" or "bca"

- n_reps:

  Number of bootstrap replications

- n_failed:

  Number of failed bootstrap samples

- confidence_level:

  Confidence level (e.g., 0.95)

- nie_lower_ci:

  Confidence interval for NIE lower bound

- nie_upper_ci:

  Confidence interval for NIE upper bound

- nde_lower_ci:

  Confidence interval for NDE lower bound

- nde_upper_ci:

  Confidence interval for NDE upper bound

- boot_nie_lower:

  Bootstrap samples for NIE lower bound

- boot_nie_upper:

  Bootstrap samples for NIE upper bound

- boot_nde_lower:

  Bootstrap samples for NDE lower bound

- boot_nde_upper:

  Bootstrap samples for NDE upper bound

- z0:

  BCa bias-correction parameter

- acceleration:

  BCa acceleration parameter

## Value

An S7 object of class \`bootstrap_results\` holding bootstrap confidence
intervals and the replicate samples for the lower and upper bound
endpoints of the natural direct and indirect effects.
