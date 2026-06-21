# Summarize Falsification Results

Provides a detailed summary of which regions of the sensitivity
parameter space are empirically falsified by the data. Helps understand
which assumptions about misclassification are most constrained by the
observed data.

## Usage

``` r
falsification_summary(
  bounds_object,
  by_parameter = TRUE,
  n_bins = 10,
  plot = TRUE
)
```

## Arguments

- bounds_object:

  An object of class `medrobust_bounds` returned by
  [`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)

- by_parameter:

  Logical. If TRUE, breaks down falsification by each parameter
  dimension. Default is TRUE.

- n_bins:

  Integer. Number of bins for discretizing parameters when computing
  falsification rates. Default is 10.

- plot:

  Logical. If TRUE, generates visualization of falsification patterns.
  Default is TRUE.

## Value

A list of class `falsification_summary` containing:

- overall:

  Overall falsification rate

- by_parameter:

  Parameter-specific falsification rates (if by_parameter=TRUE)

- joint_falsification:

  2D falsification patterns

- most_constrained:

  Parameters that are most falsified

- least_constrained:

  Parameters that are least falsified

- plot:

  ggplot2 object (if plot=TRUE)

## Details

This function analyzes the compatible parameter sets to understand which
regions of the sensitivity space are ruled out by the testable
implications. High falsification rates indicate that the data are
informative about that particular parameter.

The falsification analysis is useful for:

- Understanding which misclassification assumptions are most constrained

- Identifying whether bounds are wide due to weak data vs. wide
  sensitivity region

- Guiding choice of sensitivity parameters for future studies

- Assessing whether additional data would meaningfully narrow bounds

## See also

[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md),
[`check_compatibility`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)

## Examples

``` r
# \donttest{
# Compute bounds first (see ?bound_ne)
sim <- simulate_dm_data(
  n = 8000,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 1
)
set.seed(1)
bounds <- bound_ne(
  data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
  confounders = "C1", misclassified_variable = "mediator",
  sensitivity_region = list(
    sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
    psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)
  ),
  n_grid = 10
)
#> Validating inputs...
#> Preparing data...
#> 
#> Computing bounds for mediator misclassification...
#> Grid resolution: 10 points per dimension
#> Total parameter sets to evaluate: 10000 
#> 
#> Using advanced grid search method: lhs 
#> 
#> === Latin Hypercube Sampling ===
#> Samples: 100 
#>   |                                                                              |                                                                      |   0%  |                                                                              |====                                                                  |   5%  |                                                                              |=======                                                               |  10%  |                                                                              |==========                                                            |  15%  |                                                                              |==============                                                        |  20%  |                                                                              |==================                                                    |  25%  |                                                                              |=====================                                                 |  30%  |                                                                              |========================                                              |  35%  |                                                                              |============================                                          |  40%  |                                                                              |================================                                      |  45%  |                                                                              |===================================                                   |  50%  |                                                                              |======================================                                |  55%  |                                                                              |==========================================                            |  60%  |                                                                              |==============================================                        |  65%  |                                                                              |=================================================                     |  70%  |                                                                              |====================================================                  |  75%  |                                                                              |========================================================              |  80%  |                                                                              |============================================================          |  85%  |                                                                              |===============================================================       |  90%  |                                                                              |==================================================================    |  95%  |                                                                              |======================================================================| 100%
#> Compatible: 100/100 (100.0%)
#> 
#>  ============================================================ 
#> COMPUTATION COMPLETE
#> ============================================================ 
#> Time elapsed: 3.67 seconds
#> Compatible parameter sets: 100 / 100 (100.0%)
#> 
#> NIE Bounds (OR scale): [1.148, 1.457]
#> NDE Bounds (OR scale): [1.271, 1.613]
#> ============================================================ 
#> 

falsif <- falsification_summary(bounds)

print(falsif)
#> 
#> ====================================================================== 
#> FALSIFICATION SUMMARY
#> ====================================================================== 
#> 
#> Overall Falsification:
#>   Total parameter sets evaluated: 100 
#>   Compatible sets: 100 (100.0%)
#>   Falsified sets: 0 (0.0%)
#> 
#>   -> Very low falsification: Minimal data constraints
#>      Consider narrowing the sensitivity region or collecting more data.
#> 
#> ---------------------------------------------------------------------- 
#> Parameter-Specific Falsification:
#> ---------------------------------------------------------------------- 
#> 
#>  Parameter Mean_Falsification Min_Falsification Max_Falsification
#>        sn0              0.000             0.000             0.000
#>        sp0              0.000             0.000             0.000
#>     psi_sn              0.000             0.000             0.000
#>     psi_sp              0.000             0.000             0.000
#> 
#> Most constrained parameters: sn0, sp0 
#> Least constrained parameters: sn0, sp0 
#> 
#> ====================================================================== 
#> 

# View falsification plot
falsif@plot
#> TableGrob (3 x 1) "arrange": 3 grobs
#>              z     cells    name           grob
#> overall      1 (1-1,1-1) arrange gtable[layout]
#> by_parameter 2 (2-2,1-1) arrange gtable[layout]
#> joint        3 (3-3,1-1) arrange gtable[layout]
# }
```
