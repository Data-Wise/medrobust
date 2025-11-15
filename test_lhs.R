# Test Latin Hypercube Sampling
library(devtools)
load_all()

set.seed(123)
test_data <- simulate_dm_data(
  n = 1000,
  true_params = list(beta_AM = 0.5, theta_AY = 0.3, theta_MY = 0.8, p_A = 0.5),
  dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
  misclass_type = "exposure",
  confounders = 2
)

sens_region <- list(
  sn0_range = c(0.80, 0.90),
  sp0_range = c(0.80, 0.90),
  psi_sn_range = c(1.0, 2.0),
  psi_sp_range = c(1.0, 1.0)
)

cat("\n=== Comparing Grid Search Methods ===\n\n")

# Test 1: Regular grid (for comparison)
cat("1. Regular grid (n_grid=10)...\n")
t_regular <- system.time({
  bounds_regular <- bound_ne(
    data = test_data$observed,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = c("C1", "C2"),
    misclassified_variable = "exposure",
    sensitivity_region = sens_region,
    n_grid = 10,
    grid_method = "regular",
    verbose = FALSE
  )
})

cat(sprintf("\nResults: NIE=[%.3f, %.3f], NDE=[%.3f, %.3f]\n",
            bounds_regular@NIE_lower, bounds_regular@NIE_upper,
            bounds_regular@NDE_lower, bounds_regular@NDE_upper))
cat(sprintf("Time: %.2f sec, Evaluations: %d\n",
            t_regular[3], bounds_regular@n_evaluated))

# Test 2: Latin Hypercube Sampling
cat("\n2. Latin Hypercube Sampling...\n")
t_lhs <- system.time({
  bounds_lhs <- bound_ne(
    data = test_data$observed,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = c("C1", "C2"),
    misclassified_variable = "exposure",
    sensitivity_region = sens_region,
    n_grid = 10,  # Used to compute target samples
    grid_method = "lhs",
    verbose = TRUE
  )
})

cat(sprintf("\nResults: NIE=[%.3f, %.3f], NDE=[%.3f, %.3f]\n",
            bounds_lhs@NIE_lower, bounds_lhs@NIE_upper,
            bounds_lhs@NDE_lower, bounds_lhs@NDE_upper))
cat(sprintf("Time: %.2f sec, Evaluations: %d\n",
            t_lhs[3], bounds_lhs@n_evaluated))

# Comparison
cat("\n=== Performance Summary ===\n")
cat(sprintf("Regular Grid:  %.1f sec, %d evaluations\n",
            t_regular[3], bounds_regular@n_evaluated))
cat(sprintf("LHS:           %.1f sec, %d evaluations\n",
            t_lhs[3], bounds_lhs@n_evaluated))
cat(sprintf("Speedup:       %.1fx faster\n", t_regular[3] / t_lhs[3]))
cat(sprintf("Reduction:     %.0f%% fewer evaluations\n",
            100 * (1 - bounds_lhs@n_evaluated / bounds_regular@n_evaluated)))

# Bound accuracy
nie_width_diff <- (bounds_lhs@NIE_upper - bounds_lhs@NIE_lower) -
                  (bounds_regular@NIE_upper - bounds_regular@NIE_lower)
nde_width_diff <- (bounds_lhs@NDE_upper - bounds_lhs@NDE_lower) -
                  (bounds_regular@NDE_upper - bounds_regular@NDE_lower)

cat(sprintf("\nBound width difference:\n"))
cat(sprintf("  NIE: %.3f (%.1f%% change)\n", nie_width_diff,
            100 * nie_width_diff / (bounds_regular@NIE_upper - bounds_regular@NIE_lower)))
cat(sprintf("  NDE: %.3f (%.1f%% change)\n", nde_width_diff,
            100 * nde_width_diff / (bounds_regular@NDE_upper - bounds_regular@NDE_lower)))
