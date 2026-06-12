# Compute Total Causal Effect (TCE)

Compute the total causal effect: TCE = NDE + NIE (on appropriate scale)

## Usage

``` r
compute_tce(nie, nde, effect_scale = "OR")
```

## Arguments

- nie:

  Natural Indirect Effect

- nde:

  Natural Direct Effect

- effect_scale:

  Character string: "OR", "RR", or "RD"

## Value

Total causal effect
