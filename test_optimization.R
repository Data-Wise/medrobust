# Test optimization performance
library(devtools)
load_all()

# Create test data
set.seed(123)
test_data <- simulate_dm_data(
  n = 1000,
  true_params = list(
    beta_AM = 0.5,
    theta_AY = 0.3,
    theta_MY = 0.8,
    p_A = 0.5
  ),
  dm_params = list(
    sn0 = 0.85,
    sp0 = 0.85,
    psi_sn = 1.5,
    psi_sp = 1.0
  ),
  misclass_type = "exposure",
  confounders = 2
)

sens_region <- list(
  sn0_range = c(0.80, 0.90),
  sp0_range = c(0.80, 0.90),
  psi_sn_range = c(1.0, 2.0),
  psi_sp_range = c(1.0, 1.0)
)

cat("\n=== Testing with n_grid = 10 ===\n\n")

# Test WITHOUT optimizations (use_adaptive_grid = FALSE)
cat("Running WITHOUT adaptive grid...\n")
t1 <- system.time({
  bounds_no_opt <- bound_ne(
    data = test_data$observed,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = c("C1", "C2"),
    misclassified_variable = "exposure",
    sensitivity_region = sens_region,
    n_grid = 10,
    effect_scale = "OR",
    parallel = FALSE,
    use_adaptive_grid = FALSE,  # Disable optimization
    verbose = TRUE
  )
})

cat("\n\nRunning WITH adaptive grid optimization...\n")
t2 <- system.time({
  bounds_with_opt <- bound_ne(
    data = test_data$observed,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = c("C1", "C2"),
    misclassified_variable = "exposure",
    sensitivity_region = sens_region,
    n_grid = 10,
    effect_scale = "OR",
    parallel = FALSE,
    use_adaptive_grid = TRUE,  # Enable optimization
    verbose = TRUE
  )
})

cat("\n\n=== Performance Comparison ===\n")
cat(sprintf("Without optimization: %.2f seconds\n", t1[3]))
cat(sprintf("With optimization:    %.2f seconds\n", t2[3]))
cat(sprintf("Speedup:              %.1fx faster\n", t1[3] / t2[3]))

cat("\n=== Bounds Comparison ===\n")
cat("Without optimization:\n")
cat(sprintf("  NIE: [%.3f, %.3f]\n", bounds_no_opt@NIE_lower, bounds_no_opt@NIE_upper))
cat(sprintf("  NDE: [%.3f, %.3f]\n", bounds_no_opt@NDE_lower, bounds_no_opt@NDE_upper))

cat("\nWith optimization:\n")
cat(sprintf("  NIE: [%.3f, %.3f]\n", bounds_with_opt@NIE_lower, bounds_with_opt@NIE_upper))
cat(sprintf("  NDE: [%.3f, %.3f]\n", bounds_with_opt@NDE_lower, bounds_with_opt@NDE_upper))

# Check if bounds are similar
nie_diff <- max(abs(bounds_no_opt@NIE_lower - bounds_with_opt@NIE_lower),
                abs(bounds_no_opt@NIE_upper - bounds_with_opt@NIE_upper))
nde_diff <- max(abs(bounds_no_opt@NDE_lower - bounds_with_opt@NDE_lower),
                abs(bounds_no_opt@NDE_upper - bounds_with_opt@NDE_upper))

cat("\n=== Accuracy Check ===\n")
cat(sprintf("Max NIE difference: %.6f\n", nie_diff))
cat(sprintf("Max NDE difference: %.6f\n", nde_diff))

if (nie_diff < 0.01 && nde_diff < 0.01) {
  cat("\n✓ PASS: Optimized bounds match original bounds!\n")
} else {
  cat("\n✗ WARNING: Bounds differ by more than 0.01\n")
}
