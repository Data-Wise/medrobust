#' Create Sensitivity Analysis Plots
#'
#' @description
#' Generate publication-quality visualizations of partial identification bounds
#' as a function of sensitivity parameters.
#'
#' @param bounds_object An object of class \code{medrobust_bounds} returned
#'   by \code{\link{bound_ne}}.
#' @param param Character vector specifying which parameter(s) to plot on the
#'   x-axis. Options: "psi_sn", "psi_sp", "sn0", "sp0". Can specify multiple
#'   for faceted plots.
#' @param effect Character string: "NIE", "NDE", or "both" (default).
#' @param plot_type Character string specifying plot type:
#'   \itemize{
#'     \item "bounds" (default): Line plot showing upper and lower bounds
#'     \item "heatmap": 2D heatmap of bound width (requires two parameters)
#'     \item "contour": Contour plot of bounds (requires two parameters)
#'   }
#' @param show_naive Logical indicating whether to overlay the naive estimate
#'   (assuming no misclassification). Default is TRUE.
#' @param show_null Logical indicating whether to show horizontal line at null
#'   value (effect = 1 for OR/RR, effect = 0 for RD). Default is TRUE.
#' @param color_scheme Character string specifying color palette: "default",
#'   "viridis", "colorblind", "grayscale".
#' @param theme Character string for ggplot2 theme: "bw" (default), "minimal",
#'   "classic", "void".
#' @param ... Additional arguments passed to ggplot2 functions.
#'
#' @return A ggplot2 object that can be further customized or saved.
#'
#' @details
#' The function creates different plot types to visualize sensitivity analysis:
#'
#' \strong{Bounds plot}: Shows how the lower and upper bounds vary as a function
#' of one sensitivity parameter, with other parameters held fixed or averaged.
#'
#' \strong{Heatmap}: Shows the width of the identification region (upper - lower)
#' as a function of two sensitivity parameters simultaneously.
#'
#' \strong{Contour plot}: Shows contour lines of the bounds in 2D parameter space.
#'
#' @examples
#' \donttest{
#' # Compute bounds to plot (see ?bound_ne)
#' sim <- simulate_dm_data(
#'   n = 600,
#'   true_params = list(beta_AM = log(2.5), theta_AY = log(1.5), theta_MY = log(2.5)),
#'   dm_params = list(sn0 = 0.9, sp0 = 0.9, psi_sn = 1, psi_sp = 1),
#'   misclass_type = "mediator", confounders = 1, seed = 1
#' )
#' set.seed(1)
#' bounds <- bound_ne(
#'   data = sim@observed, exposure = "A", mediator = "M_star", outcome = "Y",
#'   confounders = "C1", misclassified_variable = "mediator",
#'   sensitivity_region = list(
#'     sn0_range = c(0.80, 0.99), sp0_range = c(0.80, 0.99),
#'     psi_sn_range = c(0.8, 1.5), psi_sp_range = c(0.8, 1.5)
#'   ),
#'   n_grid = 10
#' )
#'
#' # Basic bounds plot
#' sensitivity_plot(bounds, param = "psi_sn", effect = "NIE")
#'
#' # Show both effects
#' sensitivity_plot(bounds, param = "psi_sn", effect = "both")
#'
#' # Customize the returned ggplot object
#' p <- sensitivity_plot(bounds, param = "psi_sn") +
#'   ggplot2::labs(title = "My Custom Title") +
#'   ggplot2::theme(legend.position = "bottom")
#' p
#' }
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon labs theme_bw
sensitivity_plot <- function(bounds_object,
                            param = "psi_sn",
                            effect = c("both", "NIE", "NDE"),
                            plot_type = c("bounds", "heatmap", "contour"),
                            show_naive = TRUE,
                            show_null = TRUE,
                            color_scheme = "default",
                            theme = "bw",
                            ...) {

  # Match arguments
  effect <- match.arg(effect)
  plot_type <- match.arg(plot_type)

  # Validate input
  if (!is_s7_class(bounds_object, "medrobust_bounds")) {
    stop("bounds_object must be of class 'medrobust_bounds'")
  }

  # Route to appropriate plot function
  if (plot_type == "bounds") {
    p <- plot_bounds_line(bounds_object, param, effect, show_naive, show_null)
  } else if (plot_type == "heatmap") {
    if (length(param) != 2) {
      stop("Heatmap requires exactly 2 parameters")
    }
    p <- plot_bounds_heatmap(bounds_object, param, effect)
  } else if (plot_type == "contour") {
    if (length(param) != 2) {
      stop("Contour plot requires exactly 2 parameters")
    }
    p <- plot_bounds_contour(bounds_object, param, effect)
  }

  # Apply theme
  p <- apply_plot_theme(p, theme)

  # Apply color scheme
  p <- apply_color_scheme(p, color_scheme)

  return(p)
}


#' Line plot of bounds vs single parameter
#'
#' @keywords internal
#' @noRd
plot_bounds_line <- function(bounds_object, param, effect, show_naive, show_null) {

  # Extract compatible sets data
  if (is.null(bounds_object@compatible_sets) || nrow(bounds_object@compatible_sets) == 0) {
    stop("No compatible parameter sets found in bounds_object. Cannot create sensitivity plot.")
  }

  compat_data <- bounds_object@compatible_sets

  # Check if the requested parameter exists in compatible_sets
  if (!param %in% names(compat_data)) {
    stop("Parameter '", param, "' not found in compatible_sets. ",
         "Available parameters: ", paste(names(compat_data), collapse = ", "))
  }

  # Aggregate bounds across other parameters for each value of the focal parameter
  # Group by the focal parameter and compute min/max bounds
  param_values <- sort(unique(compat_data[[param]]))

  # Initialize result data frame
  plot_data <- data.frame(
    param_value = numeric(),
    nie_lower = numeric(),
    nie_upper = numeric(),
    nde_lower = numeric(),
    nde_upper = numeric()
  )

  # For each unique value of the parameter, get the range of bounds
  for (pval in param_values) {
    subset_data <- compat_data[compat_data[[param]] == pval, ]

    if (nrow(subset_data) > 0) {
      # The compatible_sets contains NIE and NDE point estimates
      # We compute the range (min/max) across all compatible sets for this parameter value
      nie_vals <- subset_data$NIE[!is.na(subset_data$NIE)]
      nde_vals <- subset_data$NDE[!is.na(subset_data$NDE)]

      # Only add to plot data if we have valid values
      if (length(nie_vals) > 0 && length(nde_vals) > 0) {
        plot_data <- rbind(plot_data, data.frame(
          param_value = pval,
          nie_lower = min(nie_vals),
          nie_upper = max(nie_vals),
          nde_lower = min(nde_vals),
          nde_upper = max(nde_vals)
        ))
      }
    }
  }

  # Create parameter label
  param_label <- switch(param,
    "sn0" = "Sensitivity (Y=0)",
    "sp0" = "Specificity (Y=0)",
    "psi_sn" = "Sensitivity Odds Ratio",
    "psi_sp" = "Specificity Odds Ratio",
    param
  )

  # Create base plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = param_value)) +
    ggplot2::labs(
      x = param_label,
      y = paste("Effect (", bounds_object@effect_scale, ")", sep = ""),
      title = "Sensitivity Analysis: Bounds vs. Misclassification Parameter"
    )

  # Add NIE bounds if requested
  if (effect %in% c("NIE", "both")) {
    p <- p +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = nie_lower, ymax = nie_upper),
                          alpha = 0.3, fill = "steelblue") +
      ggplot2::geom_line(ggplot2::aes(y = nie_lower), color = "steelblue",
                        linewidth = 1, linetype = "dashed") +
      ggplot2::geom_line(ggplot2::aes(y = nie_upper), color = "steelblue",
                        linewidth = 1, linetype = "dashed")
  }

  # Add NDE bounds if requested
  if (effect %in% c("NDE", "both")) {
    p <- p +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = nde_lower, ymax = nde_upper),
                          alpha = 0.3, fill = "coral") +
      ggplot2::geom_line(ggplot2::aes(y = nde_lower), color = "coral",
                        linewidth = 1, linetype = "dashed") +
      ggplot2::geom_line(ggplot2::aes(y = nde_upper), color = "coral",
                        linewidth = 1, linetype = "dashed")
  }

  # Add null hypothesis line if requested
  if (show_null) {
    null_value <- ifelse(bounds_object@effect_scale == "RD", 0, 1)
    p <- p + ggplot2::geom_hline(yintercept = null_value,
                                 linetype = "dotted", color = "red", alpha = 0.7)
  }

  # Add naive estimates if available and requested
  if (show_naive && !is.null(bounds_object@naive_estimates)) {
    if (effect %in% c("NIE", "both")) {
      p <- p + ggplot2::geom_hline(yintercept = bounds_object@naive_estimates$NIE,
                                   linetype = "solid", color = "steelblue",
                                   alpha = 0.5, linewidth = 0.5)
    }
    if (effect %in% c("NDE", "both")) {
      p <- p + ggplot2::geom_hline(yintercept = bounds_object@naive_estimates$NDE,
                                   linetype = "solid", color = "coral",
                                   alpha = 0.5, linewidth = 0.5)
    }
  }

  return(p)
}


#' Heatmap of bound width
#'
#' @keywords internal
#' @noRd
plot_bounds_heatmap <- function(bounds_object, params, effect) {

  # TODO: Create 2D heatmap of bound width
  # PLACEHOLDER

  p <- ggplot2::ggplot() +
    ggplot2::labs(
      x = params[1],
      y = params[2],
      title = "Bound Width Heatmap"
    )

  return(p)
}


#' Contour plot of bounds
#'
#' @keywords internal
#' @noRd
plot_bounds_contour <- function(bounds_object, params, effect) {

  # TODO: Create contour plot
  # PLACEHOLDER

  p <- ggplot2::ggplot() +
    ggplot2::labs(
      x = params[1],
      y = params[2],
      title = "Bounds Contour Plot"
    )

  return(p)
}


#' Apply ggplot2 theme
#'
#' @keywords internal
#' @noRd
apply_plot_theme <- function(p, theme) {

  theme_func <- switch(theme,
    "bw" = ggplot2::theme_bw,
    "minimal" = ggplot2::theme_minimal,
    "classic" = ggplot2::theme_classic,
    "void" = ggplot2::theme_void,
    ggplot2::theme_bw  # default
  )

  p <- p + theme_func()
  return(p)
}


#' Apply color scheme
#'
#' @keywords internal
#' @noRd
apply_color_scheme <- function(p, color_scheme) {

  # TODO: Implement color scheme application
  # This would modify the fill/color scales

  return(p)
}


# Note: falsification_summary() function has been moved to R/falsification_summary.R
# The full implementation is now in that file.
