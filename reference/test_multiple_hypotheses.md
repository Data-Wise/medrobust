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

  List of parameter sets to test, each a list with `sn0`, `sp0`,
  `psi_sn` and `psi_sp`. Names label the rows of the result; unnamed
  entries are labeled `H1`, `H2`, ... by position.

- misclassified_variable:

  Character string

## Value

Data frame with test results for each hypothesis

## Examples

``` r
sim <- simulate_dm_data(
  n = 2000,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 1
)

# psi_list must be named: the names label the rows of the result
test_multiple_hypotheses(
  data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
  confounders = "C1", misclassified_variable = "mediator",
  psi_list = list(
    accurate = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    poor     = list(sn0 = 0.6, sp0 = 0.6, psi_sn = 1, psi_sp = 1)
  )
)
#>   hypothesis sn0 sp0 psi_sn psi_sp compatible n_violated
#> 1   accurate 0.9 0.9      1      1       TRUE          0
#> 2       poor 0.6 0.6      1      1      FALSE          2
```
