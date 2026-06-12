# Identification Mathematics: Recovering Latent Effects under Differential Misclassification

## Overview

`medrobust` derives partial-identification bounds for natural direct and
indirect effects (NDE/NIE) when the mediator $`M`$ or the exposure $`A`$
is subject to **differential misclassification** — measurement error
whose sensitivity/specificity depend on the outcome $`Y`$. This vignette
documents the identification mathematics the package implements:

1.  the target estimand and its **g-computation**;
2.  **mediator** identification via two per-outcome $`2\times2`$
    systems;
3.  **exposure** identification via a closed-form $`2\times2`$ inverse;
4.  the testable solvability condition $`Sn_y + Sp_y \neq 1`$.

It also records two correctness fixes made in version 0.1.0.9000 and the
verification evidence behind them.

## The estimand and g-computation

For binary $`A`$, $`M`$, $`Y`$ with confounders $`C`$, the natural
effects compare three counterfactual outcome means $`E[Y(a, M(a'))]`$.
The mediator is binary, so the inner expectation over $`M`$ is exact,
and we average over $`C`$:

``` math
E[Y(a, M(a'))]
= \sum_{c} P(C=c) \sum_{m \in \{0,1\}} P(M=m \mid a', c)\, P(Y=1 \mid a, m, c).
```

This is the **g-formula**. The crucial point is that the *outcome* is
averaged over the distributions of $`M`$ and $`C`$ — the expectation is
taken **after** the nonlinear link, not before. Collapsing $`M`$ or
$`C`$ to a mean and plugging it into $`\mathrm{expit}(\cdot)`$
introduces a Jensen-inequality bias.

> **Fix \#1 — estimand (v0.1.0.9000)**
>
> The simulator’s ground-truth helper `compute_true_effects()`
> previously used a plug-in-mean-$`M`$ formula, biasing the reference
> `NDE_OR` to $`\approx 1.500`$ where the correct g-computation gives
> $`\approx 1.480`$. The simulator now Monte-Carlo g-computes over the
> empirical $`C`$ distribution, so the simulation “truth” matches the
> estimand the bounds target.

## Differential misclassification

Let $`M^*`$ be the observed (mismeasured) mediator. Differential error
means the sensitivity and specificity depend on $`Y`$:

``` math
Sn_y = P(M^*=1 \mid M=1, Y=y), \qquad
Sp_y = P(M^*=0 \mid M=0, Y=y), \qquad y \in \{0,1\}.
```

Within a fixed exposure/confounder cell $`(a, c)`$ write
$`\pi = P(M=1\mid a,c)`$, $`g_1 = P(Y=1\mid M=1,a,c)`$,
$`g_0 = P(Y=1\mid M=0,a,c)`$. The four latent joint cells
$`P(M=m, Y=y\mid a,c)`$ are

``` math
\begin{aligned}
P(M{=}1,Y{=}1) &= \pi g_1, & P(M{=}0,Y{=}1) &= (1-\pi) g_0,\\
P(M{=}1,Y{=}0) &= \pi (1-g_1), & P(M{=}0,Y{=}0) &= (1-\pi)(1-g_0).
\end{aligned}
```

## Mediator identification: two $`2\times2`$ systems

Because the error rates differ by $`Y`$, the $`Y=1`$ and $`Y=0`$
observed cells form **two independent** $`2\times2`$ systems. Writing
$`x_1=\pi g_1`$, $`x_0=(1-\pi)g_0`$ (the $`Y=1`$ block) and
$`z_1=\pi(1-g_1)`$, $`z_0=(1-\pi)(1-g_0)`$ (the $`Y=0`$ block):

``` math
\underbrace{\begin{pmatrix} Sn_1 & 1-Sp_1\\ 1-Sn_1 & Sp_1\end{pmatrix}}_{A_1}
\begin{pmatrix}x_1\\ x_0\end{pmatrix}
= \begin{pmatrix}P_{11}\\ P_{10}\end{pmatrix},
\qquad
\underbrace{\begin{pmatrix} Sn_0 & 1-Sp_0\\ 1-Sn_0 & Sp_0\end{pmatrix}}_{A_0}
\begin{pmatrix}z_1\\ z_0\end{pmatrix}
= \begin{pmatrix}P_{01}\\ P_{00}\end{pmatrix},
```

where $`P_{ym^*}=P(Y=y, M^*=m^*\mid a,c)`$. Each block is solvable iff

``` math
\det(A_y) = Sn_y + Sp_y - 1 \neq 0.
```

Recover the structural parameters by $`\pi = x_1 + z_1`$,
$`g_1 = x_1/\pi`$, $`g_0 = x_0/(1-\pi)`$.

> **Fix \#2 — mediator solve (v0.1.0.9000)**
>
> The previous implementation stacked these into a single $`3\times3`$
> system whose $`P_{01}`$ row multiplied $`(1-Sp_0)`$ by the **$`Y=1`$**
> unknown $`x_0=(1-\pi)g_0`$, where the $`Y=0`$ equation actually
> involves $`(1-\pi)(1-g_0)`$. The system was internally inconsistent,
> biasing $`(\pi, \gamma)`$ and offsetting the bounds (NDE overstated,
> NIE understated, by \$\$0.05–0.12 on the OR scale). Splitting into the
> two $`2\times2`$ systems above resolves it. The bias was largest under
> **strong differential** error ($`Sn_1 \neq Sn_0`$), exactly where the
> mis-coupling bites hardest.

### Exact-population recovery (runnable)

With population cells (no sampling) the solve is exact to machine
precision — including a differential case:

``` r

true_parc <- function(a, cc, bM=-1.5, bY=-2.0, bAM=log(2.5),
                      tAY=log(1.5), tMY=log(2.5), bC=0.3, tC=0.3) {
  list(pi = expit(bM + bAM*a + bC*cc),
       g1 = expit(bY + tAY*a + tMY*1 + tC*cc),
       g0 = expit(bY + tAY*a + tMY*0 + tC*cc))
}
obs_pop <- function(a, cc, Sn1, Sp1, Sn0, Sp0) {
  p <- true_parc(a, cc)
  c(P11 = Sn1*p$pi*p$g1 + (1-Sp1)*(1-p$pi)*p$g0,
    P10 = (1-Sn1)*p$pi*p$g1 + Sp1*(1-p$pi)*p$g0,
    P01 = Sn0*p$pi*(1-p$g1) + (1-Sp0)*(1-p$pi)*(1-p$g0),
    P00 = (1-Sn0)*p$pi*(1-p$g1) + Sp0*(1-p$pi)*(1-p$g0))
}
solve_two_2x2 <- function(P, Sn1, Sp1, Sn0, Sp0) {
  xy1 <- solve(matrix(c(Sn1,1-Sp1,1-Sn1,Sp1), 2, 2, byrow=TRUE), c(P["P11"],P["P10"]))
  xy0 <- solve(matrix(c(Sn0,1-Sp0,1-Sn0,Sp0), 2, 2, byrow=TRUE), c(P["P01"],P["P00"]))
  pi_a <- xy1[1] + xy0[1]
  c(pi = unname(pi_a), g1 = unname(xy1[1]/pi_a), g0 = unname(xy1[2]/(1-pi_a)))
}

# Differential error: Sn1 != Sn0, Sp1 != Sp0
err <- 0
for (cc in 0:1) for (a in 0:1) {
  P  <- obs_pop(a, cc, Sn1=0.95, Sp1=0.85, Sn0=0.80, Sp0=0.92)
  rp <- solve_two_2x2(P, 0.95, 0.85, 0.80, 0.92)
  tp <- true_parc(a, cc)
  err <- max(err, abs(tp$pi-rp["pi"]), abs(tp$g1-rp["g1"]), abs(tp$g0-rp["g0"]))
}
cat(sprintf("max |recovered - true| (differential case) = %.2e\n", err))
```

    max |recovered - true| (differential case) = 5.55e-17

## Exposure identification: closed-form $`2\times2`$ inverse

For exposure misclassification ($`A^*`$ observed, error depending on
$`Y`$), within a cell $`(m, y, c)`$ let $`p_1 = P(A=1\mid m,y,c)`$,
$`p_0 = 1-p_1`$, and observed $`P^*_1 = P(A^*=1\mid m,y,c)`$. The map is
again a $`2\times2`$ system,

``` math
P^*_1 = Sn_y\, p_1 + (1-Sp_y)\, p_0, \qquad
P^*_0 = (1-Sn_y)\, p_1 + Sp_y\, p_0,
```

with $`\det = Sn_y + Sp_y - 1`$, so by Cramer’s rule

``` math
p_1 = \frac{Sp_y\,P^*_1 - (1-Sp_y)\,P^*_0}{Sn_y + Sp_y - 1}, \qquad
p_0 = \frac{Sn_y\,P^*_0 - (1-Sn_y)\,P^*_1}{Sn_y + Sp_y - 1}.
```

This is exactly the closed form in `bound_ne_exposure.R`. It was
independently audited and is **correct** (recovery verified to
$`\sim10^{-16}`$); the exposure path never shared the mediator
$`3\times3`$ defect.

## Convergence of the bound to the truth

With the solve fixed,
[`bound_ne()`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md)
evaluated at a degenerate region equal to the true
$`\Psi=(Sn_0{=}0.9, Sp_0{=}0.9, \psi_{sn}{=}1, \psi_{sp}{=}1)`$
converges to the oracle NDE/NIE as the sample size grows — confirming
the remaining gap at moderate $`n`$ is finite-sample, not bias:

|             $`n`$ | bound `NDE_OR` (midpoint) | gap to oracle (1.48025) |
|------------------:|--------------------------:|------------------------:|
| $`5\times10^{5}`$ |                   1.49665 |                   0.016 |
| $`2\times10^{6}`$ |                   1.48055 |                  0.0003 |
| $`8\times10^{6}`$ |                   1.48110 |                  0.0009 |

``` r

# Reproduce (slow; not evaluated at build time):
reg <- sensitivity_region(c(0.899, 0.901), c(0.899, 0.901), c(1, 1), c(1, 1))
sim <- simulate_dm_data(
  n = 2e6,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
  misclass_type = "mediator", confounders = 1, seed = 7)
b <- bound_ne(sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
              confounders = "C1", misclassified_variable = "mediator",
              sensitivity_region = reg, n_grid = 10, effect_scale = "OR")
c(NDE = (b@NDE_lower + b@NDE_upper) / 2, NIE = (b@NIE_lower + b@NIE_upper) / 2)
```

## Finite-sample coverage and inference

The estimated endpoints $`\hat L, \hat U`$ are **consistent**
(population recovery is exact to $`5\times10^{-17}`$, and at a fixed
$`\Psi`$ the effect estimate is essentially unbiased), but the *raw*
estimated set $`[\hat L, \hat U]`$ is **not a confidence set**. At
finite $`n`$ it **under-covers** the true effect, with coverage rising
to nominal as $`n\to\infty`$ (e.g. mediator NDE, $`\psi=1`$:
$`\approx 0.20`$ at $`n{=}500`$, $`0.83`$ at $`n{=}20{,}000`$).

> **This is the Imbens–Manski problem, not estimator bias**
>
> A natural first guess is finite-sample *bias* of the endpoints.
> Diagnostics rule that out: at a fixed $`\Psi`$ the effect estimate is
> unbiased, and the population bound contains the truth. The cause is
> geometric — the **identified set is narrow** (width $`\sim 0.15`$ for
> NDE here) **relative to the sampling SD of the endpoints** at small
> $`n`$. When set-width $`\approx`$ endpoint-SD, a point estimate of the
> set under-covers the *true parameter*. This is exactly the setting of
> Imbens & Manski (2004), and the rise of coverage with $`n`$ is its
> signature (the SD shrinks relative to the fixed width).

The principled fix is a **confidence interval for the set** that widens
the endpoints by their sampling uncertainty. The Imbens–Manski interval
is
``` math
\big[\, \hat L - c\,\widehat{\mathrm{SE}}(\hat L),\;\; \hat U + c\,\widehat{\mathrm{SE}}(\hat U)\,\big],
```
where the critical value $`c`$ interpolates between the one-sided
$`z_{1-\alpha}`$ (when the set is wide relative to the SEs) and the
two-sided $`z_{1-\alpha/2}`$ (when the set is short). The endpoint SEs
are obtained cheaply by re-evaluating the effect at the *fixed*
argmin/argmax $`\Psi`$ on resampled data (one evaluation per resample,
no grid search — orders of magnitude faster than re-running the whole
bootstrap). This restores nominal coverage at small $`n`$:

| effect | raw-bound coverage ($`n{=}500`$) | Imbens–Manski CI coverage |
|--------|---------------------------------:|--------------------------:|
| NDE    |                         $`0.09`$ |                  $`0.95`$ |
| NIE    |                         $`0.12`$ |                  $`0.93`$ |

This pattern holds across the full design: a simulation over **both
misclassification paths**, $`N\in\{100,200,500\}`$, and the OR/RR/RD
scales finds raw-bound coverage of $`0.00\text{–}0.42`$ versus
Imbens–Manski coverage of $`0.90\text{–}1.00`$ (conservative at the
smallest $`N`$).

In the package this is
[`bound_ci()`](https://data-wise.github.io/medrobust/dev/reference/bound_ci.md),
called on a fitted bound:

``` r

b  <- bound_ne(data, exposure = "A_star", mediator = "M", outcome = "Y",
               confounders = "C1", misclassified_variable = "exposure",
               sensitivity_region = region, n_grid = 50, effect_scale = "OR")
ci <- bound_ci(b, data, exposure = "A_star", mediator = "M", outcome = "Y",
               confounders = "C1", misclassified_variable = "exposure")
ci$NDE   # lower, upper (point bounds); ci_lower, ci_upper (Imbens-Manski CI)
```

> **Cost**
>
> A *full* nonparametric bootstrap re-runs the entire grid search per
> replicate and is prohibitive for coverage studies. The endpoint-SE
> construction above evaluates only at the two optimal $`\Psi`$, so it
> is feasible at scale; a closed-form delta-method SE is a further
> optimization.

## Practical implication: grid resolution

Because identification is exact only in the population, the
partial-identification bound covers the truth reliably only on a
sufficiently **dense** grid over the sensitivity region. For simulation
or applied work, use `n_grid` $`\gtrsim 50`$ when the region is wide;
coarse grids can miss the parameter combination that brackets the true
effect.

## References

- Tofighi, D. (2025). *Partial identification under differential
  misclassification.* (In preparation.)
- Manski, C. F. (2003). *Partial Identification of Probability
  Distributions.*
- VanderWeele, T. J. (2015). *Explanation in Causal Inference.*
