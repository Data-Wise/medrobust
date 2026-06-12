# Power Analysis Result Class

S7 class for storing power analysis results for partial identification
bounds.

## Arguments

- power_curve:

  Data frame with power and width by sample size

- true_effect:

  True effect value used in simulations

- target_power:

  Target power level for sample size recommendations

- target_width:

  Target bound width for sample size recommendations

- recommended_n_power:

  Recommended sample size to achieve target power

- recommended_n_width:

  Recommended sample size to achieve target width

- simulation_params:

  List of simulation parameters used
