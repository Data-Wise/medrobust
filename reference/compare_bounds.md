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
  n = 8000,
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
#> Compatible: 100/100 (100.0%)
#> 
#>  ============================================================ 
#> COMPUTATION COMPLETE
#> ============================================================ 
#> Time elapsed: 3.52 seconds
#> Compatible parameter sets: 100 / 100 (100.0%)
#> 
#> NIE Bounds (OR scale): [1.161, 1.381]
#> NDE Bounds (OR scale): [1.341, 1.596]
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
#> Compatible: 100/100 (100.0%)
#> 
#>  ============================================================ 
#> COMPUTATION COMPLETE
#> ============================================================ 
#> Time elapsed: 3.68 seconds
#> Compatible parameter sets: 100 / 100 (100.0%)
#> 
#> NIE Bounds (OR scale): [1.148, 1.457]
#> NDE Bounds (OR scale): [1.271, 1.613]
#> ============================================================ 
#> 

comparison <- compare_bounds(
  list(conservative = bounds1, liberal = bounds2)
)
print(comparison)
#>                  analysis NIE_lower NIE_upper NDE_lower NDE_upper
#> conservative conservative  1.160812  1.381489  1.340810  1.595705
#> liberal           liberal  1.148348  1.457499  1.270886  1.613025
#>              falsified_prop
#> conservative              0
#> liberal                   0
# }
```
