# Convert Effects Between Scales

Approximate conversion between OR, RR, and RD scales. Note: Exact
conversion generally requires knowing baseline risks.

## Usage

``` r
convert_effect_scale(
  effect,
  from_scale = "OR",
  to_scale = "RR",
  baseline_risk = NULL
)
```

## Arguments

- effect:

  Numeric effect estimate

- from_scale:

  Character string: current scale

- to_scale:

  Character string: desired scale

- baseline_risk:

  Numeric: baseline outcome probability (needed for conversions)

## Value

Converted effect estimate
