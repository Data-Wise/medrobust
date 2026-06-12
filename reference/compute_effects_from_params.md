# ============================================================================= Effect Computation Functions ============================================================================= Compute Effects from Solved Parameters (Mediator Misclassification)

Given solved causal parameters (pi_a, gamma_a0, gamma_a1) for each
exposure level and covariate stratum, compute NDE and NIE using
g-computation.

## Usage

``` r
compute_effects_from_params(solved_params, data, C_names, effect_scale = "OR")
```

## Arguments

- solved_params:

  List of solved parameters from mediator misclassification

- data:

  Data frame with observations

- C_names:

  Character vector of confounder names

- effect_scale:

  Character string: "OR", "RR", or "RD"

## Value

List with elements nie and nde
