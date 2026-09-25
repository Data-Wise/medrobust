# Create sensitivity_region object from list

Create sensitivity_region object from list

## Usage

``` r
as_sensitivity_region(region_list)
```

## Arguments

- region_list:

  List with sn0_range, sp0_range, psi_sn_range, psi_sp_range

## Value

sensitivity_region S7 object

## Examples

``` r
as_sensitivity_region(list(
  sn0_range = c(0.80, 0.95), sp0_range = c(0.85, 0.99),
  psi_sn_range = c(1, 2), psi_sp_range = c(1, 1)
))
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
