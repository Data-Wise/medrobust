#' Coerce to data frame (S3 - Legacy)
#'
#' @description
#' Extract bounds as a data frame for further analysis or export.
#' NOTE: This is a legacy S3 method. The package now uses S7 methods (see s7-methods.R).
#'
#' @param x An object of class \code{medrobust_bounds}.
#' @param row.names Optional row names (not used).
#' @param optional Logical (not used).
#' @param ... Additional arguments (not used).
#'
#' @return A data frame with one row containing the bounds.
#'
#' @export
as.data.frame.medrobust_bounds <- function(x, row.names = NULL,
                                          optional = FALSE, ...) {

  df <- data.frame(
    misclassified_variable = x@misclassified_variable,
    effect_scale = x@effect_scale,
    n = x@data_summary$n,
    NIE_lower = x@NIE_lower,
    NIE_upper = x@NIE_upper,
    NDE_lower = x@NDE_lower,
    NDE_upper = x@NDE_upper,
    falsified_proportion = x@falsified_proportion,
    stringsAsFactors = FALSE
  )

  return(df)
}


#' Convert sensitivity_region S7 object to list
#'
#' @param x A sensitivity_region S7 object
#' @param ... Additional arguments (ignored)
#'
#' @return A list with sn0_range, sp0_range, psi_sn_range, psi_sp_range
#'
#' @export
as.list.sensitivity_region <- function(x, ...) {
  list(
    sn0_range = x@sn0_range,
    sp0_range = x@sp0_range,
    psi_sn_range = x@psi_sn_range,
    psi_sp_range = x@psi_sp_range
  )
}
