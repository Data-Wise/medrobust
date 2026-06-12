# Advanced Grid Search Algorithms

## Overview

The
[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md)
function computes partial identification bounds by evaluating
compatibility across a 4-dimensional parameter space (sn0, sp0, ψ_sn,
ψ_sp). This vignette describes **6 advanced grid search algorithms**
that dramatically reduce computation time while maintaining accuracy.

**Key insight**: These methods reduce evaluations by **90-99%** compared
to exhaustive grid search, enabling practical analysis with large grids.

## The Computational Challenge

### Exponential Complexity

With a regular grid approach:

- **4 dimensions**: sn0, sp0, ψ_sn, ψ_sp
- **Grid resolution**: `n_grid` points per dimension
- **Total evaluations**: n_grid⁴

**Examples**:

This exponential growth makes fine-grained grids (n_grid ≥ 50)
impractical with exhaustive search.

### The Solution: Smart Sampling

Instead of evaluating all n_grid⁴ points, advanced algorithms sample
strategically:

- **Space-filling designs** (LHS, Sobol): Ensure coverage with fewer
  points
- **Adaptive refinement**: Focus on compatible regions
- **Boundary search**: Find edges efficiently
- **Auto-selection**: Choose best method automatically

## Available Grid Methods

### 1. Latin Hypercube Sampling (`"lhs"`) ⭐ **DEFAULT**

**What it is**: A space-filling experimental design that ensures uniform
coverage across all dimensions.

**How it works**: 1. Divide each parameter range into N equal intervals
2. Sample once from each interval (guaranteed coverage) 3. Randomly
permute assignments across dimensions 4. Result: N well-distributed
points in 4D space

**Performance**:

**When to use**: - Default choice for most analyses - Exploratory data
analysis - Large grids (n_grid ≥ 20) - Need broad parameter space
coverage

**Example**:

``` r

# Default: LHS is used automatically
bounds <- bound_ne(
  data = data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 50 # LHS evaluates ~2,500 points instead of 6.25M
)
```

### 2. Regular Grid (`"regular"`)

**What it is**: Exhaustive evaluation of all n_grid⁴ combinations.

**Performance**:

- Evaluations: n_grid⁴ (always)
- Speed: Baseline (1x)
- Accuracy: Exact min/max over grid

**When to use**:

- Publication-quality results requiring exact bounds
- Small grids (n_grid ≤ 10) where speed is acceptable
- When computational budget allows
- Critical policy decisions

**Example**:

``` r

# Exact bounds (slow for large grids)
bounds_exact <- bound_ne(
  ...,
  n_grid = 10,
  grid_method = "regular" # 10,000 evaluations
)
```

### 3. Sobol Sequences (`"sobol"`)

**What it is**: Low-discrepancy quasi-random sequences ensuring even
coverage.

**How it differs from LHS**: - Deterministic (no random seed needed) -
Better uniformity in high dimensions - Slightly better coverage for \>4
dimensions

**Performance**: - Evaluations: sqrt(n_grid⁴) (same as LHS) - Speed:
50-100x faster than regular - Accuracy: Similar to LHS

**When to use**: - High-dimensional extensions (future features) - Need
reproducibility without setting seed - Sparse compatible regions

**Example**:

``` r

bounds_sobol <- bound_ne(
  ...,
  n_grid = 50,
  grid_method = "sobol"
)
```

### 4. Adaptive Grid (`"adaptive"`)

**What it is**: Two-stage coarse-to-fine refinement.

**How it works**: 1. **Coarse stage**: Evaluate small grid (e.g.,
3×3×3×3) 2. **Identify compatible regions**: Find where constraints are
satisfied 3. **Fine stage**: Refine only around compatible regions 4.
**Result**: Focus computational effort where it matters

**Performance**: - Evaluations: 1-20% of full grid (when falsification
is high) - Speed: 5-10x faster - Accuracy: Good for identifying
compatible regions

**When to use**:

- High falsification rate expected (\>80% incompatible)
- Sparse compatible regions
- Medium-sized grids (10 ≤ n_grid ≤ 30)

**Example**:

``` r

bounds_adaptive <- bound_ne(
  ...,
  n_grid = 20,
  grid_method = "adaptive"
)
```

### 5. Binary Search on Bounds (`"binary"`)

**What it is**: Find exact boundaries between compatible/incompatible
regions.

**How it works**: 1. Test corner points of parameter space 2. For each
parameter, binary search to find boundaries 3. Sample densely near
boundaries (Beta distribution) 4. Focus on finding min/max effect values

**Performance**: - Evaluations: O(log n) per dimension when monotonic -
Speed: 10-50x faster - Accuracy: Excellent for boundaries

**When to use**: - Compatibility is monotonic in parameters - Need
precise boundary estimates - Computational constraints

**Limitations**: - Assumes monotonicity (not always satisfied) - May
miss complex interior structures - Falls back to LHS if assumptions fail

**Example**:

``` r

bounds_binary <- bound_ne(
  ...,
  n_grid = 50,
  grid_method = "binary"
)
```

### 6. Auto-Selection (`"auto"`)

**What it is**: Automatically selects best method based on problem
characteristics.

**How it works**: 1. Probe 16 corner points of parameter space 2.
Estimate compatibility rate 3. Select method based on heuristics: - 100%
compatible → Regular grid (all points useful) - 0% compatible → LHS
(need dense search) - \<25% compatible → Sobol (sparse search) - \>75%
compatible → Binary search (find edges) - 25-75% compatible → LHS
(balanced)

**Performance**: - Evaluations: 100-500 typically - Speed: Optimal for
problem - Overhead: Minimal (16 evaluations)

**When to use**: - Unsure which method is best - Problem characteristics
unknown - Exploratory analysis

**Example**:

``` r

bounds_auto <- bound_ne(
  ...,
  n_grid = 50,
  grid_method = "auto" # Adapts to your data
)
```

## Performance Comparison

### Test Case: Exposure Misclassification

**Results** (n=1000, n_grid=10, 2 confounders):

**Key observations**: - LHS is **67x faster** than regular grid - Bounds
are similar across methods (slight variations due to sampling) - All
methods identify the same general bound ranges

### Large Grid Performance (n_grid=50)

## Recommended Workflow

### Three-Stage Analysis

#### Stage 1: Quick Exploration

Use LHS with moderate grid for initial insights:

``` r

# Fast exploration (~30 seconds)
bounds_quick <- bound_ne(
  data = data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 20,
  grid_method = "lhs", # Fast exploration
  verbose = TRUE
)

print(bounds_quick)
```

#### Stage 2: Refinement

Increase resolution or use auto-selection:

``` r

# Refined analysis (~2 minutes)
bounds_refined <- bound_ne(
  data = data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 50,
  grid_method = "auto", # Adapts to data characteristics
  verbose = TRUE
)
```

#### Stage 3: Publication-Quality Results

Use regular grid with parallel processing:

``` r

# Exact bounds with parallel processing (~10-20 minutes)
library(parallel)
n_cores <- detectCores() - 1

bounds_exact <- bound_ne(
  data = data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 100, # High resolution
  grid_method = "regular", # Exact bounds
  parallel = TRUE,
  n_cores = n_cores,
  verbose = TRUE
)
```

## Accuracy vs. Speed Trade-offs

### Bound Width Differences

Sampling methods (LHS, Sobol) produce approximate bounds:

### When is approximation acceptable?

**✅ Use sampling methods (LHS, Sobol) for**: - Exploratory data
analysis - Sensitivity checking - Interactive workflows - Preliminary
results - Computational constraints

**❌ Use exact methods (regular grid) for**: - Final publication
results - Critical policy decisions - Small grids (n_grid ≤ 10, cost is
low) - When exact bounds are required

## Combining with Parallel Processing

All grid methods benefit from parallelization:

``` r

# LHS + Parallel = Fastest combination
bounds_fast <- bound_ne(
  data = data,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = c("C1", "C2"),
  misclassified_variable = "exposure",
  sensitivity_region = sens_region,
  n_grid = 50,
  grid_method = "lhs", # 99% fewer evaluations
  parallel = TRUE, # Additional speedup
  n_cores = 8,
  verbose = TRUE
)

# Expected time: ~10-20 seconds
# vs. ~30 hours with sequential regular grid
```

**Performance multipliers**: - LHS alone: 50-100x faster - Parallel (8
cores): 5-7x faster - **Combined: 250-700x faster!**

## Selection Guide

## Algorithm Implementation Details

### Reproducibility

**Sampling methods** (LHS, Sobol):

``` r

# Set seed for reproducibility
set.seed(42)
bounds1 <- bound_ne(..., grid_method = "lhs")

set.seed(42)
bounds2 <- bound_ne(..., grid_method = "lhs")

# bounds1 and bounds2 will be identical
```

**Sobol sequences**: Deterministic, no seed needed for reproducibility.

### Memory Efficiency

All methods use: - **Pre-computed probabilities**: Calculate observed
distributions once - **Vectorized operations**: Process combinations in
batches - **Early termination**: Stop evaluation at first constraint
violation - **Streaming results**: Don’t store incompatible parameter
sets

### Computational Complexity

Where: - n_grid: grid resolution - n_coarse: coarse grid size (typically
3-5) - k: proportion of compatible coarse regions - n_boundary: points
near boundaries - n_compatible: number of compatible parameter sets
(stored)

## Practical Examples

### Example 1: Quick sensitivity check

``` r

# 30-second sensitivity check
bounds <- bound_ne(
  data = mydata,
  exposure = "treatment",
  mediator = "mediator_measure",
  outcome = "outcome",
  confounders = c("age", "sex", "baseline"),
  misclassified_variable = "mediator",
  sensitivity_region = list(
    sn0_range = c(0.7, 0.9),
    sp0_range = c(0.7, 0.9),
    psi_sn_range = c(0.8, 1.5),
    psi_sp_range = c(0.8, 1.5)
  ),
  n_grid = 20,
  grid_method = "lhs" # Fast
)
```

### Example 2: Publication-ready analysis

``` r

# High-resolution exact bounds
bounds_pub <- bound_ne(
  data = mydata,
  exposure = "treatment",
  mediator = "mediator_measure",
  outcome = "outcome",
  confounders = c("age", "sex", "baseline"),
  misclassified_variable = "mediator",
  sensitivity_region = list(
    sn0_range = c(0.7, 0.9),
    sp0_range = c(0.7, 0.9),
    psi_sn_range = c(0.8, 1.5),
    psi_sp_range = c(0.8, 1.5)
  ),
  n_grid = 100, # High resolution
  grid_method = "regular", # Exact
  parallel = TRUE,
  n_cores = 8,
  bootstrap = TRUE, # Add CIs
  bootstrap_reps = 1000
)
```

### Example 3: Comparing methods

``` r

# Compare different grid methods
methods <- c("lhs", "sobol", "binary", "regular")
results <- list()

for (method in methods) {
  cat("\nTesting method:", method, "\n")

  results[[method]] <- system.time({
    bounds <- bound_ne(
      data = mydata,
      exposure = "A_star",
      mediator = "M",
      outcome = "Y",
      confounders = c("C1", "C2"),
      misclassified_variable = "exposure",
      sensitivity_region = sens_region,
      n_grid = 10,
      grid_method = method,
      verbose = FALSE
    )
  })

  cat("  Time:", results[[method]]["elapsed"], "seconds\n")
  cat("  NIE bounds:", bounds@NIE_lower, "-", bounds@NIE_upper, "\n")
  cat("  NDE bounds:", bounds@NDE_lower, "-", bounds@NDE_upper, "\n")
}
```

## Future Enhancements

Potential algorithm additions:

1.  **Bayesian Optimization**: Learn from evaluations to guide search
    toward optimal regions
2.  **Particle Swarm**: Use swarm intelligence for global optimization
3.  **Gradient-based methods**: When bounds are differentiable
4.  **Hybrid approaches**: Combine methods (e.g., Sobol initialization +
    adaptive refinement)
5.  **Uncertainty-guided sampling**: Add points where bound uncertainty
    is highest

## References

McKay, M. D., Beckman, R. J., & Conover, W. J. (1979). A comparison of
three methods for selecting values of input variables in the analysis of
output from a computer code. *Technometrics*, 21(2), 239-245.
<https://doi.org/10.2307/1268522>

Sobol’, I. M. (1967). On the distribution of points in a cube and the
approximate evaluation of integrals. *USSR Computational Mathematics and
Mathematical Physics*, 7(4), 86-112.
<https://doi.org/10.1016/0041-5553(67)90144-9>

## Session Information

``` r

sessionInfo()
```
