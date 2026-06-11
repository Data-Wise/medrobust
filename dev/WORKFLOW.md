# medrobust Package - Local Development Workflow

**Date:** 2025-01-14 **Branch:**
`claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im`
**Status:** S7 OOP conversion complete, ready for local testing

**Development Tools:** renv (reproducible environments), Quarto (modern
vignettes), S7 (OOP system)

------------------------------------------------------------------------

## Table of Contents

1.  [Initial Setup](#initial-setup)
2.  [renv Setup (Reproducible
    Environment)](#renv-setup-reproducible-environment)
3.  [Package Dependencies](#package-dependencies)
4.  [Building and Loading](#building-and-loading)
5.  [Testing the S7 Implementation](#testing-the-s7-implementation)
6.  [Running Test Suite](#running-test-suite)
7.  [Documentation Generation](#documentation-generation)
8.  [Package Validation](#package-validation)
9.  [Development Workflow](#development-workflow)
10. [Local Editing and Git Workflow](#local-editing-and-git-workflow)
11. [Merging to Main](#merging-to-main)
12. [Validation Checklist](#validation-checklist)
13. [Troubleshooting](#troubleshooting)
14. [Next Steps](#next-steps)

------------------------------------------------------------------------

## Overview: Complete Development Workflow

This document guides you through local development of the medrobust R
package using modern tools:

### 🔄 Typical Development Session

``` bash
# 1. Pull latest changes
git pull origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

``` r

# 2. Restore packages (if renv.lock changed)
renv::restore()

# 3. Load package for development
library(devtools)
load_all()

# 4. Make your changes to R/*.R files
# 5. Test interactively
# Try your changes in console...

# 6. Run tests
test()

# 7. Update documentation
document()

# 8. Check package
check()

# 9. Update renv if you installed packages
renv::snapshot()
```

``` bash
# 10. Commit and push
git add .
git commit -m "Your descriptive message"
git push origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

### 📚 Key Resources

- **`RENV_SETUP.md`** - Reproducible environment setup and
  troubleshooting
- **`QUARTO_VIGNETTES_SETUP.md`** - Creating modern vignettes with
  Quarto
- **This file (`WORKFLOW.md`)** - Complete local development workflow

### 🎯 Quick Navigation

- **First time setup?** → Start with [Initial
  Setup](#id_1-initial-setup) and [renv
  Setup](#id_2-renv-setup-reproducible-environment)
- **Want to make changes?** → See [Local Editing and Git
  Workflow](#id_10-local-editing-and-git-workflow)
- **Having problems?** → Check [Troubleshooting](#id_13-troubleshooting)
- **Ready to merge?** → See [Merging to Main](#id_11-merging-to-main)

------------------------------------------------------------------------

## 1. Initial Setup

### Clone and Checkout Development Branch

``` bash
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

``` bash
# Check that key files exist
ls R/s7-classes.R
ls R/s7-methods.R
ls R/simulate_dm_data.R
ls R/power_analysis.R
ls tests/testthat/test-s7-classes.R
ls RENV_SETUP.md
ls QUARTO_VIGNETTES_SETUP.md
```

------------------------------------------------------------------------

## 2. renv Setup (Reproducible Environment)

### Why renv?

This package uses **renv** for reproducible package development: - ✅
All developers use the same package versions - ✅ Isolated from system R
library - ✅ Easy rollback if updates break things - ✅ Simplified CI/CD
setup

**📖 See `RENV_SETUP.md` for comprehensive renv documentation.**

### Initialize renv (First Time Only)

``` r

# Install renv if not already installed
install.packages("renv")

# Navigate to medrobust directory
setwd("path/to/medrobust")

# Initialize renv (creates renv/ directory and renv.lock)
renv::init()

# This will:
# - Create renv/library/ (project-specific packages)
# - Create renv.lock (package versions)
# - Create .Rprofile (activates renv on startup)
# - Scan DESCRIPTION and install dependencies
```

### Restore Environment (Subsequent Times)

``` r

# When you open the project, renv activates automatically
# If packages are out of sync with renv.lock:

renv::restore()

# This installs all packages from renv.lock to match other developers
```

### Daily renv Usage

``` r

# Check status (compares installed vs. renv.lock)
renv::status()

# After installing new packages, update renv.lock
renv::snapshot()

# Commit renv.lock to git after snapshot
```

------------------------------------------------------------------------

## 3. Package Dependencies

### Option A: Using renv (Recommended)

``` r

# renv automatically installs dependencies from DESCRIPTION
# when you run renv::init() or renv::restore()

# Check what's installed
renv::status()

# Install additional development tools
renv::install(c(
  "devtools",
  "testthat",
  "roxygen2",
  "covr",
  "pkgdown",
  "quarto"
))

# Update renv.lock after installing
renv::snapshot()
```

### Option B: Manual Installation (Without renv)

``` r

# Core dependencies (from DESCRIPTION)
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
```

### Verify Installation

``` r

# Check S7 is installed correctly
library(S7)
packageVersion("S7")  # Should be >= 0.1.0

# Check renv status (if using renv)
renv::status()  # Should show "No issues found"
```

------------------------------------------------------------------------

## 4. Building and Loading

### Option A: Development Loading (Recommended)

``` r

# Load package without installation
library(devtools)
setwd("path/to/medrobust")
load_all()

# This loads all functions and makes them available
# Changes to .R files will be reflected after running load_all() again
```

### Option B: Install Locally

``` r

library(devtools)
setwd("path/to/medrobust")
install()

# Then load normally
library(medrobust)
```

### Option C: Command Line Build/Install

``` bash
# From terminal in medrobust directory
R CMD build .
R CMD INSTALL medrobust_0.1.0.9000.tar.gz

# Then in R
library(medrobust)
```

------------------------------------------------------------------------

## 5. Testing the S7 Implementation

### Test 1: Create S7 Objects Manually

``` r

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

``` r

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

``` r

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

``` r

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

``` r

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

``` r

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

------------------------------------------------------------------------

## 6. Running Test Suite

### Run All Tests

``` r

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

``` r

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

------------------------------------------------------------------------

## 7. Documentation Generation

### Generate roxygen2 Documentation

``` r

library(devtools)

# Generate documentation from roxygen comments
document()

# This updates:
# - man/*.Rd files
# - NAMESPACE file
```

### View Help Files

``` r

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

``` r

# Install pkgdown if needed
# install.packages("pkgdown")

library(pkgdown)

# Build website
build_site()

# View in browser - opens docs/index.html
```

------------------------------------------------------------------------

## 8. Package Validation

### R CMD check

**Option A: Via devtools**

``` r

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

``` bash
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

- [x] 0 errors
- [x] 0 warnings
- [x] 0-2 notes (acceptable notes: new submission, sub-directories)

**Common acceptable NOTEs:**

- “New submission” (if first CRAN submission)
- “Maintainer: …” (informational)
- “Days since last update: …” (informational)

------------------------------------------------------------------------

## 9. Development Workflow

### Typical Development Cycle (with renv)

This is the complete cycle for making changes to the package:

``` r

# 1. Start R session - renv activates automatically
# 2. Check environment is in sync
renv::status()

# 3. If needed, restore packages
renv::restore()

# 4. Load package for development
library(devtools)
load_all()

# 5. Make changes to R/*.R files in your editor
# 6. Reload changes
load_all()

# 7. Test interactively in console
# Try your changes...

# 8. Run automated tests
test()

# 9. Update documentation
document()

# 10. Check package
check()

# 11. If you installed new packages, update renv.lock
renv::snapshot()

# 12. Commit changes (done in terminal - see next section)
```

### Quick Development Loop

For rapid iteration:

``` r

# Edit R files → Save
load_all()  # Reload
# Test in console
# Repeat
```

### Before Committing Checklist

``` r

# 1. Load latest changes
load_all()

# 2. All tests pass
test()

# 3. Documentation up to date
document()

# 4. Package checks clean
check()

# 5. renv.lock up to date (if you installed packages)
renv::snapshot()

# 6. Check git status
system("git status")
```

------------------------------------------------------------------------

## 10. Local Editing and Git Workflow

### Making Local Changes to Files

#### Step 1: Edit Files in Your Editor

You can edit any file in the package using your preferred editor: - **R
code**: `R/*.R` files - **Tests**: `tests/testthat/*.R` files -
**Documentation**: Roxygen comments in R files - **Vignettes**:
`vignettes/*.qmd` files (see `QUARTO_VIGNETTES_SETUP.md`) -
**Configuration**: `DESCRIPTION`, `NAMESPACE` (auto-generated)

**Example: Adding a new function**

1.  Create or edit file: `R/my_new_function.R`

    ``` r

    #' Title of My Function
    #'
    #' @description
    #' Description of what it does
    #'
    #' @param x Description of parameter
    #' @return Description of return value
    #' @export
    #'
    #' @examples
    #' my_new_function(x = 5)
    my_new_function <- function(x) {
      # Implementation
      x * 2
    }
    ```

2.  Test it:

    ``` r

    load_all()
    my_new_function(5)
    ```

3.  Add tests in `tests/testthat/test-my_new_function.R`:

    ``` r

    test_that("my_new_function works", {
      expect_equal(my_new_function(5), 10)
      expect_equal(my_new_function(0), 0)
    })
    ```

4.  Update documentation:

    ``` r

    document()
    ```

#### Step 2: Check Your Changes

``` r

# Load and test
load_all()
test()

# Generate documentation
document()

# Run R CMD check
check()
```

### Git Workflow: Committing Changes

#### Basic Git Commands

``` bash
# 1. Check what files changed
git status

# 2. View changes in detail
git diff

# 3. Stage specific files
git add R/my_new_function.R
git add tests/testthat/test-my_new_function.R
git add man/my_new_function.Rd  # Auto-generated by document()

# Or stage all modified files
git add -u

# 4. Commit with clear message
git commit -m "Add my_new_function for computing X

- Implements algorithm for X
- Adds comprehensive tests
- Includes documentation and examples"

# 5. Push to remote
git push origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

#### Committing renv Changes

If you installed/updated packages:

``` bash
# After renv::snapshot(), commit the lock file
git add renv.lock
git commit -m "Update package dependencies

- Add ggplot2 for visualization
- Update dplyr to 1.1.4"
git push origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

### Git Workflow: Pulling Changes

When other developers (or Claude) make changes:

``` bash
# 1. Fetch and pull latest changes
git pull origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im

# 2. In R, restore packages if renv.lock changed
```

``` r

renv::restore()  # Install packages from updated renv.lock
```

### Complete Example: Adding a New Feature

**Scenario**: Add a plot method for `simulated_dm_data`

``` bash
# In terminal: Make sure you're on right branch
git status
git pull origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

``` r

# In R: Make sure environment is current
renv::restore()
load_all()
```

**Step 1: Edit** `R/s7-methods.R` and add:

``` r

#' Plot Method for simulated_dm_data
#'
#' @export
method(plot, simulated_dm_data) <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 required for plotting")
  }

  # Create plot
  p <- ggplot2::ggplot(x@observed, ggplot2::aes(x = M, y = Y)) +
    ggplot2::geom_point() +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Simulated Data")

  print(p)
  invisible(x)
}
```

**Step 2: Add test** in `tests/testthat/test-s7-methods.R`:

``` r

test_that("plot method for simulated_dm_data works", {
  skip_if_not_installed("ggplot2")

  sim <- simulate_dm_data(n = 50, seed = 123)
  expect_no_error(plot(sim))
})
```

**Step 3: Test locally**

``` r

load_all()

# Try it
sim <- simulate_dm_data(n = 100, seed = 123)
plot(sim)

# Run tests
test()

# Update docs
document()

# Check package
check()
```

**Step 4: Commit and push**

``` bash
git status
git add R/s7-methods.R
git add tests/testthat/test-s7-methods.R
git add man/  # Documentation files
git add NAMESPACE  # May be updated

git commit -m "Add plot method for simulated_dm_data class

- Creates ggplot2 visualization of simulated data
- Adds test coverage for plot method
- Updates documentation"

git push origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

### Troubleshooting Git Push

If push is rejected:

``` bash
# Pull latest changes first
git pull origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im

# Resolve any merge conflicts if they occur
# Then push again
git push origin claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im
```

### Best Practices

- ✅ **Commit frequently** with clear messages
- ✅ **Test before committing** (`test()` and `check()`)
- ✅ **Update renv.lock** after installing packages
  ([`renv::snapshot()`](https://rstudio.github.io/renv/reference/snapshot.html))
- ✅ **Pull before editing** to get latest changes
- ✅ **Push regularly** to backup your work
- ✅ **Use descriptive commit messages** explaining why, not just what

------------------------------------------------------------------------

## 11. Merging to Main

### When Ready to Merge

**Option A: Direct Git Merge**

``` bash
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

1.  Go to GitHub repository
2.  Click “Pull requests” → “New pull request”
3.  Base: `main`, Compare:
    `claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im`
4.  Review changes
5.  Add description of S7 conversion
6.  Request review (if applicable)
7.  Merge pull request
8.  Delete branch after merge

------------------------------------------------------------------------

## 12. Validation Checklist

Before merging to main, verify:

### ✓ Code Quality

All functions have roxygen documentation

All S7 classes have validators

All S7 methods are exported

No [`library()`](https://rdrr.io/r/base/library.html) calls in package
code (use `@importFrom`)

Code follows R style guidelines

### ✓ Tests

All tests pass: `devtools::test()`

Test coverage \>80%:
[`covr::package_coverage()`](http://covr.r-lib.org/reference/package_coverage.md)

S7 validators tested for all classes

S7 methods tested for all classes

### ✓ Documentation

All functions documented: `devtools::document()`

Examples run without errors: `devtools::run_examples()`

Help files render correctly: `?function_name`

README.md is up to date

### ✓ Package Structure

R CMD check passes: `devtools::check()`

No errors, warnings, or problematic notes

NAMESPACE is correct

DESCRIPTION has all dependencies

### ✓ S7 Functionality

S7 objects can be created

S7 validators work (reject invalid input)

S7 print methods display correctly

S7 property access works (`@` operator)

S7 methods dispatch correctly

### ✓ Core Functions

[`bound_ne()`](https://data-wise.github.io/medrobust/dev/reference/bound_ne.md)
works with S7 objects

[`simulate_dm_data()`](https://data-wise.github.io/medrobust/dev/reference/simulate_dm_data.md)
returns S7 object

[`power_analysis()`](https://data-wise.github.io/medrobust/dev/reference/power_analysis.md)
returns S7 object

All algorithms produce expected results

------------------------------------------------------------------------

## 13. Troubleshooting

### S7 Package Not Found

``` r

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

``` r

# Install all dependencies
devtools::install_deps()
```

**Run specific failing test:**

``` r

# Get detailed output
test_file("tests/testthat/test-s7-classes.R", reporter = "progress")
```

**Check for missing imports:**

``` r

# Make sure NAMESPACE is up to date
document()
```

### Documentation Issues

**Roxygen not generating docs:**

``` r

# Force regeneration
unlink("man", recursive = TRUE)
document()
```

**NAMESPACE problems:**

``` r

# Regenerate NAMESPACE
document()
```

### Load Errors

**“object not found” errors:**

``` r

# Reload package
detach("package:medrobust", unload = TRUE)
load_all()
```

**S7 class not recognized:**

``` r

# Check that S7 is imported in DESCRIPTION
# Should have: Imports: S7 (>= 0.1.0)

# Check NAMESPACE has:
# importFrom(S7, new_class)
# importFrom(S7, new_property)
# importFrom(S7, method)
```

### Validator Errors

**Validators not working:**

``` r

# Test validator directly
try(sensitivity_region(
  sn0_range = c(1.5, 0.8),  # Invalid
  sp0_range = c(0.8, 0.9),
  psi_sn_range = c(1.0, 2.0),
  psi_sp_range = c(1.0, 1.0)
))
# Should show error message
```

### renv Issues

**renv not activating:**

``` r

# Manually activate
renv::activate()

# Or rebuild .Rprofile
renv::init()
```

**Packages out of sync:**

``` r

# Check status
renv::status()

# Restore from renv.lock
renv::restore()

# Or sync with DESCRIPTION
renv::hydrate()
renv::snapshot()
```

**Package installation fails:**

``` r

# Clear cache and retry
renv::purge("packagename")
renv::install("packagename")

# Or restore from clean state
renv::restore(clean = TRUE)
```

**After pulling git changes, packages don’t work:**

``` r

# Restore packages from updated renv.lock
renv::restore()

# If problems persist, clean install
renv::restore(clean = TRUE)
```

**📖 See `RENV_SETUP.md` for more renv troubleshooting.**

------------------------------------------------------------------------

## 14. Next Steps

### Immediate Actions

1.  **Initialize renv** (if not already done)

    ``` r

    renv::init()
    renv::snapshot()
    ```

    **See `RENV_SETUP.md` for detailed instructions.**

2.  **Clone and test locally** (follow sections 1-5)

3.  **Run full test suite** to verify everything works

4.  **Generate documentation** to see how it looks

5.  **Run R CMD check** to catch any platform-specific issues

### Short-term Goals

6.  **Create Quarto vignettes** (recommended)

    **📖 See `QUARTO_VIGNETTES_SETUP.md` for complete guide with
    templates.**

    Quick start:

    ``` bash
    # Install Quarto CLI
    # macOS: brew install quarto
    # Windows: choco install quarto
    # Linux: see QUARTO_VIGNETTES_SETUP.md
    ```

    ``` r

    # Add quarto to dependencies
    renv::install("quarto")
    renv::snapshot()

    # Create vignettes/ directory
    dir.create("vignettes", showWarnings = FALSE)

    # Copy templates from QUARTO_VIGNETTES_SETUP.md
    # - introduction.qmd
    # - simulation-studies.qmd
    # - power-analysis.qmd
    ```

7.  **Create example datasets** (if not already present)

    - Generate realistic `arsenic_synthetic` data
    - Create `example_param_grids` object
    - Create `validation_subsample` data

8.  **Add more examples**

    - Real-world case studies
    - Comparison with naive analysis
    - Sensitivity to misclassification

### Long-term Goals

8.  **Prepare for CRAN submission** (if desired)

    - Ensure R CMD check passes with `--as-cran`
    - Write cran-comments.md
    - Submit to CRAN

9.  **Create package website**

    ``` r

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

------------------------------------------------------------------------

## Summary

The medrobust package now has **complete S7 OOP implementation** with
modern development tools:

### Package Features

- **7 S7 classes** with full validation
- **18 S7 methods** (print, summary, conversion, plotting)
- **~950 lines** of new simulation and power analysis code
- **31+ tests** covering all S7 functionality
- **Complete documentation** for all datasets

### Development Tools

- **renv** for reproducible environments (see `RENV_SETUP.md`)
- **Quarto** for modern vignettes (see `QUARTO_VIGNETTES_SETUP.md`)
- **S7** for type-safe object-oriented programming
- **devtools** for streamlined package development

### Quick Start Command Sequence

``` r

# In R console
library(devtools)
setwd("path/to/medrobust")

# Initialize renv (first time only)
renv::init()

# Or restore environment (subsequent times)
renv::restore()

# Load and test
load_all()
test()
check()

# Try it out
sim <- simulate_dm_data(n = 200, seed = 123)
print(sim)
```

### Key Files to Review

**Core Implementation:** - `R/s7-classes.R` - S7 class definitions -
`R/s7-methods.R` - S7 method implementations - `R/simulate_dm_data.R` -
Data simulation - `R/power_analysis.R` - Power analysis -
`tests/testthat/test-s7-classes.R` - S7 tests - `NAMESPACE` - Exported
functions/classes

**Setup Guides:** - `WORKFLOW.md` - This file (local development
workflow) - `RENV_SETUP.md` - Reproducible environment setup -
`QUARTO_VIGNETTES_SETUP.md` - Modern vignette creation

**Configuration:** - `DESCRIPTION` - Package metadata and dependencies -
`renv.lock` - Package versions (created after
[`renv::init()`](https://rstudio.github.io/renv/reference/init.html)) -
`.Rprofile` - Activates renv (created after
[`renv::init()`](https://rstudio.github.io/renv/reference/init.html))

------------------------------------------------------------------------

**Questions or Issues?**

- Check [Troubleshooting](#id_13-troubleshooting) section above
- Review test files for usage examples
- Examine existing S7 methods for patterns
- Run `devtools::check()` for diagnostic information
- Consult `RENV_SETUP.md` for renv problems
- Consult `QUARTO_VIGNETTES_SETUP.md` for vignette help

**The package is ready for local testing and use!** 🎉

------------------------------------------------------------------------

**Next Steps:**

1.  Initialize renv:
    [`renv::init()`](https://rstudio.github.io/renv/reference/init.html)
2.  Create Quarto vignettes (see `QUARTO_VIGNETTES_SETUP.md`)
3.  Test all functionality locally
4.  Merge to main when ready
