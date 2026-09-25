# Compute Width of Bootstrap Distribution

Compute the mean, median, and range of bound widths from bootstrap
samples.

## Usage

``` r
bootstrap_width_summary(bootstrap_results, effect = "NIE")
```

## Arguments

- bootstrap_results:

  The `bootstrap_results` property of a
  [`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
  fit with `bootstrap = TRUE`, or the list returned by
  `compute_bootstrap_ci()`

- effect:

  Character string: "NIE" or "NDE"

## Value

List with width statistics
