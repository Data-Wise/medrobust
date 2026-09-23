# SPEC — sparse strata are reported as untested, not falsified (#35)

|  |  |
|----|----|
| **Status** | draft — ready for implementation once \#39 lands |
| **Created** | 2026-09-23 |
| **Branch** | `feature/sparse-strata` (off `dev`, not yet created) |
| **Closes** | [\#35](https://github.com/Data-Wise/medrobust/issues/35) |
| **Depends on** | [\#39](https://github.com/Data-Wise/medrobust/issues/39) (mediator γ checks in [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md) are vacuous) — fix first |
| **Unblocks** | [\#36](https://github.com/Data-Wise/medrobust/issues/36) (regenerate `heals_data`) |
| **From** | `archive/BRAINSTORM-sparse-strata-2026-09-23.md` (deep, arch) plus its adversarial review `archive/REVIEW-sparse-strata-2026-09-23.md` |
| **Code cited at** | `origin/dev` a49fc7f. Line numbers here supersede the brainstorm’s, several of which have drifted. |
| **Release** | 0.5.0, with a NEWS entry |

------------------------------------------------------------------------

## Context

[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
and
[`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
cross-classify `confounders` exactly, and
[`prepare_data()`](https://data-wise.github.io/medrobust/reference/prepare_data.md)
does no binning. With a continuous or high-cardinality confounder,
nearly every row becomes its own stratum. Today the two functions then
get it wrong in opposite directions:

- **[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
  reports sparsity as falsification.** It drops every parameter set for
  an n \< 5 cell and reports `falsified_proportion = 1`. Example:
  `heals_data` with `age, male, smoking, bmi` gives 450 strata for 450
  rows and 0/100 compatible. The package’s own simulator with
  `type = "continuous"` gives 8,000 strata and 0/100.
- **[`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
  reports it as a pass.** It skips those cells and returns
  `compatible = TRUE` with 0 constraints tested.

Neither output says the data were never tested. The evidence table, with
regions R1\* and R2, is in the brainstorm and is not repeated here.

The method itself is defined for discrete C.
`vignettes/articles/identification-math.qmd:48` writes the mediation
formula as Σ_c P(C=c) Σ_m …, and `inst/scripts/prepare_nhanes_pa.R:78`
already coarsens its confounders before calling
[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md).
The bug is that the package never checks the assumption, and misreports
what happens when it fails.

## Overview

1.  **One data-only support check up front, in one shared helper.** It
    runs before any ψ is evaluated. On sparse data,
    [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
    returns the existing FixA infeasible object (no
    [`stop()`](https://rdrr.io/r/base/stop.html)) with a new reason,
    `insufficient_stratum_support`, and `falsified_proportion = NA`. It
    also warns, naming the sparse cells.
2.  **[`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
    becomes three-valued.**
    - `FALSE` if any tested cell violates a constraint.
    - `TRUE` only if every cell was tested and all pass.
    - Otherwise `NA`, with a new `n_untested_cells` count and a warning.
3.  **Degenerate cells warn and keep computing.** These are supported
    cells whose observed proportion is 0 or 1, and the warning states
    exactly which ψ they reject.
4.  **`grid_method = "adaptive"` / `"auto"` stop calling
    [`stop()`](https://rdrr.io/r/base/stop.html)** on an empty coarse
    grid and fall into the same FixA path as every other grid method.
5.  **The discrete-C assumption is documented**, and
    `simulate_dm_data(type = "continuous")` warns.

## Key decisions (resolved)

The author made decisions 1–6 at the brainstorm (Decision 1 was revised
after review) and answered Q2, Q4 and the γ question on 2026-09-23. Rows
marked *(spec default)* are choices this SPEC made where no question was
asked; override any of them before implementation.

| \# | Decision | Source |
|----|----|----|
| D1 | [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md) runs one upfront, data-only support check. On any sparse cell it returns the FixA infeasible object: NA bounds, `n_compatible = 0L`, `n_evaluated = 0L`, `falsified_proportion = NA_real_`, `reason = "insufficient_stratum_support"`. It emits a warning and signals `medrobust_infeasible`. **No [`stop()`](https://rdrr.io/r/base/stop.html).** | author (revised after review) |
| D2 | One shared internal helper builds strata and checks support. `min_cell_size = 5L` is exposed as an argument of [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md) and [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md). | author |
| D2a | [`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md) takes **no** `min_cell_size` argument. It reads the value [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md) stored on the object (`bounds@min_cell_size`), so the two can never disagree. | *(spec default)*, refining the brainstorm’s Medium item |
| D3 | [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md) returns `compatible = NA` with a reason when it cannot give a verdict. | author |
| D3a | That reason is the same machine-readable token as D1, `"insufficient_stratum_support"`, so a single grep finds both. The brainstorm’s example string, “no testable strata”, is replaced. | *(spec default)* |
| Q2 | **Three-valued `compatible`**: FALSE if any tested cell violates, TRUE only if all cells are tested and pass, otherwise NA plus `n_untested_cells` plus a warning. | author, 2026-09-23 |
| D4 | Guard plus docs; no support for continuous C. The discrete-C assumption goes in [`?bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md), [`?check_compatibility`](https://data-wise.github.io/medrobust/reference/check_compatibility.md) and the methodology article, and `simulate_dm_data(type = "continuous")` warns. | author |
| D5 | Degenerate cells warn, name the cells, and keep computing. The mediator rule is now derived (Q1 below). Sampling slack stays with \#36. | author |
| Q1 | On the mediator path, a zero cell **does** reject automatically, with two stated exceptions. This corrects the brainstorm and the review; see the derivation. | derived, verified numerically |
| Q3 | The warning prints the first **10** sparse or degenerate cells plus a total count. | *(spec default)* |
| Q4 | `adaptive` / `auto` are brought under FixA: an empty coarse grid returns an empty result instead of calling [`stop()`](https://rdrr.io/r/base/stop.html). | author, 2026-09-23 |
| γ | The vacuous γ checks are filed separately as \#39 and fixed **before** this work. | author, 2026-09-23 |
| D6 | Ships in 0.5.0. No [`stop()`](https://rdrr.io/r/base/stop.html) is introduced, so callers that already handle the infeasible object keep working. | author |

### Q1 — the mediator degenerate-cell rule (derivation)

**Setting.** Within one supported cell (a, c), write P\*(y, m\*) =
P(Y=y, M\*=m\* \| a, c). For each outcome level y, the observed pair
solves a 2×2 system (`bound_ne_mediator.R:108-138`). With d_y = Sn_y +
Sp_y − 1 \> 0:

``` text
P(M=1, Y=y) = [ Sp_y · P*(y,1) − (1 − Sp_y) · P*(y,0) ] / d_y
P(M=0, Y=y) = [ Sn_y · P*(y,0) − (1 − Sn_y) · P*(y,1) ] / d_y
```

**The checks are exactly non-negativity.** π_a = P(M=1, Y=1) + P(M=1,
Y=0), γ_a1 = P(M=1, Y=1)/π_a and γ_a0 = P(M=0, Y=1)/(1 − π_a). For π_a ∈
(0, 1):

- γ_a1 ∈ \[0, 1\] ⇔ both P(M=1, ·) ≥ 0.
- γ_a0 ∈ \[0, 1\] ⇔ both P(M=0, ·) ≥ 0.

So `bound_ne_mediator.R:145-169` tests exactly that the four solved
joint cells are non-negative.

**Cases**, for a supported cell with n ≥ `min_cell_size`:

| Observed pattern in row y | Solved cell | Consequence |
|----|----|----|
| P\*(y,1) = 0 \< P\*(y,0) | P(M=1, Y=y) = −(1 − Sp_y) P\*(y,0) / d_y \< 0 | **rejects every ψ with Sp_y \< 1** |
| P\*(y,0) = 0 \< P\*(y,1) | P(M=0, Y=y) = −(1 − Sn_y) P\*(y,1) / d_y \< 0 | **rejects every ψ with Sn_y \< 1** |
| P\*(y,1) = P\*(y,0) = 0 (empty outcome margin) | both are 0 | no rejection; γ is pinned (γ_a1 = γ_a0 = 0 if y = 1 is empty, 1 if y = 0 is empty) |

**Why “every ψ”.** ψ enters through odds (`bound_ne_mediator.R:45-46`,
`sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))`), so Sn_1 and Sp_1
stay below 1 for every finite ψ. `bound_ne_mediator` compares with exact
`< 0`, so the first two rows reject for every finite ψ.

**Two exceptions**, which the warning text must not overstate:

1.  **π_a within 1e-6 of 0 or 1.** `bound_ne_mediator.R:152-159` sets
    the undefined γ to 0.5, so its two cells go unchecked. A negative
    P(M=1, ·) whose partner nearly cancels it escapes when π_a \< 1e-6.
2.  **[`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)’s
    tolerance.** After \#39 it accepts γ ≥ −1e-6. At ψ_sp ≈ 1e9 the
    negative cell is about −1e-10, so
    [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
    accepts what
    [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
    rejects. See open question 1.

**Numeric check.** The \#39 repro has P\*(1,1) = 0 \< P\*(1,0) in cell A
= 0, no confounders, and 30 and 40 rows per cell.
[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
returned 0/100 compatible for ψ_sp in \[0.8, 1.5\], \[1e3, 1e4\] and
\[1e8, 1e9\].

**Correction on record.** The brainstorm’s open question 1 said “π_a …
can still land in \[0, 1\], so the rejection is not automatic”, and the
review “confirmed” it. Both were wrong: they checked π_a and missed that
the γ checks bound each solved cell individually. The archived
brainstorm stays as written; this section supersedes it.

### Exposure path, for comparison

On the exposure path the cell is (m, y, c), and P\*\_a = P(A\*=a \| m,
y, c). If P\*\_1 = 0, constraint 1 (`bound_ne_exposure.R:118-119`)
rejects every Sp_y \< 1/(1 + 1e-6). If P\*\_0 = 0, constraint 2 rejects
every Sn_y \< 1/(1 + 1e-6). The tolerance is 1e-6 in both functions on
this path.

## Deliverables (acceptance criteria)

### A. Shared helper — new `R/strata.R` (internal)

`build_strata(data, confounders)` assigns one `stratum_id` per
**observed** confounder combination; `NULL` confounders give a single
stratum. It replaces the five copies at `bound_ne_mediator.R:58-69`,
`check_compatibility.R:215-226` and `:439-451`, `bound_ci.R:133-140`,
and `precompute_observed_probs()` (`optimization.R:17-30`, the exposure
path).

`stratum_support(data, strata, cell_vars, min_cell_size)` returns one
row per cell with columns `stratum_id`, the cell variables, `n`,
`sparse` (= `n < min_cell_size`) and `degenerate`.

- The cells are the **full cross** of the cell values × the observed
  strata.
- An absent cell appears with `n = 0` and `sparse = TRUE`.
  [`dplyr::count()`](https://dplyr.tidyverse.org/reference/count.html)
  drops absent cells, so it must not be used alone. This matches the
  current exposure rule `nrow(size_row) > 0 && n >= 5`
  (`bound_ne_exposure.R:86-92`).
- Exposure cells are (m, y, c) with m, y ∈ {0, 1}. Mediator cells are
  (a, c) with a ∈ {0, 1}.

`degenerate` follows the rules above:

- Exposure: P\*(A\*=1 \| cell) ∈ {0, 1}.
- Mediator: some y with exactly one of P\*(y,0), P\*(y,1) equal to 0, or
  an empty outcome margin, reported as its own type.

`describe_stratum_support(support, confounders, min_cell_size, max_rows = 10L)`
builds the warning text: the first 10 offending cells, the total count,
the strata-to-rows ratio, and a coarsening hint that points at
`inst/scripts/prepare_nhanes_pa.R`.

`min_cell_size` is validated as a single integer-valued number ≥ 1.

### B. `bound_ne()`

[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
gains the argument `min_cell_size = 5L`. The support check runs after
[`prepare_data()`](https://data-wise.github.io/medrobust/reference/prepare_data.md)
and before dispatch.

On any sparse cell,
[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
builds a result list **of the same shape as** the dispatchers’
infeasible list (`bound_ne_exposure.R:251-262`), with
`n_evaluated = 0L`, `falsified_proportion = NA_real_` and
`reason = "insufficient_stratum_support"`. That list flows through the
existing constructor (`bound_ne.R:336-353`) and condition signal. No ψ
is evaluated.

The `medrobust_infeasible` condition (`bound_ne.R:319-328`) gains a
`reason` field. Its message branches on the reason: the existing “widen
sensitivity_region” advice is wrong for sparsity.

The verbose summary at `bound_ne.R:373-374` also branches on the reason.

The per-set checks are deleted: `size_check`
(`bound_ne_exposure.R:85-96`) and the sparse
[`break`](https://rdrr.io/r/base/Control.html)
(`bound_ne_mediator.R:83-87`). The marginal A\*×M×Y warning in
[`check_data_quality()`](https://data-wise.github.io/medrobust/reference/check_data_quality.md)
(`utilities_helpers.R:251-258`, called at `bound_ne.R:212`) is replaced
by the stratum-level warning. That old warning could not see strata and
was silent under `verbose = FALSE`.

Degenerate cells trigger one warning (D5), and computation continues.

`medrobust_bounds` gains the property `min_cell_size` (`class_integer`,
default `5L`). The `falsified_proportion` validator
(`s7-classes.R:247-253`) accepts `NA`:
`if (!is.na(value) && (value < 0 || value > 1))`.

### C. `check_compatibility()` — three-valued (Q2)

The function gains the argument `min_cell_size = 5L`, and its sparse
skips (`check_compatibility.R:245-254` mediator, `:471-480` exposure) go
through the helper.

`compatibility_test` gains the property `n_untested_cells`
(`class_integer`, default `0L`). “Cell” is the path’s cell: (a, c) on
the mediator path and (m, y, c) on the exposure path. The property is
named for both paths, not “strata”.

Result logic:

- `compatible = FALSE` if any tested cell violates a constraint. The
  existing early exits (`:118`, `:136`) are unchanged.
- `TRUE` iff there are no violations and `n_untested_cells == 0`.
- Otherwise `NA`, with `reason = "insufficient_stratum_support"` and one
  warning from `describe_stratum_support()`.

**`if (all_compatible)` at `check_compatibility.R:419` and `:633`
becomes `isTRUE(all_compatible)`.** Otherwise an NA verdict errors
inside the function itself, the same class of bug as \#34.

Degenerate cells warn, as in B.

### D. `bound_ci()`

The short-circuit (`bound_ci.R:228-239`) propagates `bounds@reason` into
`NIE_reason` / `NDE_reason` in place of the hard-coded
`"infeasible_no_compatible_sets"`. Hard-coding it would relabel sparsity
as “no compatible sets”, the conflation this issue removes.

The mediator primitive’s `nrow(das) < 5` (`bound_ci.R:147`) and a
**new** gate in `.effect_at_psi_exposure()` (`bound_ci.R:11-56`, ungated
today; missing cells become 0) both use `bounds@min_cell_size`. Both
return `NULL` for a sparse resample. Counting those failures is \#31’s
work, not this one’s.

### E. Adaptive and auto grid (Q4)

`adaptive_grid_search()` (`optimization.R:144-147`) returns
`structure(list(), n_evaluated = nrow(coarse_grid))` instead of calling
[`stop()`](https://rdrr.io/r/base/stop.html). The attribute is required:
without it the dispatchers fall back to `length(results)`, which is 0
and understates the work done.

The existing graceful path then applies unchanged
(`bound_ne_exposure.R:243-262`; the mediator path at
`bound_ne_mediator.R:341-352`).

No test expects the old error (checked: no match in `tests/` for “No
compatible parameter sets found in coarse grid”).

`fast_check_exposure_compatibility()` (`optimization.R:277`) is deleted.
It has no callers on `dev` and looks up `$M` / `$Y` by literal name.

### F. NA-safe consumers

The print method for `compatibility_test` (`s7-methods.R:374`,
`if (x@compatible)`) gets three branches, and the NA branch prints
`n_untested_cells` and the reason.

The print method for `medrobust_bounds` (`s7-methods.R:58-62`) prints
“not tested (insufficient_stratum_support)” instead of “NA%” when
`falsified_proportion` is `NA`.

[`falsification_summary()`](https://data-wise.github.io/medrobust/reference/falsification_summary.md)
(`falsification_summary.R:82-84`) and
[`sensitivity_plot()`](https://data-wise.github.io/medrobust/reference/sensitivity_plot.md)
(`visualization.R:128-129`) keep their
[`stop()`](https://rdrr.io/r/base/stop.html) on an empty object, but
name the reason, so a sparse result no longer says “No compatible
parameter sets found”.

[`test_multiple_hypotheses()`](https://data-wise.github.io/medrobust/reference/test_multiple_hypotheses.md)
(`falsification_summary.R:500-512`) adds an `n_untested` column. Its
`@return` documents that `compatible` can be `NA`.

The `falsified_prop` column of
[`compare_bounds()`](https://data-wise.github.io/medrobust/reference/compare_bounds.md)
(`simulation.R:451`) passes `NA` through. `@return` documents it.

### G. Documentation and simulator (D4)

`@details` in
[`?bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
and
[`?check_compatibility`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
gets three things:

- the discrete-C assumption, citing the Σ_c form;
- `min_cell_size`;
- the `insufficient_stratum_support` reason.

`identification-math.qmd` gets a short section, “Confounders are
stratified exactly”, with a coarsening example.

`s7-documentation.qmd:132` describes `falsified_proportion = NA`.

[`simulate_dm_data()`](https://data-wise.github.io/medrobust/reference/simulate_dm_data.md)
warns when `type = "continuous"` (`simulate_dm_data.R:165-166`) and
points to coarsening.

NEWS entry under `# medrobust 0.5.0`, covering:

- the new reason and `falsified_proportion = NA`;
- three-valued `compatible` and `n_untested_cells`;
- `min_cell_size`;
- adaptive/auto no longer stopping;
- the new warnings.

## Architecture

``` mermaid
flowchart LR
  D[data] --> P[prepare_data]
  P --> BS["build_strata(data, confounders)"]
  BS --> SUP["stratum_support(..., cell_vars,<br/>min_cell_size)"]
  SUP -->|"bound_ne: any sparse cell"| E["FixA infeasible object<br/>reason = insufficient_stratum_support<br/>falsified_proportion = NA<br/>warning + medrobust_infeasible(reason)"]
  SUP -->|degenerate cells| W["warning: cells + which psi they reject"]
  SUP -->|"bound_ne: all supported"| G{"grid of psi<br/>(all grid methods)"}
  G -->|none compatible| E2["FixA infeasible object<br/>reason = infeasible_no_compatible_sets"]
  G -->|some compatible| B[bounds]
  SUP -->|check_compatibility| CC{"violation in a<br/>tested cell?"}
  CC -->|yes| F[FALSE]
  CC -->|"no, and n_untested_cells = 0"| T[TRUE]
  CC -->|"no, and n_untested_cells > 0"| NA["NA + reason + warning"]
  E --> CI["bound_ci: NA CIs,<br/>reason propagated"]
  E2 --> CI
```

[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
needs every cell, because the effects standardize over Σ_c P(C=c).
[`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
tests implications cell by cell, so a partial test still means
something. It is reported as NA rather than TRUE, because an untested
cell could have held the violation.

## API / data models

| Object | Change |
|----|----|
| `bound_ne(..., min_cell_size = 5L)` | new argument |
| `check_compatibility(..., min_cell_size = 5L)` | new argument |
| `medrobust_bounds@min_cell_size` | new, `class_integer`, default `5L` |
| `medrobust_bounds@falsified_proportion` | may now be `NA_real_` (validator relaxed) |
| `medrobust_bounds@reason` | new value `"insufficient_stratum_support"` |
| `compatibility_test@compatible` | may now be `NA` |
| `compatibility_test@n_untested_cells` | new, `class_integer`, default `0L` |
| `compatibility_test@reason` | new value `"insufficient_stratum_support"` |
| `medrobust_infeasible` condition | new field `reason` |
| [`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md) result `NIE_reason` / `NDE_reason` | carries `bounds@reason` |
| [`test_multiple_hypotheses()`](https://data-wise.github.io/medrobust/reference/test_multiple_hypotheses.md) result | new column `n_untested`; `compatible` may be `NA` |

No new exports and no new package dependencies.

## Dependencies and sequencing

1.  **\#39 first.** It edits the mediator γ block of
    `check_compatibility.R` (`:331-340`). Section C here edits the same
    function, and the three-valued verdict is only meaningful once γ is
    actually tested.
2.  **This SPEC**, as one PR off `dev` targeting 0.5.0.
3.  **\#36** follows. Its regenerated `heals_data` must pass the new
    support check with no degenerate-cell warning.

## Open questions

1.  **Tolerance alignment on the mediator path.** `bound_ne_mediator`
    compares exactly, while
    [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
    uses `tolerance = 1e-6` (a user-facing argument). After \#39 the two
    can disagree on degenerate cells at large ψ. **Deferred to \#39’s
    PR**, where that comparison is being edited. Recommendation: keep
    the user-facing `tolerance`, and document that
    [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)
    is the more lenient of the two. The warning from this SPEC is
    data-only and states rejection in
    [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)’s
    terms, so it does not depend on the answer.
2.  **Should the empty-outcome-margin case warn at all?** It rejects
    nothing, but it pins γ. The spec default is to warn, with its own
    message. Drop it if it proves noisy on `gesthtn` / `nhanes_pa`; the
    dogfood step below will show whether it does.

## Implementation notes

- Write the upfront check’s infeasible list in one place: a small
  `infeasible_result(reason, n_evaluated, naive_estimates)` in
  `R/strata.R`. Use it for the three existing copies too
  (`bound_ne_exposure.R:251-262` and `:326-337`,
  `bound_ne_mediator.R:341-352`). The four sites then cannot drift in
  shape.
- The support check is data-only, so it runs once per call, not once per
  ψ. The failing `heals_data` call that took 93 s (default `lhs`,
  `n_grid = 50`, measured) becomes near-instant.
- Keep `stratum_details` on `compatibility_test` as it is, with
  `compatible = NA` entries for untested cells. `n_untested_cells` is
  their count, not a replacement.
- US English in every message. The warning is a single
  [`warning()`](https://rdrr.io/r/base/warning.html) call per function,
  not one per cell.

## Verification (end-to-end)

### Tests (red first)

| Tier | Test |
|----|----|
| unit | `stratum_support()`: counts, absent cells at `n = 0`, the `sparse` and `degenerate` flags for both paths, `min_cell_size` validation |
| unit | Q1 table: each of the three mediator patterns gives the stated solved-cell sign and the stated rejection |
| integration | the same sparse data give `insufficient_stratum_support` in [`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md), NA in [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md), and a propagated reason in [`bound_ci()`](https://data-wise.github.io/medrobust/reference/bound_ci.md) |
| integration | Q4: `grid_method = "adaptive"` on an incompatible region returns the infeasible object with `n_evaluated` equal to the coarse grid size |
| e2e | continuous-C [`simulate_dm_data()`](https://data-wise.github.io/medrobust/reference/simulate_dm_data.md) and `heals_data` with 4 confounders, end to end |
| dogfood | `vignettes/articles/*-bounds.qmd` (gesthtn, nhanes_pa) are unchanged, and no new warning fires on them |

Test file changes:

- **`test-bound-ne-infeasible.R:60` expects
  `"insufficient_stratum_support"`.** Its data are sparse, as the file’s
  own header says (every (A, C1) cell holds about 4 rows), so the new
  reason is the correct one.
- **Add a genuine-incompatibility test that expects
  `"infeasible_no_compatible_sets"`.** Use the \#39 repro data:
  supported cells of 30 and 40 rows, deterministic, 0/100 on the
  mediator path. This removes the header’s “forcing an empty grid
  empirically is unreliable” problem, on the same path.
- **`test-s7-classes.R`:** `falsified_proportion = NA` is accepted, and
  1.5 is still rejected.

``` r

# tests/testthat/test-strata-support.R  (red-first stubs)
# TODO(author): delete if not contract-bearing

test_that("sparse strata give insufficient_stratum_support, not falsification", {
  fail("continuous C1 from simulate_dm_data(): no error; reason == 'insufficient_stratum_support'; is.na(falsified_proportion); n_evaluated == 0L; medrobust_infeasible signaled with $reason")
})

test_that("genuine incompatibility still reports infeasible_no_compatible_sets", {
  fail("#39 repro data, mediator path: reason == 'infeasible_no_compatible_sets'; falsified_proportion == 1")
})

test_that("check_compatibility is three-valued", {
  fail("heals_data 4 confounders -> NA, n_untested_cells > 0; #39 repro -> FALSE; simulate_dm_data truth -> TRUE")
})

test_that("absent cells count as sparse", {
  fail("drop every (M=1, Y=1) row of one stratum -> that cell appears with n = 0, sparse = TRUE")
})

test_that("degenerate cells warn but compute", {
  fail("#39 repro -> warning names cell A=0 and 'Sp_1 < 1'; exposure zero cell -> warning names 'Sp_y < 1'")
})

test_that("bound_ci propagates the infeasible reason", {
  fail("sparse bounds -> bound_ci()$NIE_reason == 'insufficient_stratum_support'")
})

test_that("simulate_dm_data warns for continuous confounders", {
  fail("expect_warning(simulate_dm_data(..., confounder_params = list(type = 'continuous')))")
})
```

### Commands

``` bash
Rscript -e 'devtools::test()'
Rscript -e 'devtools::check(args = c("--as-cran", "--no-manual"))'
quarto render vignettes/articles/gesthtn-bounds.qmd
quarto render vignettes/articles/nhanes-pa-bounds.qmd
```

Run the check on a `git archive` export: the local `.token-optimizer/`
directory adds a hidden-files NOTE that the base branch does not have.
The PR body quotes the test counts and a transcript of the sparse
`heals_data` call showing the new warning and reason.

## History

- **2026-09-23** — Brainstorm (deep, arch) with six decisions.
  Adversarial review by opencode `big-pickle`, after which Decision 1
  was revised to keep FixA. Both files were committed to `archive/` in
  d920345.
- **2026-09-23** — PR \#38 (#34) merged as a8faec9, unblocking this
  SPEC.
- **2026-09-23** — While resolving Q1, found that
  [`check_compatibility()`](https://data-wise.github.io/medrobust/reference/check_compatibility.md)’s
  mediator γ checks reduce to 1. Filed as \#39 with a reprex and a
  verified four-line fix. Also found that the brainstorm’s Q1 caution,
  and the review’s confirmation of it, were wrong: a single zero rejects
  automatically. Recorded above; the archived brainstorm is left as
  written.
- **2026-09-23** — Author answers: Q2 three-valued, Q4 fixed in \#35,
  the γ bug as a separate issue sequenced first. This SPEC written.
