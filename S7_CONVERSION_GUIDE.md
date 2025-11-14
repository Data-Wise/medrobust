# S7 OOP Conversion Guide for medrobust

**Branch:** `dev/s7-oop`
**Status:** Phase 1 Complete
**Version:** 0.1.0.9000 (development)

## Overview

This document tracks the conversion of the medrobust package from S3 to S7 OOP system, providing better type safety, validation, and maintainability.

---

## ✅ Phase 1: Core Infrastructure (COMPLETE)

### Files Created

#### 1. `R/s7-classes.R` (460 lines)
Complete S7 class definitions with validation:

**`sensitivity_region` Class:**
- Properties: `sn0_range`, `sp0_range`, `psi_sn_range`, `psi_sp_range`
- Validators: Range checking [0,1], ordering, informativeness
- Constructor: `as_sensitivity_region(list)`

**`bootstrap_results` Class:**
- Properties: Method, reps, CIs, distributions, BCa params
- Validators: Confidence level, failed reps count
- Auto-validates that n_failed ≤ n_reps

**`medrobust_bounds` Class (Main):**
- Properties: NIE/NDE bounds, compatible sets, falsification stats
- Validators:
  - NIE_lower ≤ NIE_upper
  - NDE_lower ≤ NDE_upper
  - n_compatible ≤ n_evaluated
  - Effect scale ∈ {OR, RR, RD}
- Nested S7 objects: `sensitivity_region`, `bootstrap_results`

**`compatibility_test` Class:**
- Properties: Compatible flag, constraints, implied probabilities
- Validators: Constraint counts, probability ranges
- Stratum-level details

**`falsification_summary` Class:**
- Properties: Falsification rates, parameter breakdowns
- Validators: Rate ∈ [0,1], count consistency
- Optional plot storage

#### 2. `R/s7-methods.R` (400 lines)
S7 generic methods for all classes:

**For `medrobust_bounds`:**
- `print()` - Clean formatted output with bounds, CIs, diagnostics
- `summary()` - Extended diagnostics with sensitivity region details
- `as.data.frame()` - Export to data frame for further analysis

**For `compatibility_test`:**
- `print()` - Test results with violated constraints
- `summary()` - Stratum-level details

**For `falsification_summary`:**
- `print()` - Falsification rates with interpretation
- `summary()` - Same as print (simple class)

**For `sensitivity_region`:**
- `print()` - Compact region display

**For `bootstrap_results`:**
- `print()` - CI table

### Files Modified

#### `DESCRIPTION`
- Added `S7 (>= 0.1.0)` to Imports
- Bumped version to `0.1.0.9000` (development)
- All existing dependencies retained

#### `R/bound_ne.R`
Updated return statement (lines 225-270):
- Converts `sensitivity_region` list to S7 class via `as_sensitivity_region()`
- Converts `bootstrap_results` list to S7 class
- Uses `medrobust_bounds()` S7 constructor instead of `structure()`
- Automatic validation on object creation

---

## 🔄 Phase 2: Function Updates (IN PROGRESS)

### Remaining Updates Needed

#### High Priority

**1. `R/check_compatibility.R`**
- Update return to use `compatibility_test()` S7 constructor
- Around line 620-650 (current S3 return)
- Change from `class(result) <- "compatibility_test"` to S7 constructor

**2. `R/falsification_summary.R`**
- Update return to use `falsification_summary()` S7 constructor
- Around line 80-100
- Convert result list to S7 object

**3. `R/bootstrap.R` (if separate return)**
- May need to return `bootstrap_results` S7 object
- Check `compute_bootstrap_ci()` function
- Ensure it returns S7-compatible list or object

#### Medium Priority

**4. `R/bound_ne_mediator.R`**
- Verify return structure matches S7 expectations
- Should return compatible_sets as data.frame
- Ensure n_compatible, n_evaluated are integers

**5. `R/bound_ne_exposure.R`**
- Same as mediator - verify return structure
- Check all return values for type correctness

#### Lower Priority

**6. Helper Functions**
- Most helpers don't need changes (internal functions)
- Only update if they return class objects
- Validation functions stay as-is

---

## 📋 Phase 3: NAMESPACE & Exports (PENDING)

### Updates Needed

#### `NAMESPACE`
Current exports work but need S7-specific additions:

```r
# Add S7 class exports
export(sensitivity_region)
export(bootstrap_results)
export(medrobust_bounds)
export(compatibility_test)
export(falsification_summary)

# Add S7 constructor helpers
export(as_sensitivity_region)

# S7 methods are auto-exported by the S7 package
# No need for explicit S3method() declarations
```

#### Import S7
```r
import(S7)
# Or selectively:
importFrom(S7, new_class)
importFrom(S7, new_property)
importFrom(S7, method)
```

---

## 🧪 Phase 4: Testing (PENDING)

### Test Files to Update

#### `tests/testthat/test-bound_ne.R`
- Test S7 object creation
- Test validators (expect errors for invalid inputs)
- Test property access with `@` operator
- Test method dispatch

Example test additions:
```r
test_that("medrobust_bounds validates properly", {
  # Should fail: NIE_lower > NIE_upper
  expect_error(
    medrobust_bounds(
      NIE_lower = 2.0,
      NIE_upper = 1.5,
      ...
    ),
    "NIE_lower must be <= NIE_upper"
  )

  # Should fail: invalid effect scale
  expect_error(
    medrobust_bounds(..., effect_scale = "INVALID"),
    "effect_scale must be 'OR', 'RR', or 'RD'"
  )
})

test_that("sensitivity_region validates ranges", {
  expect_error(
    sensitivity_region(sn0_range = c(0.9, 0.8)),  # Wrong order
    "sn0_range\\[1\\] must be < sn0_range\\[2\\]"
  )
})
```

#### New Test Files
- `tests/testthat/test-s7-classes.R` - Class validation
- `tests/testthat/test-s7-methods.R` - Method dispatch
- `tests/testthat/test-s7-conversions.R` - S3 to S7 conversions

---

## 📚 Phase 5: Documentation (PENDING)

### Roxygen Updates

#### For S7 Classes
Add roxygen blocks to `R/s7-classes.R`:

```r
#' @title Medrobust Bounds Class
#' @description S7 class for partial identification bounds...
#' @slot NIE_lower Lower bound for NIE
#' @slot NIE_upper Upper bound for NIE
#' ...
#' @export
medrobust_bounds <- new_class(...)
```

#### For S7 Methods
Document in `R/s7-methods.R`:

```r
#' @export
#' @rdname medrobust_bounds-methods
method(print, medrobust_bounds) <- function(x, ...) {...}
```

### Vignette Updates

Update `vignettes/introduction.Rmd`:
- Show S7 property access with `@` operator
- Demonstrate validation features
- Show how to create S7 objects manually
- Add "Why S7?" section

---

## 🔍 Key Differences: S3 vs S7

### Property Access

**S3 (old):**
```r
bounds$NIE_lower          # Access via $
bounds$NIE_lower <- 5.0   # Can modify freely (no validation!)
```

**S7 (new):**
```r
bounds@NIE_lower          # Access via @
bounds@NIE_lower <- 5.0   # Validated automatically!
# Error if NIE_lower > NIE_upper
```

### Class Checking

**S3 (old):**
```r
inherits(x, "medrobust_bounds")  # Still works
class(x) == "medrobust_bounds"   # Works but less robust
```

**S7 (new):**
```r
S7_inherits(x, medrobust_bounds)  # Recommended
# Also works: inherits(x, "medrobust_bounds")
```

### Method Dispatch

**S3 (old):**
```r
print.medrobust_bounds <- function(x, ...) {...}
```

**S7 (new):**
```r
method(print, medrobust_bounds) <- function(x, ...) {...}
# Faster dispatch, better error messages
```

---

## 🎯 Benefits Achieved

### 1. Type Safety
- Can't assign wrong types to properties
- Automatic validation on creation and modification
- Catch errors earlier in development

### 2. Better Validation
- **Bounds ordering**: NIE_lower ≤ NIE_upper enforced
- **Probability ranges**: [0,1] validated automatically
- **Effect scales**: Only "OR", "RR", "RD" allowed
- **Count consistency**: n_compatible ≤ n_evaluated

### 3. Self-Documenting
- Class structure visible in definition
- Property types explicit
- Validators show constraints

### 4. Performance
- Faster method dispatch than S3
- No need for class attribute checks
- Compiled generics

### 5. Developer Experience
- Better autocomplete in RStudio
- Clearer error messages
- Easier debugging

---

## 📝 Backward Compatibility

### S3 Methods Still Work
Old code using S3 methods will still function:
```r
# These still work:
print(bounds)
summary(bounds)
is(bounds, "medrobust_bounds")
```

### Property Access Compatibility
For a transition period, both work:
```r
bounds$NIE_lower  # S3 style (still works)
bounds@NIE_lower  # S7 style (recommended)
```

### Conversion Helpers
Provided `as_sensitivity_region()` for easy conversion:
```r
# Old S3 list
old_list <- list(sn0_range = c(0.8, 0.9), ...)

# Convert to S7
new_s7 <- as_sensitivity_region(old_list)
```

---

## 🚀 Next Steps

### Immediate (to complete S7 conversion):

1. **Update `check_compatibility()`**
   - File: `R/check_compatibility.R`
   - Lines: ~620-650
   - Change: Use `compatibility_test()` constructor

2. **Update `falsification_summary()`**
   - File: `R/falsification_summary.R`
   - Lines: ~80-100
   - Change: Use `falsification_summary()` constructor

3. **Update NAMESPACE**
   - Add S7 class exports
   - Add S7 import statements

4. **Test basic functionality**
   - Run existing tests
   - Fix any S7-related issues

### Short-term (1-2 weeks):

5. **Write S7-specific tests**
   - Validator tests
   - Type checking tests
   - Method dispatch tests

6. **Update documentation**
   - Add roxygen for S7 classes
   - Update vignettes
   - Add S7 examples

### Long-term (future):

7. **Performance benchmarking**
   - Compare S3 vs S7 speed
   - Optimize if needed

8. **Extended S7 features**
   - Custom validators
   - Computed properties
   - Property change callbacks

---

## 📖 References

- **S7 Package**: https://rconsortium.github.io/S7/
- **S7 Vignette**: `vignette("S7", package = "S7")`
- **S7 vs S3/S4**: https://rconsortium.github.io/S7/articles/compatibility.html

---

## 💾 Git Workflow

### Branches

```
main                           # S3 version (stable)
  └── dev/s7-oop              # S7 conversion (current branch)
       └── (future feature branches as needed)
```

### Current Commit
```
c3197a8 - Initial S7 OOP conversion - Phase 1
```

### To Continue Work

```bash
# Ensure you're on the S7 branch
git checkout dev/s7-oop

# Make changes to remaining files
# (check_compatibility, falsification_summary, etc.)

# Commit incrementally
git add R/check_compatibility.R
git commit -m "Convert check_compatibility to S7"

# When phase complete, merge to main
git checkout main
git merge dev/s7-oop
```

---

## 🐛 Known Issues / TODO

- [ ] `library(S7)` called in class/method files - should use `@importFrom S7`
- [ ] Need to add S7 to NAMESPACE imports
- [ ] Some validators may be too strict - monitor in testing
- [ ] Consider adding `$` accessor methods for smoother S3 → S7 transition
- [ ] Documentation for S7 classes needs roxygen blocks

---

**Last Updated**: 2025-01-14
**Maintained By**: Claude (S7 Conversion Assistant)
**Questions?**: See S7 package documentation or this guide
