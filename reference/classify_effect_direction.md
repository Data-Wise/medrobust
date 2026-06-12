# Classify Effect Direction

Classify the direction of the effect based on the bounds.

## Usage

``` r
classify_effect_direction(lower, upper, effect_scale = "OR")
```

## Arguments

- lower:

  Lower bound

- upper:

  Upper bound

- effect_scale:

  Character string: "OR", "RR", or "RD"

## Value

Character string: "positive", "negative", "null", or "indeterminate"
