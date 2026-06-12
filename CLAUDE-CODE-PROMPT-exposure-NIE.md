PASTE INTO THE ACTIVE CLAUDE CODE SESSION (cwd = ~/projects/r-packages/active/medrobust)

---

There is an OPEN correctness bug: the exposure (A*) NIE bound is wrong. Fix it per the spec.
Read first, in order:
  - SPEC-fix-exposure-NIE-2026-06-11.md   (the contract: requirements R1-R5, acceptance A1-A5)
  - PLAN-fix-exposure-NIE-2026-06-11.md    (investigation steps + hypotheses)
  - CLAUDE.md "OPEN — exposure NIE" section

BRANCH SETUP (use dev, but sync it first — dev is currently 14 commits BEHIND main and the
bug fixes live on main):
  git checkout main && git pull
  git checkout dev && git merge main          # bring dev up to date (or: git reset --hard main if dev's 1 extra commit is disposable — check `git log main..dev` first)
  git checkout -b fix/exposure-nie dev
  # do the work on fix/exposure-nie; PR -> dev (then dev -> main per the package's main<-dev<-feature flow)

THE BUG (evidence, n=2e5, true Psi in-region, OR scale):
  exposure NDE: true 1.480 in [1.424,1.588]  OK
  exposure NIE: true 1.199 in [0.980,0.991]  WRONG (below null)
  mediator path: both NDE & NIE contain truth -> fix is mediator-correct; problem is A* NIE only.
The exposure SOLVE (class-probability 2x2 inverse) was already audited correct; the bug is in
the A* NIE ASSEMBLY / g-computation. Invariant to enforce: NIE holds the OUTCOME exposure at
a=1 while varying the MEDIATOR-distribution exposure between M(1) and M(0).

TASKS (acceptance criteria A1-A5 in the SPEC):
1. Build A* oracle: dev-diagnostics/oracle_exposure.R — direct potential-outcome simulation of
   the exposure-misclassification DGP (true A; A* = Y-dependent corruption; M ~ true A; Y ~ A,M,C).
   Mirror dev-diagnostics/oracle_potential_outcomes.R. This is ground truth (no formula).
2. Point test: dev-diagnostics/bne_point_test_exposure.R — degenerate region at true Psi, n=5e5;
   assert bound_ne(misclassified_variable="exposure") NDE AND NIE within 0.01 (OR) of the oracle.
3. Trace & fix the exposure NIE assembly in R/bound_ne_exposure.R (and any shared g-comp it calls)
   until the point test passes. Do NOT change the mediator path or compute_effects_from_params
   unless shared; if shared, keep all existing mediator tests green.
4. Add tests: tests/testthat/test-recovery-exposure.R and test-bound-contains-truth-exposure.R
   (NDE and NIE; OR/RR/RD; non-differential AND differential cases).
5. Verify: devtools::test() all green; devtools::check() --as-cran clean (0 err/0 warn).
   Re-run dev-diagnostics/smoke2_popcheck_both_paths.R — the exposure NIE row must now be TRUE.

WRAP UP:
  - NEWS.md: move the exposure-NIE item from "Known issues" to "Bug fixes".
  - CLAUDE.md: change the "OPEN — exposure NIE" section to RESOLVED.
  - .STATUS: clear the exposure-NIE note from `blocked:`.
  - Open PR fix/exposure-nie -> dev.

DOWNSTREAM: unblocks me-exposure-recall (M2b) §6 simulations; regenerate any A* illustrative
numbers in the M2b draft after the fix.

ENV NOTE: renv won't restore under R 4.6 (old Rcpp). Use:
  install.packages(c("S7","dplyr","rlang","ggplot2","pkgload","testthat")); pkgload::load_all(".")
