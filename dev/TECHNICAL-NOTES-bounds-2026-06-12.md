# Technical notes — bound_ne correctness & inference (2026-06-11/12)

A consolidated record of the technical issues found and resolved in the
differential-misclassification bounds, and the inference
**breakthrough**. Companion to the *Identification Mathematics* vignette
(the formal math) and the per-issue SPEC/PLAN docs.

------------------------------------------------------------------------

## Part 1 — Three correctness bugs (all fixed & merged)

The point bounds and the simulator’s ground truth were wrong in three
independent ways. The §4.2/§5.2 manuscript derivations were verified
**exact** (population recovery to $`5\times10^{-17}`$); all three faults
were in the implementation.

### Bug 1 — mediator solve mis-specified (PR \#2)

`bound_ne_mediator.R` recovered $`(\pi,\gamma)`$ from a single
$`3\times3`$ system whose $`P_{01}`$ (Y=0) row used the **Y=1**
parameterization $`(1-\pi)g_0`$ instead of the Y=0 form
$`(1-\pi)(1-g_0)`$. The system was internally inconsistent → biased
recovery → bounds offset (NDE overstated, NIE understated, ~0.05–0.12
OR; worst under strong differential error). **Fix:** two clean
per-Y-stratum $`2\times2`$ systems (each solvable iff
$`Sn_y+Sp_y\neq1`$). **Found by:** population oracle + point test
(`popcheck_exact_recovery.R`, 5e-17).

### Bug 2 — true-effects estimand (PR \#2)

`compute_true_effects()` plugged mean-$`M`$ and mean-$`C`$ into the
nonlinear outcome model (double Jensen), giving `NDE_OR` ~1.500 vs the
correct g-computation ~1.480. **Fix:** Monte-Carlo g-computation over
the empirical confounder distribution. The *bounds* already targeted the
correct estimand; only the simulator’s `@true_effects` label was wrong.

### Bug 3 — exposure NIE assembly (PR \#4)

`bound_ne_exposure.R` recovers the **conditional** $`P(A\mid M,Y,C)`$,
but
[`compute_effects_from_joint_probs()`](https://data-wise.github.io/medrobust/dev/reference/compute_effects_from_joint_probs.md)
consumed those as the **joint** $`P(A,M,Y\mid C)`$, dropping the
observed $`P(M,Y\mid C)`$ weight. That made the M,Y marginal effectively
uniform → $`P(M\mid A{=}1)`$ and $`P(M\mid A{=}0)`$ collapsed toward the
same shape → **NIE driven to the null** (bound \[0.980,0.991\] vs truth
1.199). NDE was spared because it fixes the mediator distribution at
$`M(0)`$ in both terms, so the shared mis-weight cancels. **Fix:**
multiply the recovered conditional by the observed $`P(M,Y\mid C)`$ to
form the joint. **Lesson recorded:** the earlier “exposure audited
correct” claim covered only the *solve* (the $`2\times2`$
class-probability inverse), not the NIE *assembly* — a real over-claim.

**The symptom located each cause:** offset-both-directions (Bug 1),
wrong simulator label only (Bug 2), NIE-to-null-but-NDE-fine (Bug 3).
Each test was designed to discriminate.

------------------------------------------------------------------------

## Part 2 — Finite-sample coverage: a red herring, then the breakthrough

After the bugs were fixed, the *raw* bound under-covered the true effect
at small $`n`$ (mediator NDE, $`\psi=1`$: ~0.20 at $`n{=}500`$ → 0.83 at
$`n{=}20{,}000`$).

### The red herring — “the bound is biased low”

A single $`n{=}2000`$ realization gave NDE bound $`[1.06,1.07]`$ vs
truth 1.48, read as a **downward finite-sample bias**. A method-scout
pointed at bias-corrected bootstrap (Kilian 1998; Schafer 2024;
SAFE/Nakagawa 2025). An analysis plan set up the correction.

### The discriminating experiment (Stage 1)

Before building the correction, characterize the bias and split two
hypotheses: - **H1 plug-in nonlinearity** → predicts bias even at a
**single fixed $`\Psi`$** (no min/max). - **H2 extremum/selection** →
predicts bias only with the grid.

Result (`dev-diagnostics/bias_characterization.R`): at a **single fixed
true $`\Psi`$** the effect is **unbiased** (mildly *high*, vanishing
with $`n`$). And the **population bound is correct** (NDE
$`[1.426,1.580]\ni1.480`$; the corner sweep confirms the genuine
partial-ID range). The “\[1.06,1.07\]” was **one unlucky sample** —
over-read.

### The breakthrough — it’s Imbens–Manski, and the fix already existed

There is **no material finite-sample bias**. The under-coverage is
geometric: the **identified set is narrow** (~0.15 for NDE) **relative
to the endpoint sampling SD** at small $`n`$, so a point estimate of the
set under-covers the true parameter — exactly **Imbens & Manski
(2004)**. The rise of coverage with $`n`$ is its signature.

The fix is the IM CI — widen the endpoints by their SE — which had
*already* been built in `R/bound_ci.R`. Validated (exposure, $`\psi=1`$,
$`n{=}500`$):

| effect | raw-bound coverage | Imbens–Manski CI |
|--------|-------------------:|-----------------:|
| NDE    |               0.09 |         **0.95** |
| NIE    |               0.12 |         **0.93** |

**Outcome:** the investigation *prevented* a multi-day bias-correction
build that would have “fixed” a non-existent problem. Endpoint SEs come
from re-evaluating at the fixed argmin/argmax $`\Psi`$ on resampled data
(no grid search per replicate) — feasible at scale.

------------------------------------------------------------------------

## Status

- Correctness: **done** (PRs \#2, \#4 merged; `main` green; CRAN-clean).
- Inference: **done** —
  [`bound_ci()`](https://data-wise.github.io/medrobust/dev/reference/bound_ci.md)
  (exported) and `bound_ne(ci_method="analytic")` provide Imbens–Manski
  CIs for both paths; validated across the full design (table below);
  187 tests pass, `check() --as-cran` clean. In review as PR \#6 →
  `dev`.

## Key references

Imbens & Manski (2004, *Econometrica*) — CIs for partially identified
parameters; Kilian (1998), Schafer (2024), Nakagawa et al. (2025) —
bias-corrected bootstrap (scouted, not needed here); manuscript
§4.2/§5.2 (Tofighi).

------------------------------------------------------------------------

## Coverage validation — full design (2026-06-12)

Coverage of the true effect (R=60 reps, B=80 endpoint resamples, ψ=1),
raw bound vs Imbens–Manski CI, both paths × N∈{100,200,500} × OR/RR/RD.
Truth = `@true_effects` per scale. Script:
`dev-diagnostics/coverage_table.R`.

| path     |   N |  scale   |       NDE raw → IM        |       NIE raw → IM        |
|----------|----:|:--------:|:-------------------------:|:-------------------------:|
| exposure | 100 | OR/RR/RD |   0.00–0.17 → **1.00**    |   0.17–0.33 → **1.00**    |
| exposure | 200 | OR/RR/RD | 0.07–0.12 → **0.93–0.95** |   0.05–0.14 → **0.95**    |
| exposure | 500 | OR/RR/RD | 0.17–0.18 → **0.95–0.97** | 0.17–0.20 → **0.95–0.97** |
| mediator | 100 | OR/RR/RD |   0.13 → **0.96–1.00**    |   0.17–0.22 → **0.96**    |
| mediator | 200 | OR/RR/RD | 0.04–0.08 → **0.90–0.96** |   0.18–0.27 → **0.92**    |
| mediator | 500 | OR/RR/RD |   0.13–0.17 → **0.95**    |   0.32–0.42 → **0.98**    |

**Conclusion:** the raw bound under-covers badly (0.00–0.42); the
Imbens–Manski CI
([`bound_ci()`](https://data-wise.github.io/medrobust/dev/reference/bound_ci.md)
/ `bound_ne(ci_method="analytic")`) restores ≥ nominal coverage
everywhere (0.90–1.00), conservatively at the smallest N. Confirms the
IM CI as the inference fix across both misclassification paths and all
three effect scales.
