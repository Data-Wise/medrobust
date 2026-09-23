# Convert a sensitivity region to a list

[`as.list()`](https://rdrr.io/r/base/list.html) on a sensitivity region
object (as returned by
[`sensitivity_region`](https://data-wise.github.io/medrobust/reference/sensitivity_region.md))
returns its four parameter ranges as a plain named list, the same shape
accepted by the `sensitivity_region` argument of
[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md).

This is an S7 method for the base generic; call it as `as.list(region)`.

## Arguments

- x:

  A sensitivity region object created by
  [`sensitivity_region`](https://data-wise.github.io/medrobust/reference/sensitivity_region.md).

- ...:

  Ignored.

## Value

A named list with elements `sn0_range`, `sp0_range`, `psi_sn_range`, and
`psi_sp_range`, each a length-2 numeric vector `c(lower, upper)`.

## See also

[`sensitivity_region`](https://data-wise.github.io/medrobust/reference/sensitivity_region.md),
[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
