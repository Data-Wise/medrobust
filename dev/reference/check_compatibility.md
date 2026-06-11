# Check Compatibility of Misclassification Parameters

Tests whether a specific set of misclassification parameters is
compatible with the observed data by checking testable implications.
Returns detailed diagnostics about which constraints are satisfied or
violated.

## Usage

``` r
check_compatibility(
  data,
  exposure,
  mediator,
  outcome,
  confounders = NULL,
  psi,
  misclassified_variable = c("exposure", "mediator"),
  return_details = TRUE,
  tolerance = 1e-06
)
```

## Arguments

- data:

  Data frame containing the observed variables

- exposure:

  Character string. Name of exposure variable

- mediator:

  Character string. Name of mediator variable

- outcome:

  Character string. Name of outcome variable

- confounders:

  Character vector. Names of confounding variables

- psi:

  Named list containing misclassification parameters:

  - `sn0`: Baseline sensitivity

  - `sp0`: Baseline specificity

  - `psi_sn`: Differential sensitivity (odds ratio)

  - `psi_sp`: Differential specificity (odds ratio)

- misclassified_variable:

  Character string. Either "exposure" or "mediator"

- return_details:

  Logical. If TRUE, returns detailed stratum-level diagnostics. Default
  is TRUE.

- tolerance:

  Numeric. Tolerance for numerical precision when checking constraints.
  Default is 1e-6.

## Value

A list with class `compatibility_test` containing:

- compatible:

  Logical. TRUE if parameters are compatible

- psi:

  The tested parameter set

- n_constraints_total:

  Total number of testable constraints

- n_constraints_satisfied:

  Number of satisfied constraints

- n_constraints_violated:

  Number of violated constraints

- violated_constraints:

  Data frame of violated constraints (if any)

- implied_probabilities:

  Solved true probabilities (if compatible)

- stratum_details:

  Stratum-level diagnostics (if return_details=TRUE)

## Details

This function implements the testable implications derived in
Propositions 4.1 and 5.1 of the paper. For mediator misclassification,
it checks whether the observed data can be explained by any true causal
parameters given the specified misclassification mechanism. For exposure
misclassification, it checks the likelihood ratio constraints on
observed probabilities.

The function is useful for:

- Testing specific hypotheses about misclassification parameters

- Understanding which constraints are most informative

- Debugging sensitivity analyses

- Generating diagnostic plots

## See also

[`bound_ne`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md),
[`falsification_summary`](https://data-wise.github.io/medrobust/dev/reference/falsification_summary.md)

## Examples

``` r
if (FALSE) { # \dontrun{
data("heals_data")

# Test non-differential misclassification with high accuracy
test_ndm <- check_compatibility(
  data = heals_data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("age", "male", "smoking", "bmi"),
  psi = list(sn0 = 0.90, sp0 = 0.90, psi_sn = 1.0, psi_sp = 1.0),
  misclassified_variable = "exposure"
)

print(test_ndm)

# Test strong differential misclassification
test_strong_dm <- check_compatibility(
  data = heals_data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("age", "male", "smoking", "bmi"),
  psi = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 3.0, psi_sp = 1.0),
  misclassified_variable = "exposure"
)

print(test_strong_dm)
} # }
```
