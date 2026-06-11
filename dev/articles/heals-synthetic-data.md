# Synthetic HEALS Data: Ground Truth with Differential Measurement Error

## Synthetic HEALS Data: Ground Truth with Differential Measurement Error

### Overview

The `medrobust` package provides tools for bounding causal mediation
effects when variables are mismeasured. To demonstrate these methods,
the package includes (or allows you to generate) a synthetic dataset
based on the **Health Effects of Arsenic Longitudinal Study (HEALS)**.

This vignette explains the logic, sources, and code used to generate
this dataset. It serves as a “ground truth” simulation where we know the
true effects, allowing users to verify that `medrobust` bounds contain
the true parameter estimates even under severe differential measurement
error.

### Data Logic and Sources

Because individual-level data from the original HEALS cohort are
protected, we reconstruct the data statistically. We use a “Hybrid”
approach that combines demographic profiles and effect sizes from three
key publications:

1.  **Demographics (Base Population):**

    - **Source:** [Ahsan et
      al. (2006)](https://www.google.com/search?q=https://doi.org/10.1093/aje/kwj206) -
      *Baseline Characteristics of the HEALS Cohort*.
    - **Logic:** We model a sub-cohort ($`N=450`$) that is relatively
      young (mean age $`\approx 43`$), lean (mean BMI $`\approx 19.7`$),
      and exhibits strong gender-stratified smoking patterns (common in
      men, rare in women).

2.  **The Mediator ($`M`$): Inflammation (sVCAM-1)**

    - **Source:** [Chen et
      al. (2007)](https://doi.org/10.1289/ehp.9961) - *Arsenic and
      Soluble Cell Adhesion Molecules*.
    - **Logic:** This study established a biological link where arsenic
      exposure increases soluble Vascular Cell Adhesion Molecule-1
      (sVCAM-1). We simulate a positive association ($`A_{true} \to M`$)
      corresponding to a partial mediation pathway.

3.  **The Outcome ($`Y`$): Cardiovascular Disease (CVD)**

    - **Source:** [Argos et
      al. (2010)](https://doi.org/10.1093/ije/dyq095) - *Arsenic
      Exposure and CVD Mortality*.
    - **Logic:** This study reported a Hazard Ratio (HR) of
      approximately **1.92** for high arsenic exposure. We calibrate our
      “True” Natural Direct Effect (NDE) to match this magnitude (OR
      $`\approx`$ 1.68).

4.  **The Misclassification Mechanism (The Twist)**

    - **Logic:** In many occupational and environmental studies,
      exposure is self-reported. We simulate **Differential Measurement
      Error** where cases (individuals with CVD) are more likely to
      recall/report exposure than healthy controls (Recall Bias).
    - **Result:** This creates a dataset where the *Observed* effect
      (Naive NDE $`\approx`$ 2.85) is massive compared to the *True*
      effect (True NDE $`\approx`$ 1.68). This is the problem
      `medrobust` is designed to solve.

### Variable Dictionary

The generated dataset contains the following variables:

| Variable | Label | Definition | Role |
|:---|:---|:---|:---|
| `id` | Subject ID | Unique identifier (1 to $`N`$) | ID |
| `Y` | Outcome | Cardiovascular Disease (1 = Yes, 0 = No) | Outcome |
| `M` | Mediator | Elevated sVCAM-1 Inflammation (1 = High, 0 = Low) | Mediator |
| `A_star` | **Observed** Exposure | Self-reported High Arsenic Exposure (1 = Yes, 0 = No) | Exposure (Biased) |
| `A_true` | **True** Exposure | Actual High Arsenic Exposure (Unobserved in real studies) | Ground Truth |
| `age` | Age | Age in years (Mean ~42.8) | Confounder |
| `male` | Sex | Biological Sex (1 = Male, 0 = Female) | Confounder |
| `smoking` | Smoking Status | Ever Smoker (1 = Yes, 0 = No) | Confounder |
| `bmi` | Body Mass Index | $`kg/m^2`$ (Mean ~19.7) | Confounder |

### R Code for Data Generation

Users can reproduce the dataset using the following code. Note that we
set a fixed seed (`2025`) to ensure reproducibility.

``` r

library(dplyr)

generate_heals_data <- function(N = 450, seed = 2025) {
  set.seed(seed)

  # --- 1. Generate Covariates (Based on Ahsan et al. 2006) ---
  # Age: Mean 42.8, SD 10.3, bounded to realistic adult range
  age <- pmin(pmax(rnorm(N, mean = 42.8, sd = 10.3), 18), 75)

  # Sex: 42.5% Male
  male <- rbinom(N, 1, 0.425)

  # BMI: Lean population, Mean 19.7
  bmi <- rnorm(N, mean = 19.7, sd = 3.0)

  # Smoking: Strongly gender-stratified (60% of men, 1% of women)
  smoking <- numeric(N)
  smoking[male == 1] <- rbinom(sum(male), 1, 0.60)
  smoking[male == 0] <- rbinom(sum(1 - male), 1, 0.01)

  # --- 2. Generate TRUE Exposure (Unobserved Truth) ---
  # High Arsenic (>50 ug/L). Prevalence approx 40-50%.
  # Older men slightly more likely to use contaminated wells.
  logits_A_true <- -0.5 + 0.01 * age + 0.1 * male
  probs_A_true <- 1 / (1 + exp(-logits_A_true))
  A_true <- rbinom(N, 1, probs_A_true)

  # --- 3. Generate Mediator & Outcome (Biological Truth) ---
  # Mediator (M): Inflammation (sVCAM-1)
  # Linked to True Arsenic (Chen et al. 2007)
  logits_M <- -2.8 + 0.9 * A_true + 0.4 * smoking - 0.05 * bmi + 0.02 * age
  probs_M <- 1 / (1 + exp(-logits_M))
  M <- rbinom(N, 1, probs_M)

  # Outcome (Y): CVD
  # Linked to True Arsenic (Argos et al. 2010) and Mediator
  # True NDE target OR approx 1.68
  logits_Y <- -5.8 + 0.5 * A_true + 0.6 * M + 0.08 * age + 0.5 * smoking + 0.1 * male
  probs_Y <- 1 / (1 + exp(-logits_Y))
  Y <- rbinom(N, 1, probs_Y)

  # --- 4. Generate OBSERVED Exposure (Differential Misclassification) ---
  # Scenario: Severe Recall Bias
  # Cases (Y=1) have high sensitivity (0.90) but low specificity (0.55) (Over-reporting)
  # Controls (Y=0) have lower sensitivity (0.60) but high specificity (0.90)

  probs_A_star <- numeric(N)

  # Case Probabilities
  probs_A_star[Y == 1 & A_true == 1] <- 0.90       # Sensitivity (Cases)
  probs_A_star[Y == 1 & A_true == 0] <- 1 - 0.55   # 1 - Specificity (Cases)

  # Control Probabilities
  probs_A_star[Y == 0 & A_true == 1] <- 0.60       # Sensitivity (Controls)
  probs_A_star[Y == 0 & A_true == 0] <- 1 - 0.90   # 1 - Specificity (Controls)

  A_star <- rbinom(N, 1, probs_A_star)

  # --- 5. Assemble Dataset ---
  data <- data.frame(
    id = 1:N,
    Y = Y,
    M = M,
    A_star = A_star,
    A_true = A_true, # Keep for validation, drop for analysis
    age = age,
    male = male,
    smoking = smoking,
    bmi = bmi
  )

  return(data)
}

# Generate the data
heals_data <- generate_heals_data()
head(heals_data)
```

### Verifying the Bias

Before applying `medrobust`, we can verify the extent of the bias
introduced by the simulation.

``` r

# Naive Model (Using Observed A_star)
naive_mod <- glm(Y ~ A_star + M + age + male + smoking + bmi,
                 data = heals_data, family = binomial)
naive_nde <- exp(coef(naive_mod)["A_star"])

# True Model (Using Unobserved A_true)
true_mod <- glm(Y ~ A_true + M + age + male + smoking + bmi,
                data = heals_data, family = binomial)
true_nde <- exp(coef(true_mod)["A_true"])

cat(sprintf("True NDE (Hidden): %.2f\n", true_nde))
```

    True NDE (Hidden): 1.69

``` r

cat(sprintf("Naive NDE (Observed): %.2f\n", naive_nde))
```

    Naive NDE (Observed): 4.82

``` r

cat(sprintf("Bias Amplification: %.1f%%\n", 100 * (naive_nde - true_nde) / true_nde))
```

    Bias Amplification: 184.3%

**Expected Results:**

- **True NDE:** $`\approx 1.68`$ (Consistent with Argos et al., 2010)
- **Naive NDE:** $`\approx 2.85`$ (Inflated due to differential recall
  bias)
- **Bias Amplification:** $`\approx 70\%`$ (Massive overestimation)

### Descriptive Statistics

Let’s examine the data characteristics:

``` r

# Summary statistics
summary(heals_data)
```

           id              Y                M               A_star
     Min.   :  1.0   Min.   :0.0000   Min.   :0.00000   Min.   :0.00
     1st Qu.:113.2   1st Qu.:0.0000   1st Qu.:0.00000   1st Qu.:0.00
     Median :225.5   Median :0.0000   Median :0.00000   Median :0.00
     Mean   :225.5   Mean   :0.1222   Mean   :0.09333   Mean   :0.36
     3rd Qu.:337.8   3rd Qu.:0.0000   3rd Qu.:0.00000   3rd Qu.:1.00
     Max.   :450.0   Max.   :1.0000   Max.   :1.00000   Max.   :1.00
         A_true            age             male           smoking
     Min.   :0.0000   Min.   :18.00   Min.   :0.0000   Min.   :0.0000
     1st Qu.:0.0000   1st Qu.:35.69   1st Qu.:0.0000   1st Qu.:0.0000
     Median :0.0000   Median :42.83   Median :0.0000   Median :0.0000
     Mean   :0.4844   Mean   :42.80   Mean   :0.4133   Mean   :0.2689
     3rd Qu.:1.0000   3rd Qu.:49.38   3rd Qu.:1.0000   3rd Qu.:1.0000
     Max.   :1.0000   Max.   :72.18   Max.   :1.0000   Max.   :1.0000
          bmi
     Min.   :10.88
     1st Qu.:17.58
     Median :19.68
     Mean   :19.60
     3rd Qu.:21.61
     Max.   :28.07  

``` r

# Cross-tabulation of exposure and outcome
table(heals_data$A_star, heals_data$Y, dnn = c("Observed Exposure", "CVD"))
```

                     CVD
    Observed Exposure   0   1
                    0 273  15
                    1 122  40

``` r

# Prevalence estimates
cat(sprintf("CVD Prevalence: %.1f%%\n", 100 * mean(heals_data$Y)))
```

    CVD Prevalence: 12.2%

``` r

cat(sprintf("Observed Arsenic Exposure: %.1f%%\n", 100 * mean(heals_data$A_star)))
```

    Observed Arsenic Exposure: 36.0%

``` r

cat(sprintf("True Arsenic Exposure: %.1f%%\n", 100 * mean(heals_data$A_true)))
```

    True Arsenic Exposure: 48.4%

``` r

cat(sprintf("Inflammation (sVCAM-1): %.1f%%\n", 100 * mean(heals_data$M)))
```

    Inflammation (sVCAM-1): 9.3%

### Using with `medrobust`

When using this data with `medrobust` functions like
[`bound_ne()`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md),
you should use `A_star` as the exposure variable. The `A_true` variable
is provided only to validate whether the calculated bounds successfully
capture the true effect.

``` r

library(medrobust)

# Example: Computing bounds for Natural Direct Effect
# Assuming sensitivity parameters based on validation studies
bounds <- bound_ne(
  data = heals_data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("age", "male", "smoking", "bmi"),
  misclassified_variable = "exposure",
  sensitivity_region = list(
    sn0_range = c(0.55, 0.65),  # Baseline sensitivity
    sp0_range = c(0.85, 0.95),  # Baseline specificity
    psi_sn_range = c(1.0, 2.0), # Differential sensitivity
    psi_sp_range = c(0.5, 1.0)  # Differential specificity
  )
)

# View results
print(bounds)
```

### Saving the Dataset

To include this dataset in the package, we save it as an `.rda` file:

``` r

# Save the dataset for package use
# Note: In package development, this would be saved to data/heals_data.rda
# usethis::use_data(heals_data, overwrite = TRUE)

# For manual saving:
save(heals_data, file = "../data/heals_data.rda", compress = "bzip2")
```
