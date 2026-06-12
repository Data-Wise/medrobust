# Test Multiple Hypotheses

Test multiple hypotheses about misclassification parameters
simultaneously.

## Usage

``` r
test_multiple_hypotheses(
  data,
  exposure,
  mediator,
  outcome,
  confounders,
  psi_list,
  misclassified_variable
)
```

## Arguments

- data:

  Data frame

- exposure:

  Character string

- mediator:

  Character string

- outcome:

  Character string

- confounders:

  Character vector

- psi_list:

  List of parameter sets to test

- misclassified_variable:

  Character string

## Value

Data frame with test results for each hypothesis
