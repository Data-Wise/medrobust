# Worked example: bounds for a differentially misclassified exposure (physical inactivity)

## The question

Does **systemic inflammation** mediate the association between
**physical inactivity** and **prevalent cardiovascular disease (CVD)**?
Here the *exposure* is the problem variable: self-reported physical
inactivity has no biomarker, relies on participant report, and its
reporting accuracy plausibly depends on health status — a
*differentially misclassified* binary exposure. The mediator (laboratory
hs-CRP) is, by contrast, measured without error. With no validation
data, the natural direct (NDE) and indirect (NIE) effects are not
point-identified — but `medrobust` returns a **sharp identified set**
over a transparent sensitivity region, plus an Imbens–Manski confidence
interval.

This is the exposure-side mirror of `vignette("gesthtn-bounds")`, which
instead misclassifies the *mediator*. The only structural change to the
estimator call is `misclassified_variable = "exposure"`.

``` r

library(medrobust)
data("nhanes_pa")
# A_star: self-reported inactivity (misclassified) | M: hs-CRP >= 3 mg/L (lab, error-free)
# Y: prevalent CVD                                  | C1/C2/C3: age>=50, female, obese
table(A_star = nhanes_pa$A_star, Y = nhanes_pa$Y)
```

          Y
    A_star    0    1
         0 3146  204
         1 5737  819

## A naive analysis (treats the surrogate as truth)

We compute the OR-scale natural effects from a no-interaction logistic
specification, treating self-reported inactivity `A_star` as if it were
the true exposure (the VanderWeele closed form, evaluated across the
three confounders).

``` r

Cnames <- c("C1", "C2", "C3")
fM <- glm(reformulate(c("A_star", Cnames), "M"), data = nhanes_pa, family = binomial())
fY <- glm(reformulate(c("A_star", "M", Cnames), "Y"), data = nhanes_pa, family = binomial())

bA <- coef(fM)[["A_star"]]; b0 <- coef(fM)[[1]]
tA <- coef(fY)[["A_star"]]; tM <- coef(fY)[["M"]]
base <- b0 + sum(coef(fM)[Cnames] * colMeans(nhanes_pa[Cnames]))   # b0 + bC . Cbar
lin  <- base + bA
naive_NDE <- exp(tA)
naive_NIE <- ((1 + exp(base)) * (1 + exp(tM + lin))) /
             ((1 + exp(lin))  * (1 + exp(tM + base)))
round(c(naive_NDE_OR = naive_NDE, naive_NIE_OR = naive_NIE), 3)
```

    naive_NDE_OR naive_NIE_OR
           1.629        1.014 

## The sensitivity region

With no validation data we posit *plausible* accuracy for self-reported
inactivity: sensitivity and specificity each in `[0.80, 0.95]`. The
differential parameter $`\psi_{Sn} > 1`$ allows reporting accuracy to
depend on the outcome (respondents with CVD may report activity
differently). We sweep the differential ceiling
$`\psi_{Sn} \in \{1, 1.5, 2, 3\}`$ — non-differential through moderate
differential reporting.

## Partial-identification bounds as $`\psi_{Sn}`$ grows

``` r

fmt <- function(x) sprintf("%.3f", x)
rows <- list()
for (psi in c(1.0, 1.5, 2.0, 3.0)) {
  region <- sensitivity_region(
    sn0_range    = c(0.80, 0.95),
    sp0_range    = c(0.80, 0.95),
    psi_sn_range = c(1.0, psi),
    psi_sp_range = c(1.0, 1.0)
  )
  b <- tryCatch(bound_ne(
    data = nhanes_pa, exposure = "A_star", mediator = "M", outcome = "Y",
    confounders = Cnames, misclassified_variable = "exposure",
    sensitivity_region = region, n_grid = 50, effect_scale = "OR",
    confidence_level = 0.95, ci_method = "analytic",
    verbose = FALSE, use_adaptive_grid = TRUE
  ), error = function(e) { message("psi ", psi, " failed: ", conditionMessage(e)); NULL })
  if (is.null(b)) next
  ci  <- b@analytic_ci
  cig <- function(eff, k) {
    v <- tryCatch(ci[[eff]][[k]], error = function(e) NA_real_)
    if (is.null(v) || !length(v)) NA_real_ else as.numeric(v[[1]])
  }
  rows[[length(rows) + 1]] <- data.frame(
    psi_sn = psi,
    NDE_L = b@NDE_lower, NDE_U = b@NDE_upper,
    NDE_ciL = cig("NDE", "ci_lower"), NDE_ciU = cig("NDE", "ci_upper"),
    NIE_L = b@NIE_lower, NIE_U = b@NIE_upper,
    NIE_ciL = cig("NIE", "ci_lower"), NIE_ciU = cig("NIE", "ci_upper")
  )
}
res <- do.call(rbind, rows)
res
```

## Reading the result

Read down the $`\psi_{Sn}`$ column. At **non-differential to mild**
reporting error ($`\psi_{Sn} \le 1.5`$) the NDE identified set (and its
Imbens–Manski interval) excludes 1 — the direct effect of inactivity on
CVD is **robust** to that much misclassification. As the differential
ceiling rises to $`\psi_{Sn} \ge 2`$, the NDE set widens to **cover 1**:
once reporting accuracy is allowed to depend strongly on the outcome,
the data can no longer rule out a null direct effect. The NIE (mediated
through hs-CRP) is **small and not distinguishable from the null**
throughout — inflammation carries little of the total association in
this cross-section.

The lesson mirrors `gesthtn` from the other side: a naive point estimate
that treats the self-report as truth overstates certainty, while the
bounds make the robustness-to-misclassification claim explicit and
falsifiable.

> Note: `nhanes_pa` ships the full pooled complete-case sample (no
> random subsampling), regenerate it from
> `system.file("scripts", "prepare_nhanes_pa.R", package = "medrobust")`.
> The full $`\psi_{Sn} \in \{1, 1.5, 2, 3\}`$ sweep here matches the
> manuscript application; widen `sn0_range`/`sp0_range` to probe less
> certainty about the reporting mechanism.
