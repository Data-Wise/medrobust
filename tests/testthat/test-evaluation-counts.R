# n_evaluated used to be a per-method estimate: the mediator path reported
# n_coarse + n_compatible * 625 for "adaptive" (5.3 million for 10,081
# evaluations) and n_compatible for "binary"/"auto" (a falsified proportion of
# 0). The 16 probe corners of "auto" and "binary" were evaluated but dropped,
# so compatible corners were missing from the bounds. Counts, compatible sets
# and bounds now all come from the recorded evaluations.

ec_region <- list(sn0_range = c(0.6, 0.99), sp0_range = c(0.6, 0.99),
                  psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5))
ec_data <- function(type) {
  simulate_dm_data(
    n = 400,
    true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
    dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
    misclass_type = type, confounders = 1, seed = 1
  )@observed
}
ec_fit <- function(type, method) {
  vars <- if (type == "mediator") c("A", "M_star") else c("A_star", "M")
  suppressWarnings(bound_ne(ec_data(type), vars[1], vars[2], "Y", "C1",
                            misclassified_variable = type,
                            sensitivity_region = ec_region, n_grid = 10,
                            grid_method = method, verbose = FALSE))
}
ec_params <- c("sn0", "sp0", "psi_sn", "psi_sp")

expect_counts_consistent <- function(fit) {
  es <- fit@evaluated_sets
  expect_equal(fit@n_evaluated, nrow(es))
  expect_equal(fit@n_compatible, sum(es$compatible))
  expect_equal(nrow(fit@compatible_sets), fit@n_compatible)
  expect_equal(fit@falsified_proportion, mean(!es$compatible))
  # Every set judged compatible is in compatible_sets, so it shaped the bounds
  kept <- merge(es[es$compatible, ec_params], fit@compatible_sets[, ec_params],
                by = ec_params)
  expect_equal(nrow(kept), fit@n_compatible)
}

test_that("auto (mediator): the 16 probe corners are counted and kept", {
  fit <- ec_fit("mediator", "auto")
  expect_equal(fit@n_evaluated, 16L + ceiling(sqrt(10^4)))
  expect_gt(sum(fit@evaluated_sets$compatible[1:16]), 0)
  expect_counts_consistent(fit)
})

test_that("lhs: counts match the recorded evaluations on both paths", {
  expect_counts_consistent(ec_fit("mediator", "lhs"))
  expect_counts_consistent(ec_fit("exposure", "lhs"))
})

test_that("binary (exposure): counts include the probe corners", {
  skip_on_cran()
  fit <- ec_fit("exposure", "binary")
  expect_counts_consistent(fit)
})

# A cheap stand-in for a search: it evaluates 30 points spread over the region
# but returns only its compatible results, as the real searches do. bound_ne()
# must count what was evaluated, not what the search returned.
stub_search <- function(sensitivity_region, evaluate_func, ...) {
  r <- S7::props(sensitivity_region)
  pts <- data.frame(sn0 = seq(r$sn0_range[1], r$sn0_range[2], length.out = 30),
                    sp0 = rev(seq(r$sp0_range[1], r$sp0_range[2], length.out = 30)),
                    psi_sn = seq(r$psi_sn_range[1], r$psi_sn_range[2], length.out = 30),
                    psi_sp = rep(r$psi_sp_range, 15))
  res <- lapply(seq_len(nrow(pts)), function(i) evaluate_func(i, pts[i, ]))
  Filter(Negate(is.null), res)
}

test_that("adaptive and binary (mediator) report the number of evaluations", {
  local_mocked_bindings(adaptive_grid_search = stub_search,
                        binary_search_bounds = stub_search)
  for (method in c("adaptive", "binary")) {
    fit <- ec_fit("mediator", method)
    expect_equal(fit@n_evaluated, 30L)
    expect_counts_consistent(fit)
  }
})

test_that(".recording_evaluator() logs every call and keeps compatible results", {
  rec <- .recording_evaluator(function(i, row) if (row$sn0 > 0.5) list(i = i) else NULL)
  rows <- data.frame(sn0 = c(0.4, 0.6, 0.7), sp0 = 0.9, psi_sn = 1, psi_sp = 1)
  for (i in 1:3) rec$evaluate(i, rows[i, ])
  expect_equal(rec$sets()$compatible, c(FALSE, TRUE, TRUE))
  expect_equal(vapply(rec$results(), `[[`, numeric(1), "i"), c(2, 3))
})
