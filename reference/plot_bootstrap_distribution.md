# Plot Bootstrap Distribution

Visualize the bootstrap distribution of bounds.

## Usage

``` r
plot_bootstrap_distribution(
  bootstrap_results,
  effect = "NIE",
  original_bounds = NULL
)
```

## Arguments

- bootstrap_results:

  The `bootstrap_results` property of a
  [`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
  fit with `bootstrap = TRUE`, or the list returned by
  `compute_bootstrap_ci()`

- effect:

  Character string: "NIE" or "NDE"

- original_bounds:

  Original bound estimates (optional)

## Value

ggplot2 object
