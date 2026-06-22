# Compare Bounds Across Multiple Analyses

Compare partial identification bounds from multiple analyses (e.g.,
different sensitivity regions, different datasets, different
assumptions).

## Usage

``` r
compare_bounds(bounds_list, labels = NULL)
```

## Arguments

- bounds_list:

  A named list of `medrobust_bounds` objects.

- labels:

  Optional character vector of labels for each analysis. If NULL, uses
  names from bounds_list.

## Value

A data frame comparing the bounds, and optionally a plot.

## Examples

``` r
# \donttest{
# Compare bounds under different sensitivity assumptions
sim <- simulate_dm_data(
  n = 500,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 1
)
args0 <- list(
  data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
  confounders = "C1", misclassified_variable = "mediator", n_grid = 10
)
set.seed(1)
bounds1 <- do.call(bound_ne, c(args0, list(sensitivity_region = list(
  sn0_range = c(0.82, 0.97), sp0_range = c(0.82, 0.97),
  psi_sn_range = c(0.85, 1.3), psi_sp_range = c(0.85, 1.3)))))
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
#> Compatible: 84/100 (84.0%)
#> 
#>  ============================================================ 
#> COMPUTATION COMPLETE
#> ============================================================ 
#> Time elapsed: 3.13 seconds
#> Compatible parameter sets: 84 / 100 (84.0%)
#> 
#> NIE Bounds (OR scale): [1.156, 1.295]
#> NDE Bounds (OR scale): [2.288, 2.563]
#> ============================================================ 
#> 
bounds2 <- do.call(bound_ne, c(args0, list(sensitivity_region = list(
  sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
  psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)))))
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
#> Compatible: 77/100 (77.0%)
#> 
#>  ============================================================ 
#> COMPUTATION COMPLETE
#> ============================================================ 
#> Time elapsed: 3 seconds
#> Compatible parameter sets: 77 / 100 (77.0%)
#> 
#> NIE Bounds (OR scale): [1.143, 1.315]
#> NDE Bounds (OR scale): [2.253, 2.591]
#> ============================================================ 
#> 

comparison <- compare_bounds(
  list(conservative = bounds1, liberal = bounds2)
)
print(comparison)
#>                  analysis NIE_lower NIE_upper NDE_lower NDE_upper
#> conservative conservative  1.155871  1.294767  2.288433  2.563423
#> liberal           liberal  1.143389  1.315085  2.253076  2.591408
#>              falsified_prop
#> conservative           0.16
#> liberal                0.23
# }
```
