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
