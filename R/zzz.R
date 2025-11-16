# R/zzz.R
.onLoad <- function(libname, pkgname) {
  # Ensure S7 methods in this package are registered.
  # If you put S7 in Imports, this is safe.
  S7::methods_register()
}