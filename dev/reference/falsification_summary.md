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
  [`bound_ne`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md)

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

[`bound_ne`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md),
[`check_compatibility`](https://data-wise.github.io/medrobust/dev/reference/check_compatibility.md)

## Examples

``` r
if (FALSE) { # \dontrun{
bounds <- bound_ne(...)

falsif <- falsification_summary(bounds)
print(falsif)

# View falsification plot
falsif$plot
} # }
```
