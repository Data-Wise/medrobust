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
