# PLAN — Audit & fix the exposure (A\*) NIE bound

**Repo:** `medrobust` **Severity:** High (blocks M2b sims) **Date:**
2026-06-11 **Status:** Open. Found post-merge; the two mediator-side
bugs are already fixed (PR \#2).

## TL;DR

A population-limit smoke check shows the exposure path’s **NIE** bound
is wrong while its **NDE** bound is correct. The mediator fix didn’t
touch `bound_ne_exposure.R`, and the earlier audit only validated its
*solve* (class-probability inverse), not its *NIE assembly*.

## Evidence (n = 2e5, true Ψ interior, OR scale)

    exposure NDE: true 1.480 in [1.424, 1.588]   OK
    exposure NIE: true 1.199 in [0.980, 0.991]   WRONG  (bound entirely below truth, near/under null)
    mediator NDE/NIE at psi=1 and 1.5:           OK     (contain truth) -> fix is mediator-correct

Repro: `dev-diagnostics/smoke2.R` (writes the three population-limit
rows).

## Hypotheses (most → least likely)

1.  **NIE g-computation on the A\* path mis-assembles the cross-world
    term.** For exposure misclassification the recovered quantities are
    P(A,M,Y\|·); the NIE `E[Y(1,M(1))] vs E[Y(1,M(0))]` must hold the
    *outcome* exposure at a=1 while varying the *mediator-distribution*
    exposure. Check the A\*-analogue assembly (in `bound_ne_exposure.R`
    or wherever it g-computes) for the same M(0)/M(1) mix-up class that
    hit the mediator side.
2.  **Scale/odds composition for NIE only** (NDE OK rules out a global
    OR bug, but NIE has an extra term).
3.  **Min/max over the region picks an NIE-incompatible Ψ** that the NDE
    search tolerates.

## Steps

1.  **Build an A\* oracle** — extend
    `dev-diagnostics/oracle_potential_outcomes.R` to the
    exposure-misclassification DGP (true A, surrogate A\* = A +
    Y-dependent error). Compute true NDE/NIE by direct potential-outcome
    simulation. This is the ground truth.
2.  **Point test** — degenerate region at true Ψ, n large; assert
    `bound_ne(... misclassified_variable="exposure")` returns the A\*
    oracle for BOTH NDE and NIE. (Mirror `bne_point_test.R`, exposure
    variant.)
3.  If NIE diverges, **trace the exposure g-computation** line-by-line
    against the oracle’s intermediate `E[Y(a, M(a*))]` quantities; fix
    the assembly.
4.  **Regression tests** — add exposure analogues of `test-recovery.R` /
    `test-bound-contains-truth.R` (NDE *and* NIE, OR/RR/RD), including a
    differential case.
5.  `devtools::test()` + `check()` clean before merge.

## Gate / downstream

- Blocks `me-exposure-recall` (M2b) §6 simulations.
- Does NOT block M2a (mediator) — that path is verified.
- After fix: re-run the exposure smoke and the M2b sims.

## Refs

`PLAN-fix-bound_ne-solve-2026-06-11.md` (mediator analogue, the template
for this fix), `me-exposure-recall/.STATUS` (blocker), CLAUDE.md “OPEN”
section.
