# Extract Falsified Region

Extract the parameter sets that the grid search evaluated and the data
falsified. Works for every `grid_method`, because
[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
records each evaluated set with its verdict.

## Usage

``` r
extract_falsified_region(bounds_object)
```

## Arguments

- bounds_object:

  An object of class `medrobust_bounds`

## Value

A data frame with columns `sn0`, `sp0`, `psi_sn` and `psi_sp`, one row
per falsified parameter set.
