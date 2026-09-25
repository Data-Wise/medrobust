# Compute Standard Errors for Bounds

Estimate standard errors for the lower and upper bounds using the
bootstrap distribution.

## Usage

``` r
compute_bound_se(bootstrap_results)
```

## Arguments

- bootstrap_results:

  The `bootstrap_results` property of a
  [`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
  fit with `bootstrap = TRUE`, or the list returned by
  `compute_bootstrap_ci()`

## Value

Named vector of standard errors
