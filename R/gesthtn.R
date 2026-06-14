#' Gestational Hypertension as a Differentially Misclassified Binary Mediator
#'
#' @description
#' A random sample of U.S. live births used to illustrate partial-identification
#' bounds when a binary mediator is differentially misclassified, without
#' validation data. The mediator---gestational hypertension as recorded on the
#' birth certificate---is a textbook differentially misclassified variable: its
#' birth-certificate sensitivity is poor and reporting accuracy plausibly depends
#' on the outcome (preterm birth). This is the substantive triad analyzed by the
#' closest prior point-identification method (Hochstedler Webb and Wells, 2025).
#'
#' @format A data frame with 5,000 observations and 4 binary variables:
#' \describe{
#'   \item{A}{Binary. Advanced maternal age (1 = age >= 35 years, 0 = age < 35).}
#'   \item{M_star}{Binary. Recorded (surrogate) gestational hypertension from the
#'     birth certificate (1 = Yes, 0 = No). A misclassified measurement of the
#'     true mediator; the true status is not observed.}
#'   \item{Y}{Binary. Preterm birth (1 = gestational age < 37 weeks, 0 = term).}
#'   \item{C1}{Binary. Parity (1 = one or more prior live births, 0 = none).}
#' }
#'
#' @details
#' ## Source data
#' A fixed-seed (20260614) random sample of 5,000 from 3,662,426 complete cases in
#' the 2021 U.S. National Center for Health Statistics (NCHS) Natality
#' (birth-certificate) file, public-domain U.S.-government data obtained via the
#' NBER mirror. Variables were derived as above from \code{mager}, \code{rf_ghype},
#' \code{combgest}, and \code{priorlive}; see
#' \code{system.file("scripts", "prepare_gesthtn.R", package = "medrobust")}.
#'
#' ## Misclassification
#' Validation of the 2003 revised birth certificate against the medical record
#' (Dietz et al., 2015) found the gestational-hypertension item to have *poor*
#' sensitivity (< 70\%) and *excellent* specificity (> 90\%); differential
#' (outcome-dependent) sensitivity is plausible. These motivate a sensitivity
#' region with baseline sensitivity in roughly [0.50, 0.70], specificity in
#' [0.90, 0.99], and a differential-sensitivity odds ratio at or above 1.
#'
#' @source
#' NCHS Natality 2021 (U.S. birth certificates), via the NBER mirror
#' \url{https://data.nber.org/nvss/natality/csv/2021/natality2021us.csv}.
#' Misclassification context: Dietz et al. (2015),
#' \emph{Public Health Reports} 130(1):60-70, \doi{10.1177/003335491513000108}.
#' Prior art on this application: Hochstedler Webb and Wells (2025),
#' \emph{Statistical Methods in Medical Research} 34(5):1037-1059,
#' \doi{10.1177/09622802251316970}.
#'
#' @examples
#' data("gesthtn")
#' table(gesthtn$M_star, gesthtn$Y)
#'
#' # Partial-identification bounds for the (differentially misclassified) mediator;
#' # see ?bound_ne and vignette("gesthtn-bounds", package = "medrobust").
#' region <- sensitivity_region(
#'   sn0_range = c(0.50, 0.70), sp0_range = c(0.90, 0.99),
#'   psi_sn_range = c(1.0, 3.0), psi_sp_range = c(1.0, 1.0)
#' )
#'
#' @keywords datasets
"gesthtn"
