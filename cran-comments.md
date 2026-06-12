## Submission summary

This is a new submission of **medrobust** (version 0.2.1). The package has not
previously been on CRAN.

medrobust provides partial-identification sensitivity analysis for causal mediation
effects (Natural Direct and Indirect Effects) when the exposure or mediator is subject to
*differential* misclassification. It derives bounds that remain valid without validation
data or gold-standard measurements. The package has no dependencies outside CRAN.

## Test environments

* Local: macOS 15 (aarch64-apple-darwin25.4.0), R 4.6.0 — `R CMD check --as-cran`
* win-builder: R-devel and R-release (`devtools::check_win_devel()`, `check_win_release()`)
* GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release

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

* **Vignettes use Quarto** (`VignetteBuilder: quarto`). They re-execute and render
  cleanly under `R CMD check --as-cran`
  (`checking re-building of vignette outputs ... OK`). Quarto is listed in `Suggests`.
* The `Description` explains all acronyms and gives method references in the requested
  `authors (year) <doi:...>` / `<ISBN:...>` form.
* All exported objects document their return value via `\value`. Examples use
  `\donttest{}` and execute against small simulated data. The single example for
  `power_analysis()` remains in `\dontrun{}`: it runs many bootstrap-bound replications
  across several sample sizes and is genuinely too slow to execute during checks.

## Downstream dependencies

This is a new submission, so there are no reverse dependencies to check.
