# Check for Effect Reversal

Check if the bounds contain the null value (effect reversal possible).

## Usage

``` r
bounds_cross_null(lower, upper, effect_scale = "OR")
```

## Arguments

- lower:

  Lower bound

- upper:

  Upper bound

- effect_scale:

  Character string: "OR", "RR", or "RD"

## Value

Logical indicating if bounds cross null
