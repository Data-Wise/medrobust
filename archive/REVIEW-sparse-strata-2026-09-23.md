# REVIEW: adversarial review of BRAINSTORM-sparse-strata-2026-09-23.md (#35)

**Date:** 2026-09-23
**Reviewer:** opencode 1.18.32, model `opencode/big-pickle` (OpenCode Zen free tier), agent `plan`
**Target:** `archive/BRAINSTORM-sparse-strata-2026-09-23.md`, reviewed before the revision it prompted.

**Method.** The review ran on an isolated read-only snapshot: `git archive origin/dev` plus the BRAINSTORM, committed into a throwaway repo. `git status` on that repo was empty afterwards, so no file was written.
- The first run timed out at 15 minutes, before its final write-up.
- The same session was then continued and asked for its final ranked findings. That output is reproduced verbatim below.

**The opencode MCP was not used.** It is configured (`opencode-mcp@3.0.0`, user scope), but its tools never loaded in the session. The CLI calls the same backend.

## Verdicts (each finding re-checked against the code and against the author's own runs)

| Finding | Verdict | Evidence |
|---|---|---|
| C1: evidence row 2 is not reproducible | **Claim wrong, real defect** | Reproduces as 100 vs 0 with `psi_sn` ∈ [1e8, 1e9] (reprex, 2026-09-23). The table omitted the region, so the reviewer tested other regions and got 0/100 because of the #36 zero cell. |
| M1: the exposure CI primitive has no size gate | **Confirmed** | `R/bound_ci.R:11-56`: missing cells become 0 (`if (is.null(v) \|\| is.na(v)) 0 else v`), with no n check; the mediator primitive has `if (nrow(das) < 5) return(NULL)` at `:147`. |
| M2: an unconditional `stop()` breaks callers | **Confirmed, stronger than reported** | `tests/testthat/test-bound-ne-infeasible.R` (commit `3a9ee46`, FixA) uses sparse data as its trigger and asserts `bound_ne` "must NOT stop()". This led the author to revise Decision 1. |
| M3: the 93 s figure is unverified and depends on the grid method | **Resolved** | The author's run used the default `grid_method = "lhs"`, printed "Samples: 2500", and measured `real 93.35`. |
| m1: `test_multiple_hypotheses()` inherits `NA` | **Confirmed** | `R/falsification_summary.R:510`. |
| m2: line citations drift | Valid, cosmetic | |
| m3: the marginal warning is gated on `verbose` | **Confirmed** | `R/utilities_helpers.R:256`: `if (sparse_cells > 0 && verbose)`. |

## Reviewer output (verbatim)

# Adversarial review — `BRAINSTORM-sparse-strata-2026-09-23.md`

Review basis: vendored snapshot `53c8e51` (doc's claim "code unchanged through 25df4b2" is consistent with what passed inspection; `origin/dev 7819731` itself is not verifiable here). Evidence-table rows and code paths were reproduced by sourcing the snapshot's `R/*.R` in-memory against `data/heals_data.rda` (installed `medrobust 0.4.0` is *pre-PR#38* — its `check_compatibility` has no `data_mys`/`all_compatible`/`next`, so it is NOT the code the doc scans).

---

## CRITICAL

### C1. Evidence row 2 is not reproducible, and cannot be true on this data under current code
(a) Claim: `same region, confounders = NULL | 100/100 compatible, falsified_proportion = 1` (doc line 16), used as the contrast that frames the whole problem ("The package's own simulator can produce data its estimator cannot use", line 21).

(b) Evidence: Direct reproduction on the vendored snapshot returns **0/100, `falsified_proportion = 1`** for `confounders = NULL` (default and vignette regions). The cause is structural, not a reproduction quirk. `heals_data` has a degenerate cell: the (M=1, Y=1) cell is 14/14 on `A_star=1` (`table(heals_data$A_star, heals_data$M, heals_data$Y)` → `A_star=0, M=1, Y=1` has **0**, `A_star=1, M=1, Y=1` has **14**). Every parameter set is then rejected via `bound_ne_exposure.R:120-121`:
```r
test2 <- (P_star_1_vec > 1e-6) &
         (P_star_0_vec / P_star_1_vec < (1 - combinations$sn_y) / combinations$sn_y - 1e-6)
```
With `P_star_0 = 0`, `P_star_1 = 1`, this fires for **any** `sn_y < 1` — i.e. essentially every point of any realistic region, since `sn1 = odds_to_prob(psi_sn * prob_to_odds(sn0))` stays < 1. Non-negativity (line 135-137) rejects the same sets. So "100/100 compatible" is unattainable **today** on this data; the degenerate data are doing the rejecting, and the doc's own decision 5 ("warn-and-continue for degenerate cells") is what would actually restore row 2 — not the confounder-sparsity fix. The reproduced 0/100 result instead confirms the degenerate falsification is *real*, so the intended row-2 contrast misstates the cause.

(c) Correction: Either relabel row 2 as a *post-decision-5* target result ("degenerate cells warn-and-continue → 100/100"), or drop it from "reproduced evidence" and restate the no-confounder baseline as "0/100, falsified by a degenerate (M=1,Y=1,A*=1) cell, not by sparse confounder strata."

---

## MAJOR

### M1. The "seven copies" inventory misses an eighth site where the rule is *absent*: the `bound_ci` exposure primitive
(a) Claim: "The rule has seven copies. They agree on the threshold (5) but differ in granularity and response" (line 28), and table row `R/bound_ci.R:147 | (a, c) | return(NULL) for the endpoint computation` (line 36). Decision 1 then says the stop applies to `bound_ne()` **and `bound_ci()`** (line 48).

(b) Evidence: `bound_ci.R:147` is the **mediator** primitive only. `.effect_at_psi_exposure` (`R/bound_ci.R:11-56`) has **no size gate at all** — only the informativity check (line 15) and non-negativity (line 36). Missing cells are silently zeroed: `if (is.null(v) || is.na(v)) 0 else v` (lines 29-31) and `Pmy = 0` (lines 39-45). A resample cell with `n ∈ [1, 4]` contributes its empirical proportions to the endpoint SEs undetected. This is the exact asymmetry the doc's own long-term item #31 warns about ("a bootstrap resample can go sparse"), but only from the mediator side; the exposure side has no gate for the resample to trip.

(c) Correction: "Seven copies" → "seven sites *plus* one unguarded path;" add a row `R/bound_ci.R` `.effect_at_psi_exposure` (──, no gate / computes from n<5 cells). Decision 1's `bound_ci()` stop is a genuinely new restriction on the exposure CI path, which M2 makes material.

### M2. Decision 6's "every case that now errors currently returns no usable bounds" overstates — the default path does not error today
(a) Claim: "Every case that now errors currently returns no usable bounds, so no working analysis breaks" (line 53).

(b) Evidence: With the **default** `grid_method = "lhs"` (first option in `bound_ne.R:174`; the docstring even labels lhs default), an all-sparse data run does *not* error. It filters all `NULL` sets and returns a graceful infeasible result with `NA` bounds + `reason = "infeasible_no_compatible_sets"` (`bound_ne_exposure.R:248-263`, `bound_ne_mediator.R:330-353`), `bound_ne.R:319-329` signals the `medrobust_infeasible` *condition* (not an error), and `bound_ci()` short-circuits on that object to NA CIs without resampling (`bound_ci.R:228-239`). Turning that into a hard `stop()` in 0.5.0 is a breaking change for every caller that handles `n_compatible == 0` (e.g. the power/bootstrap loops and `tests/test-bound-ne-infeasible.R`), not a no-op. Separately, the grid methods the doc doesn't mention — `grid_method = "adaptive" | "auto"` with `n_grid ≥ 10` → `adaptive_grid_search` (`bound_ne_exposure.R:193`, `bound_ne_mediator.R:258`) — already hard-`stop()` today on all-sparse data (`optimization.R:144-147`), with no `tryCatch` at the call sites (`bound_ne.R:222/240`), so "sparsity shows up as falsification" is only true for lhs/sobol/binary/regular.

(c) Correction: Split the claim: default lhs returns an NA-bounds object (breaking a current, documented output state → needs a flag/opt-out or NEWS-heavy framing); adaptive/auto already error (decision 1 makes that error structured and upfront — a fix, not a behavior change). Verify the "0.5.0 error" framing against `test-bound-ne-infeasible.R` before committing to an unconditional `stop()`.

### M3. The quote "2,500 sets × 1,800 cell lookups … 93 s" is arithmetic-consistent but method-dependent and the time is unverified
(a) Claim: "the failing `heals_data` call took 93 s at `n_grid = 50`: 2,500 sets × 1,800 cell lookups, all doomed" (line 27).

(b) Evidence: 2,500 = `ceiling(sqrt(n_grid^4))` for `grid_method="lhs"` (`bound_ne_exposure.R:204`) — correct under the default. 1,800 = `4 (m,y) × 450 strata` per set (`bound_ne_exposure.R:70-78`, the `size_check` vapply over 1,800 rows at 86-92). Both arithmetic checks pass. But this only holds for explicit `grid_method = "lhs"`/`"sobol"`; the doc never states which method produced the run. Under `grid_method="adaptive"`/`"auto"(n_grid≥10)` the actual workload is a 10⁴-point coarse grid that `stop()`s at the first all-sparse coarse stage (`optimization.R:121-147`), so "all doomed" is not a uniform description. The 93 s itself was not re-timed (reproduction interrupted); it is plausible order-of-magnitude but UNVERIFIED.

(c) Correction: Pin the timing statement to `grid_method = "lhs"`, quote `n_grid` and the region, and either re-time or mark 93 s as UNVERIFIED.

---

## MINOR

### m1. A consumer of `check_compatibility`'s change is unnamed: `test_multiple_hypotheses`
Under decision 3, `compatible = NA` flows directly into the results of `test_multiple_hypotheses()`, which reads `test_result$compatible` and `$n_constraints_violated` and binds them into a data.frame (`R/falsification_summary.R:510-511`). Any downstream boolean test on that column hits the same NA hazard as `R/s7-methods.R:339` (`if (x@compatible)`). Add this consumer to the NA-propagation plan (Quick Win 3) and to test coverage.

### m2. Verified-but-cited line numbers drift slightly from the code
Doc cites `bound_ne_exposure.R:91-95` (drop is at 95-96, loop 86-92); `check_compatibility.R:245/471` are the `nrow(...) < 5` lines with the NA-record/`next` on adjacent lines. Cosmetic, but the table's "count nothing"/"record NA" claims depend on those adjacent lines — keep the citations pointed at the actual guard lines in the SPEC.

### m3. The marginal-warning row's evidence was verified, but only by construction
"`utilities_helpers.R:255` … warning only; cannot see strata" (line 38) — confirmed, and the "1 sparse cell" figure is exactly right: `table(A_star, M, Y)` on `heals_data` has one cell < 5 (`M=1,Y=1,A*=0` → 0), gated on `verbose` (lines 254-259). The doc's inference ("instead of 450 sparse strata") is sound; just noting the count is now independently confirmed.

---

## UNVERIFIED
- **93 s runtime** at `n_grid = 50` (M3).
- **Row 2 "100/100 compatible"** — not reproducible and structurally impossible under current code (C1).
- **Row 5 `check_compatibility` run** on `heals_data` (450 strata): reproduction interrupted; the internals (`all_compatible` starts `TRUE`, never flipped on skipped cells, `n_constraints_total` stays 0) confirm the *vacuous TRUE / 0 constraints* output at code level.
- **`simulate_dm_data` binary path "2 strata, 100/100"**: 2 strata confirmed by construction (`rbinom` C1); the 100/100 bound_ne outcome plausible but not run.
- **`gesthtn` "one binary C1"** (data doc not read).
- **"Code scanned: origin/dev 7819731"** — cannot inspect `dev`; the vendored snapshot matches everything cited.

## CONFIRMED claims
1. **`heals_data` → 450 strata for 450 rows;** `bmi` has 450 distinct values, `age` 446; also 450 distinct `(male, smoking, bmi)` combos. (Computed from `data/heals_data.rda`.)
2. **Row 1 "0/100 compatible, `falsified_proportion = 1`"** — reproduced exactly (`n_compatible = 0`, `n_evaluated = 100`, `falsified = 1`, `reason = infeasible_no_compatible_sets`). 100 = `ceiling(sqrt(10^4))` lhs at `n_grid = 10`.
3. **The sparse rule is data-only** in both `bound_ne` paths: `bound_ne_exposure.R:86-97` (vapply over `stratum_sizes`, drop = `return(NULL)`), `bound_ne_mediator.R:83-87` (`nrow(data_as) < 5` → `compatible <- FALSE; break`). Region-independent.
4. **`check_compatibility` vacuous-TRUE / 0-constraint behavior** (code-level): skipped cells at `R/check_compatibility.R:245` (mediator) and `:471` (exposure) with `next`; `all_compatible` never set FALSE for skipped cells; `n_constraints_total` remains 0.
5. **`R/bound_ci.R:147`** mediator primitive `if (nrow(das) < 5) return(NULL)` — confirmed; exposure primitive has no such gate (M1).
6. **`R/optimization.R:277-…` `fast_check_exposure_compatibility` has no callers; literal `stratum_sizes$M`/`$Y` at 317-318; size check at 320** — confirmed by grep. Doc's "delete it" recommendation is right.
7. **`R/utilities_helpers.R:255`** marginal `A*×M×Y` warning, verbose-gated, strata-blind; the single sparse cell it reports is genuinely the `M=1,Y=1,A*=0` cell (n=0).
8. **`R/s7-methods.R:339` `if (x@compatible)`** will error on NA; the `compatible` property (`R/s7-classes.R`, `class_logical`, no validator) accepts NA. Quick Win 3 is required before decision 3 lands.
9. **Default `grid_method` is `"lhs"`** (`bound_ne.R:174` first choice; roxygen line 45 agrees); `target_samples = ceiling(sqrt(n_grid^4))` → 2,500 at n_grid=50 (`bound_ne_exposure.R:204`); `"adaptive"/"auto"(n_grid≥10)` route to `adaptive_grid_search` (`bound_ne_exposure.R:193`), which `stop()`s when the coarse grid has no compatible sets (`optimization.R:144-147`).
10. **Degenerate-cell math (open question 1)**: exposure — a `P* = 0` cell rejects all `sn<sp < 1` via `test1`/`test2` (`bound_ne_exposure.R:118-121`) and non-negativity (135-137); mediator — a zero `P(Y, M*)` cell does **not** automatically reject (only `pi_a ∉ [0,1]` and gamma-range checks, `bound_ne_mediator.R:145-166`). Doc's framing is correct.
11. **`vignettes/articles/identification-math.qmd:48`** writes the mediation formula as `Σ_c P(C=c) Σ_m …` — discrete-C math present; package Rd docs do not state it as a requirement.
12. **`inst/scripts/prepare_nhanes_pa.R:78`** records "Binary confounders crossed into bound_ne strata (8 cells…)" with binary `C1/C2/C3` (age ≥ 50, female, BMI ≥ 30) at lines 79-81.
13. **Finding 6**: no `type = "continuous"` callers in `R/`, `tests/`, or vignettes within the snapshot; `simulate_dm_data.R:166-167` uses `rnorm(n)` for continuous C → n distinct strata by construction (8000 for n=8000).
14. **Installed `medrobust 0.4.0` ≠ snapshot** for `check_compatibility` (pre-PR#38), corroborating the doc's sequencing claim that PR #38 must merge before this work.

Bottom line: the architecture (one shared strata/support helper + `min_cell_size`, upfront stop, `compatible = NA`) is sound and the code-level claims are almost entirely accurate; but row 2 of the evidence table is wrong as current-state evidence (C1), the "seven copies" table undercounts exposure-CI (M1), and decision 6's "no working analysis breaks" needs narrowing (M2) before it's written into the SPEC.
