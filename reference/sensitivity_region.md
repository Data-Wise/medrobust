# Create Sensitivity Region

Constructor for sensitivity_region S7 objects. Issues a warning if the
region may be non-informative (Sn + Sp \<= 1).

## Usage

``` r
sensitivity_region(sn0_range, sp0_range, psi_sn_range, psi_sp_range)
```

## Arguments

- sn0_range:

  Numeric vector of length 2: \[min, max\] for baseline sensitivity

- sp0_range:

  Numeric vector of length 2: \[min, max\] for baseline specificity

- psi_sn_range:

  Numeric vector of length 2: \[min, max\] for sensitivity OR

- psi_sp_range:

  Numeric vector of length 2: \[min, max\] for specificity OR

## Value

A sensitivity_region S7 object

## Examples

``` r
region <- sensitivity_region(
  sn0_range = c(0.80, 0.95), sp0_range = c(0.85, 0.99),
  psi_sn_range = c(1, 2), psi_sp_range = c(1, 1)
)
region
#> 
#> Sensitivity Region (Theta_psi):
#> ---------------------------------------- 
#>   Sn0:  [0.800, 0.950]
#>   Sp0:  [0.850, 0.990]
#>   psi_Sn: [1.000, 2.000]
#>   psi_Sp: [1.000, 1.000]
#> ---------------------------------------- 
#> 
```
