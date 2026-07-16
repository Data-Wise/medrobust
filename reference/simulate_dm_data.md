# Simulate Data with Differential Misclassification

Generates synthetic data with known differential misclassification for
power analysis, methods validation, and simulation studies. Allows
control over true causal parameters and misclassification mechanisms.

## Usage

``` r
simulate_dm_data(
  n = 500,
  true_params = list(beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405),
  dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1),
  misclass_type = c("exposure", "mediator"),
  confounders = 1,
  confounder_params = list(type = "binary", effect_on_A = 0.3, effect_on_M = 0.3,
    effect_on_Y = 0.3),
  effect_modification = FALSE,
  interaction_coef = 0,
  seed = NULL,
  return_truth = TRUE,
  return_params = TRUE
)
```

## Arguments

- n:

  Integer. Sample size. Default is 500.

- true_params:

  Named list of true causal parameters:

  - `beta_AM`: Effect of A on M (log-odds scale)

  - `theta_AY`: Direct effect of A on Y (log-odds scale)

  - `theta_MY`: Effect of M on Y (log-odds scale)

  - `baseline_M`: Baseline probability of M when A=0 (optional)

  - `baseline_Y`: Baseline probability of Y when A=0, M=0 (optional)

- dm_params:

  Named list of misclassification parameters:

  - `sn0`: Baseline sensitivity (Y=0)

  - `sp0`: Baseline specificity (Y=0)

  - `psi_sn`: Differential sensitivity (odds ratio)

  - `psi_sp`: Differential specificity (odds ratio)

- misclass_type:

  Character string. Either "exposure" or "mediator" to indicate which
  variable is misclassified. Default is "exposure".

- confounders:

  Integer. Number of confounding variables to include. Default is 1. Set
  to 0 for no confounders.

- confounder_params:

  Named list controlling confounder generation:

  - `type`: "binary" or "continuous". Default is "binary".

  - `effect_on_A`: Effect size on exposure (log-odds). Default is 0.3.

  - `effect_on_M`: Effect size on mediator (log-odds). Default is 0.3.

  - `effect_on_Y`: Effect size on outcome (log-odds). Default is 0.3.

- effect_modification:

  Logical. Should there be effect modification (interaction between A
  and M on Y)? Default is FALSE.

- interaction_coef:

  Numeric. Interaction coefficient if effect_modification=TRUE. Default
  is 0.

- seed:

  Integer. Random seed for reproducibility. If NULL, no seed is set.

- return_truth:

  Logical. Should true (unobserved) values be returned? Default is TRUE.

- return_params:

  Logical. Should true causal effects be calculated and returned?
  Default is TRUE.

## Value

An S7 object of class `simulated_dm_data` containing:

- observed:

  Data frame with observed (potentially misclassified) variables

- truth:

  Data frame with true (unobserved) values (if return_truth=TRUE)

- true_effects:

  List of true causal effects (if return_params=TRUE)

- generation_params:

  Parameters used for data generation

- misclassification_applied:

  Summary of applied misclassification

## See also

[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md),
[`power_analysis`](https://data-wise.github.io/medrobust/reference/power_analysis.md)

## Examples

``` r
# \donttest{
# Basic simulation with moderate effects and mild DM
sim_data <- simulate_dm_data(
  n = 500,
  true_params = list(
    beta_AM = 0.405,   # OR = 1.5
    theta_AY = 0.405,  # OR = 1.5
    theta_MY = 0.405   # OR = 1.5
  ),
  dm_params = list(
    sn0 = 0.85,
    sp0 = 0.85,
    psi_sn = 1.5,
    psi_sp = 1.0
  ),
  misclass_type = "exposure",
  seed = 12345
)

# Use in analysis
set.seed(1)
bounds <- bound_ne(
  data = sim_data@observed,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = "C1",
  misclassified_variable = "exposure",
  sensitivity_region = list(
    sn0_range = c(0.80, 0.90),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(1.0, 2.0),
    psi_sp_range = c(1.0, 1.0)
  ),
  n_grid = 10
)
#> Validating inputs...
#> Preparing data...
#> 
#> Computing bounds for exposure misclassification...
#> Grid resolution: 10 points per dimension
#> Total parameter sets to evaluate: 10000 
#> 
#> Pre-computing observed probabilities...
#> 
#> === Latin Hypercube Sampling ===
#> Samples: 100 
#>   |                                                                              |                                                                      |   0%  |                                                                              |====                                                                  |   5%  |                                                                              |=======                                                               |  10%  |                                                                              |==========                                                            |  15%  |                                                                              |==============                                                        |  20%  |                                                                              |==================                                                    |  25%  |                                                                              |=====================                                                 |  30%  |                                                                              |========================                                              |  35%  |                                                                              |============================                                          |  40%  |                                                                              |================================                                      |  45%  |                                                                              |===================================                                   |  50%  |                                                                              |======================================                                |  55%  |                                                                              |==========================================                            |  60%  |                                                                              |==============================================                        |  65%  |                                                                              |=================================================                     |  70%  |                                                                              |====================================================                  |  75%  |                                                                              |========================================================              |  80%  |                                                                              |============================================================          |  85%  |                                                                              |===============================================================       |  90%  |                                                                              |==================================================================    |  95%  |                                                                              |======================================================================| 100%
#> Compatible: 100/100 (100.0%)
#> 
#>  ============================================================ 
#> COMPUTATION COMPLETE
#> ============================================================ 
#> Time elapsed: 0.62 seconds
#> Compatible parameter sets: 100 / 100 (100.0%)
#> 
#> NIE Bounds (OR scale): [1.054, 1.069]
#> NDE Bounds (OR scale): [1.460, 1.975]
#> ============================================================ 
#> 
# }
```
