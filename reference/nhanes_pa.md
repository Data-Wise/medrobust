# Physical Inactivity as a Differentially Misclassified Binary Exposure

A pooled sample of U.S. adults from NHANES used to illustrate
partial-identification bounds when a binary *exposure* is differentially
misclassified, without validation data. The exposure—self-reported
physical inactivity—is a textbook differentially misclassified variable:
it has no biomarker, relies on participant recall and report, and
reporting accuracy plausibly depends on health status (and thus on the
outcome). The mediator, laboratory-measured systemic inflammation
(hs-CRP), is by contrast measured *without error*. `nhanes_pa` is the
exposure-side mirror image of
[`gesthtn`](https://data-wise.github.io/medrobust/reference/gesthtn.md)
(which misclassifies the *mediator*), completing the mediator/exposure
symmetry of the package's worked examples.

## Usage

``` r
nhanes_pa
```

## Format

A data frame with approximately 9,906 observations and 6 binary
variables (every column is an `integer` in {0, 1}):

- A_star:

  Binary. Self-reported physical inactivity (1 = inactive, 0 = active).
  A misclassified (surrogate) measurement of the true exposure;
  "inactive" means leisure-time aerobic activity below the 2018 Physical
  Activity Guidelines threshold of 150 moderate-equivalent minutes per
  week (vigorous minutes counted double). The true activity status is
  not observed.

- M:

  Binary. Elevated systemic inflammation, hs-CRP \>= 3 mg/L (1 =
  elevated, 0 = not). Laboratory-measured, treated as error-free.

- Y:

  Binary. Prevalent cardiovascular disease (1 = any of coronary heart
  disease, angina, myocardial infarction, or stroke; 0 = none).

- C1:

  Binary. Older age (1 = age \>= 50 years, 0 = age \< 50).

- C2:

  Binary. Female sex (1 = female, 0 = male).

- C3:

  Binary. Obesity (1 = BMI \>= 30, 0 = BMI \< 30).

## Source

CDC National Health and Nutrition Examination Survey (NHANES),
public-domain U.S.-government data for cycles 2015–2016 and 2017–2018,
obtained via the nhanesA package
(<https://cran.r-project.org/package=nhanesA>). Survey home:
<https://www.cdc.gov/nchs/nhanes/>. Activity threshold: 2018 Physical
Activity Guidelines for Americans (150 moderate-equivalent min/week).

## Details

\## Source data Pooled NHANES 2015–2016 (`_I`) and 2017–2018 (`_J`)
cycles, adults aged 20 and older, restricted to complete cases on the
six modeled binaries. Unlike
[`gesthtn`](https://data-wise.github.io/medrobust/reference/gesthtn.md)
(a fixed-seed random sample drawn from millions of births), `nhanes_pa`
ships the *full* complete-case sample with **no random sampling**: the
data are tiny (six binary columns), and the complete-case construction
is deterministic, so the dataset is reproducible by construction with no
seed. The eight `C1 x C2 x C3` strata are well-populated (each roughly
843–1,588), which keeps `bound_ne(confounders = c("C1", "C2", "C3"))`
feasible across the differential-sensitivity sweep. Variables were
derived from the PAQ (physical-activity questionnaire), HSCRP
(high-sensitivity C-reactive protein), MCQ (medical conditions), DEMO
(demographics), and BMX (body measures) files; see
`system.file("scripts", "prepare_nhanes_pa.R", package = "medrobust")`.

\## Misclassification The misclassified variable here is a
**self-reported exposure** in a *cross-sectional* survey, so the
relevant mechanism is differential *reporting*: sensitivity and
specificity for self-reported inactivity may depend on the prevalent
outcome (e.g., respondents with cardiovascular disease may report
activity differently from healthy respondents). This is
outcome-dependent reporting error, **not** case-control recall
bias—there is no retrospective recall of past exposure conditional on
diagnosis. With no validation data, an analyst can posit plausible
accuracy (e.g., baseline sensitivity and specificity each in \[0.80,
0.95\]) and sweep a differential-sensitivity odds ratio (\\\psi\_{Sn}\\)
at or above 1 to probe robustness.

## Examples

``` r
data("nhanes_pa")
table(A_star = nhanes_pa$A_star, Y = nhanes_pa$Y)
#>       Y
#> A_star    0    1
#>      0 3146  204
#>      1 5737  819

# Partial-identification bounds for the (differentially misclassified) exposure;
# see ?bound_ne and vignette("nhanes_pa-bounds", package = "medrobust").
region <- sensitivity_region(
  sn0_range = c(0.80, 0.95), sp0_range = c(0.80, 0.95),
  psi_sn_range = c(1.0, 2.0), psi_sp_range = c(1.0, 1.0)
)
```
