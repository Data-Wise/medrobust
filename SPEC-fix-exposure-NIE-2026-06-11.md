# SPEC — Correct the exposure (A*) NIE bound in `bound_ne`

**Component:** `R/bound_ne_exposure.R` (+ shared g-computation it calls)
**Type:** correctness fix, test-gated
**Owner:** medrobust   **Date:** 2026-06-11   **Status:** OPEN
**Companion:** `PLAN-fix-exposure-NIE-2026-06-11.md` (investigation steps)

---

## 1. Problem statement
For differential misclassification of a binary **exposure** `A*` (Y-dependent recall bias),
`bound_ne(..., misclassified_variable = "exposure")` returns an **NIE** bound that does not
contain the true NIE, even at the population limit with the true Ψ inside the sensitivity
region. The **NDE** bound is correct. (Mediator path NDE & NIE both correct after PR #2.)

Observed (n = 2e5, true Ψ in-region, OR scale):
| effect | truth | bound | verdict |
|--------|-------|-------|---------|
| exposure NDE | 1.480 | [1.424, 1.588] | ✓ contains |
| exposure NIE | 1.199 | [0.980, 0.991] | ✗ misses (below null) |

## 2. Estimand (the contract — what NIE must equal)
Binary A, M, Y; covariates C. Under exposure misclassification the recovered cell
probabilities identify `P(M=m | A=a, C=c)` and `P(Y=1 | A=a, M=m, C=c)`. The natural effects
(VanderWeele, OR scale) are, with
`E[Y(a, M(a*))] = Σ_c P(c) Σ_m P(M=m | a*, c) · P(Y=1 | a, m, c)`:
```
NDE_OR = odds(E[Y(1, M(0))]) / odds(E[Y(0, M(0))])
NIE_OR = odds(E[Y(1, M(1))]) / odds(E[Y(1, M(0))])
```
Key invariant for NIE: the **outcome exposure is held at a = 1** while the **mediator-
distribution exposure varies between M(1) and M(0)**. The bug is almost certainly a violation
of this invariant in the A*-path assembly (wrong `P(M | a*, c)` index, or odds taken on the
wrong term).

## 3. Functional requirements
- R1. `bound_ne(misclassified_variable="exposure")` NIE bound MUST contain the true NIE at the
  population limit when the true Ψ ∈ region, on OR, RR, and RD scales.
- R2. NDE behavior MUST be unchanged (regression guard — it is currently correct).
- R3. Must hold under BOTH non-differential (psi=1) and differential (psi≠1) misclassification.
- R4. No change to the mediator path or to `compute_effects_from_params()` unless the exposure
  path shares the buggy code — if shared, fix without breaking mediator tests.
- R5. CRAN-clean (`check() --as-cran`: 0 errors/0 warnings).

## 4. Reference oracle (ground truth to test against)
Add `dev-diagnostics/oracle_exposure.R`: direct potential-outcome simulation of the
exposure-misclassification DGP (true A drawn; A* = Y-dependent corruption of A; M depends on
true A; Y depends on true A, M, C). Compute NDE/NIE by Monte-Carlo over potential outcomes —
NO formula. This is the authoritative target (mirrors `oracle_potential_outcomes.R`).

## 5. Acceptance criteria (all must pass)
- A1. **Point test** (`dev-diagnostics/bne_point_test_exposure.R`): degenerate region at true Ψ,
  n=5e5 → `bound_ne` exposure NDE *and* NIE within 0.01 (OR) of the A* oracle.
- A2. **Recovery test** (`tests/testthat/test-recovery-exposure.R`): exact population cells →
  recovered P(M|a,c), P(Y|a,m,c) match truth to 1e-8; incl. a differential case.
- A3. **Contains-truth test** (`tests/testthat/test-bound-contains-truth-exposure.R`): large-n,
  true Ψ interior, dense grid → NDE & NIE bounds contain the oracle on OR/RR/RD.
- A4. `devtools::test()` all green (existing 157 + new); `devtools::check()` clean.
- A5. Re-running `dev-diagnostics/smoke2_popcheck_both_paths.R` shows the exposure NIE row TRUE.

## 6. Out of scope
- Mediator path (verified). Finite-sample coverage tuning of the simulation driver (that's an
  M2a/M2b sim-config task, separate from this correctness fix).

## 7. Downstream unblock
On A1–A5 passing: clear the exposure-NIE blocker in `me-exposure-recall/.STATUS`; M2b §6 sims
may run; regenerate any A* illustrative numbers in the M2b draft.
