# Simulated Data with Differential Misclassification Class

S7 class for storing simulated data with known differential
misclassification, used for power analysis and methods validation.

## Arguments

- observed:

  Data frame with observed (potentially misclassified) variables

- truth:

  Data frame with true (unobserved) values

- true_effects:

  List of true causal effects

- generation_params:

  List of parameters used to generate the data

- misclassification_applied:

  List of misclassification parameters applied
