# Analysis & Implementation Plan — finite-sample bias of bound endpoints

**Study:** medrobust partial-ID bound endpoints (NDE/NIE) under
differential misclassification **Branch:** `feature/analytic-ci`
**Date:** 2026-06-12 **Version:** 1.0 **From:** method-scout
(bias-corrected bootstrap \[Kilian 1998; SAFE/Nakagawa 2025; Schafer
2024\] + Imbens-Manski 2004) → this plan

------------------------------------------------------------------------

## 1. Objective

**Primary:** characterize and correct the finite-sample (downward) bias
of the bound endpoints `L̂, Û` for NDE/NIE so a CI around the
*bias-corrected* endpoints achieves ≈ nominal coverage of the true
effect at N ∈ {100, 200, 500}.

**Estimand (the thing we measure):** `bias_n(e) = E[ê_n] − e_pop` for
`e ∈ {L, U} × {NDE, NIE}`, scales {OR, RR, RD}, paths {mediator,
exposure}. `e_pop` = endpoint at the population limit (large-n bound);
true effect from the oracles.

## 2. Competing hypotheses for the bias source (must discriminate first)

- **H1 — plug-in nonlinearity.** Bias from the nonlinear functional
  (deconvolution `÷(Sn+Sp−1)`, odds, ratio); shifts `θ(Ψ)` *downward at
  every Ψ*. → Predicts bias is present even at a **single fixed Ψ** (no
  min/max). Supported by Schafer (2024): plug-in nonlinear-functional
  estimators are biased.
- **H2 — extremum/selection (“winner’s curse”).** Bias from `min`/`max`
  over the Ψ-grid; `min` biased down, `max` biased up → *widens* the
  interval (would help, not hurt, the low-side miss). → Predicts bias
  appears only with the grid and scales with grid density × noise.
- **Discriminating test:** compare bias at a single fixed Ψ (degenerate
  region) vs over a wide grid. Current evidence (whole bound shifted
  low) → expect **H1 dominant**.

## 3. Stage 1 — Characterize (diagnostics, no package changes)

- Truth from `dev-diagnostics/oracle_potential_outcomes.R`,
  `oracle_exposure.R`.
- Grid: path {med, exp} × scale {OR} (then RR/RD) × n {100, 200, 500,
  1000, 2000, 8000}, R = 300 reps, fixed Ψ region around the truth.
- Measure per cell: (a) **single-Ψ effect bias**
  `mean(θ̂(Ψ_true)) − θ_true` (isolates H1);
  2.  **endpoint bias** `mean(L̂) − L_pop`, `mean(Û) − U_pop` (H1 + H2).
- Output: bias-vs-n table; confirm O(1/n) decay; attribute H1 vs H2.
  Script: `dev-diagnostics/bias_characterization.R`.

## 4. Stage 2 — Implement correction (`R/bound_ci.R`)

- Bias-corrected endpoint via the **fixed-Ψ envelope resample** (already
  built, ~11× faster than full bootstrap): `L̂_bc = 2L̂ − mean_b(L̂*_b)`;
  same for `Û`. Offer median-bias-corrected variant.
- Imbens–Manski CI around `(L̂_bc, Û_bc)` with envelope SEs.
- Both paths (add `.effect_at_psi_mediator`), scales OR/RR/RD.

## 5. Stage 3 — Validate coverage (fast)

- N ∈ {100, 200, 500}, ψ ∈ {1, 1.5}, both paths, R ≈ 200, B ≈ 150
  envelope reps.
- Metric: CI-envelope coverage of the true effect; **target ≥ 0.93**.
  Report raw-bound vs bias-corrected-CI coverage side by side, plus CI
  width (bias-variance check).

## 6. Stage 4 — Decision rule

- Bias-corrected CI ≈ nominal → **ship** (the answer to the coverage
  problem).
- Residual bias (bootstrap correction insufficient for the
  deconvolution) → escalate to **iterated bootstrap** \[Schafer 2024;
  Ouysse 2013\] or **analytic 2nd-order** \[Yang 2015\], or document the
  **asymptotic framing** with the bias curve. Decide on evidence, not a
  priori.

## 7. Gates (CRAN P0)

- `devtools::test()` + `check() --as-cran` clean; mediator/exposure
  **point bounds unchanged** (regression guard); new tests for
  bias-correction + IM behaviour.

## 8. Risks / diagnostics

- Bias correction inflates variance (bias–variance trade-off) — monitor
  CI width + MSE.
- Envelope SE may understate if the argmin Ψ moves across resamples —
  check argmin stability; fall back to re-selecting Ψ per resample if
  unstable.
- Deconvolution near `det = Sn+Sp−1 → 0` amplifies bias —
  exclude/penalize low-det Ψ.

## 9. Software / reproducibility

- R 4.x,
  [`pkgload::load_all`](https://pkgload.r-lib.org/reference/load_all.html);
  fixed seeds; artifacts in `dev-diagnostics/` (dev-only) + tests.

## References (from method-scout)

Imbens & Manski (2004, *Econometrica*); Kilian (1998, *REStat*);
Nakagawa et al. (2025, SAFE bootstrap); Schafer (2024, *SIMODS*,
iterated bootstrap / Möbius); Yang (2015, *J. Econometrics*, 3rd-order
bias); Abadie & Imbens (2011, bias-corrected matching).

------------------------------------------------------------------------

## FINDINGS & RESOLUTION (2026-06-12)

**Conclusion: there is no material finite-sample bias to correct. The
under-coverage is the Imbens-Manski narrow-set-vs-sampling-noise
problem, and the IM CI (already built in `R/bound_ci.R`) is the correct
and sufficient fix.**

Evidence: 1. **Stage 1 (single-Psi bias, isolates H1):** at the true Psi
the effect is ~unbiased (NDE bias +0.17→+0.01 from n=200→8000; NIE
+0.02→+0.003) and biased *high*, not low. So H1 (plug-in nonlinearity)
is NOT the cause of the bound’s apparent low bias. 2. **Population bound
is correct:** over \[0.85,0.95\]^2 at n=3e5 the bound is
NDE\[1.426,1.580\] ∋ 1.480 and NIE\[1.178,1.217\] ∋ 1.199; the
single-Psi corner sweep confirms this is the genuine partial-ID range.
The earlier “\[1.06,1.07\]” was a single unlucky n=2000 realization, not
systematic bias (over-read of one sample). 3. **Mechanism:**
identified-set width (~0.15 for NDE) is comparable to endpoint sampling
SD at small n, so the *raw* set under-covers the true point — the
textbook IM problem. Raw coverage rises with n (0.20→0.83) as SD shrinks
relative to width: the IM signature. 4. **IM CI achieves nominal
coverage** (exposure, psi=1, n=500): NIE 0.12→**0.93**, NDE
0.09→**0.95**. (`dev-diagnostics/im_cov.R`.)

Revised plan: SKIP bias correction (Stages 2-bias, 4-escalation).
Remaining work is pure productionization of the IM CI: mediator
primitive + `bound_ci_mediator`; wire `ci_method="analytic"` (IM, no
bias-correction) into `bound_ne`; full coverage table N∈{100,200,500}
both paths OR/RR/RD; tests; CRAN-clean; update SPEC-analytic-ci sec 8.
