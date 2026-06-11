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

- **(2b) `bound_ne` systematic offset — GENUINE OPEN BUG.** At matched settings `bound_ne`
  sits ~0.05 ABOVE the faithful analytic bound at every n
  (N=200k: bound_ne NDE [1.531,1.564] vs analytic [1.413,1.474]). Two implementations of
  the same §4.2 bound should not differ by a stable offset. **Investigate
  `R/bound_ne_mediator.R`** — candidate causes: internal grid construction/density,
  OR-scale stratum aggregation, or the min/max search. Isolate on NDE first.

Repro: `dev-diagnostics/diag_grid_scale_sweep.R`, `diag_dense_grid_popscale.R`.

## Cross-refs
Research finding: `~/projects/research/me-mediator-bounds/02_Notes/FINDING-sim-coverage-2026-06-11.md`
Affects manuscripts M2a (mediator) and M2b (exposure) simulation sections.
