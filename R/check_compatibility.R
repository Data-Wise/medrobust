#' Check Compatibility of Misclassification Parameters
#'
#' @description
#' Tests whether a specific set of misclassification parameters is compatible
#' with the observed data by checking testable implications. Returns detailed
#' diagnostics about which constraints are satisfied or violated.
#'
#' @param data Data frame containing the observed variables
#' @param exposure Character string. Name of exposure variable
#' @param mediator Character string. Name of mediator variable
#' @param outcome Character string. Name of outcome variable
#' @param confounders Character vector. Names of confounding variables
#' @param psi Named list containing misclassification parameters:
#'   \itemize{
#'     \item \code{sn0}: Baseline sensitivity
#'     \item \code{sp0}: Baseline specificity
#'     \item \code{psi_sn}: Differential sensitivity (odds ratio)
#'     \item \code{psi_sp}: Differential specificity (odds ratio)
#'   }
#' @param misclassified_variable Character string. Either "exposure" or "mediator"
#' @param return_details Logical. If TRUE, returns detailed stratum-level diagnostics.
#'   Default is TRUE.
#' @param tolerance Numeric. Tolerance for numerical precision when checking
#'   constraints. Default is 1e-6.
#'
#' @return A list with class \code{compatibility_test} containing:
#'   \item{compatible}{Logical. TRUE if parameters are compatible}
#'   \item{psi}{The tested parameter set}
#'   \item{n_constraints_total}{Total number of testable constraints}
#'   \item{n_constraints_satisfied}{Number of satisfied constraints}
#'   \item{n_constraints_violated}{Number of violated constraints}
#'   \item{violated_constraints}{Data frame of violated constraints (if any)}
#'   \item{implied_probabilities}{Solved true probabilities (if compatible)}
#'   \item{stratum_details}{Stratum-level diagnostics (if return_details=TRUE)}
#'
#' @details
#' This function implements the testable implications derived in Propositions 4.1
#' and 5.1 of the paper. For mediator misclassification, it checks whether the
#' observed data can be explained by any true causal parameters given the specified
#' misclassification mechanism. For exposure misclassification, it checks the
#' likelihood ratio constraints on observed probabilities.
#'
#' The function is useful for:
#' \itemize{
#'   \item Testing specific hypotheses about misclassification parameters
#'   \item Understanding which constraints are most informative
#'   \item Debugging sensitivity analyses
#'   \item Generating diagnostic plots
#' }
#'
#' @examples
#' \dontrun{
#' data("heals_data")
#'
#' # Test non-differential misclassification with high accuracy
#' test_ndm <- check_compatibility(
#'   data = heals_data,
#'   exposure = "A_star",
#'   mediator = "M",
#'   outcome = "Y",
#'   confounders = c("age", "male", "smoking", "bmi"),
#'   psi = list(sn0 = 0.90, sp0 = 0.90, psi_sn = 1.0, psi_sp = 1.0),
#'   misclassified_variable = "exposure"
#' )
#'
#' print(test_ndm)
#'
#' # Test strong differential misclassification
#' test_strong_dm <- check_compatibility(
#'   data = heals_data,
#'   exposure = "A_star",
#'   mediator = "M",
#'   outcome = "Y",
#'   confounders = c("age", "male", "smoking", "bmi"),
#'   psi = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 3.0, psi_sp = 1.0),
#'   misclassified_variable = "exposure"
#' )
#'
#' print(test_strong_dm)
#' }
#'
#' @seealso \code{\link{bound_ne}}, \code{\link{falsification_summary}}
#'
#' @export
check_compatibility <- function(data,
                               exposure,
                               mediator,
                               outcome,
                               confounders = NULL,
                               psi,
                               misclassified_variable = c("exposure", "mediator"),
                               return_details = TRUE,
                               tolerance = 1e-6) {

  # Match arguments
  misclassified_variable <- match.arg(misclassified_variable)

  # Validate psi parameter list
  required_params <- c("sn0", "sp0", "psi_sn", "psi_sp")
  missing_params <- setdiff(required_params, names(psi))
  if (length(missing_params) > 0) {
    stop("psi must contain: ", paste(required_params, collapse = ", "))
  }

  # Extract parameters
  sn0 <- psi$sn0
  sp0 <- psi$sp0
  psi_sn <- psi$psi_sn
  psi_sp <- psi$psi_sp

  # Compute sn1 and sp1
  sn1 <- odds_to_prob(psi_sn * prob_to_odds(sn0))
  sp1 <- odds_to_prob(psi_sp * prob_to_odds(sp0))

  # Validate that these are valid probabilities
  if (any(c(sn1, sp1) < 0 | c(sn1, sp1) > 1)) {
    return(compatibility_test(
      compatible = FALSE,
      psi = psi,
      sn1 = sn1,
      sp1 = sp1,
      n_constraints_total = 0L,
      n_constraints_satisfied = 0L,
      n_constraints_violated = 0L,
      violated_constraints = data.frame(),
      implied_probabilities = NULL,
      stratum_details = NULL,
      misclassified_variable = misclassified_variable,
      reason = "Invalid probabilities: sn1 or sp1 outside [0,1]"
    ))
  }

  # Check informativeness condition
  if ((sn0 + sp0 - 1) <= tolerance || (sn1 + sp1 - 1) <= tolerance) {
    return(compatibility_test(
      compatible = FALSE,
      psi = psi,
      sn1 = sn1,
      sp1 = sp1,
      n_constraints_total = 0L,
      n_constraints_satisfied = 0L,
      n_constraints_violated = 0L,
      violated_constraints = data.frame(),
      implied_probabilities = NULL,
      stratum_details = NULL,
      misclassified_variable = misclassified_variable,
      reason = "Non-informative misclassification (Sn + Sp <= 1)"
    ))
  }

  # Prepare data
  prepared_data <- prepare_data(data, exposure, mediator, outcome,
                                confounders, stratify_by = NULL)

  # Dispatch to appropriate method
  if (misclassified_variable == "mediator") {
    result <- check_compatibility_mediator(
      data = prepared_data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      sn0 = sn0, sp0 = sp0, sn1 = sn1, sp1 = sp1,
      return_details = return_details,
      tolerance = tolerance
    )
  } else {
    result <- check_compatibility_exposure(
      data = prepared_data,
      exposure = exposure,
      mediator = mediator,
      outcome = outcome,
      confounders = confounders,
      sn0 = sn0, sp0 = sp0, sn1 = sn1, sp1 = sp1,
      return_details = return_details,
      tolerance = tolerance
    )
  }

  # Convert result to S7 compatibility_test object
  return(compatibility_test(
    compatible = result$compatible,
    psi = psi,
    sn1 = sn1,
    sp1 = sp1,
    n_constraints_total = as.integer(result$n_constraints_total),
    n_constraints_satisfied = as.integer(result$n_constraints_satisfied),
    n_constraints_violated = as.integer(result$n_constraints_violated),
    violated_constraints = if (is.null(result$violated_constraints)) {
      data.frame()
    } else {
      result$violated_constraints
    },
    implied_probabilities = result$implied_probabilities,
    stratum_details = result$stratum_details,
    misclassified_variable = misclassified_variable,
    reason = result$reason
  ))
}


#' Check Compatibility for Mediator Misclassification
#'
#' @keywords internal
#' @noRd
check_compatibility_mediator <- function(data,
                                        exposure,
                                        mediator,
                                        outcome,
                                        confounders,
                                        sn0, sp0, sn1, sp1,
                                        return_details,
                                        tolerance) {

  # Get strata
  if (is.null(confounders) || length(confounders) == 0) {
    strata <- data.frame(stratum_id = 1)
    data$stratum_id <- 1
  } else {
    data <- data |>
      dplyr::group_by(across(all_of(confounders))) |>
      dplyr::mutate(stratum_id = cur_group_id()) |>
      dplyr::ungroup()
    strata <- data |>
      dplyr::select(stratum_id, all_of(confounders)) |>
      dplyr::distinct()
  }

  # Initialize storage
  all_compatible <- TRUE
  violated_constraints <- list()
  implied_probs_list <- list()
  stratum_details_list <- list()

  n_constraints_total <- 0
  n_constraints_satisfied <- 0

  # Loop over exposure levels and strata
  for (a in c(0, 1)) {
    for (s in strata$stratum_id) {
      # Get data for this (a, stratum) combination
      data_as <- data |>
        dplyr::filter(!!sym(exposure) == a, stratum_id == s)

      if (nrow(data_as) < 5) {
        # Sparse stratum - mark as incompatible but don't count constraints
        if (return_details) {
          stratum_details_list[[paste0("a", a, "_s", s)]] <- list(
            compatible = NA,
            reason = "Sparse stratum (n < 5)"
          )
        }
        next
      }

      # Compute observed joint probabilities
      obs_probs <- data_as |>
        dplyr::group_by(!!sym(outcome), !!sym(mediator)) |>
        dplyr::summarise(n = n(), .groups = "drop") |>
        dplyr::mutate(prob = n / sum(n)) |>
        dplyr::select(-n)

      # Extract P_11, P_10, P_01, P_00
      P <- matrix(0, nrow = 2, ncol = 2)
      for (j in 1:nrow(obs_probs)) {
        y_val <- obs_probs[[outcome]][j]
        m_val <- obs_probs[[mediator]][j]
        P[y_val + 1, m_val + 1] <- obs_probs$prob[j]
      }
      P_11 <- P[2, 2]
      P_10 <- P[2, 1]
      P_01 <- P[1, 2]
      P_00 <- P[1, 1]

      # Solve system of equations
      # System for Y=1
      A_mat_1 <- matrix(c(
        sn1, (1-sp1),
        (1-sn1), sp1
      ), nrow = 2, byrow = TRUE)

      b_vec_1 <- c(P_11, P_10)

      # System for Y=0
      A_mat_0 <- matrix(c(
        sn0, (1-sp0),
        (1-sn0), sp0
      ), nrow = 2, byrow = TRUE)

      b_vec_0 <- c(P_01, P_00)

      # Solve
      stratum_compatible <- TRUE
      reason <- NULL

      tryCatch({
        # Solve for Y=1
        theta_sol_1 <- solve(A_mat_1, b_vec_1)
        pi_gamma1 <- theta_sol_1[1]  # P(M=1, Y=1 | A=a, C)
        oneminuspi_gamma0_y1 <- theta_sol_1[2]  # P(M=0, Y=1 | A=a, C)

        # Solve for Y=0
        theta_sol_0 <- solve(A_mat_0, b_vec_0)
        pi_oneminusgamma1 <- theta_sol_0[1]  # P(M=1, Y=0 | A=a, C)
        oneminuspi_gamma0_y0 <- theta_sol_0[2]  # P(M=0, Y=0 | A=a, C)

        # Recover pi_a
        pi_a <- pi_gamma1 + pi_oneminusgamma1

        # Check constraint: 0 <= pi_a <= 1
        n_constraints_total <- n_constraints_total + 1
        if (pi_a < -tolerance || pi_a > 1 + tolerance) {
          stratum_compatible <- FALSE
          reason <- sprintf("pi_a = %.3f violates [0,1]", pi_a)
          violated_constraints[[length(violated_constraints) + 1]] <- data.frame(
            stratum = s,
            exposure = a,
            constraint = "pi_a in [0,1]",
            value = pi_a,
            lower = 0,
            upper = 1
          )
        } else {
          n_constraints_satisfied <- n_constraints_satisfied + 1
        }

        # Ensure non-negative (with tolerance)
        pi_a <- max(0, min(1, pi_a))

        # Recover gamma parameters
        if (pi_a < tolerance) {
          gamma_a1 <- 0.5  # Undefined
          gamma_a0 <- (oneminuspi_gamma0_y1 + oneminuspi_gamma0_y0) / (1 - pi_a + tolerance)
        } else if (pi_a > 1 - tolerance) {
          gamma_a1 <- (pi_gamma1 + pi_oneminusgamma1) / (pi_a + tolerance)
          gamma_a0 <- 0.5  # Undefined
        } else {
          gamma_a1 <- (pi_gamma1 + pi_oneminusgamma1) / pi_a
          gamma_a0 <- (oneminuspi_gamma0_y1 + oneminuspi_gamma0_y0) / (1 - pi_a)
        }

        # Check constraints: 0 <= gamma_a0, gamma_a1 <= 1
        n_constraints_total <- n_constraints_total + 2

        if (gamma_a0 < -tolerance || gamma_a0 > 1 + tolerance) {
          stratum_compatible <- FALSE
          reason <- sprintf("gamma_a0 = %.3f violates [0,1]", gamma_a0)
          violated_constraints[[length(violated_constraints) + 1]] <- data.frame(
            stratum = s,
            exposure = a,
            constraint = "gamma_a0 in [0,1]",
            value = gamma_a0,
            lower = 0,
            upper = 1
          )
        } else {
          n_constraints_satisfied <- n_constraints_satisfied + 1
        }

        if (gamma_a1 < -tolerance || gamma_a1 > 1 + tolerance) {
          stratum_compatible <- FALSE
          reason <- sprintf("gamma_a1 = %.3f violates [0,1]", gamma_a1)
          violated_constraints[[length(violated_constraints) + 1]] <- data.frame(
            stratum = s,
            exposure = a,
            constraint = "gamma_a1 in [0,1]",
            value = gamma_a1,
            lower = 0,
            upper = 1
          )
        } else {
          n_constraints_satisfied <- n_constraints_satisfied + 1
        }

        # Store implied probabilities if compatible
        if (stratum_compatible) {
          implied_probs_list[[paste0("a", a, "_s", s)]] <- list(
            pi_a = max(0, min(1, pi_a)),
            gamma_a0 = max(0, min(1, gamma_a0)),
            gamma_a1 = max(0, min(1, gamma_a1)),
            stratum_id = s,
            exposure = a
          )
        }

      }, error = function(e) {
        stratum_compatible <<- FALSE
        reason <<- paste("Matrix inversion failed:", e$message)
      })

      # Update overall compatibility
      if (!stratum_compatible) {
        all_compatible <- FALSE
      }

      # Store stratum details
      if (return_details) {
        stratum_details_list[[paste0("a", a, "_s", s)]] <- list(
          compatible = stratum_compatible,
          reason = reason,
          n_obs = nrow(data_as),
          observed_probs = list(P_11 = P_11, P_10 = P_10, P_01 = P_01, P_00 = P_00)
        )
      }
    }
  }

  # Compile results
  result <- list(
    compatible = all_compatible,
    n_constraints_total = n_constraints_total,
    n_constraints_satisfied = n_constraints_satisfied,
    n_constraints_violated = n_constraints_total - n_constraints_satisfied,
    violated_constraints = if (length(violated_constraints) > 0) {
      do.call(rbind, violated_constraints)
    } else {
      NULL
    },
    implied_probabilities = if (all_compatible) implied_probs_list else NULL,
    stratum_details = if (return_details) stratum_details_list else NULL
  )

  return(result)
}


#' Check Compatibility for Exposure Misclassification
#'
#' @keywords internal
#' @noRd
check_compatibility_exposure <- function(data,
                                        exposure,
                                        mediator,
                                        outcome,
                                        confounders,
                                        sn0, sp0, sn1, sp1,
                                        return_details,
                                        tolerance) {

  # Get strata
  if (is.null(confounders) || length(confounders) == 0) {
    strata <- data.frame(stratum_id = 1)
    data$stratum_id <- 1
  } else {
    data <- data |>
      dplyr::group_by(across(all_of(confounders))) |>
      dplyr::mutate(stratum_id = cur_group_id()) |>
      dplyr::ungroup()
    strata <- data |>
      dplyr::select(stratum_id, all_of(confounders)) |>
      dplyr::distinct()
  }

  # Initialize storage
  all_compatible <- TRUE
  violated_constraints <- list()
  implied_probs_list <- list()
  stratum_details_list <- list()

  n_constraints_total <- 0
  n_constraints_satisfied <- 0

  # Loop over (M, Y, stratum) combinations
  for (m in c(0, 1)) {
    for (y in c(0, 1)) {
      for (s in strata$stratum_id) {
        # Get data for this combination
        data_mys <- data |>
          dplyr::filter(!!sym(mediator) == m, !!sym(outcome) == y, stratum_id == s)

        if (nrow(data_mys) < 5) {
          if (return_details) {
            stratum_details_list[[paste0("m", m, "_y", y, "_s", s)]] <- list(
              compatible = NA,
              reason = "Sparse cell (n < 5)"
            )
          }
          next
        }

        # Compute observed P*(A*=a* | M=m, Y=y, C=c)
        obs_probs <- data_mys |>
          dplyr::group_by(!!sym(exposure)) |>
          dplyr::summarise(n = n(), .groups = "drop") |>
          dplyr::mutate(prob = n / sum(n))

        P_star_1 <- obs_probs$prob[obs_probs[[exposure]] == 1]
        P_star_0 <- obs_probs$prob[obs_probs[[exposure]] == 0]

        if (length(P_star_1) == 0) P_star_1 <- 0
        if (length(P_star_0) == 0) P_star_0 <- 0

        # Select sensitivity/specificity based on Y
        sn_y <- if (y == 1) sn1 else sn0
        sp_y <- if (y == 1) sp1 else sp0

        # Check testable implications (Proposition 5.1)
        stratum_compatible <- TRUE
        reason <- NULL

        # Constraint 1: P*_1 / P*_0 >= (1-sp_y) / sp_y
        n_constraints_total <- n_constraints_total + 1
        if (P_star_0 > tolerance) {
          ratio_1 <- P_star_1 / P_star_0
          lower_bound_1 <- (1 - sp_y) / sp_y

          if (ratio_1 < lower_bound_1 - tolerance) {
            stratum_compatible <- FALSE
            reason <- sprintf("Constraint 1 violated: %.3f < %.3f", ratio_1, lower_bound_1)
            violated_constraints[[length(violated_constraints) + 1]] <- data.frame(
              stratum = s,
              mediator = m,
              outcome = y,
              constraint = "P*_1/P*_0 >= (1-Sp)/Sp",
              value = ratio_1,
              lower = lower_bound_1,
              upper = Inf
            )
          } else {
            n_constraints_satisfied <- n_constraints_satisfied + 1
          }
        } else {
          n_constraints_satisfied <- n_constraints_satisfied + 1
        }

        # Constraint 2: P*_0 / P*_1 >= (1-sn_y) / sn_y
        n_constraints_total <- n_constraints_total + 1
        if (P_star_1 > tolerance) {
          ratio_2 <- P_star_0 / P_star_1
          lower_bound_2 <- (1 - sn_y) / sn_y

          if (ratio_2 < lower_bound_2 - tolerance) {
            stratum_compatible <- FALSE
            reason <- sprintf("Constraint 2 violated: %.3f < %.3f", ratio_2, lower_bound_2)
            violated_constraints[[length(violated_constraints) + 1]] <- data.frame(
              stratum = s,
              mediator = m,
              outcome = y,
              constraint = "P*_0/P*_1 >= (1-Sn)/Sn",
              value = ratio_2,
              lower = lower_bound_2,
              upper = Inf
            )
          } else {
            n_constraints_satisfied <- n_constraints_satisfied + 1
          }
        } else {
          n_constraints_satisfied <- n_constraints_satisfied + 1
        }

        # If compatible, solve for true probabilities
        if (stratum_compatible) {
          denom <- sn_y + sp_y - 1
          P_1 <- (sp_y * P_star_1 - (1 - sp_y) * P_star_0) / denom
          P_0 <- (sn_y * P_star_0 - (1 - sn_y) * P_star_1) / denom

          # Additional check: non-negativity
          n_constraints_total <- n_constraints_total + 2

          if (P_1 < -tolerance) {
            stratum_compatible <- FALSE
            reason <- sprintf("P(A=1|M,Y,C) = %.3f < 0", P_1)
            violated_constraints[[length(violated_constraints) + 1]] <- data.frame(
              stratum = s,
              mediator = m,
              outcome = y,
              constraint = "P(A=1) >= 0",
              value = P_1,
              lower = 0,
              upper = 1
            )
          } else {
            n_constraints_satisfied <- n_constraints_satisfied + 1
          }

          if (P_0 < -tolerance) {
            stratum_compatible <- FALSE
            reason <- sprintf("P(A=0|M,Y,C) = %.3f < 0", P_0)
            violated_constraints[[length(violated_constraints) + 1]] <- data.frame(
              stratum = s,
              mediator = m,
              outcome = y,
              constraint = "P(A=0) >= 0",
              value = P_0,
              lower = 0,
              upper = 1
            )
          } else {
            n_constraints_satisfied <- n_constraints_satisfied + 1
          }

          # Store implied probabilities
          if (stratum_compatible) {
            implied_probs_list[[paste0("m", m, "_y", y, "_s", s)]] <- c(
              P_1 = max(0, P_1),
              P_0 = max(0, P_0),
              stratum_id = s,
              M = m,
              Y = y
            )
          }
        }

        # Update overall compatibility
        if (!stratum_compatible) {
          all_compatible <- FALSE
        }

        # Store stratum details
        if (return_details) {
          stratum_details_list[[paste0("m", m, "_y", y, "_s", s)]] <- list(
            compatible = stratum_compatible,
            reason = reason,
            n_obs = nrow(data_mys),
            observed_probs = list(P_star_1 = P_star_1, P_star_0 = P_star_0)
          )
        }
      }
    }
  }

  # Compile results
  result <- list(
    compatible = all_compatible,
    n_constraints_total = n_constraints_total,
    n_constraints_satisfied = n_constraints_satisfied,
    n_constraints_violated = n_constraints_total - n_constraints_satisfied,
    violated_constraints = if (length(violated_constraints) > 0) {
      do.call(rbind, violated_constraints)
    } else {
      NULL
    },
    implied_probabilities = if (all_compatible) implied_probs_list else NULL,
    stratum_details = if (return_details) stratum_details_list else NULL
  )

  return(result)
}


#' Print Method for compatibility_test
#'
#' @param x An object of class \code{compatibility_test}
#' @param ... Additional arguments (currently unused)
#'
#' @return Invisibly returns the input object
#' @export
print.compatibility_test <- function(x, ...) {

  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("COMPATIBILITY TEST\n")
  cat(strrep("=", 70), "\n\n")

  # Tested parameters
  cat("Tested Parameters:\n")
  cat("  Sn0:", sprintf("%.3f", x$psi$sn0), "\n")
  cat("  Sp0:", sprintf("%.3f", x$psi$sp0), "\n")
  cat("  psi_Sn:", sprintf("%.3f", x$psi$psi_sn), "\n")
  cat("  psi_Sp:", sprintf("%.3f", x$psi$psi_sp), "\n")

  if (!is.null(x$sn1) && !is.null(x$sp1)) {
    cat("  -> Sn1:", sprintf("%.3f", x$sn1), "\n")
    cat("  -> Sp1:", sprintf("%.3f", x$sp1), "\n")
  }

  cat("\n")
  cat(strrep("-", 70), "\n")

  # Result
  if (x$compatible) {
    cat("RESULT: COMPATIBLE [PASS]\n")
    cat(strrep("-", 70), "\n\n")

    cat("The specified misclassification parameters are consistent with\n")
    cat("the observed data. All testable implications are satisfied.\n\n")

    if (!is.null(x$n_constraints_total)) {
      cat("Constraints satisfied:", x$n_constraints_satisfied, "/",
          x$n_constraints_total, "\n\n")
    }

    if (!is.null(x$implied_probabilities)) {
      cat("Implied true causal parameters have been successfully solved.\n")
      cat("Use summary() to see detailed results.\n")
    }

  } else {
    cat("RESULT: INCOMPATIBLE [FAIL]\n")
    cat(strrep("-", 70), "\n\n")

    if (!is.null(x$reason)) {
      cat("Reason:", x$reason, "\n\n")
    } else {
      cat("The specified misclassification parameters are NOT consistent\n")
      cat("with the observed data. Some testable implications are violated.\n\n")

      if (!is.null(x$n_constraints_total)) {
        cat("Constraints satisfied:", x$n_constraints_satisfied, "/",
            x$n_constraints_total, "\n")
        cat("Constraints violated:", x$n_constraints_violated, "\n\n")
      }

      if (!is.null(x$violated_constraints)) {
        cat("Violated Constraints:\n")
        print(head(x$violated_constraints, 10), row.names = FALSE)
        if (nrow(x$violated_constraints) > 10) {
          cat("... and", nrow(x$violated_constraints) - 10, "more\n")
        }
        cat("\n")
      }
    }
  }

  cat(strrep("=", 70), "\n\n")

  invisible(x)
}


#' Summary Method for compatibility_test
#'
#' @param object An object of class \code{compatibility_test}
#' @param ... Additional arguments (currently unused)
#'
#' @return Invisibly returns the input object
#' @export
summary.compatibility_test <- function(object, ...) {

  # Print basic info
  print(object)

  # Additional details if available
  if (!is.null(object$stratum_details) && length(object$stratum_details) > 0) {
    cat("STRATUM-LEVEL DETAILS\n")
    cat(strrep("=", 70), "\n\n")

    for (stratum_name in names(object$stratum_details)) {
      detail <- object$stratum_details[[stratum_name]]
      cat("Stratum:", stratum_name, "\n")
      cat("  Compatible:", if (is.na(detail$compatible)) "NA" else detail$compatible, "\n")
      if (!is.null(detail$reason)) {
        cat("  Reason:", detail$reason, "\n")
      }
      if (!is.null(detail$n_obs)) {
        cat("  n =", detail$n_obs, "\n")
      }
      cat("\n")
    }
  }

  invisible(object)
}
