# S7 Package Documentation: medrobust

This document provides a comprehensive overview of the S7 class and
method architecture for the `medrobust` R package.

## Design Overview

The `medrobust` package leverages the S7 object-oriented system to
provide a robust and type-safe framework for sensitivity analysis in
mediation contexts. The architecture is centered around a few key
classes:

- `medrobust_bounds`: The main result container, holding the computed
  partial identification bounds for the Natural Indirect Effect (NIE)
  and Natural Direct Effect (NDE). It encapsulates all aspects of a
  single analysis run.
- `sensitivity_region`: A helper class that formally defines the
  multi-dimensional parameter space (Θψ) over which the sensitivity
  analysis is performed.
- `compatibility_test`: Stores the results of checking whether a
  specific point in the sensitivity parameter space is compatible with
  the observed data.
- `bootstrap_results`: Contains the results of bootstrap inference for
  the computed bounds, providing confidence intervals.
- `falsification_summary`: Summarizes the extent to which the
  sensitivity parameter space is falsified (ruled out) by the observed
  data.
- `simulated_dm_data`: A class to hold simulated data with known
  characteristics, essential for validation and power analysis.
- `power_analysis_result`: Stores the results from a power analysis
  simulation, including the power curve and sample size recommendations.

The design emphasizes encapsulation and clear separation of concerns.
`medrobust_bounds` acts as the central hub, composing other objects like
`sensitivity_region` and `bootstrap_results`. Methods are implemented
polymorphically for `print`, `summary`, and `plot`, providing
user-friendly ways to inspect and visualize the results.

## UML Class Diagram

Below is a PlantUML diagram illustrating the relationships between the
S7 classes in the `medrobust` package.

``` plantuml
@startuml
!theme plain
skinparam classAttributeIconSize 0
skinparam linetype ortho

class sensitivity_region {
  +sn0_range: numeric[2]
  +sp0_range: numeric[2]
  +psi_sn_range: numeric[2]
  +psi_sp_range: numeric[2]
  +sensitivity_region()
}

class bootstrap_results {
  +method: character
  +n_reps: integer
  +n_failed: integer
  +confidence_level: numeric
  +nie_lower_ci: numeric
  +nie_upper_ci: numeric
  +nde_lower_ci: numeric
  +nde_upper_ci: numeric
  +boot_nie_lower: numeric
  +boot_nie_upper: numeric
  +boot_nde_lower: numeric
  +boot_nde_upper: numeric
  +z0: any
  +acceleration: any
}

class medrobust_bounds {
  +NIE_lower: numeric
  +NIE_upper: numeric
  +NDE_lower: numeric
  +NDE_upper: numeric
  +compatible_sets: data.frame
  +n_compatible: integer
  +n_evaluated: integer
  +falsified_proportion: numeric
  +effect_scale: character
  +misclassified_variable: character
  +naive_estimates: list
  +data_summary: list
  +call: any
  +print()
  +summary()
  +as.data.frame()
}

class compatibility_test {
  +compatible: logical
  +psi: list
  +sn1: any
  +sp1: any
  +n_constraints_total: integer
  +n_constraints_satisfied: integer
  +n_constraints_violated: integer
  +violated_constraints: data.frame
  +implied_probabilities: list
  +stratum_details: list
  +misclassified_variable: character
  +reason: any
  +print()
  +summary()
}

class falsification_summary {
  +overall: numeric
  +n_evaluated: integer
  +n_compatible: integer
  +n_falsified: integer
  +by_parameter: any
  +joint_falsification: any
  +most_constrained: character
  +least_constrained: character
  +plot: any
  +print()
  +summary()
}

class simulated_dm_data {
  +observed: data.frame
  +truth: any
  +true_effects: list
  +generation_params: list
  +misclassification_applied: list
  +print()
  +summary()
}

class power_analysis_result {
  +power_curve: data.frame
  +true_effect: numeric
  +target_power: numeric
  +target_width: numeric
  +recommended_n_power: integer
  +recommended_n_width: integer
  +simulation_params: list
  +print()
  +plot()
}

medrobust_bounds o-- "1" sensitivity_region
medrobust_bounds o-- "0..1" bootstrap_results

@enduml
```

## Class Documentation

### `medrobust_bounds`

- **Purpose**: The primary container for the results of a partial
  identification analysis. It stores the calculated bounds for NIE and
  NDE, along with extensive metadata about the analysis.

- **Properties**:

  - `NIE_lower`: (numeric) The lower bound of the Natural Indirect
    Effect.
  - `NIE_upper`: (numeric) The upper bound of the Natural Indirect
    Effect.
  - `NDE_lower`: (numeric) The lower bound of the Natural Direct Effect.
  - `NDE_upper`: (numeric) The upper bound of the Natural Direct Effect.
  - `compatible_sets`: (data.frame) A data frame where each row is a set
    of sensitivity parameters compatible with the data.
  - `n_compatible`: (integer) The total number of compatible parameter
    sets found.
  - `n_evaluated`: (integer) The total number of parameter sets
    evaluated from the sensitivity region.
  - `falsified_proportion`: (numeric) The proportion of the sensitivity
    parameter space that was falsified (i.e., incompatible with the
    data).
  - `effect_scale`: (character) The scale of the reported effects (e.g.,
    “OR”, “RR”, “RD”).
  - `misclassified_variable`: (character) The variable assumed to be
    misclassified (“exposure” or “mediator”).
  - `sensitivity_region`: (`sensitivity_region`) The S7 object defining
    the parameter space for the analysis.
  - `naive_estimates`: (list) A list containing the NIE and NDE
    calculated without correction for misclassification.
  - `bootstrap_results`: (`bootstrap_results` \| NULL) An S7 object
    containing bootstrap confidence intervals for the bounds, or NULL if
    not computed.
  - `data_summary`: (list) Summary statistics of the input data.
  - `call`: (call) The function call that generated the object.

- **Example**:

  ``` r

  # This is a conceptual example. Direct construction is typically done
  # by the bound_ne() function.
  bounds_result <- medrobust_bounds(
    NIE_lower = 0.1,
    NIE_upper = 0.5,
    NDE_lower = 0.2,
    NDE_upper = 0.8,
    compatible_sets = data.frame(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    n_compatible = 1L,
    n_evaluated = 100L,
    falsified_proportion = 0.99,
    effect_scale = "RD",
    misclassified_variable = "exposure",
    sensitivity_region = sensitivity_region(
      sn0_range = c(0.8, 1), sp0_range = c(0.8, 1),
      psi_sn_range = c(1, 1), psi_sp_range = c(1, 1)
    )
  )
  ```

### `sensitivity_region`

- **Purpose**: Defines the multi-dimensional parameter space for the
  sensitivity analysis. It specifies the plausible range for baseline
  sensitivity/specificity and the odds ratios for differential
  misclassification.

- **Properties**:

  - `sn0_range`: (numeric) A vector of length 2 specifying the
    `[min, max]` range for baseline sensitivity (Sn0).
  - `sp0_range`: (numeric) A vector of length 2 specifying the
    `[min, max]` range for baseline specificity (Sp0).
  - `psi_sn_range`: (numeric) A vector of length 2 specifying the
    `[min, max]` range for the odds ratio comparing sensitivity across
    covariate levels.
  - `psi_sp_range`: (numeric) A vector of length 2 specifying the
    `[min, max]` range for the odds ratio comparing specificity across
    covariate levels.

- **Constructor**:
  [`sensitivity_region()`](https://data-wise.github.io/medrobust/dev/reference/sensitivity_region.md)

- **Example**:

  ``` r

  # Define a sensitivity region
  region <- sensitivity_region(
    sn0_range = c(0.85, 0.95),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(0.8, 1.2),
    psi_sp_range = c(0.9, 1.1)
  )
  ```

### `compatibility_test`

- **Purpose**: Stores the detailed results of a test for a single point
  in the sensitivity parameter space, indicating whether that point is
  compatible with the observed data.

- **Properties**:

  - `compatible`: (logical) `TRUE` if the parameter set is compatible,
    `FALSE` otherwise.
  - `psi`: (list) The list of sensitivity parameters that were tested
    (sn0, sp0, psi_sn, psi_sp).
  - `violated_constraints`: (data.frame) If incompatible, a data frame
    detailing which constraints were violated.
  - `reason`: (character) A string explaining the reason for
    incompatibility, if applicable.

- **Example**:

  ``` r

  # This is a conceptual example. Direct construction is typically done
  # by the check_compatibility() function.
  test_result <- compatibility_test(
      compatible = FALSE,
      psi = list(sn0 = 0.7, sp0 = 0.7, psi_sn = 1, psi_sp = 1),
      reason = "Implied probabilities are not in [0, 1]"
  )
  ```

### `bootstrap_results`

- **Purpose**: Encapsulates the results of bootstrap inference performed
  on the partial identification bounds.

- **Properties**:

  - `method`: (character) The bootstrap method used (“percentile” or
    “bca”).
  - `n_reps`: (integer) The number of bootstrap replications.
  - `confidence_level`: (numeric) The confidence level for the intervals
    (e.g., 0.95).
  - `nie_lower_ci`: (numeric) The confidence interval for the lower
    bound of the NIE.
  - `nie_upper_ci`: (numeric) The confidence interval for the upper
    bound of the NIE.
  - `nde_lower_ci`: (numeric) The confidence interval for the lower
    bound of the NDE.
  - `nde_upper_ci`: (numeric) The confidence interval for the upper
    bound of the NDE.

- **Example**:

  ``` r

  # Conceptual example.
  boot_res <- bootstrap_results(
      method = "bca",
      n_reps = 1000L,
      confidence_level = 0.95,
      nie_lower_ci = c(0.05, 0.15),
      nie_upper_ci = c(0.45, 0.55),
      nde_lower_ci = c(0.15, 0.25),
      nde_upper_ci = c(0.75, 0.85)
  )
  ```

## Method Documentation

### `print()`

- **Functionality**: Provides a concise, user-friendly summary of an S7
  object, suitable for display in the console.

- **Polymorphism**:

  - `print(medrobust_bounds)`: Displays the calculated NIE/NDE bounds,
    the falsification summary, and bootstrap CIs if available.
  - `print(compatibility_test)`: Shows the tested parameters and clearly
    states whether they were compatible or not, providing a reason for
    falsification if applicable.
  - `print(sensitivity_region)`: Prints the defined ranges for each
    sensitivity parameter.

- **Example**:

  ``` r

  # Assuming 'bounds_result' is a medrobust_bounds object
  print(bounds_result)

  # Output will be a formatted summary of the bounds.
  ```

### `summary()`

- **Functionality**: Provides a more detailed summary than
  [`print()`](https://rdrr.io/r/base/print.html), often including
  additional diagnostic information.

- **Polymorphism**:

  - `summary(medrobust_bounds)`: First calls
    [`print()`](https://rdrr.io/r/base/print.html), then adds details
    about the sensitivity region, naive estimates, and a preview of
    compatible parameter sets.
  - `summary(compatibility_test)`: First calls
    [`print()`](https://rdrr.io/r/base/print.html), then adds
    stratum-level details if the analysis was stratified.

- **Example**:

  ``` r

  # Assuming 'bounds_result' is a medrobust_bounds object
  summary(bounds_result)

  # Output will include the print summary plus extra details.
  ```

### `plot()`

- **Functionality**: Generates a visualization of the object’s data.

- **Polymorphism**:

  - `plot(power_analysis_result)`: Creates a multi-panel plot showing
    the power curve, the bound width curve, and the coverage rate as a
    function of sample size. Requires `ggplot2` and `patchwork` or
    `gridExtra`.

- **Example**:

  ``` r

  # Assuming 'power_res' is a power_analysis_result object
  # This will generate and display the plots.
  plot(power_res)
  ```

### `as.data.frame()`

- **Functionality**: Converts an S7 object into a flat `data.frame`.

- **Polymorphism**:

  - `as.data.frame(medrobust_bounds)`: Creates a one-row data frame
    containing all key results from the bounds object, including the
    bounds themselves, widths, and all bootstrap CI endpoints if
    available. This is useful for programmatically extracting and
    comparing results from multiple analyses.

- **Example**:

  ``` r

  # Assuming 'bounds_result' is a medrobust_bounds object
  df <- as.data.frame(bounds_result)

  # 'df' is now a data.frame with columns like NIE_lower, NIE_upper, etc.
  ```
