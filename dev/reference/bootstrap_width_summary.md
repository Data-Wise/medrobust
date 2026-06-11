# Compute Width of Bootstrap Distribution

Compute the mean, median, and range of bound widths from bootstrap
samples.

## Usage

``` r
bootstrap_width_summary(bootstrap_results, effect = "NIE")
```

## Arguments

- bootstrap_results:

  List returned by compute_bootstrap_ci

- effect:

  Character string: "NIE" or "NDE"

## Value

List with width statistics
