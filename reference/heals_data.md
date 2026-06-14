# Synthetic HEALS Data with Differential Measurement Error

A synthetic dataset based on the Health Effects of Arsenic Longitudinal
Study (HEALS) that demonstrates differential measurement error in
exposure assessment. The dataset includes both observed (misclassified)
and true (ground truth) arsenic exposure, allowing for validation of
sensitivity analysis methods.

## Usage

``` r
heals_data
```

## Format

A data frame with 450 observations and 9 variables:

- id:

  Integer. Unique subject identifier (1 to 450).

- Y:

  Binary. Cardiovascular disease status (0 = Absent, 1 = Present).

- M:

  Binary. Elevated inflammation marker (sVCAM-1) (0 = Low, 1 = High).

- A_star:

  Binary. Self-reported arsenic exposure (0 = No, 1 = Yes). Subject to
  severe differential recall bias.

- A_true:

  Binary. True arsenic exposure status (0 = No, 1 = Yes). Included for
  validation; not available in real studies.

- age:

  Numeric. Age in years (range: 18-75, mean ~42.8).

- male:

  Binary. Sex (0 = Female, 1 = Male).

- smoking:

  Binary. Ever smoker status (0 = Never, 1 = Ever).

- bmi:

  Numeric. Body mass index in kg/m² (mean ~19.7).

## Source

Synthetic data generated using methods described in the package vignette
"Synthetic HEALS Data: Ground Truth with Differential Measurement
Error". See
[`vignette("heals-synthetic-data", package = "medrobust")`](https://data-wise.github.io/medrobust/articles/heals-synthetic-data.md)
for full details.

## Details

\## Data Generation The data were generated to mimic the HEALS cohort
using published effect sizes and demographic profiles from:

- Ahsan et al. (2006) - Baseline demographics

- Chen et al. (2007) - Arsenic-inflammation relationship

- Argos et al. (2010) - Arsenic-CVD relationship (HR ~ 1.92)

\## Measurement Error Model Differential misclassification was
introduced with:

- Cases (Y=1): Sensitivity = 0.90, Specificity = 0.55 (over-reporting)

- Controls (Y=0): Sensitivity = 0.60, Specificity = 0.90

This creates severe recall bias where CVD cases over-report arsenic
exposure, inflating the naive effect estimate by approximately 70

\## True vs. Naive Effects

- True Natural Direct Effect: OR ~ 1.68

- Naive NDE (using A_star): OR ~ 2.85

- Bias amplification: ~70

## Examples

``` r
# Load the data
data("heals_data")
str(heals_data)
#> 'data.frame':    450 obs. of  9 variables:
#>  $ id     : int  1 2 3 4 5 6 7 8 9 10 ...
#>  $ Y      : int  0 0 1 0 1 0 0 0 0 0 ...
#>  $ M      : int  0 0 0 0 0 0 0 0 0 0 ...
#>  $ A_star : int  0 0 0 0 0 0 1 0 0 1 ...
#>  $ A_true : int  1 1 0 0 1 0 1 0 0 1 ...
#>  $ age    : num  49.2 43.2 50.8 55.9 46.6 ...
#>  $ male   : int  0 0 1 1 0 0 1 0 1 0 ...
#>  $ smoking: num  0 0 1 1 0 0 0 0 0 0 ...
#>  $ bmi    : num  25.9 21.4 19.3 18.4 17.1 ...

# Examine prevalence
table(heals_data$A_star, heals_data$Y)
#>    
#>       0   1
#>   0 273  15
#>   1 122  40

# Compare naive vs. true effect
naive_mod <- glm(Y ~ A_star + M + age + male + smoking + bmi,
                 data = heals_data, family = binomial)
true_mod <- glm(Y ~ A_true + M + age + male + smoking + bmi,
                data = heals_data, family = binomial)

cat("Naive NDE:", round(exp(coef(naive_mod)["A_star"]), 2), "\n")
#> Naive NDE: 4.82 
cat("True NDE:", round(exp(coef(true_mod)["A_true"]), 2), "\n")
#> True NDE: 1.69 

# To compute partial-identification bounds for the (potentially
# misclassified) exposure A_star, pass this data to bound_ne();
# see ?bound_ne for a complete, runnable example.
```
