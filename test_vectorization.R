# Quick test of vectorized optimization
library(devtools)
load_all()

# Create test data
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

cat("\n=== Testing Vectorized Implementation ===\n")
cat("Running with n_grid = 10, use_adaptive_grid = FALSE...\n\n")

t1 <- system.time({
  bounds <- bound_ne(
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
    use_adaptive_grid = FALSE,
    verbose = TRUE
  )
})

cat("\n=== Results ===\n")
cat(sprintf("Time: %.2f seconds\n", t1[3]))
cat(sprintf("NIE: [%.3f, %.3f]\n", bounds@NIE_lower, bounds@NIE_upper))
cat(sprintf("NDE: [%.3f, %.3f]\n", bounds@NDE_lower, bounds@NDE_upper))
cat(sprintf("Compatible: %d/%d\n", bounds@n_compatible, bounds@n_evaluated))
