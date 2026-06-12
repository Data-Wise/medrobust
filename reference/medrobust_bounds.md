# Medrobust Bounds Class

S7 class for storing partial identification bounds for natural direct
and indirect effects under differential misclassification.

## Arguments

- NIE_lower:

  Lower bound for Natural Indirect Effect

- NIE_upper:

  Upper bound for Natural Indirect Effect

- NDE_lower:

  Lower bound for Natural Direct Effect

- NDE_upper:

  Upper bound for Natural Direct Effect

- compatible_sets:

  Data frame of parameter sets compatible with data

- n_compatible:

  Number of compatible parameter sets

- n_evaluated:

  Total number of parameter sets evaluated

- falsified_proportion:

  Proportion of parameter space falsified

- effect_scale:

  Character: "OR", "RR", or "RD"

- misclassified_variable:

  Character: "exposure" or "mediator"

- sensitivity_region:

  Sensitivity region specification

- naive_estimates:

  List of naive effect estimates

- bootstrap_results:

  Bootstrap inference results (if computed)

- data_summary:

  Summary statistics from the data

- call:

  The function call that created this object
