# falsification_summary() used to spread n_evaluated evenly over the bins and
# count only the compatible sets in each, clipping the result to [0, 1]. Bins or
# cells the search never visited came out as 100% falsified, and sets on a
# range's upper edge were dropped from the joint grid. Rates are now the share
# of the sets evaluated in each bin that the data falsified.

fs_region <- list(sn0_range = c(0.6, 0.99), sp0_range = c(0.6, 0.99),
                  psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5))
fs_fit <- function() {
  d <- simulate_dm_data(
    n = 400,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = "mediator", confounders = 1, seed = 1
  )@observed
  suppressWarnings(bound_ne(d, "A", "M_star", "Y", "C1",
                            misclassified_variable = "mediator",
                            sensitivity_region = fs_region, n_grid = 10,
                            grid_method = "lhs", verbose = FALSE))
}

direct_rate <- function(x, falsified, lo, hi, n_bins) {
  k <- findInterval(x, seq(lo, hi, length.out = n_bins + 1), rightmost.closed = TRUE)
  as.vector(tapply(falsified, factor(k, levels = seq_len(n_bins)), mean))
}

test_that("per-parameter rates are the falsified share of the sets in each bin", {
  fit <- fs_fit()
  es <- fit@evaluated_sets
  fs <- falsification_summary(fit, n_bins = 5, plot = FALSE)
  for (p in c("sn0", "sp0", "psi_sn", "psi_sp")) {
    r <- fs_region[[paste0(p, "_range")]]
    b <- fs@by_parameter[[p]]
    expect_equal(b$falsification_rate, direct_rate(es[[p]], !es$compatible, r[1], r[2], 5))
    expect_equal(sum(b$n_evaluated), nrow(es))
    expect_equal(sum(b$n_compatible), fit@n_compatible)
  }
})

test_that("joint cells with no evaluated set are NA, not 100% falsified", {
  fs <- falsification_summary(fs_fit(), n_bins = 10, plot = FALSE)
  j <- fs@joint_falsification$sn0_sp0
  expect_true(any(j$n_evaluated == 0))
  expect_true(all(is.na(j$falsification_rate[j$n_evaluated == 0])))
  expect_false(anyNA(j$falsification_rate[j$n_evaluated > 0]))
  expect_equal(sum(j$n_evaluated), 100L)
  # print() and summary statistics cope with NA bins
  expect_output(print(fs))
})

test_that("values on a range's upper edge fall in the last bin", {
  breaks <- seq(0.6, 0.99, length.out = 11)
  expect_equal(.bin_index(c(0.6, 0.795, 0.99), breaks), c(1L, 6L, 10L))
})

test_that("falsification_summary() asks for a refit without evaluated_sets", {
  fit <- fs_fit()
  fit@evaluated_sets <- NULL
  expect_error(falsification_summary(fit, plot = FALSE), "refit")
})

test_that("adaptive refinement stays inside the sensitivity region", {
  # Compatible in the upper part of sn0/sp0: the coarse points 0.86 and 0.99
  # pass, and the 10% expansion of [0.86, 0.99] reaches past 0.99 without the
  # clamp.
  seen <- list()
  eval_fn <- function(i, row) {
    seen[[length(seen) + 1L]] <<- unlist(row[c("sn0", "sp0")])
    if (row$sn0 > 0.8 && row$sp0 > 0.8) list(params = row, nie = 1, nde = 1) else NULL
  }
  adaptive_grid_search(fs_region, eval_fn, n_grid_fine = 20, coarse_factor = 5,
                       verbose = FALSE)
  pts <- do.call(rbind, seen)
  expect_lte(max(pts[, "sn0"]), 0.99 + 1e-12)
  expect_lte(max(pts[, "sp0"]), 0.99 + 1e-12)
  expect_gte(min(pts[, "sn0"]), 0.6 - 1e-12)
})
