# Extract Compatible Parameter Sets

Extract the compatible parameter sets from a bounds analysis.

## Usage

``` r
extract_bounds(bounds_object)
```

## Arguments

- bounds_object:

  An object of class `medrobust_bounds`

## Value

A data frame containing compatible parameter sets

## Examples

``` r
# \donttest{
sim <- simulate_dm_data(
  n = 2000,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 1
)
bounds <- bound_ne(
  data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
  confounders = "C1", misclassified_variable = "mediator",
  sensitivity_region = list(
    sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
    psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)
  ),
  n_grid = 10, verbose = FALSE
)
head(extract_bounds(bounds))
#>         sn0       sp0    psi_sn    psi_sp      NIE      NDE
#> 1 0.9542000 0.9348607 1.3537490 0.9619354 1.125633 1.647831
#> 2 0.8454987 0.8497896 1.4162717 1.0896619 1.192847 1.554980
#> 3 0.8325232 0.9779831 0.9926369 1.0026117 1.167010 1.589406
#> 4 0.9305171 0.8085158 0.8983405 1.0358055 1.232621 1.504804
#> 5 0.9026740 0.9621810 0.9561360 0.9497378 1.144488 1.620683
#> 6 0.8752624 0.8374582 1.2206655 0.8215801 1.174306 1.579532
# }
```
