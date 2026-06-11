# BUG / ISSUE — `compute_true_effects()` uses plug-in-mean-M, not g-computation

**Date:** 2026-06-11  **Severity:** High (affects simulation validity)  **Found by:** smoke-testing DM bounds sims

## Summary
`compute_true_effects()` (R/simulate_dm_data.R) computes natural direct/indirect
effects by substituting the **mediator probability** `prob_M_a` into the outcome
model's linear predictor:

```r
prob_M_a1   <- expit(baseline_M + beta_AM*1 + C_mean_M)
E_Y_a1_Ma1  <- expit(baseline_Y + theta_AY*1 + theta_MY * prob_M_a1 + ... )  # <-- plug-in mean
```

This is **not** the natural-effect estimand. For a binary mediator the correct
g-computation averages the outcome over the M distribution:

```r
# E[Y(a, M(a'))] = sum_c P(c) * sum_m P(M=m | a', c) * P(Y=1 | a, m, c)
piM <- expit(baseline_M + beta_AM*aprime + beta_C*c)
g1  <- expit(baseline_Y + theta_AY*a + theta_MY*1 + theta_C*c)
g0  <- expit(baseline_Y + theta_AY*a + theta_MY*0 + theta_C*c)
EY  <- piM*g1 + (1 - piM)*g0
```

Because `expit` is nonlinear, `expit(.. + tMY*E[M] ..) != E_M[ expit(.. + tMY*M ..) ]`
(Jensen gap). The `bound_ne()` machinery targets the correct (averaged) estimand,
so simulation coverage is checked against a mis-specified truth.

## Reproduction
- `/tmp/diag2.R`: package NDE_OR=1.5000 vs correct NDE_OR=1.4802 (Δ≈0.02);
  NIE_OR 1.1872 vs 1.1994 on the default DGP, n=4000, psi=1.
- `/tmp/diag.R`: independent analytic bound (base R, manuscript §4.2) reproduces
  `bound_ne`'s behavior, confirming the discrepancy is in the *truth*, not the bound.

## Fix
Rewrite `compute_true_effects()` to average over M (binary closed form above;
generalize by summing over mediator support). Add a regression test:
> on a large sample with NO misclassification, `@true_effects$NDE_OR` must match the
> empirical g-computation estimate within Monte Carlo error.

## Secondary issues — RESOLVED into two, after grid×scale sweep (2026-06-11)
An independent base-R analytic bound (manuscript §4.2) was run at n∈{4k,20k,200k,300k}
and grid k∈{9,81}. Conclusions:

- **(2a) Grid resolution — usage, not a bug.** Analytic bound MISSES truth at coarse grid
  (k=9) but CONTAINS it at dense grid (k=81, pop scale):
  NDE [1.4715,1.5300] ∋ 1.4802 ✓. So sims must use a high `n_grid` (≥~50–80/axis).

- **(2b) `bound_ne` g-computation bug — PINPOINTED.** Derivation verified exact
  (popcheck recovers truth to 5e-17), so the fault is in `bound_ne`. Direct point test
  (region = {true Ψ}, n=5e5) returns the wrong effect on BOTH scales:
  `NDE_OR 1.601 / NIE_OR 1.121` vs oracle `1.480 / 1.199`; `NDE_RD 0.076 / NIE_RD 0.022`
  vs `0.062 / 0.034`.
  **Signature: NDE overstated, NIE understated (opposite directions)** → NOT an OR/Jensen
  conversion (same-direction). This is the classic signature of using the WRONG mediator
  distribution in the cross-world g-computation: a swap of which $\pi_a$ multiplies which
  $\gamma_{a'}$, or $M(0)$↔$M(1)$ in $E[Y(1,M(\cdot))]$. NDE uses $M(0)$, NIE is the
  $M(1)-M(0)$ contrast, so one swap pushes NDE up and NIE down — exactly observed.
  **Fix in `R/bound_ne_mediator.R`** (and exposure analogue): verify the mediator-distribution
  indices in the $E[Y(a,M(a^*))]$ assembly against `dev-diagnostics/popcheck_exact_recovery.R`.

Repro: `dev-diagnostics/{bne_point_test, oracle_potential_outcomes, popcheck_exact_recovery,
diag_grid_scale_sweep}.R`.

## Cross-refs
Research finding: `~/projects/research/me-mediator-bounds/02_Notes/FINDING-sim-coverage-2026-06-11.md`
Affects manuscripts M2a (mediator) and M2b (exposure) simulation sections.
