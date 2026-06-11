setwd("/Users/dt/projects/r-packages/active/medrobust")
suppressWarnings(suppressMessages(pkgload::load_all(".", quiet = TRUE)))
cat("== package loaded ==\n")

# 1) DGP returns S7 object with expected slots?
sim <- simulate_dm_data(
  n = 300,
  true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
  dm_params   = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1.5, psi_sp = 1.0),
  misclass_type = "mediator", confounders = 1, seed = 101
)
cat("class:", class(sim)[1], "\n")
cat("observed cols:", paste(names(sim@observed), collapse=", "), "\n")
te <- sim@true_effects
cat("true_effects names:", paste(names(te), collapse=", "), "\n")
cat("true NDE_OR:", round(te$NDE_OR,3), " NIE_OR:", round(te$NIE_OR,3), "\n")

# 2) bound_ne runs on mediator strand?
reg <- sensitivity_region(c(0.85,0.95), c(0.85,0.95), c(1.0,1.5), c(1.0,1.0))
b <- bound_ne(
  data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
  confounders = "C1", misclassified_variable = "mediator",
  sensitivity_region = reg, n_grid = 20, effect_scale = "OR",
  confidence_level = 0.95, verbose = FALSE, use_adaptive_grid = TRUE
)
cat("bounds class:", class(b)[1], "\n")
cat(sprintf("NDE [%.3f, %.3f]  NIE [%.3f, %.3f]\n", b@NDE_lower, b@NDE_upper, b@NIE_lower, b@NIE_upper))
cat("NDE covered:", te$NDE_OR>=b@NDE_lower && te$NDE_OR<=b@NDE_upper,
    " NIE covered:", te$NIE_OR>=b@NIE_lower && te$NIE_OR<=b@NIE_upper, "\n")
cat("== SMOKE OK ==\n")
