# Compute Effects from Joint Probabilities (Exposure Misclassification)

Given solved true joint probabilities P(A=a, M=m, Y=y \| C=c), compute
NDE and NIE using g-computation.

## Usage

``` r
compute_effects_from_joint_probs(
  P_true_list,
  data,
  C_names,
  effect_scale = "OR"
)
```

## Arguments

- P_true_list:

  List of true joint probabilities from exposure misclassification

- data:

  Data frame with observations

- C_names:

  Character vector of confounder names

- effect_scale:

  Character string: "OR", "RR", or "RD"

## Value

List with elements nie and nde
