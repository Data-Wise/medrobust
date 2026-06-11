# Partial Identification Bounds for Natural Effects Under Differential Misclassification

Computes partial identification bounds for the Natural Direct Effect
(NDE) and Natural Indirect Effect (NIE) when either the exposure or
mediator is subject to differential misclassification. The method does
not require validation data.

## Usage

``` r
bound_ne(
  data,
  exposure,
  mediator,
  outcome,
  confounders = NULL,
  misclassified_variable = c("exposure", "mediator"),
  sensitivity_region = NULL,
  n_grid = 50,
  effect_scale = c("OR", "RR", "RD"),
  confidence_level = 0.95,
  bootstrap = FALSE,
  bootstrap_reps = 1000,
  bootstrap_method = c("percentile", "bca"),
  parallel = FALSE,
  n_cores = NULL,
  cache = FALSE,
  cache_dir = NULL,
  verbose = TRUE,
  stratify_by = NULL,
  use_adaptive_grid = TRUE,
  grid_method = c("lhs", "auto", "regular", "adaptive", "sobol", "binary")
)
```

## Arguments

- data:

  A data frame containing the observed variables.

- exposure:

  Character string. Name of the exposure variable (A or A\*).

- mediator:

  Character string. Name of the mediator variable (M or M\*).

- outcome:

  Character string. Name of the outcome variable (Y).

- confounders:

  Character vector. Names of confounding variables.

- misclassified_variable:

  Character string. Either "exposure" or "mediator" to indicate which
  variable is subject to misclassification.

- sensitivity_region:

  A named list defining the sensitivity region Theta_Psi. Should
  contain: `sn0_range`, `sp0_range`, `psi_sn_range`, `psi_sp_range`.
  Each element should be a numeric vector of length 2 giving the minimum
  and maximum values. If NULL, default ranges are used.

- n_grid:

  Integer. Number of grid points per parameter dimension. Default is 50.

- effect_scale:

  Character string. Scale for reporting effects: "OR" (odds ratio), "RR"
  (risk ratio), or "RD" (risk difference). Default is "OR".

- confidence_level:

  Numeric. Confidence level for bootstrap intervals. Default is 0.95.

- bootstrap:

  Logical. Whether to compute bootstrap confidence intervals. Default is
  FALSE.

- bootstrap_reps:

  Integer. Number of bootstrap replicates if bootstrap=TRUE. Default is
  1000.

- bootstrap_method:

  Character string. Bootstrap CI method: "percentile" (default) or "bca"
  (bias-corrected and accelerated). The percentile method is faster and
  adequate for most applications. BCa provides second-order accurate
  intervals but requires jackknife estimation, which is computationally
  intensive for large datasets.

- parallel:

  Logical. Whether to use parallel processing. Default is FALSE.

- n_cores:

  Integer. Number of cores for parallel processing. If NULL, uses
  detectCores() - 1. Default is NULL.

- cache:

  Logical. Whether to cache intermediate results. Default is FALSE.

- cache_dir:

  Character string. Directory for cache files. If NULL, uses temp
  directory.

- verbose:

  Logical. Whether to print progress messages. Default is TRUE.

- stratify_by:

  Character vector. Additional variables to stratify by (advanced use).

- use_adaptive_grid:

  Logical. Whether to use adaptive grid refinement for large grids
  (n_grid \>= 20). This dramatically reduces computation time by
  focusing on compatible regions. Default is TRUE.

- grid_method:

  Character string specifying grid search algorithm:

  - `"lhs"` (default): Latin Hypercube Sampling - space-filling design
    that reduces evaluations by 99% while maintaining broad coverage.
    Best for most applications (McKay et al., 1979).

  - `"auto"`: Automatically selects best method based on a 16-point
    probe of the parameter space.

  - `"regular"`: Exhaustive regular grid (n_grid^4 evaluations). Use for
    exact bounds when computational budget allows.

  - `"sobol"`: Sobol low-discrepancy sequences (Sobol, 1967). Similar to
    LHS but better for high-dimensional problems.

  - `"adaptive"`: Two-stage coarse-to-fine refinement. Effective when
    falsification rate is high.

  - `"binary"`: Binary search on parameter boundaries. Efficient when
    compatibility is monotonic in parameters.

## Value

An object of class `medrobust_bounds` containing:

- NIE_lower:

  Lower bound for Natural Indirect Effect

- NIE_upper:

  Upper bound for Natural Indirect Effect

- NDE_lower:

  Lower bound for Natural Direct Effect

- NDE_upper:

  Upper bound for Natural Direct Effect

- compatible_sets:

  Data frame of compatible parameter sets

- falsified_proportion:

  Proportion of sensitivity region falsified

- effect_scale:

  Scale used for reporting

- n_evaluated:

  Number of parameter sets evaluated

- n_compatible:

  Number of compatible parameter sets

- computation_time:

  Time taken for computation

- call:

  Original function call

- data_summary:

  Summary statistics of the data

- bootstrap_results:

  Bootstrap results if bootstrap=TRUE

## Details

This function implements the partial identification approach described
in \[Author\] (2025). The method derives bounds on causal mediation
effects by specifying a plausible range for misclassification parameters
and using testable implications to rule out empirically inconsistent
values.

The sensitivity region Theta_Psi is defined by four parameters:

- `sn0`: Baseline sensitivity (probability of correct classification
  when Y=0)

- `sp0`: Baseline specificity

- `psi_sn`: Differential sensitivity parameter (odds ratio)

- `psi_sp`: Differential specificity parameter (odds ratio)

Non-differential misclassification corresponds to psi_sn = psi_sp = 1.

## References

\[Author\] (2025). Partial Identification of Causal Mediation Effects
Under Differential Misclassification. *Biostatistics*.

McKay, M. D., Beckman, R. J., & Conover, W. J. (1979). A comparison of
three methods for selecting values of input variables in the analysis of
output from a computer code. *Technometrics*, 21(2), 239-245.

Sobol', I. M. (1967). On the distribution of points in a cube and the
approximate evaluation of integrals. *USSR Computational Mathematics and
Mathematical Physics*, 7(4), 86-112.

## See also

[`check_compatibility`](https://data-wise.github.io/medrobust/dev/reference/check_compatibility.md),
[`sensitivity_plot`](https://data-wise.github.io/medrobust/dev/reference/sensitivity_plot.md),
[`falsification_summary`](https://data-wise.github.io/medrobust/dev/reference/falsification_summary.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Load example data
data("heals_data")

# Define sensitivity region
sens_region <- list(
  sn0_range = c(0.55, 0.65),
  sp0_range = c(0.85, 0.95),
  psi_sn_range = c(1.0, 2.0),
  psi_sp_range = c(0.5, 1.0)
)

# Compute bounds for exposure misclassification
bounds <- bound_ne(
  data = heals_data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("age", "male", "smoking", "bmi"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 50
)

# View results
print(bounds)
summary(bounds)

# Visualize
sensitivity_plot(bounds, param = "psi_sn")
} # }
```
