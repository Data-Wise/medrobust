# PLAN — medrobust pkgdown Website Enhancements

**Date:** 2026-06-21 · **Branch:** `dev` · **Status:** proposed (no
edits applied) **Exemplar:** `mediationverse` meta-package site
(`Data-Wise.github.io/mediationverse`)

------------------------------------------------------------------------

## TL;DR

medrobust’s site is already strong (Bootstrap 5 + litera,
ecosystem-consistent theme, 9 well-grouped vignettes, OpenGraph, ORCID,
8-section reference index). The gap is **ecosystem integration + status
surfacing** — exactly the two custom navbar components the
`mediationverse` exemplar has and medrobust lacks. Plus one real
**lifecycle/badge drift** (README says *experimental/wip*; package is
0.4.0 CRAN-ready).

------------------------------------------------------------------------

## Current state (what’s already good — don’t touch)

- ✅ Bootstrap 5, `litera`, shared ecosystem palette (`#0054AD`,
  Inter/Montserrat/Fira Code)
- ✅ 9 vignettes, sensibly menu-grouped (Worked Examples / Methods /
  Computational)
- ✅ Reference index: 8 titled sections, 57 topics
- ✅ OpenGraph + Twitter card, logo, ORCID author block, custom footer
- ✅ README badges: lifecycle, repostatus, R-CMD-check, pkgdown, R-hub,
  Codecov, r-universe

## Gaps vs the `mediationverse` exemplar

| \# | Gap | Exemplar has it | Effort |
|----|----|----|----|
| 1 | No **`ecosystem`** navbar menu cross-linking sibling pkg sites | `ecosystem:` menu (medfit/probmed/RMediation/medrobust/medsim) | quick |
| 2 | No **`status`/planning** navbar (roadmap, contributing, planning hub) | `status:` menu w/ chart-line icon | quick |
| 3 | No **r-universe link** in home `sidebar.links` (only in README) | sidebar link to r-universe binaries | quick |
| 4 | **Lifecycle/badge drift** — README `experimental` + `wip` vs 0.4.0 CRAN-ready | n/a (real correctness fix) | quick |
| 5 | No **CRAN badge** (add post-acceptance) | — | deferred |

------------------------------------------------------------------------

## Quick Wins (\< 30 min, `_pkgdown.yml` + README only — all `.md`/yaml, dev-safe)

1.  **Add an `ecosystem` navbar menu** — reciprocate mediationverse’s
    cross-links so a reader on medrobust can reach the siblings. Insert
    into `navbar.structure.left`
    (`[home, reference, articles, ecosystem, news]`) + component:

    ``` yaml
    ecosystem:
      text: Ecosystem
      menu:
      - text: "Core Packages"
      - text: "medfit (Foundation)"           {href: https://Data-Wise.github.io/medfit/}
      - text: "probmed (P_med Effect Size)"    {href: https://Data-Wise.github.io/probmed/}
      - text: "RMediation (Confidence Intervals)" {href: https://Data-Wise.github.io/RMediation/}
      - text: "medsim (Simulation)"            {href: https://Data-Wise.github.io/medsim/}
      - text: "---------"
      - text: "mediationverse (Umbrella)"      {href: https://Data-Wise.github.io/mediationverse/}
    ```

2.  **Add r-universe to `home.links`** —
    `{text: "r-universe (binaries)", href: https://data-wise.r-universe.dev/medrobust}`.

3.  **Fix lifecycle drift** — bump README lifecycle badge
    `experimental → stable` (or `maturing`) and repostatus
    `wip → active`; package is feature-complete + CRAN-ready.

## Medium Effort (1–2 hrs)

4.  **`status` navbar menu** — link the package `.STATUS`, the
    `mediation-planning` PROJECT-HUB + ECOSYSTEM-COORDINATION, and
    (optional) a short roadmap article. Mirrors the exemplar’s planning
    surface so the site self-documents where the package sits in the
    release cascade.
5.  **Landing-page “where this fits” callout** — a short
    `index.Rmd`/README block placing medrobust in the pipeline (medfit →
    {probmed, RMediation, **medrobust**} → mediationverse), one sentence
    each. Improves first-visit orientation.

## Long-term (post-CRAN / future sessions)

6.  **CRAN status + downloads badges** — add once accepted
    (`https://www.r-pkg.org/badges/version/medrobust`, grand-total
    downloads).
7.  **`pkgdown` article freeze audit** — confirm `_freeze/` regenerates
    for all 9 articles on a full site render (see memory
    `quarto-hidden-worktree-path` — dot-prefixed worktree paths break
    Quarto freeze discovery; build from a non-dot path).

## Recommended Next Step

→ **Start with Quick Wins \#1–#3** (one `_pkgdown.yml` edit + one README
edit, ~20 min, all dev-safe `.md`/yaml). \#1 (ecosystem menu) is highest
value: it completes the bidirectional cross-linking the exemplar already
established one-way.

------------------------------------------------------------------------

## Out of scope / not blockers

- These are **post-submission** enhancements — none gate the imminent
  CRAN 0.4.0 submit.
- All proposed edits are docs/config (`.md` + `_pkgdown.yml`) →
  committable on `dev`.
