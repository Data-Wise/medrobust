# Compatibility Test Class

S7 class for storing results of compatibility tests for specific
misclassification parameter values.

## Arguments

- compatible:

  Logical indicating if parameters are compatible with data

- psi:

  List of misclassification parameters tested

- sn1:

  Sensitivity when Y=1 (implied from psi)

- sp1:

  Specificity when Y=1 (implied from psi)

- n_constraints_total:

  Total number of testable constraints

- n_constraints_satisfied:

  Number of constraints satisfied

- n_constraints_violated:

  Number of constraints violated

- violated_constraints:

  Data frame with details of violated constraints

- implied_probabilities:

  List of implied probability distributions

- stratum_details:

  List with stratum-specific details

- misclassified_variable:

  Character: "exposure" or "mediator"

- reason:

  Character describing reason for incompatibility (if any)

## Value

An S7 object of class \`compatibility_test\` holding the outcome of the
data-compatibility (falsification) test, including the satisfied and
violated testable constraints.
