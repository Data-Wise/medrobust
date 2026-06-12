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
