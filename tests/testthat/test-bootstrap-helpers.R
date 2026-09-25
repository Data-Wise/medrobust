# compute_bound_se(), bootstrap_width_summary() and plot_bootstrap_distribution()
# read the replicate vectors with `$`, but bound_ne() stores them in an S7
# `bootstrap_results` object, whose fields need `@`. They errored on the only
# input bound_ne() produces.

make_boot <- function() {
  bootstrap_results(
    method = "percentile", n_reps = 5L, confidence_level = 0.95,
    nie_lower_ci = c(1.0, 1.2), nie_upper_ci = c(1.3, 1.5),
    nde_lower_ci = c(1.3, 1.5), nde_upper_ci = c(1.6, 1.9),
    boot_nie_lower = c(1.10, 1.12, 1.08, 1.15, 1.11),
    boot_nie_upper = c(1.35, 1.40, 1.32, 1.42, 1.38),
    boot_nde_lower = c(1.40, 1.45, 1.38, 1.47, 1.43),
    boot_nde_upper = c(1.70, 1.76, 1.66, 1.80, 1.74)
  )
}

test_that("compute_bound_se() reads an S7 bootstrap_results object", {
  br <- make_boot()
  se <- compute_bound_se(br)
  expect_equal(unname(se["nie_lower_se"]), sd(br@boot_nie_lower))
  expect_equal(unname(se["nde_upper_se"]), sd(br@boot_nde_upper))
})

test_that("bootstrap_width_summary() reads an S7 bootstrap_results object", {
  br <- make_boot()
  w <- bootstrap_width_summary(br, effect = "NDE")
  expect_equal(w$mean_width, mean(br@boot_nde_upper - br@boot_nde_lower))
})

test_that("plot_bootstrap_distribution() reads an S7 bootstrap_results object", {
  expect_s3_class(plot_bootstrap_distribution(make_boot(), effect = "NIE"), "ggplot")
})

test_that("bootstrap helpers still accept the list from compute_bootstrap_ci()", {
  br <- make_boot()
  lst <- list(boot_nie_lower = br@boot_nie_lower, boot_nie_upper = br@boot_nie_upper,
              boot_nde_lower = br@boot_nde_lower, boot_nde_upper = br@boot_nde_upper)
  expect_equal(compute_bound_se(lst), compute_bound_se(br))
  expect_equal(bootstrap_width_summary(lst)$mean_width,
               bootstrap_width_summary(br)$mean_width)
})

test_that("bootstrap helpers reject a bounds object fitted without bootstrap", {
  expect_error(compute_bound_se(NULL), "bootstrap")
})
