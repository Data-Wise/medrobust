# PLAN — Fix the `bound_ne` recovery bug (+ estimand fix)

**Repo:** `medrobust` (YES — fix here; the research repos only consume the package).
**Branch:** `fix/true-effects-estimand` (already checked out; rename/extend OK).
**Date:** 2026-06-11
**Status:** Root cause identified for BOTH bugs. Derivation verified exact (`popcheck`).

---

## TL;DR — two bugs, both in `medrobust`, both root-caused

1. **`compute_true_effects()`** (R/simulate_dm_data.R): plug-in-mean-M estimand. (Bug #1)
2. **The 3×3 linear solve in `bound_ne_mediator.R`** (lines ~118–125): **mis-specified
   system matrix** → recovers wrong (π, γ) → wrong bounds. (Bug #2, the ~0.05 offset)

`compute_effects_from_params()` (the g-computation) is **CORRECT** — verified: fed true
params it returns the oracle (1.48025/1.19941). So do NOT touch it.

---

## Bug #2 — the precise defect

`R/bound_ne_mediator.R` solves a 3×3 system with unknown vector
`theta = (pi*g1, (1-pi)*g0, pi*(1-g1))` and matrix:
```
A = [ sn1    1-sp1   0   ]   b = (P11, P10, P01)
    [ 1-sn1  sp1     0   ]
    [ 0      1-sp0   sn0 ]
```
The third row encodes `P01 = (1-sp0)*theta[2] + sn0*theta[3]`
                     = `(1-sp0)*(1-pi)*g0 + sn0*pi*(1-g1)`.
**But the true equation (manuscript §4.2) is**
`P01 = sn0*(1-g1)*pi + (1-sp0)*(1-g0)*(1-pi)`.
The term `(1-g0)*(1-pi)` is NOT `theta[2]=(1-pi)*g0`. The matrix multiplies `(1-sp0)` by the
WRONG unknown — it mixes `g0` (Y=1 parameterization) into a `(1-g0)` (Y=0) slot. The system
is internally inconsistent ⇒ biased recovery of (π, γ) ⇒ NDE↑/NIE↓ offset.

### Verified evidence
- `dev-diagnostics/popcheck_exact_recovery.R`: the CORRECT approach (two 2×2 systems, one
  per Y) recovers (π,γ) to 5e-17 and g-computes the oracle.
- `dev-diagnostics/instrument.R`: g-comp formula with TRUE params = oracle; `bound_ne` on
  n=5e5 data = 1.601/1.121 ⇒ the gap is the SOLVE, not the formula.

---

## The fix (Bug #2) — replace the 3×3 with two clean 2×2 systems

In `R/bound_ne_mediator.R`, replace the `A_mat`/`b_vec`/`theta_sol` block (~lines 114–160)
with the per-Y-stratum solve. Observed cells `P_ym*` for fixed (a,c):

```
# Y = 1 block:  P11 = sn1*x1 + (1-sp1)*x0 ;  P10 = (1-sn1)*x1 + sp1*x0
#   where x1 = pi*g1   (=P(M=1,Y=1)),  x0 = (1-pi)*g0  (=P(M=0,Y=1))
# Y = 0 block:  P01 = sn0*z1 + (1-sp0)*z0 ;  P00 = (1-sn0)*z1 + sp0*z0
#   where z1 = pi*(1-g1)(=P(M=1,Y=0)), z0 = (1-pi)*(1-g0)(=P(M=0,Y=0))
A1 <- matrix(c(sn1, 1-sp1, 1-sn1, sp1), 2, 2, byrow = TRUE)
A0 <- matrix(c(sn0, 1-sp0, 1-sn0, sp0), 2, 2, byrow = TRUE)
xy1 <- solve(A1, c(P_11, P_10))   # (x1, x0)
xy0 <- solve(A0, c(P_01, P_00))   # (z1, z0)
x1 <- xy1[1]; x0 <- xy1[2]; z1 <- xy0[1]; z0 <- xy0[2]
pi_a     <- x1 + z1               # P(M=1 | a,c)
gamma_a1 <- x1 / pi_a             # P(Y=1 | M=1, a,c)
gamma_a0 <- x0 / (1 - pi_a)       # P(Y=1 | M=0, a,c)
```
Then keep the existing validity checks (0≤·≤1) and boundary handling. Solvable iff
`det(A1), det(A0) != 0`, i.e. `sn_y + sp_y != 1` — add that to compatibility pruning.

**Exposure path — AUDITED 2026-06-11: NO bug, do NOT change.** `R/bound_ne_exposure.R`
(lines ~128–135) uses the standard 2×2 misclassification matrix inverse
`P_1 = (sp·P*_1 − (1−sp)·P*_0)/(sn+sp−1)`, `P_0 = (sn·P*_0 − (1−sn)·P*_1)/(sn+sp−1)`
with `denom = sn_y+sp_y−1`. Verified algebraically correct (recovers true probs to 1e-16,
incl. differential Sn/Sp). The bug is SPECIFIC to the mediator path's 3×3 formulation.

**Verification of the proposed mediator fix (`dev-diagnostics/verify_fix.R`, 2026-06-11):**
On arbitrary true params with DIFFERENTIAL Sn/Sp (Sn1=.88,Sp1=.93,Sn0=.80,Sp0=.85):
- current 3×3 recovers pi=0.428/g1=0.344/g0=0.205 (true 0.350/0.420/0.180) → WRONG
- two-2×2 fix recovers all three to **0.00e+00** error, pi consistent across Y blocks → EXACT

---

## The fix (Bug #1) — `compute_true_effects()`

Per `START-HERE-fix-true-effects.md` §1: average the outcome over the M distribution and
over C, not plug-in means. (Closed form already written there.)

---

## Test strategy (add to tests/testthat/)

1. **`test-true-effects.R`** (Bug #1): at Sn=Sp=1, `@true_effects$NDE_OR` == empirical
   g-computation within MC error.
2. **`test-recovery.R`** (Bug #2, the decisive one): build EXACT population cells from a
   known DGP (port `popcheck_exact_recovery.R`), solve at the true Ψ, assert recovered
   (π,γ) == truth within 1e-8, and assert g-comp NDE/NIE == oracle within 1e-6.
3. **`test-bound-contains-truth.R`**: on large-n simulated data with the true Ψ interior to
   a dense-grid region, assert the bound CONTAINS the oracle effect (OR, RR, RD).
4. **Point test**: port `dev-diagnostics/bne_point_test.R` — degenerate region at true Ψ
   must return the oracle (1.480/1.199), not 1.601/1.121.

Run order: fix #2 first (it's the load-bearing one), confirm test 2 & 4 pass, then fix #1.

---

## Gates before merge
- [ ] `devtools::test()` green incl. the 4 new tests
- [ ] `devtools::check()` clean — **CRAN compliance is standing P0 for this package**
- [ ] `bne_point_test.R` returns oracle on both OR and RD scales
- [ ] Re-run `code/run_simulations.R` (mediator, small N, dense n_grid): coverage ≈ nominal
- [ ] NEWS.md entry; PR `fix/true-effects-estimand` → `main`

## After merge — unblock the papers
- Clear 🔴 blockers in `me-mediator-bounds/.STATUS` and `me-exposure-recall/.STATUS`
- Scale `run_simulations.R` to the full 324-cell design; populate draft §6 tables

## Scope / non-goals
- Do NOT modify `compute_effects_from_params()` (verified correct).
- Bug also implies any published/preliminary `bound_ne` numbers (incl. the manuscript's
  illustrative §7) must be regenerated after the fix.

## Reference oracles (dev-diagnostics/, gitignored)
`popcheck_exact_recovery.R` (correct solve), `oracle_potential_outcomes.R` (ground truth),
`bne_point_test.R` (point test), `instrument.R` (formula-vs-solve isolation),
`diag_*` (sweeps).
