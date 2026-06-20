## Submission summary

This is a new submission of **medrobust** (version 0.4.0). The package has not
previously been on CRAN.

medrobust provides partial-identification sensitivity analysis for causal mediation
effects (Natural Direct and Indirect Effects) when the exposure or mediator is subject to
*differential* misclassification. It derives bounds that remain valid without validation
data or gold-standard measurements. The package has no dependencies outside CRAN.

## Test environments

* Local: macOS 15 (aarch64-apple-darwin25.4.0), R 4.6.0 — `R CMD check --as-cran`
* win-builder R-release (R 4.6.0): token 0pY8ajL2oIoD — **Status: 1 NOTE (new submission)**
* win-builder R-oldrelease (R 4.5.3): token d0MT9b7E7wFP — **Status: 1 NOTE (new submission)**
* GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release + oldrel-1
* r-hub (kaleidoscopic-bubblefish, run 27853569154, on dev/v0.4.0):
  - `ubuntu-clang`: OK
  - `ubuntu-gcc12`: OK
  - `nosuggests`: FAILED — infrastructure issue (see Notes below)
  - `gcc-asan`: FAILED — infrastructure issue (see Notes below)

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

* **r-hub `nosuggests` and `gcc-asan` failures**: Both containers failed at the
  dependency-installation step with `Error in loadNamespace(x) : there is no package called 'pak'`
  immediately after pak was successfully installed. This is a known regression in pak devel
  version 0.10.0.9000 (r-lib/pak issue #887, filed 2026-06-13): the binary installs but the
  namespace cannot be loaded due to a broken bootstrap routine in that pre-release build. The
  `r-hub/actions/setup-deps@v1` action defaults to installing the devel pak stream. This is an
  r-hub infrastructure issue, not caused by any medrobust code. The two passing Linux containers
  (`ubuntu-clang`, `ubuntu-gcc12`) confirm 0 errors, 0 warnings, 0 notes from this package's
  own code.

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
