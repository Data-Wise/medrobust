## Submission summary

This is a new submission of **medrobust** (version 0.4.4). The package has not
previously been on CRAN.

medrobust provides partial-identification sensitivity analysis for causal mediation
effects (Natural Direct and Indirect Effects) when the exposure or mediator is subject to
*differential* misclassification. It derives bounds that remain valid without validation
data or gold-standard measurements. The package has no dependencies outside CRAN.

## Test environments

* Local: macOS (aarch64), R 4.6.1 — `R CMD check --as-cran --run-donttest` on the tarball built from the `v0.4.4` tag (6ef7b0e): 0 errors | 0 warnings | 1 note (new submission)
* win-builder R-devel (2026-09-25 r90590): https://win-builder.r-project.org/bEZirU2YC95t — **Status: 1 NOTE (new submission + DESCRIPTION spellings)**
* win-builder R-release (R 4.6.1): https://win-builder.r-project.org/5Q33R9cQTLgZ — **Status: 1 NOTE (new submission + DESCRIPTION spellings)**
* win-builder R-oldrelease (R 4.5.3): https://win-builder.r-project.org/8nkd7joyNAN1 — **Status: 1 NOTE (new submission + DESCRIPTION spellings)**
* GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release, green on the v0.4.4 tag (6ef7b0e)
* r-hub (run 36217031113, on the `v0.4.4` tag):
  - `linux` (R-devel): OK
  - `windows` (R-devel): OK
  - `macos` (R-devel): OK
  - `ubuntu-clang`: OK
  - `ubuntu-gcc12`: OK
  - `nosuggests`: OK
  - `gcc-asan`: OK
  - `macos-arm64` (R-devel): not run — r-hub dependency setup failed again on the `v0.4.4` run (no R 4.7
    arm64 binary repository yet); the package check never started. macOS is covered by `macos`
    (R-devel) above and GitHub Actions macOS-latest (release).

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
