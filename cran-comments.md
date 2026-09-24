## Submission summary

This is a new submission of **medrobust** (version 0.4.2). The package has not
previously been on CRAN.

medrobust provides partial-identification sensitivity analysis for causal mediation
effects (Natural Direct and Indirect Effects) when the exposure or mediator is subject to
*differential* misclassification. It derives bounds that remain valid without validation
data or gold-standard measurements. The package has no dependencies outside CRAN.

## Test environments

> **Re-run on the `v0.4.2` tag before submitting.** The results below are for `v0.4.1`; 0.4.2
> changes only help-page text (links to website articles instead of `vignette()`, #44).

* Local: macOS (aarch64), R 4.6.1 — `R CMD check --as-cran --run-donttest` on the tarball built from the `v0.4.1` tag (54812ec): 0 errors | 0 warnings | 1 note (new submission)
* win-builder R-devel (2026-09-21 r90579): https://win-builder.r-project.org/3l38uWfnQlRB — **Status: 1 NOTE (new submission + DESCRIPTION spellings)**
* win-builder R-release (R 4.6.1): https://win-builder.r-project.org/2CEkI89WdS64 — **Status: 1 NOTE (new submission + DESCRIPTION spellings)**
* win-builder R-oldrelease (R 4.5.3): https://win-builder.r-project.org/zmmbDslTB1uN — **Status: 1 NOTE (new submission + DESCRIPTION spellings)**
* GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release, green on the v0.4.1 tag (54812ec)
* r-hub (beachy-asiaticmouflon, run 35951885492, on dev at 5cff2de; built package identical to the `v0.4.1` tag, since the only differences are .Rbuildignore'd):
  - `ubuntu-clang`: OK
  - `ubuntu-gcc12`: OK
  - `nosuggests`: OK
  - `gcc-asan`: OK

## R CMD check results

`0 errors | 0 warnings | 1 note`

The remaining NOTE is the expected new-submission note. On win-builder it also lists
"possibly misspelled words" in DESCRIPTION: *BCa*, *Imbens*, *Manski*, *NDE*, *NIE* and
*Tofighi*. All are spelled correctly: *Imbens*, *Manski* and *Tofighi* are author surnames,
*BCa* is the bias-corrected and accelerated bootstrap, and *NDE*/*NIE* are the natural
direct/indirect effects, spelled out in the Description.

```
* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Davood Tofighi <dtofighi@gmail.com>'
  New submission
```

## Notes for the CRAN team

* **No vignettes in the built package.** All documentation articles (`.qmd` Quarto
  files) are placed in `vignettes/articles/`, which is listed in `.Rbuildignore`. They
  are served only on the pkgdown site (`https://data-wise.github.io/medrobust/`). There
  is no `VignetteBuilder` entry in `DESCRIPTION`, so `R CMD check` does not attempt to
  build any vignettes and the `checking re-building of vignette outputs` step is skipped.
* The `Description` explains all acronyms and gives method references in the requested
  `authors (year) <doi:...>` / `<ISBN:...>` form.
* All exported objects document their return value via `\value`. Examples use
  `\donttest{}` and execute against small simulated data. The single example for
  `power_analysis()` remains in `\dontrun{}`: it runs many bootstrap-bound replications
  across several sample sizes and is genuinely too slow to execute during checks.

## Downstream dependencies

This is a new submission, so there are no reverse dependencies to check.
