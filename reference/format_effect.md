# Format Effect Estimate for Reporting

Format an effect estimate as a string for tables/reports.

## Usage

``` r
format_effect(estimate, effect_scale = "OR", digits = 2, ci = NULL)
```

## Arguments

- estimate:

  Numeric effect estimate (or bounds)

- effect_scale:

  Character string: "OR", "RR", or "RD"

- digits:

  Integer: number of decimal places

- ci:

  Optional: confidence interval (length 2 vector)

## Value

Character string

## Examples

``` r
format_effect(1.48)
#> [1] "1.48"
format_effect(1.48, ci = c(1.21, 1.81))   # point estimate with a CI
#> [1] "1.48 (1.21, 1.81)"
format_effect(c(1.12, 1.37))              # bounds [L, U]
#> [1] "[1.12, 1.37]"
format_effect(0.031, effect_scale = "RD", digits = 3)
#> [1] "0.031"
```
