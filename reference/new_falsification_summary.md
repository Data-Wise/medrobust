# Create Falsification Summary Object

Low-level constructor for falsification_summary S7 objects. Most users
should use the falsification_summary() function which analyzes bounds.

## Usage

``` r
new_falsification_summary(
  overall,
  n_evaluated,
  n_compatible,
  n_falsified,
  by_parameter = NULL,
  joint_falsification = NULL,
  most_constrained = character(0),
  least_constrained = character(0),
  plot = NULL
)
```

## Arguments

- overall:

  Overall falsification rate

- n_evaluated:

  Number of parameter sets evaluated

- n_compatible:

  Number of compatible parameter sets

- n_falsified:

  Number of falsified parameter sets

- by_parameter:

  Parameter-specific falsification (optional)

- joint_falsification:

  Joint falsification patterns (optional)

- most_constrained:

  Most constrained parameters (optional)

- least_constrained:

  Least constrained parameters (optional)

- plot:

  ggplot2 object (optional)

## Value

A falsification_summary S7 object

## Examples

``` r
new_falsification_summary(
  overall = 0.25, n_evaluated = 100L, n_compatible = 75L, n_falsified = 25L
)
#> 
#> ====================================================================== 
#> FALSIFICATION SUMMARY
#> ====================================================================== 
#> 
#> Overall Falsification:
#>   Total parameter sets evaluated: 100 
#>   Compatible sets: 75 (75.0%)
#>   Falsified sets: 25 (25.0%)
#> 
#>   -> Low falsification: Weak data constraints
#>      Most of the sensitivity region remains compatible.
#> 
#> ====================================================================== 
#> 
```
