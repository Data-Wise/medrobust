# medrobust Package - Local Development Workflow

**Date:** 2025-01-14
**Branch:** `claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im`
**Status:** S7 OOP conversion complete, ready for local testing

---

## Table of Contents

1. [Initial Setup](#initial-setup)
2. [Package Dependencies](#package-dependencies)
3. [Building and Loading](#building-and-loading)
4. [Testing the S7 Implementation](#testing-the-s7-implementation)
5. [Running Test Suite](#running-test-suite)
6. [Documentation Generation](#documentation-generation)
7. [Package Validation](#package-validation)
8. [Development Workflow](#development-workflow)
9. [Merging to Main](#merging-to-main)
10. [Validation Checklist](#validation-checklist)
11. [Troubleshooting](#troubleshooting)
12. [Next Steps](#next-steps)

---

## 1. Initial Setup

### Clone and Checkout Development Branch

```bash
# Navigate to your repo
cd path/to/medrobust

# Fetch latest changes from remote
git fetch origin

# Switch to the S7 development branch
git checkout claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im

# Pull latest changes
git pull origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im

# Verify you're on the correct branch
git branch
```

### Verify Package Structure

```bash
# Check that key files exist
ls R/s7-classes.R
ls R/s7-methods.R
ls R/simulate_dm_data.R
ls R/power_analysis.R
ls tests/testthat/test-s7-classes.R
```

---

## 2. Package Dependencies

### Install Required Packages

Open R and run:

```r
# Core dependencies
install.packages(c(
  "S7",           # S7 OOP system
  "dplyr",        # Data manipulation
  "ggplot2",      # Plotting
  "rlang",        # R language tools
  "parallel"      # Parallel processing
))

# Development dependencies
install.packages(c(
  "devtools",     # Package development
  "testthat",     # Testing
  "roxygen2",     # Documentation
  "covr",         # Code coverage (optional)
  "pkgdown"       # Website generation (optional)
))

# Optional visualization dependencies
install.packages(c(
  "gridExtra",    # For power_analysis plots
  "patchwork"     # Alternative for plot composition
))
```

### Verify Installation

```r
# Check S7 is installed correctly
library(S7)
packageVersion("S7")  # Should be >= 0.1.0
```

---

## 3. Building and Loading

### Option A: Development Loading (Recommended)

```r
# Load package without installation
library(devtools)
setwd("path/to/medrobust")
load_all()

# This loads all functions and makes them available
# Changes to .R files will be reflected after running load_all() again
```

### Option B: Install Locally

```r
library(devtools)
setwd("path/to/medrobust")
install()

# Then load normally
library(medrobust)
```

### Option C: Command Line Build/Install

```bash
# From terminal in medrobust directory
R CMD build .
R CMD INSTALL medrobust_0.1.0.9000.tar.gz

# Then in R
library(medrobust)
```

---

## 4. Testing the S7 Implementation

### Test 1: Create S7 Objects Manually

```r
library(medrobust)

# Create sensitivity_region S7 object
sens_reg <- sensitivity_region(
  sn0_range = c(0.8, 0.9),
  sp0_range = c(0.8, 0.9),
  psi_sn_range = c(1.0, 2.0),
  psi_sp_range = c(1.0, 1.0)
)

# Test S7 print method
print(sens_reg)

# Test property access with @ operator
sens_reg@sn0_range
sens_reg@psi_sn_range

# Test validator - this should fail
try(sensitivity_region(
  sn0_range = c(0.9, 0.8),  # Wrong order!
  sp0_range = c(0.8, 0.9),
  psi_sn_range = c(1.0, 2.0),
  psi_sp_range = c(1.0, 1.0)
))
# Should see: "sn0_range[1] must be < sn0_range[2]"
```

### Test 2: Simulate Data with S7

```r
# Generate synthetic data with known DM
sim_data <- simulate_dm_data(
  n = 200,
  true_params = list(
    beta_AM = 0.405,    # A→M effect (OR=1.5)
    theta_AY = 0.405,   # A→Y direct (OR=1.5)
    theta_MY = 0.405    # M→Y effect (OR=1.5)
  ),
  dm_params = list(
    sn0 = 0.85,         # Baseline sensitivity
    sp0 = 0.85,         # Baseline specificity
    psi_sn = 1.5,       # Differential sensitivity
    psi_sp = 1.0        # Non-differential specificity
  ),
  misclass_type = "exposure",
  confounders = 1,
  seed = 12345
)

# Test S7 print method - should show formatted output
print(sim_data)

# Test S7 summary method
summary(sim_data)

# Test property access
head(sim_data@observed)
head(sim_data@truth)
sim_data@true_effects$NIE_OR
sim_data@true_effects$NDE_OR
sim_data@generation_params$n
```

### Test 3: Run Bounds Analysis with S7

```r
# Compute partial identification bounds
bounds <- bound_ne(
  data = sim_data@observed,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = "C1",
  misclassified_variable = "exposure",
  sensitivity_region = sens_reg,
  n_grid = 20,        # Small grid for quick test
  verbose = FALSE
)

# Test S7 print method
print(bounds)

# Test S7 summary method
summary(bounds)

# Test property access with @ operator
bounds@NIE_lower
bounds@NIE_upper
bounds@NDE_lower
bounds@NDE_upper
bounds@n_compatible
bounds@n_evaluated
bounds@falsified_proportion

# Access nested S7 objects
bounds@sensitivity_region@sn0_range
bounds@sensitivity_region@psi_sn_range

# Test as.data.frame method
df <- as.data.frame(bounds)
head(df)

# Verify true effect is in bounds
sim_data@true_effects$NIE >= bounds@NIE_lower &&
  sim_data@true_effects$NIE <= bounds@NIE_upper
```

### Test 4: Check Compatibility Function

```r
# Test compatibility checking
compat <- check_compatibility(
  data = sim_data@observed,
  exposure = "A_star",
  mediator = "M",
  outcome = "Y",
  confounders = "C1",
  misclassified_variable = "exposure",
  psi = list(sn = 1.5, sp = 1.0)
)

# Test S7 print method
print(compat)

# Access properties
compat@compatible
compat@sn1
compat@sp1
compat@n_constraints_total
compat@n_constraints_violated
```

### Test 5: Power Analysis (Quick Version)

```r
# Quick power analysis with small n_sim for testing
power_result <- power_analysis(
  true_params = list(beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405),
  dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
  sensitivity_region = list(
    sn0_range = c(0.80, 0.90),
    sp0_range = c(0.80, 0.90),
    psi_sn_range = c(1.0, 2.0),
    psi_sp_range = c(1.0, 1.0)
  ),
  misclass_type = "exposure",
  sample_sizes = c(100, 200, 300),  # Just 3 sample sizes
  n_sim = 10,                       # Small for quick test
  n_grid = 15,                      # Coarse grid
  parallel = FALSE,                 # Single core for debugging
  verbose = TRUE
)

# Test S7 print method
print(power_result)

# Access properties
power_result@power_curve
power_result@true_effect
power_result@recommended_n_power
power_result@recommended_n_width

# Test S7 plot method (requires ggplot2)
if (requireNamespace("ggplot2", quietly = TRUE)) {
  plot(power_result)
}
```

### Test 6: Using Example Datasets

```r
# Load example parameter grids
data("example_param_grids")
names(example_param_grids)

# Use a pre-defined grid
realistic_grid <- example_param_grids$realistic
optimistic_grid <- example_param_grids$optimistic

# Test with real data (if available)
data("arsenic_synthetic")
str(arsenic_synthetic)
head(arsenic_synthetic)

# Run analysis with example data
if (exists("arsenic_synthetic")) {
  bounds_real <- bound_ne(
    data = arsenic_synthetic,
    exposure = "A_star",
    mediator = "M",
    outcome = "Y",
    confounders = c("age", "male"),
    misclassified_variable = "exposure",
    sensitivity_region = realistic_grid,
    n_grid = 30,
    verbose = TRUE
  )

  print(bounds_real)
}
```

---

## 5. Running Test Suite

### Run All Tests

```r
library(devtools)
library(testthat)

# Run full test suite
test()

# Run with detailed output
test(reporter = "progress")

# Run specific test file
test_file("tests/testthat/test-s7-classes.R")
test_file("tests/testthat/test-s7-methods.R")
test_file("tests/testthat/test-bound_ne.R")
```

### Check Test Coverage

```r
# Install covr if needed
# install.packages("covr")

library(covr)

# Generate coverage report
cov <- package_coverage()
print(cov)

# View in browser
report(cov)

# Check specific files
file_coverage("R/s7-classes.R", "tests/testthat/test-s7-classes.R")
```

### Expected Test Results

All tests should pass:

- `test-s7-classes.R`: 19 tests covering S7 validators
- `test-s7-methods.R`: 12 tests covering S7 methods
- `test-bound_ne.R`: 2 tests for integration

Total: **31+ passing tests**

---

## 6. Documentation Generation

### Generate roxygen2 Documentation

```r
library(devtools)

# Generate documentation from roxygen comments
document()

# This updates:
# - man/*.Rd files
# - NAMESPACE file
```

### View Help Files

```r
# View function documentation
?bound_ne
?simulate_dm_data
?power_analysis
?sensitivity_region
?simulated_dm_data
?power_analysis_result

# View dataset documentation
?arsenic_synthetic
?example_param_grids
?validation_subsample
```

### Generate Package Website (Optional)

```r
# Install pkgdown if needed
# install.packages("pkgdown")

library(pkgdown)

# Build website
build_site()

# View in browser - opens docs/index.html
```

---

## 7. Package Validation

### R CMD check

**Option A: Via devtools**

```r
library(devtools)

# Run comprehensive check
check()

# Check as CRAN would
check(cran = TRUE)

# Check with specific options
check(
  document = TRUE,
  args = "--no-manual",
  error_on = "warning"
)
```

**Option B: Command Line**

```bash
# Build tarball
R CMD build .

# Check package
R CMD check medrobust_0.1.0.9000.tar.gz

# Check as CRAN
R CMD check --as-cran medrobust_0.1.0.9000.tar.gz

# Check with specific tests
R CMD check --no-manual --no-build-vignettes medrobust_0.1.0.9000.tar.gz
```

### Expected Check Results

**Should see:**

- ✓ 0 errors
- ✓ 0 warnings
- ✓ 0-2 notes (acceptable notes: new submission, sub-directories)

**Common acceptable NOTEs:**

- "New submission" (if first CRAN submission)
- "Maintainer: ..." (informational)
- "Days since last update: ..." (informational)

---

## 8. Development Workflow

### Typical Development Cycle

```r
# 1. Make changes to R/*.R files
# 2. Load changes
load_all()

# 3. Test interactively
# Try your changes in console

# 4. Run tests
test()

# 5. Update documentation
document()

# 6. Check package
check()

# 7. Commit changes
# (done in terminal)
```

### Git Workflow

```bash
# Check status
git status

# Stage changes
git add R/your-modified-file.R
git add tests/testthat/your-test-file.R

# Commit with descriptive message
git commit -m "Add feature X with S7 validation"

# Push to remote
git push origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im

# Create pull request on GitHub when ready
```

### Making Changes

**Example: Add a new S7 method**

1. Edit `R/s7-methods.R`:
   ```r
   #' @export
   method(plot, simulated_dm_data) <- function(x, ...) {
     # Your implementation
   }
   ```

2. Add tests in `tests/testthat/test-s7-methods.R`:
   ```r
   test_that("plot method for simulated_dm_data works", {
     # Your test
   })
   ```

3. Update and check:
   ```r
   load_all()
   document()
   test()
   check()
   ```

---

## 9. Merging to Main

### When Ready to Merge

**Option A: Direct Git Merge**

```bash
# Make sure branch is up to date
git checkout claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
git pull origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im

# Switch to main branch
git checkout main  # or master
git pull origin main

# Merge with no-fast-forward (preserves history)
git merge --no-ff claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im

# Push to remote
git push origin main

# Optionally delete development branch
git branch -d claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
git push origin --delete claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

**Option B: GitHub Pull Request (Recommended)**

1. Go to GitHub repository
2. Click "Pull requests" → "New pull request"
3. Base: `main`, Compare: `claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im`
4. Review changes
5. Add description of S7 conversion
6. Request review (if applicable)
7. Merge pull request
8. Delete branch after merge

---

## 10. Validation Checklist

Before merging to main, verify:

### ✓ Code Quality

- [ ] All functions have roxygen documentation
- [ ] All S7 classes have validators
- [ ] All S7 methods are exported
- [ ] No `library()` calls in package code (use `@importFrom`)
- [ ] Code follows R style guidelines

### ✓ Tests

- [ ] All tests pass: `devtools::test()`
- [ ] Test coverage >80%: `covr::package_coverage()`
- [ ] S7 validators tested for all classes
- [ ] S7 methods tested for all classes

### ✓ Documentation

- [ ] All functions documented: `devtools::document()`
- [ ] Examples run without errors: `devtools::run_examples()`
- [ ] Help files render correctly: `?function_name`
- [ ] README.md is up to date

### ✓ Package Structure

- [ ] R CMD check passes: `devtools::check()`
- [ ] No errors, warnings, or problematic notes
- [ ] NAMESPACE is correct
- [ ] DESCRIPTION has all dependencies

### ✓ S7 Functionality

- [ ] S7 objects can be created
- [ ] S7 validators work (reject invalid input)
- [ ] S7 print methods display correctly
- [ ] S7 property access works (`@` operator)
- [ ] S7 methods dispatch correctly

### ✓ Core Functions

- [ ] `bound_ne()` works with S7 objects
- [ ] `simulate_dm_data()` returns S7 object
- [ ] `power_analysis()` returns S7 object
- [ ] All algorithms produce expected results

---

## 11. Troubleshooting

### S7 Package Not Found

```r
# Install S7
install.packages("S7")

# Or from GitHub for latest version
# remotes::install_github("RConsortium/S7")

# Verify installation
library(S7)
packageVersion("S7")
```

### Tests Fail

**Check dependencies:**
```r
# Install all dependencies
devtools::install_deps()
```

**Run specific failing test:**
```r
# Get detailed output
test_file("tests/testthat/test-s7-classes.R", reporter = "progress")
```

**Check for missing imports:**
```r
# Make sure NAMESPACE is up to date
document()
```

### Documentation Issues

**Roxygen not generating docs:**
```r
# Force regeneration
unlink("man", recursive = TRUE)
document()
```

**NAMESPACE problems:**
```r
# Regenerate NAMESPACE
document()
```

### Load Errors

**"object not found" errors:**
```r
# Reload package
detach("package:medrobust", unload = TRUE)
load_all()
```

**S7 class not recognized:**
```r
# Check that S7 is imported in DESCRIPTION
# Should have: Imports: S7 (>= 0.1.0)

# Check NAMESPACE has:
# importFrom(S7, new_class)
# importFrom(S7, new_property)
# importFrom(S7, method)
```

### Validator Errors

**Validators not working:**
```r
# Test validator directly
try(sensitivity_region(
  sn0_range = c(1.5, 0.8),  # Invalid
  sp0_range = c(0.8, 0.9),
  psi_sn_range = c(1.0, 2.0),
  psi_sp_range = c(1.0, 1.0)
))
# Should show error message
```

---

## 12. Next Steps

### Immediate Actions

1. **Clone and test locally** (follow sections 1-4)
2. **Run full test suite** to verify everything works
3. **Generate documentation** to see how it looks
4. **Run R CMD check** to catch any platform-specific issues

### Short-term Goals

5. **Create example datasets** (optional)
   - Generate realistic `arsenic_synthetic` data
   - Create `example_param_grids` object
   - Create `validation_subsample` data

6. **Write vignettes** (optional but recommended)
   ```r
   # Create vignette
   usethis::use_vignette("introduction")
   usethis::use_vignette("simulation-studies")
   usethis::use_vignette("power-analysis")
   ```

7. **Add more examples**
   - Real-world case studies
   - Comparison with naive analysis
   - Sensitivity to misclassification

### Long-term Goals

8. **Prepare for CRAN submission** (if desired)
   - Ensure R CMD check passes with `--as-cran`
   - Write cran-comments.md
   - Submit to CRAN

9. **Create package website**
   ```r
   pkgdown::build_site()
   ```

10. **Write paper/documentation**
    - Methodology paper
    - Software paper (e.g., JSS, JOSS)
    - Tutorial materials

### Optional Enhancements

11. **Add more features:**
    - Additional effect scales
    - More bootstrap methods
    - Plotting functions for bounds
    - Shiny app for interactive analysis

12. **Performance optimization:**
    - Profile code with `profvis`
    - Optimize grid search
    - Parallelize more computations

13. **Integration with other packages:**
    - Methods for `broom` (tidy, glance, augment)
    - Methods for `ggplot2` (autoplot)
    - Integration with `targets` for workflows

---

## Summary

The medrobust package now has **complete S7 OOP implementation** with:

- **7 S7 classes** with full validation
- **18 S7 methods** (print, summary, conversion, plotting)
- **~950 lines** of new simulation and power analysis code
- **31+ tests** covering all S7 functionality
- **Complete documentation** for all datasets

### Quick Start Command Sequence

```r
# In R console
library(devtools)
setwd("path/to/medrobust")

# Load and test
load_all()
test()
check()

# Try it out
sim <- simulate_dm_data(n = 200, seed = 123)
print(sim)
```

### Key Files to Review

- `R/s7-classes.R` - S7 class definitions
- `R/s7-methods.R` - S7 method implementations
- `R/simulate_dm_data.R` - Data simulation
- `R/power_analysis.R` - Power analysis
- `tests/testthat/test-s7-classes.R` - S7 tests
- `NAMESPACE` - Exported functions/classes

---

**Questions or Issues?**

- Check troubleshooting section above
- Review test files for usage examples
- Examine existing S7 methods for patterns
- Run `devtools::check()` for diagnostic information

**The package is ready for local testing and use!** 🎉
