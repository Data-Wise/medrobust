# Test script to verify mediator misclassification speed improvements
devtools::load_all()

# Generate small test data
set.seed(123)
n <- 200
data <- data.frame(
  A = rbinom(n, 1, 0.5),
  M_star = rbinom(n, 1, 0.5),
  Y = rbinom(n, 1, 0.5),
  C1 = rbinom(n, 1, 0.5),
  C2 = rbinom(n, 1, 0.5)
)

# Define sensitivity region
sens_region <- list(
  sn0_range = c(0.80, 0.90),
  sp0_range = c(0.80, 0.90),
  psi_sn_range = c(1.0, 1.5),
  psi_sp_range = c(1.0, 1.0)
)

cat("\n=== Testing Mediator Misclassification with Different Grid Methods ===\n\n")

# Test 1: Regular grid (old method)
cat("1. Regular grid method (n_grid=10 => 10,000 evaluations):\n")
start_time <- Sys.time()
bounds_regular <- bound_ne(
  data = data,
  exposure = "A",
  mediator = "M_star",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "mediator",
  sensitivity_region = sens_region,
  n_grid = 10,
  grid_method = "regular",
  verbose = FALSE
)
end_time <- Sys.time()
time_regular <- as.numeric(difftime(end_time, start_time, units = "secs"))
cat(sprintf("   Time: %.2f seconds\n", time_regular))
cat(sprintf("   Evaluated: %d parameter sets\n", bounds_regular@n_evaluated))
cat(sprintf("   Compatible: %d parameter sets\n\n", bounds_regular@n_compatible))

# Test 2: LHS method (new default)
cat("2. LHS method (n_grid=10 => ~100 evaluations):\n")
start_time <- Sys.time()
bounds_lhs <- bound_ne(
  data = data,
  exposure = "A",
  mediator = "M_star",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "mediator",
  sensitivity_region = sens_region,
  n_grid = 10,
  grid_method = "lhs",  # This is now the default
  verbose = FALSE
)
end_time <- Sys.time()
time_lhs <- as.numeric(difftime(end_time, start_time, units = "secs"))
cat(sprintf("   Time: %.2f seconds\n", time_lhs))
cat(sprintf("   Evaluated: %d parameter sets\n", bounds_lhs@n_evaluated))
cat(sprintf("   Compatible: %d parameter sets\n\n", bounds_lhs@n_compatible))

# Test 3: Default method (should be LHS)
cat("3. Default method (should use LHS):\n")
start_time <- Sys.time()
bounds_default <- bound_ne(
  data = data,
  exposure = "A",
  mediator = "M_star",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "mediator",
  sensitivity_region = sens_region,
  n_grid = 10,
  verbose = FALSE
)
end_time <- Sys.time()
time_default <- as.numeric(difftime(end_time, start_time, units = "secs"))
cat(sprintf("   Time: %.2f seconds\n", time_default))
cat(sprintf("   Evaluated: %d parameter sets\n", bounds_default@n_evaluated))
cat(sprintf("   Compatible: %d parameter sets\n\n", bounds_default@n_compatible))

# Summary
cat("=== Performance Summary ===\n")
cat(sprintf("Regular grid: %.2f seconds (%d evaluations)\n",
            time_regular, bounds_regular@n_evaluated))
cat(sprintf("LHS method:   %.2f seconds (%d evaluations)\n",
            time_lhs, bounds_lhs@n_evaluated))
cat(sprintf("Speedup:      %.1fx faster\n", time_regular / time_lhs))
cat(sprintf("Evaluation reduction: %.1f%%\n\n",
            100 * (1 - bounds_lhs@n_evaluated / bounds_regular@n_evaluated)))

# Verify bounds are similar
cat("=== Bounds Comparison ===\n")
cat(sprintf("           NIE Lower    NIE Upper    NDE Lower    NDE Upper\n"))
cat(sprintf("Regular:   %.3f        %.3f        %.3f        %.3f\n",
            bounds_regular@NIE_lower, bounds_regular@NIE_upper,
            bounds_regular@NDE_lower, bounds_regular@NDE_upper))
cat(sprintf("LHS:       %.3f        %.3f        %.3f        %.3f\n",
            bounds_lhs@NIE_lower, bounds_lhs@NIE_upper,
            bounds_lhs@NDE_lower, bounds_lhs@NDE_upper))
cat(sprintf("Default:   %.3f        %.3f        %.3f        %.3f\n",
            bounds_default@NIE_lower, bounds_default@NIE_upper,
            bounds_default@NDE_lower, bounds_default@NDE_upper))

cat("\n✅ Mediator misclassification grid search optimization COMPLETE!\n")
