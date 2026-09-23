# BRAINSTORM: sparse strata and continuous confounders (#35)

**Date:** 2026-09-23 · **Depth:** deep · **Focus:** arch · **Issue:** [Data-Wise/medrobust#35](https://github.com/Data-Wise/medrobust/issues/35)
**Status:** decisions taken (6/6 below). The next step is a SPEC, after PR #38 merges.
**Code scanned:** `origin/dev` 7819731 (package code unchanged through 25df4b2).

---

## Problem in one paragraph

`bound_ne()` and `check_compatibility()` cross-classify `confounders` exactly, and `prepare_data()` does no binning. A continuous or high-cardinality confounder therefore makes nearly every row its own stratum. `bound_ne()` then drops every parameter set for n < 5 cells and reports the drops as **"100% falsified"**. `check_compatibility()` skips those cells and returns a vacuous **`compatible = TRUE`** after testing 0 constraints. Neither output says the data were never tested.

| Evidence (reproduced 2026-09-23) | Result |
|---|---|
| `heals_data`, confounders `age, male, smoking, bmi` | 450 strata for 450 rows; 0/100 compatible, `falsified_proportion = 1` |
| same region, `confounders = NULL` | 100/100 compatible |
| `simulate_dm_data(..., confounder_params = list(type = "binary"))`, mediator path | 2 strata; 100/100 compatible |
| same call, `type = "continuous"` | 8000 strata; **0/100**, `falsified_proportion = 1` |
| `check_compatibility(heals_data, ..., confounders = 4 vars)` | `compatible = TRUE`, `n_constraints_total = 0` |

The package's own simulator can produce data its estimator cannot use.

## What the code scan settled (no question needed)

1. **The method is defined for discrete C.** `vignettes/articles/identification-math.qmd:48` writes the mediation formula as a sum, Σ_c P(C=c) Σ_m …. The package never states this assumption as a requirement.
2. **The maintainer already coarsens in data prep.** `inst/scripts/prepare_nhanes_pa.R:78` records "Binary confounders crossed into bound_ne strata (8 cells; feasibility-checked 2026-06-15)", with age ≥ 50, female, and BMI ≥ 30. `gesthtn` uses one binary `C1`.
3. **The sparse check is data-only.** It never reads a parameter (`bound_ne_exposure.R:91`, `bound_ne_mediator.R:83`), so every parameter set passes it or every set fails. Running it per set is why sparsity shows up as falsification. It is also why the failing `heals_data` call took 93 s at `n_grid = 50`: 2,500 sets × 1,800 cell lookups, all doomed.
4. **The rule has seven copies.** They agree on the threshold (5) but differ in granularity and response:

   | Site | Cell | Response to n < 5 |
   |---|---|---|
   | `R/bound_ne_exposure.R:91-95` | (m, y, c) | drop the parameter set (`return(NULL)`) |
   | `R/bound_ne_mediator.R:83` | (a, c) | `compatible <- FALSE; break` for the set |
   | `R/check_compatibility.R:471` (exposure) | (m, y, c) | `next`: skip the cell, count nothing |
   | `R/check_compatibility.R:245` (mediator) | (a, c) | record `compatible = NA` for the stratum, skip it |
   | `R/bound_ci.R:147` | (a, c) | `return(NULL)` for the endpoint computation |
   | `R/optimization.R:320` | (m, y, c) | drop the set (`return(NULL)`), inside `fast_check_exposure_compatibility()`. That function has **no callers** on `dev` and looks up `stratum_sizes$M` / `$Y` by literal name, so delete it rather than route it through the helper. |
   | `R/utilities_helpers.R:255` | marginal A\*×M×Y table | warning only; **cannot see strata** |

   The last row is why the `heals_data` run warned about "1 sparse cell" instead of 450 sparse strata.
5. **`compatible = NA` needs one print fix.** `R/s7-methods.R:339` does `if (x@compatible)`, which fails with "missing value where TRUE/FALSE needed". The property itself (`class_logical`, no validator) accepts `NA`.
6. **Nothing uses continuous simulated confounders.** No file in `R/`, `tests/`, or `vignettes/articles/*.qmd` passes `type = "continuous"`, and `power_analysis()` uses the binary default. A warning there breaks nothing.

## Decisions (all six recommended options were chosen)

| # | Question | Decision |
|---|---|---|
| 1 | What `bound_ne()` does with sparse strata | **One upfront, data-only check that stops**, naming the sparse (cell, C) combinations, their n, and a coarsening hint. No parameter set is evaluated. |
| 2 | Code structure | **One shared helper that builds strata and checks support, with `min_cell_size = 5` exposed as an argument**, used by every path. |
| 3 | `check_compatibility()` when nothing was testable | **`compatible = NA` with a reason** (e.g. `"no testable strata"`). |
| 4 | Scope of continuous-C support | **Guard plus docs.** State the discrete-C assumption in `?bound_ne` and the methodology article. `simulate_dm_data(type = "continuous")` warns that `bound_ne()` needs discrete confounders. |
| 5 | Degenerate cells (n ≥ 5 but P\* = 0 or 1) | **Warn and name the cells, but keep computing.** Sampling slack stays with #36. |
| 6 | Release | **Error in 0.5.0**, with a NEWS entry under behavior changes. Every case that now errors currently returns no usable bounds, so no working analysis breaks. |

## Architecture

### Current

```mermaid
flowchart LR
  D[data] --> P[prepare_data<br/>no binning]
  P --> G{grid of psi}
  G -->|each set| S1[size_check per set<br/>n under 5 → drop]
  S1 -->|all dropped| F["0/N compatible<br/>'100% falsified'"]
  S1 -->|kept| T[testable implications] --> B[bounds]
  P --> CC[check_compatibility]
  CC --> S2[n under 5 → skip cell]
  S2 -->|every cell skipped| V["compatible = TRUE<br/>0 constraints"]
```

### Proposed

```mermaid
flowchart LR
  D[data] --> P[prepare_data]
  P --> BS["build_strata(data, confounders)"]
  BS --> SUP["stratum_support(strata, cell_vars,<br/>min_cell_size = 5)"]
  SUP -->|"any sparse cell (bound_ne, bound_ci)"| E["stop(): table of sparse cells,<br/>n, coarsening hint"]
  SUP -->|degenerate cells| W["warning(): cells with P* = 0 or 1"]
  SUP -->|supported| G{grid of psi}
  G --> T[testable implications] --> B[bounds]
  SUP -->|check_compatibility| CC{testable strata?}
  CC -->|none| NA["compatible = NA<br/>reason: no testable strata"]
  CC -->|some or all| T2[test supported strata;<br/>report n_untested]
```

### Helper sketch (internal, not exported)

```r
# One stratum id per distinct confounder combination; NULL confounders give one stratum.
build_strata(data, confounders)
#> list(data = <data with stratum_id>, strata = <data.frame: stratum_id + confounder values>)

# Path-specific cell variables:
#   exposure misclassified: cells are (M, Y, C)
#   mediator misclassified: cells are (A, C)
stratum_support(strata, cell_vars, min_cell_size = 5)
#> data.frame(stratum_id, <cell_vars>, n, sparse = n < min_cell_size, degenerate)

# Stops with a readable table (first k rows plus a count); used by bound_ne() and bound_ci()
assert_stratum_support(support, confounders, min_cell_size, call = rlang::caller_env())
```

Draft error message:

```
Error in `bound_ne()`:
! 1800 of 1800 (M, Y, C) cells have fewer than 5 observations (min_cell_size = 5).
  bound_ne() cross-classifies `confounders` exactly, so each distinct combination
  of age, male, smoking, bmi is its own stratum (450 strata for 450 rows).
i Coarsen continuous confounders first, e.g. age >= 50, BMI >= 30
  (as inst/scripts/prepare_nhanes_pa.R does), or pass fewer confounders.
```

## Behavior matrix

| Situation | `bound_ne()` / `bound_ci()` | `check_compatibility()` |
|---|---|---|
| All cells ≥ `min_cell_size` | unchanged | unchanged |
| Some cells sparse | **stop** (today: 0/N "falsified") | test the supported strata; add `n_untested_strata` and a warning *(proposal, not asked; see open question 2)* |
| All cells sparse | **stop** | **`compatible = NA`**, reason `"no testable strata"` (today: vacuous `TRUE`) |
| Degenerate cells (P\* = 0 or 1, n ≥ min) | compute plus **warning** naming the cells | compute plus the same warning |
| `simulate_dm_data(type = "continuous")` | n/a | n/a; the simulator itself **warns** |

`bound_ne()` needs *every* stratum, because the effects standardize over Σ_c P(C=c). `check_compatibility()` tests implications stratum by stratum, so a partial test still means something. That difference is why the two can respond differently to partial sparsity.

---

## Quick Wins (< 30 min)

1. **Document the discrete-C assumption** in `?bound_ne` `@details` and `?check_compatibility`, citing the Σ_c form. This costs nothing and would have prevented the `heals_data` vignette region.
2. **Warn in `simulate_dm_data()` when `type = "continuous"`** and point to coarsening. It is a one-line guard and breaks nothing (finding 6).
3. **Fix the `if (x@compatible)` print hazard** (`R/s7-methods.R:339`) now, since decision 3 depends on it.

## Medium Effort (1–2 hrs)

- [ ] Add `build_strata()` / `stratum_support()` / `assert_stratum_support()` in a new `R/strata.R`, and route the six live sites through them. Delete the per-set `size_check` in `bound_ne_exposure.R`, the `break` in `bound_ne_mediator.R`, and the uncalled `fast_check_exposure_compatibility()`.
- [ ] Add `min_cell_size = 5` to `bound_ne()`, `bound_ci()`, and `check_compatibility()`, validated as a positive integer.
- [ ] Return `compatible = NA` with a reason from `check_compatibility()` when no stratum is testable, and add `n_untested_strata` for the partial case.
- [ ] Add the degenerate-cell warning, derived exactly for the exposure path (constraints 1 and 2). For the mediator path, see open question 1.
- [ ] Replace the marginal-table warning at `utilities_helpers.R:255` with the stratum-level check, or remove it.
- [ ] NEWS 0.5.0 behavior-change entry, plus tests (see the test plan).

## Long-term (future sessions)

- [ ] **#36:** regenerate `heals_data` with the `nhanes_pa`-style binary confounders (age ≥ 50, BMI ≥ 30, …) and no zero cells. Check in `inst/scripts/prepare_heals_data.R`, and switch the vignette chunk to `eval: true`.
- [ ] **Sampling slack in the falsification step** (the #36 methods question). Today one sampled zero rejects the true psi about 14% of the time in `heals_data`'s cell.
- [ ] **Model-based standardization for continuous C** (parametric P(A\* | M, Y, C)). This needs a separate SPEC and an identification argument; it was out of scope by decision 4.
- [ ] Optional exported `coarsen_confounders()` if users keep hand-binning. It was not chosen now.
- [ ] **Resample-level sparsity in `bound_ci()`.** A bootstrap resample can go sparse even when the original data pass the check. This interacts with #31, where failed resamples are not counted.

## Open questions (for the SPEC)

1. **Degenerate-cell rule on the mediator path.** On the exposure path, P\*(A\*=a | m, y, c) = 0 provably rejects every Sn or Sp < 1 (constraint 2 or 1). On the mediator path, a zero in P(Y, M\* | a, c) makes one solved term negative, but π_a = θ₁ + θ₀ can still land in [0, 1]. So the rejection is not automatic, and the warning condition needs deriving rather than copying.
2. **Partial sparsity in `check_compatibility()`:** test the supported strata and warn (proposed), or stop like `bound_ne()`? This was not asked. The proposal follows from the function's role as a point diagnostic.
3. **Error-message size:** how many sparse rows to print before truncating (the `heals_data` case has 1,800).

## Sequencing

1. **PR #38 (#34) merges first.** It touches `R/check_compatibility.R` and `R/s7-classes.R`, which this work also edits.
2. **#35 lands on its own branch**, with Quick Wins 1–3 plus the Medium items, in one PR targeting 0.5.0.
3. **#36 follows**, and needs 2 for its regenerated data to be checked against the new support rule.

---

## Test plan (scaffold)

Tiers are inferred from the change shape: a new internal helper (unit), a data flow shared across `bound_ne`, `bound_ci` and `check_compatibility` (integration), plus e2e. Templates live in craft's shared scaffold file (`skills/workflow/brainstorm-insights/references/scaffold-templates.md`). The stubs below are red-first.

| Tier | Status |
|---|---|
| unit | `stratum_support()` counts, the `sparse`/`degenerate` flags, and `min_cell_size` validation |
| integration | every path stops or returns NA consistently on the same sparse data |
| e2e | continuous-C simulator plus `heals_data` reproductions, run end to end |
| dogfood | re-run `vignettes/articles/*-bounds.qmd` (gesthtn, nhanes_pa); their results must not change |
| dependency | N/A — no new package dependency (`rlang` is already imported, if used for the error) |
| count-cascade | N/A — no new command, skill or agent; R package |

```r
# tests/testthat/test-strata-support.R  (red-first stubs)
# TODO(author): delete if not contract-bearing

test_that("bound_ne stops on sparse strata instead of reporting falsification", {
  fail("not implemented: continuous C1 from simulate_dm_data() -> expect_error(bound_ne(...), 'fewer than 5')")
})

test_that("check_compatibility returns NA when no stratum is testable", {
  fail("not implemented: heals_data 4 confounders -> expect_identical(res@compatible, NA)")
})

test_that("binary-confounder results are unchanged", {
  fail("not implemented: gesthtn / nhanes_pa bounds identical before and after (snapshot)")
})

test_that("degenerate cells warn but compute (exposure path)", {
  fail("not implemented: heals_data, confounders = NULL -> expect_warning(..., 'P\\\\* = 0')")
})

test_that("simulate_dm_data warns for continuous confounders", {
  fail("not implemented: expect_warning(simulate_dm_data(..., confounder_params = list(type = 'continuous')))")
})
```

## Documentation (doc-impact rubric, threshold ≥ 3; heavy types ≥ 5)

| Doc type | Score | Emit? | What, in this package's terms |
|---|---|---|---|
| Guide | 4 (new module 3 + architecture 1) | [x] | methodology article: "Confounders are stratified exactly" section plus a coarsening example |
| Refcard | 3 (new module 1 + config 2) | [x] | roxygen `@param min_cell_size`, `@details` on discrete C, `@section Errors` in `?bound_ne` / `?check_compatibility` |
| Mermaid | 5 (new module 2 + architecture 3) | [x] | the proposed diagram above, reusable in the methodology article |
| Demo | N/A — score 1 | | |
| Tutorial | N/A — score 2 | | |
| API | N/A — score 3 (< 5; an argument on existing functions is not a new user-facing surface) | | |
| Cookbook | N/A — score 2 | | |
| Architecture-doc | N/A — score 2 | | |

The NEWS entry is part of the Medium items. No version or count lines are touched here.

## Recommended Next Step

→ **Merge PR #38 first, then write the SPEC for #35 from this document**, resolving open questions 1–2 in it. The SPEC cannot start cleanly while #38 still edits the same two files, and open question 1 is the one place where the design needs a derivation rather than a choice.
