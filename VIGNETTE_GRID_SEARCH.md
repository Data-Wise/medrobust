# New Vignette: Advanced Grid Search Algorithms

## Summary

Created a comprehensive vignette documenting all 6 grid search
algorithms available in
[`bound_ne()`](https://data-wise.github.io/medrobust/reference/bound_ne.md).

## File Created

**vignettes/grid-search-algorithms.qmd**

## Vignette Contents

### 1. Overview

- Explains the computational challenge (O(n_grid^4) complexity)
- Introduces smart sampling as solution
- Key insight: 90-99% reduction in evaluations

### 2. The Computational Challenge

- **Exponential Complexity**: Table showing n_grid vs evaluations vs
  time
- **The Solution**: Smart sampling strategies explained

### 3. Detailed Method Descriptions

Each of the 6 methods gets comprehensive coverage:

#### Latin Hypercube Sampling (LHS) - Default

- What it is
- How it works (4-step process)
- Performance metrics table
- When to use
- Code example

#### Regular Grid

- Exhaustive evaluation
- When to use (exact bounds needed)
- Code example

#### Sobol Sequences

- Low-discrepancy sequences
- Differences from LHS
- When to use
- Code example

#### Adaptive Grid

- Two-stage coarse-to-fine
- How it works (3 steps)
- When to use (high falsification)
- Code example

#### Binary Search on Bounds

- Find boundaries efficiently
- How it works (4 steps)
- Limitations (assumes monotonicity)
- Code example

#### Auto-Selection

- Automatic method selection
- Decision tree logic
- Probing strategy
- Code example

### 4. Performance Comparison

Two detailed comparison tables:

**Table 1: Small Grid (n_grid=10)** - Method \| Time \| Evaluations \|
Speedup \| NIE Bounds \| NDE Bounds - Shows LHS is 67x faster -
Demonstrates similar bound accuracy

**Table 2: Large Grid (n_grid=50)** - Method \| Evaluations \| Est. Time
\| Speedup - Shows LHS is ~9,000x faster - 270 hours → 1.8 minutes

### 5. Recommended Workflow

Three-stage analysis approach:

**Stage 1: Quick Exploration** - Use LHS with n_grid=20 - ~30 seconds -
Full code example

**Stage 2: Refinement** - Use auto-selection with n_grid=50 - ~2
minutes - Full code example

**Stage 3: Publication-Quality** - Use regular grid with n_grid=100 -
Parallel processing - ~10-20 minutes - Full code example

### 6. Accuracy vs. Speed Trade-offs

**Bound Width Differences Table** - Comparison \| Typical Difference \|
Acceptable For

**When is approximation acceptable?** - ✅ Use cases for sampling
methods - ❌ Use cases for exact methods

### 7. Combining with Parallel Processing

- Code example: LHS + parallel
- Performance multipliers explained
- Combined speedup: 250-700x!

### 8. Selection Guide Table

Scenario \| Recommended Method \| Reason \|

- 7 different scenarios covered
- Clear recommendations for each

### 9. Algorithm Implementation Details

**Reproducibility** - Setting seed for LHS - Sobol deterministic
behavior

**Memory Efficiency** - Pre-computed probabilities - Vectorized
operations - Early termination - Streaming results

**Computational Complexity Table** - Time complexity for each method -
Space complexity (all O(n_compatible))

### 10. Practical Examples

Three complete examples:

**Example 1: Quick sensitivity check** - 30-second analysis - Full code

**Example 2: Publication-ready analysis** - High-resolution exact
bounds - Bootstrap CIs - Full code

**Example 3: Comparing methods** - Loop over all methods - Timing
comparison - Full code

### 11. Future Enhancements

5 potential additions: 1. Bayesian Optimization 2. Particle Swarm 3.
Gradient-based methods 4. Hybrid approaches 5. Uncertainty-guided
sampling

### 12. References

Full citations with DOIs: - McKay et al. (1979) - LHS paper - Sobol’
(1967) - Sobol sequences paper

### 13. Session Information

Standard R session info

## Key Features

### Comprehensive Coverage

- All 6 methods documented
- Performance comparisons with real data
- Clear guidance on method selection

### Practical Focus

- Multiple complete code examples
- Three-stage workflow recommendation
- Selection guide table

### Performance Emphasis

- Multiple performance comparison tables
- Concrete timing estimates
- Speedup calculations

### Pedagogical Structure

- Starts with problem (computational challenge)
- Explains each solution (algorithm)
- Shows how to apply (examples)
- Guides decision-making (selection guide)

## Vignette Metadata

``` yaml
title: "Advanced Grid Search Algorithms"
subtitle: "Optimizing Computational Performance in medrobust"
author: "medrobust package"
date: today
format:
  html:
    toc: true
    toc-depth: 3
    code-fold: false
    theme: cosmo
```

**VignetteIndexEntry**: “Advanced Grid Search Algorithms”

## Rendering

The vignette: - Uses `devtools::load_all()` for development mode -
Compatible with quarto rendering - Produces HTML output with TOC - All
code chunks are executable (eval: false where needed)

## Integration with Package

### DESCRIPTION file

- VignetteBuilder: quarto (already set)
- No changes needed

### Vignette Discovery

Once installed, users can access via:

``` r

vignette("grid-search-algorithms", package = "medrobust")
```

Or browse all vignettes:

``` r

browseVignettes("medrobust")
```

## Relationship to Other Documentation

### Complements introduction.qmd

- Introduction: Basic usage, simple examples
- Grid search vignette: Deep dive into performance optimization

### Complements GRID_SEARCH_ALGORITHMS.md

- Markdown doc: Technical reference
- Vignette: Tutorial with examples and narrative

### Complements function documentation

- ?bound_ne: Parameter reference
- Vignette: How to choose parameters in practice

## Value to Users

### For New Users

- Understand default choice (LHS)
- See concrete performance gains
- Learn when to use other methods

### For Advanced Users

- Deep understanding of algorithms
- Performance optimization strategies
- Computational budgeting

### For Contributors

- Implementation details
- Complexity analysis
- Future enhancement ideas

## Statistics

- **Lines**: ~660
- **Code chunks**: ~15
- **Tables**: 6
- **Complete examples**: 3
- **Methods documented**: 6
- **References**: 2

## Next Steps (for user)

1.  ✅ Render vignette successfully
2.  Review vignette content
3.  Add to pkgdown configuration (if using pkgdown)
4.  Consider adding to README “Get Started” section
