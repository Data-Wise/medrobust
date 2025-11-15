# NOTE: Data documentation commented out until datasets are created
# Uncomment after creating .rda files in data/ directory

# #' Synthetic Occupational Arsenic Exposure Data
# #'
# #' @description
# #' A synthetic dataset mimicking the occupational arsenic exposure study.
# #' The data contain self-reported arsenic exposure (subject to recall bias),
# #' inflammation biomarkers, cardiovascular disease outcomes, and demographic/
# #' lifestyle covariates.
# #'
# #' @format A data frame with 450 observations and 10 variables:
# #' \describe{
# #'   \item{A_star}{Binary. Self-reported occupational arsenic exposure (0=No, 1=Yes).
# #'     Subject to outcome-dependent recall bias.}
# #'   \item{M}{Binary. Elevated inflammation marker (hs-CRP > 3 mg/L) (0=No, 1=Yes).}
# #'   \item{Y}{Binary. Cardiovascular disease status (0=Absent, 1=Present).}
# #'   \item{age}{Numeric. Age in years (range: 35-70).}
# #'   \item{smoking}{Factor. Smoking status: "never", "former", "current".}
# #'   \item{alcohol}{Factor. Alcohol consumption: "none", "moderate", "heavy".}
# #'   \item{male}{Binary. Sex (0=Female, 1=Male).}
# #'   \item{bmi}{Numeric. Body mass index (kg/m²).}
# #'   \item{diabetes}{Binary. Diabetes status (0=No, 1=Yes).}
# #'   \item{hypertension}{Binary. Hypertension status (0=No, 1=Yes).}
# #' }
# #'
# #' @details
# #' The synthetic data were generated with outcome-dependent misclassification:
# #' \itemize{
# #'   \item Baseline sensitivity (Y=0): Sn0 ≈ 0.82
# #'   \item Baseline specificity (Y=0): Sp0 ≈ 0.88
# #'   \item Differential sensitivity: ψ_Sn ≈ 2.0 (OR)
# #'   \item Non-differential specificity: ψ_Sp ≈ 1.0
# #' }
# #'
# #' @examples
# #' \dontrun{
# #' data("arsenic_synthetic")
# #' str(arsenic_synthetic)
# #' table(arsenic_synthetic$A_star, arsenic_synthetic$Y)
# #'
# #' # Run analysis
# #' bounds <- bound_ne(
# #'   data = arsenic_synthetic,
# #'   exposure = "A_star",
# #'   mediator = "M",
# #'   outcome = "Y",
# #'   confounders = c("age", "smoking", "male"),
# #'   misclassified_variable = "exposure",
# #'   sensitivity_region = list(
# #'     sn0_range = c(0.75, 0.90),
# #'     sp0_range = c(0.80, 0.95),
# #'     psi_sn_range = c(1.0, 3.0),
# #'     psi_sp_range = c(1.0, 1.0)
# #'   )
# #' )
# #' }
# #'
# #' @keywords datasets
# "arsenic_synthetic"
#
#
# #' Example Parameter Grids for Sensitivity Analysis
# #'
# #' @description
# #' Pre-defined parameter grids for common sensitivity analysis scenarios,
# #' providing sensible default ranges for misclassification parameters.
# #'
# #' @format A list with 6 named elements, each containing:
# #' \describe{
# #'   \item{sn0_range}{Numeric vector. Range for baseline sensitivity.}
# #'   \item{sp0_range}{Numeric vector. Range for baseline specificity.}
# #'   \item{psi_sn_range}{Numeric vector. Range for differential sensitivity (OR).}
# #'   \item{psi_sp_range}{Numeric vector. Range for differential specificity (OR).}
# #'   \item{description}{Character. Description of the scenario.}
# #' }
# #'
# #' Available scenarios: optimistic, realistic, pessimistic, very_wide,
# #' occupational, psychiatric.
# #'
# #' @details
# #' Scenarios:
# #' \itemize{
# #'   \item \code{optimistic}: High-quality measurement, minimal bias
# #'   \item \code{realistic}: Typical epidemiologic study quality
# #'   \item \code{pessimistic}: Known measurement quality concerns
# #'   \item \code{very_wide}: Minimal assumptions, exploratory
# #'   \item \code{occupational}: Calibrated for occupational exposure studies
# #'   \item \code{psychiatric}: Calibrated for psychiatric diagnosis
# #' }
# #'
# #' @examples
# #' \dontrun{
# #' data("example_param_grids")
# #' names(example_param_grids)
# #'
# #' # Use a pre-defined grid
# #' bounds <- bound_ne(
# #'   data = my_data,
# #'   exposure = "A_star",
# #'   mediator = "M",
# #'   outcome = "Y",
# #'   confounders = "C1",
# #'   misclassified_variable = "exposure",
# #'   sensitivity_region = example_param_grids$realistic
# #' )
# #' }
# #'
# #' @keywords datasets
# "example_param_grids"
#
#
# #' Validation Study Data Subsample
# #'
# #' @description
# #' A small subsample (n=100) from a hypothetical validation study where both
# #' true exposure status (A) and self-reported status (A*) are observed.
# #'
# #' @format A data frame with 100 observations and 6 variables:
# #' \describe{
# #'   \item{A}{Binary. True exposure status (gold standard).}
# #'   \item{A_star}{Binary. Self-reported exposure status.}
# #'   \item{M}{Binary. Mediator.}
# #'   \item{Y}{Binary. Outcome.}
# #'   \item{age}{Numeric. Age in years.}
# #'   \item{male}{Binary. Sex.}
# #' }
# #'
# #' @details
# #' This dataset can be used to:
# #' \itemize{
# #'   \item Estimate misclassification parameters (Sn, Sp) empirically
# #'   \item Test for differential misclassification
# #'   \item Inform choice of sensitivity regions
# #' }
# #'
# #' @examples
# #' \dontrun{
# #' data("validation_subsample")
# #'
# #' # Compute misclassification parameters by outcome
# #' library(dplyr)
# #' validation_subsample %>%
# #'   group_by(Y) %>%
# #'   summarise(
# #'     Sn = sum(A == 1 & A_star == 1) / sum(A == 1),
# #'     Sp = sum(A == 0 & A_star == 0) / sum(A == 0)
# #'   )
# #' }
# #'
# #' @keywords datasets
# "validation_subsample"
