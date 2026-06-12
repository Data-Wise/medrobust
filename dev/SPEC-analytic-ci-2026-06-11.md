# SPEC (scope) — Fast analytic confidence intervals for bound_ne endpoints

**Component:** `R/bound_ne*.R` + new `R/bound_ci.R` (analytic CI)
**Type:** feature (enables finite-sample coverage studies) **Status:**
SCOPE / proposal — no code yet **Date:** 2026-06-11 **Motivation:** The
nonparametric bootstrap re-runs the full grid search per replicate
(`compute_bootstrap_ci`), so coverage sims over the M2a/M2b design (144
cells × 1000 reps × ~500 boot) are intractable (~years). We measured
raw-bound under-coverage (NDE 0.20 → 0.83 as n grows) and confirmed a
single bootstrapped bound at n=500 exceeds 5 min. A fast analytic CI
makes the coverage study feasible (minutes) and is the proper inference
layer for the bounds.

------------------------------------------------------------------------

## 1. Goal

Provide a confidence interval for the partial-identification set
`[L̂, Û]` (NDE and NIE, on OR/RR/RD) whose finite-sample coverage of the
true effect is ≈ nominal, computed in `O(n_grid × #cells_perturbed)`
time — **no resampling**. Expose it through the same
`@bootstrap_results`-style fields (`nde_lower_ci`, `nde_upper_ci`, …) so
the simulation driver’s coverage code is unchanged (swap
`bootstrap = TRUE` → `ci_method = "analytic"`).

## 2. Statistical approach

The effect at a fixed Ψ, `θ(Ψ) = f(p̂)`, is a smooth functional of the
observed within-stratum cell probabilities `p̂` (multinomial). Three
pieces:

1.  **Gradient ∇f.** MVP: *numerical* central differences — perturb each
    cell prob, recompute `θ` via the existing per-Ψ effect function,
    `K+1` evaluations per Ψ (vs ~500 for bootstrap). Rigorous (later):
    closed-form influence function via the chain
    `cells → solve → g-comp → odds → ratio`.
2.  **SE of θ(Ψ).** Delta method: `Var(θ) = ∇fᵀ Σ ∇f`, with `Σ` the
    multinomial covariance (block-diagonal across strata;
    `Σ_jk = (p_j(δ_jk − p_k))/n_s`). Aggregate strata by the
    g-computation weights.
3.  **SE of the endpoints + set CI.** By the envelope theorem,
    `SE(L̂) ≈ SE(θ(Ψ*_min))` at the minimizing grid point (likewise `Û`).
    Construct the **Imbens–Manski (2004)** CI for the set:
    `CI = [L̂ − c·SE(L̂), Û + c·SE(Û)]`, where `c` interpolates between
    the one-sided critical value (when `Û−L̂ ≫ SE`) and the two-sided
    value (when the set is short). Report on OR/RR/RD.

## 3. Functional requirements

- R1. `bound_ne(..., ci_method = "analytic")` returns
  `nde_lower_ci/nde_upper_ci/nie_*` (length-2 envelopes) for **both**
  mediator and exposure paths.
- R2. Runtime per replicate `O(n_grid · K)` (K = \#cells), not
  `O(n_grid · boot_reps)`.
- R3. Analytic SE agrees with the bootstrap SD within MC error on a
  sampled (Ψ, n) grid.
- R4. CI-envelope coverage of the true effect ≈ nominal at N ∈ {100,
  200, 500} (the regime the bootstrap was too slow to test at scale).
- R5. No change to the point bounds; CRAN-clean.

## 4. Implementation sketch

- Refactor the per-Ψ effect computation so it is callable on a
  *supplied* cell-prob vector (both paths already isolate this:
  `compute_effects_from_params` / `compute_effects_from_joint_probs`).
- `R/bound_ci.R`: `.bound_endpoint_se(bounds, data, ...)` →
  numerical-gradient delta-method SE at the argmin/argmax Ψ;
  `.imbens_manski_ci(L, U, seL, seU, level)`.
- Hook into `bound_ne` after the grid search; populate the CI fields
  (reuse the `bootstrap_results` S7 class shape, or add an analogous
  `analytic_ci` slot).

## 5. Validation plan

- **Unit:** `test-analytic-ci.R` — SE vs bootstrap SD within tolerance
  on 2–3 (Ψ, n); IM `c` in `[z_{1-α}, z_{1-α/2}]`; degenerate-set limit
  (`Û=L̂`) → two-sided z.
- **Coverage:** small driver run with `ci_method="analytic"` at
  N∈{100,500}, ψ∈{1,1.5} → CI coverage ≈ 0.95 (fast; minutes).
  Cross-check one cell against a (slow) bootstrap CI.

## 6. Effort / risk

- **MVP (numerical gradient + IM):** ~1–2 days. Risks: exposing the
  per-Ψ effect fn on perturbed cells; envelope-theorem SE when the
  argmin is on a region boundary or ties (fall back to a small local
  bootstrap there, or take the max SE over near-optimal Ψ); multinomial
  covariance bookkeeping across strata; near-null odds at boundaries
  (already guarded with `+1e-10`).
- **Closed-form influence functions:** higher effort, lower runtime —
  defer until MVP validates.

## 7. Recommendation

Build the **numerical-gradient MVP** first (validates the whole approach
in days, not the bootstrap’s years), wire it into `run_simulations.R`
behind `ci_method`, confirm R3/R4 on a small run, then decide whether
closed-form influence functions are worth it. Out of scope: changing the
point bounds or the mediator/exposure estimands (all verified).
