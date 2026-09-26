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
  ci_method = c("none", "analytic"),
  ci_n_boot = 200L,
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

  Numeric. Confidence level for confidence intervals. Default is 0.95.

- ci_method:

  Character. `"none"` (default) or `"analytic"`. If `"analytic"`,
  attaches Imbens-Manski confidence intervals (see
  [`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md))
  to the result's `@analytic_ci` slot.

- ci_n_boot:

  Integer. Resamples for the analytic CI endpoint SEs. Default 200.

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

  Logical. Whether `grid_method = "adaptive"` may run. With `FALSE`,
  `"adaptive"` falls back to the regular grid, and on the exposure path
  `"auto"` uses its corner probe instead of adaptive refinement.
  Adaptive refinement does not reduce the number of evaluations (see
  `grid_method`). Default is TRUE.

- grid_method:

  Character string specifying which points of the sensitivity region are
  evaluated. The bounds are the minimum and maximum over the compatible
  points evaluated, so they are an inner approximation of the identified
  set: a method that evaluates fewer points, or no corners, can only
  report narrower bounds.

  - `"lhs"` (default): Latin hypercube sample of `ceiling(n_grid^2)`
    points (McKay et al., 1979), from a fixed internal design, so the
    bounds are reproducible. Fast, but it evaluates no corners and its
    bounds can be much narrower than the regular grid's; check them
    against `"regular"` before reporting.

  - `"regular"`: every combination of `n_grid` equally spaced values per
    parameter (`n_grid^4` points, including all corners). The only
    method that uses `parallel = TRUE`.

  - `"sobol"`: a Halton-type low-discrepancy sequence (van der Corput in
    bases 3 to 6) of `ceiling(n_grid^2)` points; despite the name, not a
    Sobol' sequence. Deterministic; evaluates no corners.

  - `"adaptive"`: a coarse grid, then a full `n_grid^4` grid over the
    bounding box of the compatible coarse points. Never evaluates fewer
    points than `"regular"`; stops with an error if no coarse point is
    compatible. Requires `use_adaptive_grid = TRUE`.

  - `"binary"`: despite the name, no binary search. Evaluates the 16
    corners; if none or all are compatible, adds a 50-point Latin
    hypercube, otherwise 10,000 random points with Beta(0.5, 0.5)
    coordinates (concentrated near the edges). Ignores `n_grid`; call
    [`set.seed()`](https://rdrr.io/r/base/Random.html) first for
    reproducible bounds.

  - `"auto"`: on the exposure path with `use_adaptive_grid = TRUE`, runs
    `"adaptive"`. Otherwise evaluates the 16 corners and uses the
    regular grid (all compatible), `"binary"` (more than 75%), `"sobol"`
    (fewer than 25%, but not none) or `"lhs"` (none, or 25% to 75%).

  See the grid-search article at
  <https://data-wise.github.io/medrobust/articles/grid-search-algorithms.html>
  for a benchmark.

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

- evaluated_sets:

  Every evaluated parameter set with a logical `compatible` column; see
  [`extract_falsified_region`](https://data-wise.github.io/medrobust/reference/extract_falsified_region.md)

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
in Tofighi, D. (2025). The method derives bounds on causal mediation
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

Tofighi, D. (2025). Partial Identification of Causal Mediation Effects
Under Differential Misclassification. *Biostatistics*.

McKay, M. D., Beckman, R. J., & Conover, W. J. (1979). A comparison of
three methods for selecting values of input variables in the analysis of
output from a computer code. *Technometrics*, 21(2), 239-245.

## See also

[`check_compatibility`](https://data-wise.github.io/medrobust/reference/check_compatibility.md),
[`sensitivity_plot`](https://data-wise.github.io/medrobust/reference/sensitivity_plot.md),
[`falsification_summary`](https://data-wise.github.io/medrobust/reference/falsification_summary.md)

## Examples

``` r
# \donttest{
# Simulate data with a known mediator-misclassification mechanism
sim <- simulate_dm_data(
  n = 8000,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 1
)

# Sensitivity region containing the (here non-differential) truth
sens_region <- list(
  sn0_range = c(0.80, 0.99),
  sp0_range = c(0.80, 0.99),
  psi_sn_range = c(0.8, 1.5),
  psi_sp_range = c(0.8, 1.5)
)

# Compute partial-identification bounds for mediator misclassification.
# The raw bound [L, U] is consistent but is NOT a confidence set; at finite n
# it can under-cover the truth, so we add Imbens-Manski confidence intervals
# in the same fit via ci_method = "analytic".
set.seed(1)
bounds <- bound_ne(
  data = sim@observed,
  exposure = "A",
  mediator = "M_star",
  outcome = "Y",
  confounders = "C1",
  misclassified_variable = "mediator",
  sensitivity_region = sens_region,
  n_grid = 10,
  ci_method = "analytic", ci_n_boot = 50
)
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
#> Computing analytic (Imbens-Manski) confidence intervals...
#> 
#>  ============================================================ 
#> COMPUTATION COMPLETE
#> ============================================================ 
#> Time elapsed: 3.65 seconds
#> Compatible parameter sets: 100 / 100 (100.0%)
#> 
#> NIE Bounds (OR scale): [1.148, 1.457]
#> NDE Bounds (OR scale): [1.271, 1.613]
#> ============================================================ 
#> 

# View results
print(bounds)
#> 
#> ====================================================================== 
#> PARTIAL IDENTIFICATION BOUNDS
#> ====================================================================== 
#> 
#> Effect Scale: OR 
#> Misclassified Variable: mediator 
#> 
#> ---------------------------------------------------------------------- 
#> NATURAL INDIRECT EFFECT (NIE)
#> ---------------------------------------------------------------------- 
#>   Lower Bound: 1.1483
#>   Upper Bound: 1.4575
#>   Width:       0.3092
#> 
#> ---------------------------------------------------------------------- 
#> NATURAL DIRECT EFFECT (NDE)
#> ---------------------------------------------------------------------- 
#>   Lower Bound: 1.2709
#>   Upper Bound: 1.6130
#>   Width:       0.3421
#> 
#> ---------------------------------------------------------------------- 
#> SENSITIVITY ANALYSIS
#> ---------------------------------------------------------------------- 
#>   Parameter sets evaluated: 100
#>   Compatible sets:          100 (100.0%)
#>   Falsified sets:           0 (0.0%)
#> 
#> ====================================================================== 
#> Use summary() for detailed diagnostics
#> ====================================================================== 
#> 
summary(bounds)
#> 
#> ====================================================================== 
#> PARTIAL IDENTIFICATION BOUNDS
#> ====================================================================== 
#> 
#> Effect Scale: OR 
#> Misclassified Variable: mediator 
#> 
#> ---------------------------------------------------------------------- 
#> NATURAL INDIRECT EFFECT (NIE)
#> ---------------------------------------------------------------------- 
#>   Lower Bound: 1.1483
#>   Upper Bound: 1.4575
#>   Width:       0.3092
#> 
#> ---------------------------------------------------------------------- 
#> NATURAL DIRECT EFFECT (NDE)
#> ---------------------------------------------------------------------- 
#>   Lower Bound: 1.2709
#>   Upper Bound: 1.6130
#>   Width:       0.3421
#> 
#> ---------------------------------------------------------------------- 
#> SENSITIVITY ANALYSIS
#> ---------------------------------------------------------------------- 
#>   Parameter sets evaluated: 100
#>   Compatible sets:          100 (100.0%)
#>   Falsified sets:           0 (0.0%)
#> 
#> ====================================================================== 
#> Use summary() for detailed diagnostics
#> ====================================================================== 
#> 
#> 
#> ====================================================================== 
#> DETAILED SUMMARY
#> ====================================================================== 
#> 
#> Sensitivity Region:
#>   Sn0:     [0.800, 0.990]
#>   Sp0:     [0.800, 0.990]
#>   psi_Sn:    [0.800, 1.500]
#>   psi_Sp:    [0.800, 1.500]
#> 
#> Naive Estimates (no measurement error correction):
#> Data Summary:
#>   Sample size: 8000
#> 
#> Compatible Parameter Sets (first 5):
#>         sn0       sp0    psi_sn    psi_sp      NIE      NDE
#> 1 0.9542000 0.9348607 1.3537490 0.9619354 1.160986 1.595467
#> 2 0.8454987 0.8497896 1.4162717 1.0896619 1.265177 1.464075
#> 3 0.8325232 0.9779831 0.9926369 1.0026117 1.201886 1.541173
#> 4 0.9305171 0.8085158 0.8983405 1.0358055 1.313987 1.409690
#> 5 0.9026740 0.9621810 0.9561360 0.9497378 1.177392 1.573235
#> 
bounds@analytic_ci$NDE   # raw [L, U] plus Imbens-Manski confidence interval
#>      lower      upper   se_lower   se_upper   ci_lower   ci_upper 
#> 1.27088581 1.61302492 0.08751905 0.10507136 1.12692987 1.78585183 

# Visualize
sensitivity_plot(bounds, param = "psi_sn")

# }
```
