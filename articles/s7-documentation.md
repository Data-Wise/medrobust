# S7 Class Design and Usage in `medrobust`

## Introduction

The `medrobust` package leverages the S7 object-oriented system to
provide a modern, robust, and type-safe framework for conducting
sensitivity analysis in mediation contexts. This vignette details the
design and usage of the core S7 classes and their associated methods.

The architecture is centered around a few key classes:

- `medrobust_bounds`: The main result container for the partial
  identification bounds.
- `sensitivity_region`: A helper class that defines the sensitivity
  parameter space.
- `compatibility_test`: Stores results from checking if specific
  sensitivity parameters are compatible with the data.
- `bootstrap_results`: Contains bootstrap inference results for the
  bounds.
- `falsification_summary`: Summarizes the portion of the sensitivity
  space ruled out by the data.
- `simulated_dm_data`: Holds simulated data for validation and power
  analysis.
- `power_analysis_result`: Stores results from power analysis
  simulations.

This design promotes encapsulation and clear separation of concerns,
with `medrobust_bounds` acting as the central hub. Polymorphic methods
like [`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) provide a
consistent and user-friendly interface for interacting with the results.

## UML Class Diagram

The following diagram illustrates the relationships between the S7
classes in the `medrobust` package.

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
  +confidence_level: numeric
  +nie_lower_ci: numeric
  +nie_upper_ci: numeric
  +nde_lower_ci: numeric
  +nde_upper_ci: numeric
}

class medrobust_bounds {
  +NIE_lower: numeric
  +NIE_upper: numeric
  +NDE_lower: numeric
  +NDE_upper: numeric
  +n_compatible: integer
  +falsified_proportion: numeric
  +effect_scale: character
  +print()
  +summary()
  +as.data.frame()
}

class compatibility_test {
  +compatible: logical
  +psi: list
  +reason: any
  +print()
  +summary()
}

class falsification_summary {
  +overall: numeric
  +n_evaluated: integer
  +n_falsified: integer
  +print()
  +summary()
}

class simulated_dm_data {
  +observed: data.frame
  +truth: any
  +true_effects: list
  +print()
  +summary()
}

class power_analysis_result {
  +power_curve: data.frame
  +true_effect: numeric
  +target_power: numeric
  +recommended_n_power: integer
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
  identification analysis. It stores the calculated bounds for the
  Natural Indirect Effect (NIE) and Natural Direct Effect (NDE).

- **Properties**:

  - `NIE_lower`, `NIE_upper`: (numeric) The lower and upper bounds for
    the NIE.
  - `NDE_lower`, `NDE_upper`: (numeric) The lower and upper bounds for
    the NDE.
  - `compatible_sets`: (data.frame) A data frame of sensitivity
    parameters compatible with the data.
  - `n_compatible`: (integer) The number of compatible parameter sets
    found.
  - `n_evaluated`: (integer) The total number of parameter sets
    evaluated.
  - `falsified_proportion`: (numeric) The proportion of the sensitivity
    space that was falsified.
  - `effect_scale`: (character) The scale of the effects (“OR”, “RR”, or
    “RD”).
  - `misclassified_variable`: (character) The variable assumed to be
    misclassified (“exposure” or “mediator”).
  - `sensitivity_region`: (`sensitivity_region`) The object defining the
    analysis’s parameter space.
  - `bootstrap_results`: (`bootstrap_results` \| NULL) An object
    containing bootstrap CIs, if computed.

- **Example**:

  ``` r

  # Conceptual example; construction is handled by bound_ne()
  library(medrobust)

  # Define a sensitivity region first
  region <- sensitivity_region(
    sn0_range = c(0.8, 1), sp0_range = c(0.8, 1),
    psi_sn_range = c(1, 1), psi_sp_range = c(1, 1)
  )

  bounds_result <- new("medrobust_bounds",
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
    sensitivity_region = region
  )

  print(bounds_result)
  ```

### `sensitivity_region`

- **Purpose**: Defines the multi-dimensional parameter space for the
  sensitivity analysis.

- **Properties**:

  - `sn0_range`: (numeric) `[min, max]` range for baseline sensitivity
    (Sn0).
  - `sp0_range`: (numeric) `[min, max]` range for baseline specificity
    (Sp0).
  - `psi_sn_range`: (numeric) `[min, max]` range for the sensitivity
    odds ratio.
  - `psi_sp_range`: (numeric) `[min, max]` range for the specificity
    odds ratio.

- **Constructor**:
  [`sensitivity_region()`](https://data-wise.github.io/medrobust/reference/sensitivity_region.md)

- **Example**:

  ``` r

  # Define a sensitivity region for analysis
  region <- sensitivity_region(
    sn0_range = c(0.85, 0.95),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(0.8, 1.2),
    psi_sp_range = c(0.9, 1.1)
  )

  print(region)
  ```

### `compatibility_test`

- **Purpose**: Stores detailed results from testing a single point in
  the sensitivity parameter space.

- **Properties**:

  - `compatible`: (logical) `TRUE` if the parameter set is compatible
    with the data.
  - `psi`: (list) The list of sensitivity parameters that were tested.
  - `violated_constraints`: (data.frame) If incompatible, details on the
    violated constraints.
  - `reason`: (character) A string explaining the reason for
    incompatibility.

- **Example**:

  ``` r

  # Conceptual example; construction is handled by check_compatibility()
  test_result <- new("compatibility_test",
      compatible = FALSE,
      psi = list(sn0 = 0.7, sp0 = 0.7, psi_sn = 1, psi_sp = 1),
      reason = "Implied probabilities are not in [0, 1]"
  )

  print(test_result)
  ```

## Method Documentation

### `print()`

- **Functionality**: Provides a concise, user-friendly summary of an S7
  object.
- **Parameters**:
  - `x`: The S7 object to print.
- **Return Value**: Invisibly returns the object `x`.
- **Example**:
  `r # Assuming 'bounds_result' is a medrobust_bounds object from a previous run # print(bounds_result) # This would display a formatted summary of the bounds in the console.`

### `summary()`

- **Functionality**: Provides a more detailed summary than
  [`print()`](https://rdrr.io/r/base/print.html), including diagnostic
  information.
- **Parameters**:
  - `object`: The S7 object to summarize.
- **Return Value**: Invisibly returns the object `object`.
- **Example**:
  `r # Assuming 'bounds_result' is a medrobust_bounds object # summary(bounds_result) # This would display the print() summary plus extra details like naive estimates.`

### `plot()`

- **Functionality**: Generates a visualization of the object’s data.
  Currently implemented for `power_analysis_result`.
- **Parameters**:
  - `x`: A `power_analysis_result` object.
- **Return Value**: A `ggplot` object (or a combined plot object).
- **Example**:
  `r # Assuming 'power_res' is a power_analysis_result object # plot(power_res) # This would generate and display power and bound width curves.`

### `as.data.frame()`

- **Functionality**: Converts a `medrobust_bounds` object into a flat
  `data.frame`.
- **Parameters**:
  - `x`: A `medrobust_bounds` object.
- **Return Value**: A single-row `data.frame` containing key results.
- **Example**:
  `r # Assuming 'bounds_result' is a medrobust_bounds object # df <- as.data.frame(bounds_result) # 'df' would now be a data.frame with columns like NIE_lower, NIE_upper, etc.`
