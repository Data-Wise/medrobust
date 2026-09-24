## Submission summary

This is a new submission of **medrobust** (version 0.4.1). The package has not
previously been on CRAN.

medrobust provides partial-identification sensitivity analysis for causal mediation
effects (Natural Direct and Indirect Effects) when the exposure or mediator is subject to
*differential* misclassification. It derives bounds that remain valid without validation
data or gold-standard measurements. The package has no dependencies outside CRAN.

## Test environments

> **Re-run on the `v0.4.1` tag before submitting:** the win-builder and r-hub results below were
> run on 633914e (0.4.1 before the #39 `check_compatibility()` fix, #43). GitHub Actions on the
> tagged commit 54812ec is green on macOS, Ubuntu and Windows.

* Local: macOS (aarch64), R 4.6.0 — `R CMD check --as-cran --run-donttest` on the 0.4.1 tarball (633914e, before #39): 0 errors | 0 warnings | 1 note (new submission)
* win-builder R-release (R 4.6.1, 0.4.1): https://win-builder.r-project.org/u1xLtKTASffB — **Status: 1 NOTE (new submission + the DESCRIPTION spellings above)**
* win-builder R-oldrelease (R 4.5.3): token d0MT9b7E7wFP — **Status: 1 NOTE (new submission)**
* GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release, green on the v0.4.1 tag (54812ec)
* r-hub (arthralgic-lark, run 35927616393, on dev at 633914e — 0.4.1 before the #39 fix; re-run on `v0.4.1`):
  - `ubuntu-clang`: OK
  - `ubuntu-gcc12`: OK
  - `nosuggests`: OK
  - `gcc-asan`: OK

## R CMD check results

`0 errors | 0 warnings | 1 note`

The remaining NOTE is the expected new-submission note (and a "possibly misspelled
words" entry flagging the author surnames *Manski* and *Imbens* and domain terms such as
*misclassification*, all of which are spelled correctly):

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
