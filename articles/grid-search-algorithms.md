# Advanced Grid Search Algorithms

## Overview

[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
evaluates the misclassification parameters
$`\Psi = (sn_0, sp_0, \psi_{sn}, \psi_{sp})`$ at a set of points in the
sensitivity region, keeps the points that are compatible with the data,
and reports the minimum and maximum of each effect over them. The
reported bounds are therefore an **inner approximation** of the
identified set: a point the search never evaluates cannot widen them.
The `grid_method` argument decides which points are evaluated, and that
choice trades run time against how close the reported bounds come to the
full identified set.

Two facts shape the choice:

- The effects are often most extreme at the edges of the region, so
  methods that evaluate the corners and edges (the regular grid) tend to
  find the widest bounds.
- Each evaluation solves the misclassification model once; cost grows
  linearly with the number of points evaluated.
- Every method, the regular grid included, tends to report wider bounds
  as `n_grid` grows. No setting is exact, so the useful question is
  whether the bounds have stopped changing.

## Points evaluated by each method

| `grid_method` | Points evaluated | Deterministic? |
|----|----|----|
| `"regular"` | $`n_{grid}^4`$ (10,000 at `n_grid = 10`) | yes |
| `"lhs"` (default) | $`\lceil n_{grid}^2 \rceil`$ (100 at `n_grid = 10`; 2,500 at the default `n_grid = 50`) | yes (fixed internal design) |
| `"sobol"` | $`\lceil n_{grid}^2 \rceil`$ | yes |
| `"adaptive"` | a coarse grid, then a full $`n_{grid}^4`$ grid over part of the region | yes |
| `"binary"` | 16 corners, then 50 or 10,000 more points | no (uses your random stream) |
| `"auto"` | depends on the path and a corner probe (see below) | depends on the method chosen |

`n_grid` must be between 10 and 200; the default is 50.

## The methods

### Regular grid (`"regular"`)

Evaluates every combination of `n_grid` equally spaced values per
parameter, including all corners of the region. It is the only method
that uses `parallel = TRUE`; every other method evaluates its points one
at a time.

### Latin hypercube sampling (`"lhs"`, the default)

Divides each parameter range into $`N = \lceil n_{grid}^2 \rceil`$
intervals, draws one value in each, and permutes the columns (McKay et
al., 1979). The design is generated with a fixed internal seed, so the
same inputs always give the same bounds, and your own random number
stream is left untouched. It evaluates no corners, and with few points
(small `n_grid`) it can report bounds well inside those of a denser
search (see the benchmark below). At the default `n_grid = 50` it
evaluates 2,500 points in a few seconds.

### Low-discrepancy sequence (`"sobol"`)

Despite its name, this method does not use a Sobol’ sequence. It uses a
simple radical-inverse (van der Corput) sequence with a different base
for each parameter (bases 3 to 6), a Halton-type design with
$`\lceil n_{grid}^2 \rceil`$ points. Like LHS it is deterministic and
evaluates no corners.

### Adaptive refinement (`"adaptive"`)

1.  Evaluates a coarse grid (3 points per parameter at `n_grid = 10`, so
    81 points).
2.  Takes the bounding box of the compatible coarse points, widening the
    $`sn_0`$ and $`sp_0`$ ranges by 10% of their width while staying
    inside the sensitivity region.
3.  Evaluates a full $`n_{grid}^4`$ grid over that box, skipping points
    already evaluated.

The refinement concentrates the fine grid where compatible points were
found, but it never evaluates fewer points than the regular grid: when
most of the region is compatible, the box is the whole region and
adaptive costs slightly more than regular. If no coarse point is
compatible,
[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
stops with an error. `"adaptive"` runs only when
`use_adaptive_grid = TRUE` (the default); otherwise the regular grid is
used.

### Corner-and-edge sampling (`"binary"`)

Despite its name, this method does no binary search.

1.  Evaluates the 16 corners of the region.
2.  If none or all 16 corners are compatible, evaluates a 50-point Latin
    hypercube and stops (66 points in total).
3.  Otherwise evaluates 10,000 random points whose coordinates are drawn
    from a Beta(0.5, 0.5) distribution rescaled to each range, which
    concentrates them near the edges.

`n_grid` has no effect on this method. Because step 3 draws from your
random number stream, call
[`set.seed()`](https://rdrr.io/r/base/Random.html) first if you need
reproducible bounds. The random points can fall between grid values, so
the bounds can be slightly wider than the regular grid’s.

### Automatic choice (`"auto"`)

The behavior differs between the two misclassification paths.

- **Exposure misclassification**: with the defaults
  (`use_adaptive_grid = TRUE`), `"auto"` runs the adaptive method above.

- **Mediator misclassification**, or the exposure path with
  `use_adaptive_grid = FALSE`: evaluates the 16 corners, then chooses by
  the share that is compatible:

  | Compatible corners | Method used  |
  |--------------------|--------------|
  | all 16             | regular grid |
  | none               | LHS          |
  | fewer than 25%     | `"sobol"`    |
  | more than 75%      | `"binary"`   |
  | 25% to 75%         | LHS          |

  The LHS and `"sobol"` sample size is $`\min(500, n_{grid}^2)`$ on the
  exposure path and $`\min(n_{grid}^2, 10\,000)`$ on the mediator path.

## Benchmark

The comparison below runs when this page is built, on simulated data
with exposure misclassification ($`n = 1000`$, two confounders) and a
sensitivity region in which about a third of the points are falsified.

``` r

library(medrobust)

test_data <- simulate_dm_data(
  n = 1000,
  true_params = list(beta_AM = 0.5, theta_AY = 0.3, theta_MY = 0.8, p_A = 0.5),
  dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
  misclass_type = "exposure",
  confounders = 2,
  seed = 123
)

sens_region <- sensitivity_region(
  sn0_range = c(0.70, 0.95),
  sp0_range = c(0.70, 0.95),
  psi_sn_range = c(0.5, 3.0),
  psi_sp_range = c(0.5, 2.0)
)
```

``` r

configs <- data.frame(
  method = c("regular", "regular", "lhs", "lhs", "sobol", "adaptive", "binary", "auto"),
  n_grid = c(10, 15, 10, 50, 10, 10, 10, 10)
)

rows <- lapply(seq_len(nrow(configs)), function(k) {
  set.seed(1) # "binary" draws from the session's random stream
  secs <- system.time(
    b <- bound_ne(
      data = test_data@observed,
      exposure = "A_star",
      mediator = "M",
      outcome = "Y",
      confounders = c("C1", "C2"),
      misclassified_variable = "exposure",
      sensitivity_region = sens_region,
      n_grid = configs$n_grid[k],
      grid_method = configs$method[k],
      verbose = FALSE
    )
  )[["elapsed"]]
  data.frame(
    Method = configs$method[k],
    n_grid = configs$n_grid[k],
    Evaluated = b@n_evaluated,
    Compatible = b@n_compatible,
    Seconds = round(secs, 1),
    NIE = sprintf("[%.3f, %.3f]", b@NIE_lower, b@NIE_upper),
    NDE = sprintf("[%.3f, %.3f]", b@NDE_lower, b@NDE_upper)
  )
})

knitr::kable(do.call(rbind, rows))
```

| Method   | n_grid | Evaluated | Compatible | Seconds | NIE              | NDE              |
|:---------|-------:|----------:|-----------:|--------:|:-----------------|:-----------------|
| regular  |     10 |     10000 |       6390 |    37.7 | \[1.050, 1.098\] | \[0.776, 4.977\] |
| regular  |     15 |     50625 |      32185 |   190.9 | \[1.050, 1.105\] | \[0.779, 5.781\] |
| lhs      |     10 |       100 |         68 |     0.4 | \[1.053, 1.078\] | \[1.069, 2.755\] |
| lhs      |     50 |      2500 |       1686 |     9.7 | \[1.050, 1.099\] | \[0.870, 4.518\] |
| sobol    |     10 |       100 |         60 |     0.4 | \[1.052, 1.092\] | \[1.072, 2.940\] |
| adaptive |     10 |     10065 |       6423 |    39.2 | \[1.050, 1.098\] | \[0.776, 4.977\] |
| binary   |     10 |     10016 |       5888 |    37.5 | \[1.050, 1.100\] | \[0.811, 5.032\] |
| auto     |     10 |     10065 |       6423 |    39.8 | \[1.050, 1.098\] | \[0.776, 4.977\] |

Reading the table:

- **LHS and `"sobol"` at `n_grid = 10`** evaluate only 100 points; their
  bounds sit well inside the others, and here the NDE lower bound moves
  from below 1 to above 1, which would change the conclusion.
- **LHS at the default `n_grid = 50`** evaluates 2,500 points in a few
  seconds, and its bounds are much closer to the dense searches.
- **The regular grid widens too**: going from `n_grid = 10` to `15`
  (10,000 to 50,625 points) raises the NDE upper bound. The regular grid
  includes the corners, but it is still an inner approximation, not an
  exact answer.
- **`"adaptive"` and `"auto"`** (which runs adaptive on this path) cost
  as much as the regular grid at the same `n_grid` and give the same
  bounds: the compatible points span the whole region, so the refinement
  box is the whole region.
- **`"binary"`** found some corners incompatible, so it drew 10,000
  random points. Its bounds are close to the regular grid’s and can
  extend slightly beyond them, because the random points fall between
  grid values.
- Times are from the machine that built this page and scale with the
  number of points evaluated.

## Choosing a method

- **Check that the bounds have stopped changing.** Before reporting,
  rerun with a larger `n_grid` (for LHS, `n_grid = 100` evaluates 10,000
  points) and confirm the bounds, and any conclusion such as whether
  they exclude 1, stay put. If they still move, keep increasing
  `n_grid`.
- **`"lhs"` at the default `n_grid = 50`** is a reasonable starting
  point: fast, reproducible, and with enough points to be close. Avoid
  small `n_grid` with LHS or `"sobol"`.
- **`"regular"`** adds the corners and is a useful cross-check, but its
  cost grows as $`n_{grid}^4`$ (10,000 points at `n_grid = 10`, 6.25
  million at 50), so it is practical only at small `n_grid`, where it is
  coarse. It is the only method that uses `parallel = TRUE`.
- **`"adaptive"` does not save time** in this implementation; it spends
  the same fine grid on a smaller box.
- **`"binary"`** probes the edges and is another cross-check, but set a
  seed, and note that it ignores `n_grid`.
- **`"auto"`** is not a shortcut on the exposure path: with the defaults
  it runs the adaptive method.

## Reproducibility

| Method | Same bounds on every run? |
|----|----|
| `"regular"`, `"adaptive"` | yes |
| `"lhs"` | yes; the design uses a fixed internal seed and restores your random stream |
| `"sobol"` | yes |
| `"binary"` | only if you call [`set.seed()`](https://rdrr.io/r/base/Random.html) first |

## Examples

``` r

# Quick look (default method)
bounds_quick <- bound_ne(
  data = data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 50,
  grid_method = "lhs"
)

# Stability check: the same search at a higher resolution
bounds_check <- bound_ne(
  data = data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 100, # 10,000 LHS points
  grid_method = "lhs"
)
```

## References

McKay, M. D., Beckman, R. J., & Conover, W. J. (1979). A comparison of
three methods for selecting values of input variables in the analysis of
output from a computer code. *Technometrics*, 21(2), 239-245.
<https://doi.org/10.2307/1268522>

## Session Information

``` r

sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.5 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] medrobust_0.4.4
#> 
#> loaded via a namespace (and not attached):
#>  [1] vctrs_0.7.3        cli_3.6.6          knitr_1.52         rlang_1.3.0       
#>  [5] xfun_0.61          otel_0.2.0         generics_0.1.4     S7_0.2.2          
#>  [9] jsonlite_2.0.0     glue_1.8.1         htmltools_0.5.9    scales_1.4.0      
#> [13] rmarkdown_2.32     grid_4.6.1         evaluate_1.0.5     tibble_3.3.1      
#> [17] fastmap_1.2.0      yaml_2.3.12        lifecycle_1.0.5    compiler_4.6.1    
#> [21] dplyr_1.2.1        RColorBrewer_1.1-3 pkgconfig_2.0.3    farver_2.1.2      
#> [25] digest_0.6.39      R6_2.6.1           tidyselect_1.2.1   parallel_4.6.1    
#> [29] pillar_1.11.1      magrittr_2.0.5     withr_3.0.3        tools_4.6.1       
#> [33] gtable_0.3.6       ggplot2_4.0.3
```
