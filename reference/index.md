# Package index

## Main Functions

Core functions for partial identification and sensitivity analysis

- [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
  : Partial Identification Bounds for Natural Effects Under Differential
  Misclassification
- [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
  : Check Compatibility of Misclassification Parameters
- [`falsification_summary()`](https://data-wise.github.io/medrobust/reference/falsification_summary.md)
  : Summarize Falsification Results

## Visualization

Functions for creating publication-ready plots

- [`sensitivity_plot()`](https://data-wise.github.io/medrobust/reference/sensitivity_plot.md)
  : Create Sensitivity Analysis Plots
- [`plot_bootstrap_distribution()`](https://data-wise.github.io/medrobust/reference/plot_bootstrap_distribution.md)
  : Plot Bootstrap Distribution

## Data Simulation

Generate synthetic data for testing and power analysis

- [`simulate_dm_data()`](https://data-wise.github.io/medrobust/reference/simulate_dm_data.md)
  : Simulate Data with Differential Misclassification
- [`power_analysis()`](https://data-wise.github.io/medrobust/reference/power_analysis.md)
  : Power Analysis for Partial Identification Bounds

## Utilities

Helper functions for extracting and comparing results

- [`extract_bounds()`](https://data-wise.github.io/medrobust/reference/extract_bounds.md)
  : Extract Compatible Parameter Sets
- [`compare_bounds()`](https://data-wise.github.io/medrobust/reference/compare_bounds.md)
  : Compare Bounds Across Multiple Analyses

## Classes and Constructors

S7 classes and sensitivity-region constructors

- [`medrobust_bounds`](https://data-wise.github.io/medrobust/reference/medrobust_bounds.md)
  : Medrobust Bounds Class
- [`power_analysis_result`](https://data-wise.github.io/medrobust/reference/power_analysis_result.md)
  : Power Analysis Result Class
- [`compatibility_test`](https://data-wise.github.io/medrobust/reference/compatibility_test.md)
  : Compatibility Test Class
- [`sensitivity_region()`](https://data-wise.github.io/medrobust/reference/sensitivity_region.md)
  : Create Sensitivity Region
- [`as_sensitivity_region()`](https://data-wise.github.io/medrobust/reference/as_sensitivity_region.md)
  : Create sensitivity_region object from list

## Falsification and Hypothesis Tests

Falsified-region extraction and multiple-testing helpers

- [`extract_falsified_region()`](https://data-wise.github.io/medrobust/reference/extract_falsified_region.md)
  : Extract Falsified Region
- [`new_falsification_summary()`](https://data-wise.github.io/medrobust/reference/new_falsification_summary.md)
  : Create Falsification Summary Object
- [`test_multiple_hypotheses()`](https://data-wise.github.io/medrobust/reference/test_multiple_hypotheses.md)
  : Test Multiple Hypotheses

## Bootstrap and Inference

Confidence intervals, bootstrap results, and standard-error helpers

- [`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md)
  : Confidence intervals for partial-identification bounds
  (Imbens-Manski)
- [`bootstrap_results()`](https://data-wise.github.io/medrobust/reference/bootstrap_results.md)
  : Bootstrap Results Class
- [`bootstrap_width_summary()`](https://data-wise.github.io/medrobust/reference/bootstrap_width_summary.md)
  : Compute Width of Bootstrap Distribution
- [`compute_bound_se()`](https://data-wise.github.io/medrobust/reference/compute_bound_se.md)
  : Compute Standard Errors for Bounds

## Methods and Formatting

S3 methods and effect-formatting helpers

- [`as.data.frame(`*`<medrobust_bounds>`*`)`](https://data-wise.github.io/medrobust/reference/as.data.frame.medrobust_bounds.md)
  : Coerce to data frame (S3 - Legacy)
- [`as.list(`*`<sensitivity_region>`*`)`](https://data-wise.github.io/medrobust/reference/as.list.sensitivity_region.md)
  : Convert sensitivity_region S7 object to list
- [`print(`*`<compatibility_test>`*`)`](https://data-wise.github.io/medrobust/reference/print.compatibility_test.md)
  : Print Method for compatibility_test
- [`summary(`*`<compatibility_test>`*`)`](https://data-wise.github.io/medrobust/reference/summary.compatibility_test.md)
  : Summary Method for compatibility_test
- [`format_effect()`](https://data-wise.github.io/medrobust/reference/format_effect.md)
  : Format Effect Estimate for Reporting

## Datasets

Example and synthetic datasets

- [`gesthtn`](https://data-wise.github.io/medrobust/reference/gesthtn.md)
  : Gestational Hypertension as a Differentially Misclassified Binary
  Mediator
- [`nhanes_pa`](https://data-wise.github.io/medrobust/reference/nhanes_pa.md)
  : Physical Inactivity as a Differentially Misclassified Binary
  Exposure
- [`heals_data`](https://data-wise.github.io/medrobust/reference/heals_data.md)
  : Synthetic HEALS Data with Differential Measurement Error
- [`simulated_dm_data`](https://data-wise.github.io/medrobust/reference/simulated_dm_data.md)
  : Simulated Data with Differential Misclassification Class
