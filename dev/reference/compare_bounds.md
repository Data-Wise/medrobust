# Compare Bounds Across Multiple Analyses

Compare partial identification bounds from multiple analyses (e.g.,
different sensitivity regions, different datasets, different
assumptions).

## Usage

``` r
compare_bounds(bounds_list, labels = NULL)
```

## Arguments

- bounds_list:

  A named list of `medrobust_bounds` objects.

- labels:

  Optional character vector of labels for each analysis. If NULL, uses
  names from bounds_list.

## Value

A data frame comparing the bounds, and optionally a plot.

## Examples

``` r
if (FALSE) { # \dontrun{
# Compare bounds under different sensitivity assumptions
bounds1 <- bound_ne(data, ..., sensitivity_region = region1)
bounds2 <- bound_ne(data, ..., sensitivity_region = region2)

comparison <- compare_bounds(
  list(conservative = bounds1, liberal = bounds2)
)
print(comparison)
} # }
```
