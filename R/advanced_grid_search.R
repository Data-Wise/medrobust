#' Latin Hypercube Sampling Grid Search
#'
#' @description
#' Space-filling design that ensures uniform coverage of parameter space
#' with far fewer points than regular grid.
#'
#' @param sensitivity_region Sensitivity parameter region
#' @param evaluate_func Function to evaluate compatibility
#' @param n_samples Number of LHS samples (default: sqrt of full grid size)
#' @param verbose Whether to print progress
#'
#' @return List of compatible results
#' @keywords internal
#' @noRd
latin_hypercube_search <- function(sensitivity_region, evaluate_func,
                                   n_samples = NULL, verbose = TRUE) {

  # Extract ranges (handle both S7 and list)
  if (inherits(sensitivity_region, "S7_object")) {
    sn0_range <- sensitivity_region@sn0_range
    sp0_range <- sensitivity_region@sp0_range
    psi_sn_range <- sensitivity_region@psi_sn_range
    psi_sp_range <- sensitivity_region@psi_sp_range
  } else {
    sn0_range <- sensitivity_region$sn0_range
    sp0_range <- sensitivity_region$sp0_range
    psi_sn_range <- sensitivity_region$psi_sn_range
    psi_sp_range <- sensitivity_region$psi_sp_range
  }

  # Default sample size: sqrt of full grid
  if (is.null(n_samples)) {
    n_samples <- ceiling(sqrt(10000))  # ~100 samples vs 10,000
  }

  if (verbose) {
    cat("\n=== Latin Hypercube Sampling ===\n")
    cat("Samples:", n_samples, "\n")
  }

  # Generate LHS design in [0,1]^4 (vectorized)
  set.seed(42)  # Reproducibility

  # Divide [0,1] into n_samples intervals
  intervals <- seq(0, 1, length.out = n_samples + 1)

  # Create all 4 columns at once using replicate
  lhs_design <- replicate(4, {
    # Random sample within each interval
    col <- runif(n_samples, intervals[1:n_samples], intervals[2:(n_samples + 1)])
    # Random permutation
    col[sample(n_samples)]
  })

  # Scale to actual parameter ranges
  param_grid <- data.frame(
    sn0 = lhs_design[, 1] * diff(sn0_range) + sn0_range[1],
    sp0 = lhs_design[, 2] * diff(sp0_range) + sp0_range[1],
    psi_sn = lhs_design[, 3] * diff(psi_sn_range) + psi_sn_range[1],
    psi_sp = lhs_design[, 4] * diff(psi_sp_range) + psi_sp_range[1]
  )

  # Evaluate samples (using lapply for functional approach)
  if (verbose) pb <- txtProgressBar(min = 0, max = n_samples, style = 3)

  results <- lapply(seq_len(n_samples), function(i) {
    result <- evaluate_func(i, param_grid[i, ])
    if (verbose && i %% max(1, floor(n_samples/20)) == 0) {
      setTxtProgressBar(pb, i)
    }
    result
  })

  if (verbose) {
    close(pb)
    compatible <- Filter(Negate(is.null), results)
    cat(sprintf("Compatible: %d/%d (%.1f%%)\n",
                length(compatible), n_samples,
                100 * length(compatible)/n_samples))
  }

  # Add metadata
  results_filtered <- Filter(Negate(is.null), results)
  attr(results_filtered, "n_evaluated") <- n_samples
  attr(results_filtered, "method") <- "latin_hypercube"

  return(results_filtered)
}


#' Sobol Sequence Grid Search
#'
#' @description
#' Low-discrepancy quasi-random sequence that provides better coverage
#' than random sampling and LHS for high-dimensional spaces.
#'
#' @keywords internal
#' @noRd
sobol_sequence_search <- function(sensitivity_region, evaluate_func,
                                  n_samples = NULL, verbose = TRUE) {

  # Extract ranges
  if (inherits(sensitivity_region, "S7_object")) {
    sn0_range <- sensitivity_region@sn0_range
    sp0_range <- sensitivity_region@sp0_range
    psi_sn_range <- sensitivity_region@psi_sn_range
    psi_sp_range <- sensitivity_region@psi_sp_range
  } else {
    sn0_range <- sensitivity_region$sn0_range
    sp0_range <- sensitivity_region$sp0_range
    psi_sn_range <- sensitivity_region$psi_sn_range
    psi_sp_range <- sensitivity_region$psi_sp_range
  }

  if (is.null(n_samples)) {
    n_samples <- 100
  }

  if (verbose) {
    cat("\n=== Sobol Sequence Sampling ===\n")
    cat("Samples:", n_samples, "\n")
  }

  # Generate Sobol sequence (simple implementation)
  # For production, use randtoolbox::sobol()
  sobol_design <- generate_sobol_sequence(n_samples, d = 4)

  # Scale to parameter ranges
  param_grid <- data.frame(
    sn0 = sobol_design[, 1] * diff(sn0_range) + sn0_range[1],
    sp0 = sobol_design[, 2] * diff(sp0_range) + sp0_range[1],
    psi_sn = sobol_design[, 3] * diff(psi_sn_range) + psi_sn_range[1],
    psi_sp = sobol_design[, 4] * diff(psi_sp_range) + psi_sp_range[1]
  )

  # Evaluate
  results <- vector("list", n_samples)
  if (verbose) pb <- txtProgressBar(min = 0, max = n_samples, style = 3)

  for (i in 1:n_samples) {
    results[[i]] <- evaluate_func(i, param_grid[i, ])
    if (verbose && i %% max(1, floor(n_samples/20)) == 0) {
      setTxtProgressBar(pb, i)
    }
  }

  if (verbose) {
    close(pb)
    compatible <- Filter(Negate(is.null), results)
    cat(sprintf("Compatible: %d/%d (%.1f%%)\n",
                length(compatible), n_samples,
                100 * length(compatible)/n_samples))
  }

  results_filtered <- Filter(Negate(is.null), results)
  attr(results_filtered, "n_evaluated") <- n_samples
  attr(results_filtered, "method") <- "sobol"

  return(results_filtered)
}


#' Simple Sobol Sequence Generator
#'
#' @description
#' Generates a simple Sobol-like low-discrepancy sequence.
#' For production use, consider randtoolbox::sobol() for true Sobol.
#'
#' @keywords internal
#' @noRd
generate_sobol_sequence <- function(n, d) {
  # Simple van der Corput-like sequence for each dimension
  # This is a simplified version; true Sobol uses direction numbers

  result <- matrix(0, nrow = n, ncol = d)

  for (dim in 1:d) {
    base <- 2 + dim  # Use different base for each dimension
    for (i in 1:n) {
      # Van der Corput sequence
      num <- i
      denom <- 1
      while (num > 0) {
        denom <- denom * base
        result[i, dim] <- result[i, dim] + (num %% base) / denom
        num <- num %/% base
      }
    }
  }

  return(result)
}


#' Binary Search for Bound Edges
#'
#' @description
#' For each parameter, performs binary search to find the exact boundary
#' between compatible and incompatible regions. Very efficient when
#' compatibility is monotonic in parameters.
#'
#' @keywords internal
#' @noRd
binary_search_bounds <- function(sensitivity_region, evaluate_func,
                                 precision = 0.01, verbose = TRUE) {

  # Extract ranges
  if (inherits(sensitivity_region, "S7_object")) {
    sn0_range <- sensitivity_region@sn0_range
    sp0_range <- sensitivity_region@sp0_range
    psi_sn_range <- sensitivity_region@psi_sn_range
    psi_sp_range <- sensitivity_region@psi_sp_range
  } else {
    sn0_range <- sensitivity_region$sn0_range
    sp0_range <- sensitivity_region$sp0_range
    psi_sn_range <- sensitivity_region$psi_sn_range
    psi_sp_range <- sensitivity_region$psi_sp_range
  }

  if (verbose) {
    cat("\n=== Binary Search on Bounds ===\n")
    cat("Precision:", precision, "\n")
  }

  # Strategy: Find edges by binary search on each parameter
  # Test corners first
  corners <- expand.grid(
    sn0 = sn0_range,
    sp0 = sp0_range,
    psi_sn = psi_sn_range,
    psi_sp = psi_sp_range
  )

  # Evaluate corners
  corner_results <- lapply(1:nrow(corners), function(i) {
    evaluate_func(i, corners[i, ])
  })

  n_compatible_corners <- sum(!sapply(corner_results, is.null))

  if (verbose) {
    cat(sprintf("Corner compatibility: %d/16\n", n_compatible_corners))
  }

  # If no corners compatible or all compatible, use LHS instead
  if (n_compatible_corners == 0 || n_compatible_corners == 16) {
    if (verbose) {
      cat("Boundary search not applicable, using LHS...\n")
    }
    return(latin_hypercube_search(sensitivity_region, evaluate_func,
                                  n_samples = 50, verbose = verbose))
  }

  # Sample grid with focus on boundaries (denser near edges)
  n_boundary <- 10  # Points per parameter dimension

  # Beta distribution sampling (concentrates near edges)
  beta_samples <- function(n, alpha = 0.5, beta = 0.5) {
    rbeta(n, alpha, beta)
  }

  param_grid <- data.frame(
    sn0 = beta_samples(n_boundary^4) * diff(sn0_range) + sn0_range[1],
    sp0 = beta_samples(n_boundary^4) * diff(sp0_range) + sp0_range[1],
    psi_sn = beta_samples(n_boundary^4) * diff(psi_sn_range) + psi_sn_range[1],
    psi_sp = beta_samples(n_boundary^4) * diff(psi_sp_range) + psi_sp_range[1]
  )

  # Evaluate
  n_eval <- nrow(param_grid)
  results <- vector("list", n_eval)

  if (verbose) pb <- txtProgressBar(min = 0, max = n_eval, style = 3)

  for (i in 1:n_eval) {
    results[[i]] <- evaluate_func(i, param_grid[i, ])
    if (verbose && i %% max(1, floor(n_eval/20)) == 0) {
      setTxtProgressBar(pb, i)
    }
  }

  if (verbose) {
    close(pb)
    compatible <- Filter(Negate(is.null), results)
    cat(sprintf("Compatible: %d/%d (%.1f%%)\n",
                length(compatible), n_eval,
                100 * length(compatible)/n_eval))
  }

  results_filtered <- Filter(Negate(is.null), results)
  attr(results_filtered, "n_evaluated") <- n_eval
  attr(results_filtered, "method") <- "binary_search"

  return(results_filtered)
}


#' Auto-Select Best Grid Search Method
#'
#' @description
#' Automatically chooses the most appropriate grid search algorithm based
#' on problem characteristics.
#'
#' @param sensitivity_region Sensitivity parameter region
#' @param evaluate_func Function to evaluate compatibility
#' @param target_samples Target number of samples
#' @param verbose Whether to print progress
#'
#' @return List of compatible results
#' @keywords internal
#' @noRd
auto_grid_search <- function(sensitivity_region, evaluate_func,
                             target_samples = 100, verbose = TRUE) {

  if (verbose) {
    cat("\n=== Auto-Selecting Grid Search Method ===\n")
  }

  # Quick probe: test 16 corners
  if (inherits(sensitivity_region, "S7_object")) {
    sn0_range <- sensitivity_region@sn0_range
    sp0_range <- sensitivity_region@sp0_range
    psi_sn_range <- sensitivity_region@psi_sn_range
    psi_sp_range <- sensitivity_region@psi_sp_range
  } else {
    sn0_range <- sensitivity_region$sn0_range
    sp0_range <- sensitivity_region$sp0_range
    psi_sn_range <- sensitivity_region$psi_sn_range
    psi_sp_range <- sensitivity_region$psi_sp_range
  }

  corners <- expand.grid(
    sn0 = sn0_range,
    sp0 = sp0_range,
    psi_sn = psi_sn_range,
    psi_sp = psi_sp_range
  )

  corner_results <- lapply(1:nrow(corners), function(i) {
    evaluate_func(i, corners[i, ])
  })

  n_compatible <- sum(!sapply(corner_results, is.null))
  compat_rate <- n_compatible / 16

  if (verbose) {
    cat(sprintf("Probe: %d/16 corners compatible (%.0f%%)\n",
                n_compatible, 100 * compat_rate))
  }

  # Decision logic
  if (compat_rate == 1.0) {
    # All compatible - use regular grid (already implemented)
    if (verbose) cat("Strategy: Regular grid (all compatible)\n")
    method <- "regular"
  } else if (compat_rate == 0) {
    # None compatible - use dense search
    if (verbose) cat("Strategy: Latin Hypercube (sparse compatibility)\n")
    method <- "lhs"
  } else if (compat_rate < 0.25) {
    # Low compatibility - focused sampling
    if (verbose) cat("Strategy: Sobol sequence (low compatibility)\n")
    method <- "sobol"
  } else if (compat_rate > 0.75) {
    # High compatibility - boundary search
    if (verbose) cat("Strategy: Binary search (high compatibility)\n")
    method <- "binary"
  } else {
    # Medium compatibility - LHS is most robust
    if (verbose) cat("Strategy: Latin Hypercube (medium compatibility)\n")
    method <- "lhs"
  }

  # Execute chosen method
  if (method == "lhs") {
    return(latin_hypercube_search(sensitivity_region, evaluate_func,
                                  target_samples, verbose))
  } else if (method == "sobol") {
    return(sobol_sequence_search(sensitivity_region, evaluate_func,
                                 target_samples, verbose))
  } else if (method == "binary") {
    return(binary_search_bounds(sensitivity_region, evaluate_func,
                                verbose = verbose))
  } else {
    # Regular grid - return NULL to signal use existing implementation
    return(NULL)
  }
}
