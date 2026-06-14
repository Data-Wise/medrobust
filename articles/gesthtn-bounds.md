# Worked example: bounds for a differentially misclassified mediator (gestational hypertension)

## The question

Does **gestational hypertension** mediate the association between
**advanced maternal age** and **preterm birth**? Gestational
hypertension recorded on the birth certificate is a *differentially
misclassified* binary mediator: its sensitivity is poor and reporting
accuracy plausibly depends on the outcome. With no validation data, the
natural direct (NDE) and indirect (NIE) effects are not point-identified
— but `medrobust` returns a **sharp identified set** over a transparent
sensitivity region, plus an Imbens–Manski confidence interval.

This is the same substantive application used by the closest prior
*point*-identification method (Hochstedler Webb and Wells, 2025); here
we instead bound the effects without an auxiliary identifying
assumption.

``` r

library(medrobust)
data("gesthtn")
# A: advanced maternal age (>=35) | M_star: birth-cert gestational HTN (misclassified)
# Y: preterm birth (<37 wk)       | C1: parity (any prior live birth)
table(M_star = gesthtn$M_star, Y = gesthtn$Y)
```

          Y
    M_star    0    1
         0 4036  503
         1  353  108

## A naive analysis (treats the surrogate as truth)

``` r

fM <- glm(M_star ~ A + C1, data = gesthtn, family = binomial())
fY <- glm(Y ~ A + M_star + C1, data = gesthtn, family = binomial())
naive_NDE_OR <- exp(coef(fY)[["A"]])
round(naive_NDE_OR, 3)
```

    [1] 1.257

## The sensitivity region

We ground the region in a birth-certificate validation study (Dietz et
al., 2015): the gestational-hypertension item has *poor* sensitivity
(`< 70%`) and *excellent* specificity (`> 90%`); differential
sensitivity ($`\psi_{Sn} > 1`$) is plausible because preterm,
higher-acuity deliveries receive closer chart abstraction.

``` r

region <- sensitivity_region(
  sn0_range    = c(0.50, 0.70),   # poor baseline sensitivity
  sp0_range    = c(0.90, 0.99),   # excellent baseline specificity
  psi_sn_range = c(1.0, 3.0),     # non-differential -> moderate differential
  psi_sp_range = c(1.0, 1.0)      # specificity non-differential
)
```

## Partial-identification bounds + Imbens–Manski CI

``` r

b <- bound_ne(
  data = gesthtn, exposure = "A", mediator = "M_star", outcome = "Y",
  confounders = "C1", misclassified_variable = "mediator",
  sensitivity_region = region, effect_scale = "OR",
  ci_method = "analytic", ci_n_boot = 100, verbose = FALSE
)

# Identified set [L, U] for each effect (OR scale)
c(NDE_lower = b@NDE_lower, NDE_upper = b@NDE_upper)
```

    NDE_lower NDE_upper
     1.114050  1.290049 

``` r

c(NIE_lower = b@NIE_lower, NIE_upper = b@NIE_upper)
```

    NIE_lower NIE_upper
     1.035935  1.199593 

``` r

# Imbens-Manski CI for the partial-identification set
b@analytic_ci$NDE[c("ci_lower", "ci_upper")]
```

     ci_lower  ci_upper
    0.8485365 1.5128204 

``` r

b@analytic_ci$NIE[c("ci_lower", "ci_upper")]
```

     ci_lower  ci_upper
    0.9815587 1.3903370 

## Reading the result

The indirect-effect identified set summarizes how the mediated effect
could range as the misclassification mechanism varies over the
sensitivity region; the Imbens–Manski interval adds finite-sample
uncertainty. If the NIE set (and CI) lie entirely above 1, the
conclusion of positive mediation is **robust to differential
misclassification** of the mediator — a statement the naive point
estimate cannot support. Widen `region` to see how the bounds respond to
less certainty about the error mechanism.

> Note: `gesthtn` is a 5,000-row random sample shipped for illustration.
> A larger sample tightens the Imbens–Manski interval; see
> `system.file("scripts", "prepare_gesthtn.R", package = "medrobust")`
> to regenerate at any size.
