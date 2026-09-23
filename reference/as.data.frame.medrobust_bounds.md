# Convert partial identification bounds to a data frame

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) on a
[`medrobust_bounds`](https://data-wise.github.io/medrobust/reference/medrobust_bounds.md)
object (as returned by
[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md))
returns a one-row data frame of the bounds and fit summary, convenient
for tabulating or combining results across analyses.

This is an S7 method for the base generic; call it as
`as.data.frame(bounds)`.

## Arguments

- x:

  A
  [`medrobust_bounds`](https://data-wise.github.io/medrobust/reference/medrobust_bounds.md)
  object.

- ...:

  Ignored.

## Value

A one-row `data.frame` with columns `NIE_lower`, `NIE_upper`,
`NDE_lower`, `NDE_upper`, `NIE_width`, `NDE_width` (upper minus lower),
`effect_scale`, `misclassified_variable`, `n_compatible`, `n_evaluated`,
and `falsified_proportion`. If the object carries bootstrap results, it
also has percentile-interval columns for each bound endpoint
(`NIE_lower_ci_lower`, `NIE_lower_ci_upper`, ..., `NDE_upper_ci_upper`)
plus `bootstrap_method` and `bootstrap_n_reps`. Analytic (Imbens-Manski)
intervals are not included; use `x@analytic_ci`.

## See also

[`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md),
[`medrobust_bounds`](https://data-wise.github.io/medrobust/reference/medrobust_bounds.md)
