#' Synthetic Arsenic Exposure Data
#'
#' @description
#' A synthetic dataset simulating a study of arsenic exposure, inflammatory
#' biomarkers as mediators, and cardiovascular disease outcomes. The exposure
#' (arsenic) is self-reported and subject to differential recall bias based
#' on disease status.
#'
#' @format A data frame with 2500 observations and 6 variables:
#' \describe{
#'   \item{A_star}{Self-reported arsenic exposure (0 = no, 1 = yes). This is
#'     the misclassified version of true exposure A, subject to differential
#'     recall bias.}
#'   \item{M}{Inflammatory biomarker level (0 = low, 1 = high). This is the
#'     mediator, measured without error.}
#'   \item{Y}{Cardiovascular disease outcome (0 = no, 1 = yes).}
#'   \item{age}{Age group (0 = younger, 1 = older).}
#'   \item{smoking}{Smoking status (0 = non-smoker, 1 = smoker).}
#'   \item{alcohol}{Alcohol consumption (0 = low, 1 = high).}
#' }
#'
#' @details
#' This dataset was generated using \code{\link{simulate_dm_data}} with
#' parameters calibrated to resemble environmental epidemiology studies.
#'
#' The true data generating process has:
#' \itemize{
#'   \item Moderate effect of arsenic on inflammation (log-OR = 0.6)
#'   \item Strong effect of inflammation on CVD (log-OR = 0.9)
#'   \item Weak direct effect of arsenic on CVD (log-OR = 0.3)
#' }
#'
#' The misclassification mechanism:
#' \itemize{
#'   \item Sensitivity when Y=0: 85\%
#'   \item Specificity when Y=0: 85\%
#'   \item Sensitivity OR: 1.8 (higher recall among diseased)
#'   \item Specificity OR: 1.0 (no differential false positives)
#' }
#'
#' True natural effects (on odds ratio scale):
#' \itemize{
#'   \item True NIE: 1.35
#'   \item True NDE: 1.18
#' }
#'
#' @source Simulated data. See \code{data-raw/generate_arsenic_data.R} for
#'   the data generation script.
#'
#' @examples
#' data("arsenic_synthetic")
#' head(arsenic_synthetic)
#' table(arsenic_synthetic$A_star, arsenic_synthetic$Y)
#'
#' # Analyze with medrobust
#' \dontrun{
#' bounds <- bound_ne(
#'   data = arsenic_synthetic,
#'   exposure = "A_star",
#'   mediator = "M",
#'   outcome = "Y",
#'   confounders = c("age", "smoking", "alcohol"),
#'   misclassified_variable = "exposure",
#'   sensitivity_region = list(
#'     sn0_range = c(0.80, 0.90),
#'     sp0_range = c(0.80, 0.90),
#'     psi_sn_range = c(1.0, 2.0),
#'     psi_sp_range = c(1.0, 1.0)
#'   )
#' )
#' print(bounds)
#' }
"arsenic_synthetic"


#' Pre-computed Simulation Results
#'
#' @description
#' Results from Monte Carlo simulations evaluating the performance of
#' \code{medrobust} under various data generating scenarios. These results
#' are provided for demonstration purposes and to enable users to explore
#' the package's performance without running lengthy simulations.
#'
#' @format A data frame with simulation results:
#' \describe{
#'   \item{scenario}{Scenario ID (1-10), varying effect sizes and misclassification}
#'   \item{n}{Sample size (500, 1000, 2000)}
#'   \item{true_nie}{True Natural Indirect Effect}
#'   \item{true_nde}{True Natural Direct Effect}
#'   \item{psi_sn}{True sensitivity odds ratio}
#'   \item{psi_sp}{True specificity odds ratio}
#'   \item{nie_lower_mean}{Average lower bound for NIE across replications}
#'   \item{nie_upper_mean}{Average upper bound for NIE across replications}
#'   \item{nde_lower_mean}{Average lower bound for NDE across replications}
#'   \item{nde_upper_mean}{Average upper bound for NDE across replications}
#'   \item{coverage}{Proportion of replications where true effect was in bounds}
#'   \item{avg_width}{Average width of identification region}
#'   \item{avg_falsified}{Average proportion of parameters falsified}
#' }
#'
#' @details
#' Each scenario was simulated with 1000 Monte Carlo replications. The
#' bounds were computed using a 50x50 grid over the true sensitivity region
#' plus/minus 10\%.
#'
#' Key findings:
#' \itemize{
#'   \item Coverage is consistently 100\%, confirming validity
#'   \item Bound width decreases with sample size
#'   \item Stronger differential misclassification leads to wider bounds
#'   \item Data-driven falsification rejects 20-40\% of parameter space on average
#' }
#'
#' @source Generated using \code{data-raw/run_simulations.R}.
#'
#' @examples
#' data("simulation_results")
#' head(simulation_results)
#'
#' # Plot coverage by sample size
#' \dontrun{
#' library(ggplot2)
#' ggplot(simulation_results, aes(x = n, y = coverage, group = scenario)) +
#'   geom_line(alpha = 0.5) +
#'   geom_hline(yintercept = 0.95, linetype = "dashed") +
#'   labs(title = "Coverage Probability by Sample Size",
#'        x = "Sample Size", y = "Coverage")
#' }
"simulation_results"
