# Fast confidence intervals for partial-identification bound endpoints.
# See SPEC-analytic-ci-2026-06-11.md. This file provides the building blocks:
#   .effect_at_psi_*  : the effect (NDE/NIE) at a SINGLE fixed Psi, no grid search
#   .imbens_manski_ci : the set CI [L - c*seL, U + c*seU] (Imbens & Manski 2004)
# The endpoint SEs are obtained by perturbing/resampling the observed cells and
# re-evaluating the effect at the argmin/argmax Psi (envelope theorem).

# --- single-Psi effect, EXPOSURE path -----------------------------------------
# Mirrors evaluate_param_set() in bound_ne_exposure.R but for one Psi, callable
# directly on a data frame. Returns list(nie, nde) or NULL if incompatible.
.effect_at_psi_exposure <- function(data, A_star_name, M_name, Y_name, C_names,
                                    sn0, sp0, psi_sn, psi_sp, effect_scale = "OR") {
  sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
  sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))
  if ((sn0 + sp0 - 1) <= 1e-8 || (sn1 + sp1 - 1) <= 1e-8) return(NULL)

  pre <- precompute_observed_probs(data, A_star_name, M_name, Y_name, C_names,
                                   misclass_type = "exposure")
  obs_probs <- pre$obs_probs; strata <- pre$strata; stratum_sizes <- pre$stratum_sizes

  comb <- expand.grid(m = c(0, 1), y = c(0, 1), s = strata$stratum_id,
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  comb$sn_y <- ifelse(comb$y == 1, sn1, sn0)
  comb$sp_y <- ifelse(comb$y == 1, sp1, sp0)
  comb$denom <- comb$sn_y + comb$sp_y - 1

  k1 <- paste0("m", comb$m, "_y", comb$y, "_s", comb$s, "_a1")
  k0 <- paste0("m", comb$m, "_y", comb$y, "_s", comb$s, "_a0")
  Ps1 <- vapply(k1, function(k) { v <- obs_probs[[k]]; if (is.null(v) || is.na(v)) 0 else v },
                numeric(1), USE.NAMES = FALSE)
  Ps0 <- vapply(k0, function(k) { v <- obs_probs[[k]]; if (is.null(v) || is.na(v)) 0 else v },
                numeric(1), USE.NAMES = FALSE)

  P1 <- (comb$sp_y * Ps1 - (1 - comb$sp_y) * Ps0) / comb$denom
  P0 <- (comb$sn_y * Ps0 - (1 - comb$sn_y) * Ps1) / comb$denom
  if (any(P1 < -1e-6) || any(P0 < -1e-6)) return(NULL)

  # conditional -> joint via observed P(M=m, Y=y | C=s)  (see bound_ne_exposure.R)
  Pmy <- vapply(seq_len(nrow(comb)), function(i) {
    sz <- stratum_sizes[stratum_sizes[[M_name]] == comb$m[i] &
                          stratum_sizes[[Y_name]] == comb$y[i] &
                          stratum_sizes$stratum_id == comb$s[i], ]
    n_s <- sum(stratum_sizes$n[stratum_sizes$stratum_id == comb$s[i]])
    if (nrow(sz) == 0 || n_s == 0) 0 else sz$n[1] / n_s
  }, numeric(1))
  P1 <- P1 * Pmy; P0 <- P0 * Pmy

  P_true_list <- lapply(seq_len(nrow(comb)), function(i) {
    c(P_1 = max(0, P1[i]), P_0 = max(0, P0[i]),
      stratum_id = comb$s[i], M = comb$m[i], Y = comb$y[i])
  })
  names(P_true_list) <- paste0("m", comb$m, "_y", comb$y, "_s", comb$s)

  eff <- compute_effects_from_joint_probs(P_true_list, pre$data, C_names, effect_scale)
  list(nie = eff$nie, nde = eff$nde)
}

# --- Imbens & Manski (2004) CI for an interval-identified parameter -----------
# Given estimated bounds [L, U] with SEs seL, seU, returns the level-CI
# [L - c*seL, U + c*seU], where c solves
#   Phi(c + Delta / max(seL,seU)) - Phi(-c) = level,   Delta = max(0, U - L).
# c -> z_{level} (one-sided) when Delta >> se; c -> z_{(1+level)/2} when Delta = 0.
.imbens_manski_ci <- function(L, U, seL, seU, level = 0.95) {
  # NA-safe: a non-finite endpoint SE means the resamples were infeasible.
  # Returning NA endpoints here avoids max(NA, ...) -> NaN and uniroot on a
  # NaN-valued function. The caller documents the reason separately.
  if (!is.finite(seL) || !is.finite(seU)) {
    return(c(lower = NA_real_, upper = NA_real_))
  }
  smax <- max(seL, seU, .Machine$double.eps)
  Delta <- max(0, U - L)
  f <- function(c) stats::pnorm(c + Delta / smax) - stats::pnorm(-c) - level
  lo <- stats::qnorm(level)            # one-sided critical value (Delta large)
  hi <- stats::qnorm((1 + level) / 2)  # two-sided critical value (Delta = 0)
  cc <- tryCatch(stats::uniroot(f, c(lo - 1e-6, hi + 1e-6))$root,
                 error = function(e) hi)
  c(lower = L - cc * seL, upper = U + cc * seU)
}

# --- endpoint SE via re-evaluation at the FIXED optimal Psi (envelope) --------
# Resample the data and recompute the effect at the argmin/argmax Psi only (one
# primitive call per resample, no grid search). ~n_grid^k faster than the full
# bootstrap, which re-runs the entire grid per replicate.
.endpoint_se_exposure <- function(data, A_star_name, M_name, Y_name, C_names,
                                  psi, which, effect_scale = "OR", n_boot = 200L,
                                  seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  n <- nrow(data)
  vals <- vapply(seq_len(n_boot), function(b) {
    d <- data[sample.int(n, n, replace = TRUE), , drop = FALSE]
    e <- tryCatch(.effect_at_psi_exposure(d, A_star_name, M_name, Y_name, C_names,
                  psi$sn0, psi$sp0, psi$psi_sn, psi$psi_sp, effect_scale),
                  error = function(err) NULL)
    if (is.null(e)) NA_real_ else e[[which]]
  }, numeric(1))
  stats::sd(vals, na.rm = TRUE)
}

# --- fast CI for an EXPOSURE bound object -------------------------------------
# Given a fitted medrobust_bounds (exposure) + its data, returns Imbens-Manski
# CIs for NDE and NIE on the bound's effect scale.
bound_ci_exposure <- function(bounds, data, exposure, mediator, outcome,
                              confounders, n_boot = 200L, level = 0.95,
                              seed = NULL) {
  cs <- bounds@compatible_sets
  effect_scale <- bounds@effect_scale
  pick <- function(col, fun) cs[which(cs[[col]] == fun(cs[[col]]))[1], ]
  out <- list()
  for (eff in c("NIE", "NDE")) {
    lo_psi <- pick(eff, min); hi_psi <- pick(eff, max)
    w <- tolower(eff)
    seL <- .endpoint_se_exposure(data, exposure, mediator, outcome, confounders,
                                 lo_psi, w, effect_scale, n_boot, seed)
    seU <- .endpoint_se_exposure(data, exposure, mediator, outcome, confounders,
                                 hi_psi, w, effect_scale, n_boot, seed)
    L <- min(cs[[eff]]); U <- max(cs[[eff]])
    ci <- .imbens_manski_ci(L, U, seL, seU, level)
    out[[eff]] <- c(lower = L, upper = U, se_lower = seL, se_upper = seU,
                    ci_lower = unname(ci["lower"]), ci_upper = unname(ci["upper"]))
  }
  out
}

# --- single-Psi effect, MEDIATOR path ----------------------------------------
# Mirrors the per-(a, stratum) two-2x2 solve in bound_ne_mediator.R for one Psi.
.effect_at_psi_mediator <- function(data, A_name, M_star_name, Y_name, C_names,
                                    sn0, sp0, psi_sn, psi_sp, effect_scale = "OR") {
  sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
  sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))
  if (any(c(sn1, sp1) < 0 | c(sn1, sp1) > 1)) return(NULL)
  if ((sn0 + sp0 - 1) <= 1e-8 || (sn1 + sp1 - 1) <= 1e-8) return(NULL)

  if (is.null(C_names) || length(C_names) == 0) {
    data$stratum_id <- 1L; strata <- data.frame(stratum_id = 1L)
  } else {
    data <- data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(C_names))) |>
      dplyr::mutate(stratum_id = dplyr::cur_group_id()) |> dplyr::ungroup()
    strata <- data |>
      dplyr::select(stratum_id, dplyr::all_of(C_names)) |> dplyr::distinct()
  }
  A1 <- matrix(c(sn1, 1 - sp1, 1 - sn1, sp1), 2, 2, byrow = TRUE)
  A0 <- matrix(c(sn0, 1 - sp0, 1 - sn0, sp0), 2, 2, byrow = TRUE)
  solved <- list()
  for (a in c(0, 1)) for (s in strata$stratum_id) {
    das <- data[data[[A_name]] == a & data$stratum_id == s, , drop = FALSE]
    if (nrow(das) < 5) return(NULL)
    tab <- table(factor(das[[Y_name]], 0:1), factor(das[[M_star_name]], 0:1))
    P <- as.numeric(tab) / sum(tab)         # column-major: Y0M0, Y1M0, Y0M1, Y1M1
    P_00 <- P[1]; P_10 <- P[2]; P_01 <- P[3]; P_11 <- P[4]
    xy1 <- tryCatch(solve(A1, c(P_11, P_10)), error = function(e) NULL)
    xy0 <- tryCatch(solve(A0, c(P_01, P_00)), error = function(e) NULL)
    if (is.null(xy1) || is.null(xy0)) return(NULL)
    x1 <- xy1[1]; x0 <- xy1[2]; z1 <- xy0[1]; pi_a <- x1 + z1
    if (pi_a < 0 || pi_a > 1) return(NULL)
    g1 <- if (pi_a < 1e-6) 0.5 else x1 / pi_a
    g0 <- if (pi_a > 1 - 1e-6) 0.5 else x0 / (1 - pi_a)
    if (any(c(g0, g1) < 0 | c(g0, g1) > 1)) return(NULL)
    solved[[paste0("a", a, "_s", s)]] <-
      list(pi_a = pi_a, gamma_a0 = g0, gamma_a1 = g1, stratum_id = s)
  }
  eff <- compute_effects_from_params(solved, data, C_names, effect_scale)
  list(nie = eff$nie, nde = eff$nde)
}

# --- generic endpoint SE + unified bound_ci ----------------------------------
# eval_fn(d) -> list(nie, nde) at the fixed Psi; resample d, take sd of `which`.
.endpoint_se <- function(eval_fn, data, which, n_boot = 200L, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  n <- nrow(data)
  vals <- vapply(seq_len(n_boot), function(b) {
    e <- tryCatch(eval_fn(data[sample.int(n, n, replace = TRUE), , drop = FALSE]),
                  error = function(err) NULL)
    if (is.null(e)) NA_real_ else e[[which]]
  }, numeric(1))
  # An endpoint SE needs at least two finite resamples; otherwise sd() is NA or
  # degenerate. Return NA_real_ and expose the count of failed (non-finite)
  # resamples so the caller can build a reason string.
  finite_vals <- vals[is.finite(vals)]
  n_failed <- n_boot - length(finite_vals)
  se <- if (length(finite_vals) < 2L) NA_real_ else stats::sd(finite_vals)
  attr(se, "n_failed") <- n_failed
  se
}

#' Confidence intervals for partial-identification bounds (Imbens-Manski)
#'
#' Computes a confidence interval for the partial-identification set returned by
#' [bound_ne()]. The raw estimated bound \eqn{[\hat L, \hat U]} is consistent but
#' is *not* a confidence set: when the identified set is narrow relative to the
#' sampling uncertainty of its endpoints, it under-covers the true effect at small
#' samples. `bound_ci()` widens the endpoints by their standard errors using the
#' Imbens & Manski (2004) construction, restoring approximately nominal coverage of
#' the true effect.
#'
#' Endpoint standard errors are obtained by re-evaluating the effect at the fixed
#' minimizing/maximizing sensitivity parameter on resampled data (one evaluation per
#' resample, with no grid search), which is far cheaper than a full bootstrap of the
#' whole grid.
#'
#' @param bounds A fitted `medrobust_bounds` object from [bound_ne()].
#' @param data The data frame passed to [bound_ne()].
#' @param exposure,mediator,outcome,confounders Column names, as in [bound_ne()].
#' @param misclassified_variable Either `"exposure"` or `"mediator"`; selects the
#'   recovery used to evaluate the effect at a single sensitivity parameter.
#' @param n_boot Number of resamples for the endpoint standard errors (default 200).
#' @param level Confidence level (default 0.95).
#' @param seed Optional integer seed for reproducibility.
#'
#' @return A named list with elements `NIE` and `NDE`, each a numeric vector with
#'   `lower`, `upper` (the point bounds), `se_lower`, `se_upper` (endpoint SEs), and
#'   `ci_lower`, `ci_upper` (the Imbens-Manski confidence interval).
#'
#' @references Imbens, G. W. and Manski, C. F. (2004). Confidence Intervals for
#'   Partially Identified Parameters. *Econometrica*, 72(6), 1845-1857.
#' @seealso [bound_ne()]
#' @export
bound_ci <- function(bounds, data, exposure, mediator, outcome, confounders,
                     misclassified_variable = c("exposure", "mediator"),
                     n_boot = 200L, level = 0.95, seed = NULL) {
  misclassified_variable <- match.arg(misclassified_variable)
  scale <- bounds@effect_scale

  # Short-circuit: an infeasible bounds object (no compatible parameter sets, so
  # NA bounds) has nothing to resample. Return NA endpoints with a reason and
  # skip all bootstrap work. Access the property defensively in case an older
  # object predates the n_compatible property.
  n_compatible <- tryCatch(bounds@n_compatible, error = function(e) NA_integer_)
  if (!is.na(n_compatible) && n_compatible == 0) {
    na_eff <- c(lower = NA_real_, upper = NA_real_,
                se_lower = NA_real_, se_upper = NA_real_,
                ci_lower = NA_real_, ci_upper = NA_real_)
    out <- list(
      NIE = na_eff, NDE = na_eff,
      NIE_reason = "infeasible_no_compatible_sets",
      NDE_reason = "infeasible_no_compatible_sets"
    )
    return(out)
  }

  primitive <- if (misclassified_variable == "exposure")
    function(d, psi) .effect_at_psi_exposure(d, exposure, mediator, outcome, confounders,
                                             psi$sn0, psi$sp0, psi$psi_sn, psi$psi_sp, scale)
  else
    function(d, psi) .effect_at_psi_mediator(d, exposure, mediator, outcome, confounders,
                                             psi$sn0, psi$sp0, psi$psi_sn, psi$psi_sp, scale)
  cs <- bounds@compatible_sets
  pick <- function(col, fun) cs[which(cs[[col]] == fun(cs[[col]]))[1], ]
  out <- list()
  for (eff in c("NIE", "NDE")) {
    w <- tolower(eff)
    lo_psi <- pick(eff, min); hi_psi <- pick(eff, max)
    seL <- .endpoint_se(function(d) primitive(d, lo_psi), data, w, n_boot, seed)
    seU <- .endpoint_se(function(d) primitive(d, hi_psi), data, w, n_boot, seed)
    L <- min(cs[[eff]]); U <- max(cs[[eff]])
    if (!is.finite(seL) || !is.finite(seU)) {
      # At least one endpoint SE is non-finite (resamples infeasible). Emit a
      # documented NA confidence interval with a reason rather than letting NA
      # propagate silently through the Imbens-Manski construction.
      fL <- attr(seL, "n_failed"); fU <- attr(seU, "n_failed")
      n_failed <- sum(if (is.null(fL)) 0L else fL, if (is.null(fU)) 0L else fU)
      out[[eff]] <- c(lower = L, upper = U,
                      se_lower = as.numeric(seL), se_upper = as.numeric(seU),
                      ci_lower = NA_real_, ci_upper = NA_real_)
      out[[paste0(eff, "_reason")]] <-
        sprintf("endpoint_se_na: resamples infeasible (%d failed)", n_failed)
      next
    }
    ci <- .imbens_manski_ci(L, U, seL, seU, level)
    out[[eff]] <- c(lower = L, upper = U,
                    se_lower = as.numeric(seL), se_upper = as.numeric(seU),
                    ci_lower = unname(ci["lower"]), ci_upper = unname(ci["upper"]))
  }
  out
}
