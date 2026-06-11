# Falsification Summary Class

S7 class for storing falsification analysis results showing which
regions of the sensitivity space are empirically ruled out.

## Usage

``` r
.falsification_summary_class(
  overall = integer(0),
  n_evaluated = integer(0),
  n_compatible = integer(0),
  n_falsified = integer(0),
  by_parameter = NULL,
  joint_falsification = NULL,
  most_constrained = character(0),
  least_constrained = character(0),
  plot = NULL
)
```
