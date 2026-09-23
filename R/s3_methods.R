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
