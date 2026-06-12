# Power Analysis for Partial Identification Bounds

Conducts simulation-based power analysis to determine the sample size
needed to achieve a target bound width or to rule out the null
hypothesis with high probability.

## Usage

``` r
power_analysis(
  true_params,
  dm_params,
  sensitivity_region,
  misclass_type = c("exposure", "mediator"),
  sample_sizes = seq(100, 1000, by = 100),
  target_width = NULL,
  target_power = 0.8,
  alpha = 0.05,
  effect = c("NIE", "NDE"),
  n_sim = 100,
  n_grid = 30,
  confounders = 1,
  parallel = TRUE,
  n_cores = NULL,
  verbose = TRUE,
  seed = 12345
)
```

## Arguments

- true_params:

  Named list of true causal parameters (see
  [`simulate_dm_data`](https://data-wise.github.io/medrobust/reference/simulate_dm_data.md))

- dm_params:

  Named list of misclassification parameters

- sensitivity_region:

  Named list defining Theta_Psi for bound_ne

- misclass_type:

  Character string. "exposure" or "mediator"

- sample_sizes:

  Integer vector. Sample sizes to evaluate. Default is seq(100, 1000, by
  = 100).

- target_width:

  Numeric. Target bound width. If specified, finds minimum sample size
  to achieve this width with high probability. Default is NULL.

- target_power:

  Numeric. Target power for rejecting null. Default is 0.80.

- alpha:

  Numeric. Significance level. Default is 0.05.

- effect:

  Character string. Which effect to power for: "NIE" or "NDE". Default
  is "NIE".

- n_sim:

  Integer. Number of simulation replicates per sample size. Default is
  100.

- n_grid:

  Integer. Grid resolution for bound_ne. Default is 30.

- confounders:

  Integer. Number of confounders. Default is 1.

- parallel:

  Logical. Use parallel processing? Default is TRUE.

- n_cores:

  Integer. Number of cores. Default is NULL (auto-detect).

- verbose:

  Logical. Print progress? Default is TRUE.

- seed:

  Integer. Random seed. Default is 12345.

## Value

An S7 object of class `power_analysis_result` containing:

- power_curve:

  Data frame with power by sample size

- true_effect:

  True effect value

- target_power:

  Target power level

- target_width:

  Target bound width (if specified)

- recommended_n_power:

  Recommended sample size for target power

- recommended_n_width:

  Recommended sample size for target width

- simulation_params:

  Parameters used for simulation

## See also

[`simulate_dm_data`](https://data-wise.github.io/medrobust/reference/simulate_dm_data.md),
[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Power analysis for exposure DM with moderate effects
power_result <- power_analysis(
  true_params = list(beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405),
  dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
  sensitivity_region = list(
    sn0_range = c(0.80, 0.90),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(1.0, 2.0),
    psi_sp_range = c(1.0, 1.0)
  ),
  misclass_type = "exposure",
  sample_sizes = c(200, 400, 600, 800, 1000),
  target_width = 0.3,
  target_power = 0.80,
  n_sim = 100
)

print(power_result)
plot(power_result)
} # }
```
