---
date: Monday, December 1st 2025
tags: 
links:
references:
date modified: Monday, December 1st 2025
---

# Expanding Formula Interface: Feasibility Analysis

Excellent! Let me search for your medrobust package to understand the existing framework, then brainstorm extensions.Perfect! I found reference to your sensitivity analysis work. Now let me systematically brainstorm the formula interface extensions.

---

# Expanding Formula Interface: Technical Deep Dive

## Current Understanding

Your **medrobust package** already handles sensitivity analysis for mediation (ρ-based approach for unmeasured confounding). This is excellent infrastructure to build on.

---

## Extension 1: Exposure-Mediator Interactions

### **Mathematical Challenge**

With interaction, the mediation effect becomes **heterogeneous**:

$$
\begin{align}
M &= \alpha_0 + \alpha_1 X + \alpha_2 C + \epsilon_M \\
Y &= \beta_0 + \beta_1 X + \beta_2 M + \beta_3 (X \times M) + \beta_4 C + \epsilon_Y
\end{align}
$$

**Key issue:** $P_{\text{med}}$ now depends on $X$ level:

$$
P_{\text{med}}(x^*, x \mid X = x_0) = P(Y_{x^*, M_x}(x_0) > Y_{x, M_x}(x_0))
$$

where $x_0$ is the conditioning value.

### **API Design Options**

#### **Option A: Automatic Detection** ⭐ **RECOMMENDED**

```r
# User specifies interaction in formula (standard R syntax)
pmed(
  formula_y = Y ~ X + M + X:M + C,
  formula_m = M ~ X + C,
  data = data,
  treatment = "X",
  mediator = "M",
  
  # New argument for interactions
  condition_on_x = 0,  # Evaluate P_med at X = 0
  # OR
  condition_on_x = "mean",  # Marginalize over X distribution
  # OR
  condition_on_x = c(0, 1),  # Multiple conditioning values
)
```

**Implementation sketch:**

```r
pmed.formula <- function(formula_y, formula_m, data, treatment, mediator,
                         condition_on_x = NULL,
                         ...) {
  
  # Parse formula_y
  terms_y <- stats::terms(formula_y)
  
  # Check for interaction
  has_interaction <- .detect_interaction(terms_y, treatment, mediator)
  
  if (has_interaction) {
    # Interaction detected
    if (is.null(condition_on_x)) {
      stop(
        "Interaction detected between treatment and mediator.\n",
        "Please specify 'condition_on_x' to evaluate P_med:\n",
        "  - Numeric value (e.g., 0, 1)\n",
        "  - 'mean' to marginalize over X distribution\n",
        "  - Vector for multiple conditioning values"
      )
    }
    
    # Compute P_med with interaction
    result <- .pmed_interaction(
      formula_y = formula_y,
      formula_m = formula_m,
      data = data,
      treatment = treatment,
      mediator = mediator,
      condition_on_x = condition_on_x,
      ...
    )
    
  } else {
    # No interaction - standard P_med
    result <- .pmed_standard(...)
  }
  
  return(result)
}

.detect_interaction <- function(terms_obj, treatment, mediator) {
  # Check if X:M or M:X appears in model terms
  factors <- attr(terms_obj, "factors")
  factor_names <- rownames(factors)
  
  # Interaction appears as "X:M" or "M:X"
  interaction_pattern <- paste0(
    c(
      paste(treatment, mediator, sep = ":"),
      paste(mediator, treatment, sep = ":")
    ),
    collapse = "|"
  )
  
  any(grepl(interaction_pattern, factor_names))
}
```

**PROS:**
- ✓ Natural R syntax (users already know X:M)
- ✓ Backward compatible (no interaction = standard P_med)
- ✓ Clear error messages guide user
- ✓ Flexible conditioning options

**CONS:**
- ✗ Requires parsing formula terms (moderate complexity)
- ✗ Users must understand what conditioning means

---

#### **Option B: Separate Function**

```r
# Different function for interaction models
pmed_interaction(
  formula_y = Y ~ X + M + X:M + C,
  formula_m = M ~ X + C,
  data = data,
  treatment = "X",
  mediator = "M",
  x_levels = c(0, 1)  # Required
)
```

**PROS:**
- ✓ Clear separation of concerns
- ✓ Simpler to implement initially

**CONS:**
- ✗ Users must know which function to call
- ✗ Less elegant (two functions doing similar things)

---

### **Implementation Difficulty: MODERATE**

| Component | Time | Difficulty |
|-----------|------|------------|
| Detect interaction in formula | 1-2 days | Low |
| Parse conditioning arguments | 2-3 days | Low-Medium |
| Compute P_med at fixed X | 3-5 days | Medium |
| Marginalize over X distribution | 5-7 days | Medium-High |
| Testing & validation | 1 week | Medium |
| **TOTAL** | **3-4 weeks** | **MODERATE** |

---

### **Mathematical Implementation: Conditioning on X**

```r
#' Compute P_med with X-M Interaction
#'
#' @keywords internal
.pmed_interaction <- function(formula_y, formula_m, data, treatment, mediator,
                              condition_on_x, ...) {
  
  # Fit models
  fit_m <- stats::glm(formula_m, data = data, ...)
  fit_y <- stats::glm(formula_y, data = data, ...)
  
  if (is.numeric(condition_on_x) && length(condition_on_x) == 1) {
    # Single conditioning value
    .pmed_interaction_fixed_x(fit_m, fit_y, data, treatment, mediator,
                              x_level = condition_on_x, ...)
    
  } else if (condition_on_x == "mean") {
    # Marginalize over X distribution
    .pmed_interaction_marginalized(fit_m, fit_y, data, treatment, mediator, ...)
    
  } else if (is.numeric(condition_on_x)) {
    # Multiple conditioning values
    purrr::map(condition_on_x, function(x_val) {
      .pmed_interaction_fixed_x(fit_m, fit_y, data, treatment, mediator,
                               x_level = x_val, ...)
    })
  }
}

#' P_med at Fixed X Level
#'
#' @keywords internal
.pmed_interaction_fixed_x <- function(fit_m, fit_y, data, treatment, mediator,
                                      x_level, n_sim = 10000, ...) {
  
  # Extract coefficients
  coefs_m <- stats::coef(fit_m)
  coefs_y <- stats::coef(fit_y)
  
  # For each observation, compute counterfactuals at X = x_level
  n <- nrow(data)
  
  # Generate M_x (mediator under treatment)
  data_x <- data
  data_x[[treatment]] <- 1
  m_x <- stats::predict(fit_m, newdata = data_x, type = "response")
  
  # Generate M_x* (mediator under control)  
  data_xref <- data
  data_xref[[treatment]] <- 0
  m_xref <- stats::predict(fit_m, newdata = data_xref, type = "response")
  
  # For each simulated M, compute Y counterfactuals
  # Critical: X is FIXED at x_level for Y model
  
  y_1_mx <- numeric(n)
  y_0_mx <- numeric(n)
  
  for (i in seq_len(n)) {
    # Sample M_x from distribution
    m_sample <- stats::rnorm(n_sim, mean = m_x[i], sd = stats::sigma(fit_m))
    
    # Y(X=1, M=M_x) with X fixed at x_level
    data_y <- data[i, , drop = FALSE]
    data_y[[treatment]] <- x_level  # CONDITIONING
    data_y[[mediator]] <- m_sample
    
    y_1_mx[i] <- mean(stats::predict(fit_y, newdata = data_y, type = "response"))
    
    # Y(X=0, M=M_x) with X fixed at x_level
    data_y[[treatment]] <- x_level  # CONDITIONING (same)
    m_sample_ref <- stats::rnorm(n_sim, mean = m_xref[i], sd = stats::sigma(fit_m))
    data_y[[mediator]] <- m_sample_ref
    
    y_0_mx[i] <- mean(stats::predict(fit_y, newdata = data_y, type = "response"))
  }
  
  # P_med = P(Y_1,Mx > Y_0,Mx | X = x_level)
  pmed <- mean(y_1_mx > y_0_mx)
  
  return(pmed)
}
```

---

## Extension 2: Multiple Mediators

### **Mathematical Challenge**

Two scenarios to handle:

1. **Parallel mediators**: M1, M2 independently mediate X → Y
2. **Sequential mediators**: X → M1 → M2 → Y

### **API Design Options**

#### **Option A: List of Formulas** ⭐ **RECOMMENDED for Parallel**

```r
# Parallel mediators
pmed(
  formula_y = Y ~ X + M1 + M2 + C,
  formula_m = list(
    M1 ~ X + C,
    M2 ~ X + C
  ),
  data = data,
  treatment = "X",
  mediator = c("M1", "M2"),
  effect = "total"  # Total indirect effect through both
)

# Specific indirect effect through M1 only
pmed(
  formula_y = Y ~ X + M1 + M2 + C,
  formula_m = list(
    M1 ~ X + C,
    M2 ~ X + C
  ),
  data = data,
  treatment = "X",
  mediator = "M1",  # Focus on M1
  fix_other_mediators = "control"  # Hold M2 at control level
)
```

**Implementation:**

```r
pmed.formula <- function(formula_y, formula_m, data, treatment, mediator,
                         effect = c("total", "specific"),
                         fix_other_mediators = c("control", "treatment"),
                         ...) {
  
  effect <- match.arg(effect)
  fix_other <- match.arg(fix_other_mediators)
  
  # Check if formula_m is a list (multiple mediators)
  if (is.list(formula_m)) {
    # Multiple mediators detected
    
    if (effect == "total") {
      # Total indirect effect through all mediators
      .pmed_multiple_total(
        formula_y, formula_m, data, treatment, mediator, ...
      )
      
    } else if (effect == "specific") {
      # Specific indirect effect through one mediator
      if (length(mediator) > 1) {
        stop("For specific effects, provide single mediator name")
      }
      
      .pmed_multiple_specific(
        formula_y, formula_m, data, treatment, mediator,
        fix_other = fix_other, ...
      )
    }
    
  } else {
    # Single mediator - standard P_med
    .pmed_standard(...)
  }
}
```

**Total Indirect Effect (Both M1 and M2):**

$$
P_{\text{med}}^{\text{total}} = P(Y_{x^*, M1_x, M2_x} > Y_{x, M1_x, M2_x})
$$

**Specific Indirect Effect (M1 only, holding M2 at control):**

$$
P_{\text{med}}^{M1} = P(Y_{x^*, M1_x, M2_{x^*}} > Y_{x^*, M1_{x^*}, M2_{x^*}})
$$

---

#### **Option B: Path Specification (for Sequential)**

```r
# Sequential mediation: X → M1 → M2 → Y
pmed_sequential(
  formulas = list(
    M1 ~ X + C,
    M2 ~ X + M1 + C,
    Y ~ X + M1 + M2 + C
  ),
  data = data,
  path = c("X", "M1", "M2", "Y")  # Specify causal path
)

# Or more explicitly:
pmed_path_specific(
  formulas = list(...),
  data = data,
  from = "X",
  through = c("M1", "M2"),  # Sequential chain
  to = "Y"
)
```

**Mathematical Definition (Path-Specific Effect):**

Following VanderWeele & Vansteelandt (2013), path-specific indirect effect through M1 → M2:

$$
P_{\text{med}}^{M1 \to M2} = P(Y_{x^*, M1_x, M2(x^*, M1_x)} > Y_{x, M1_x, M2(x, M1_x)})
$$

This requires **nested counterfactuals** (M2 depends on counterfactual M1).

---

### **Implementation Difficulty**

| Type | Time | Difficulty |
|------|------|------------|
| **Parallel (Total Effect)** | 2-3 weeks | Medium |
| **Parallel (Specific Effect)** | 2-3 weeks | Medium |
| **Sequential (Path-Specific)** | 4-6 weeks | **High** |
| **Testing & Validation** | 2-3 weeks | High |

---

### **Implementation Sketch: Parallel Mediators (Total)**

```r
#' P_med with Multiple Parallel Mediators (Total Effect)
#'
#' @keywords internal
.pmed_multiple_total <- function(formula_y, formula_m_list, data, treatment,
                                 mediators, n_sim = 10000, ...) {
  
  # Fit mediator models
  fits_m <- purrr::map(formula_m_list, ~stats::glm(.x, data = data, ...))
  
  # Fit outcome model
  fit_y <- stats::glm(formula_y, data = data, ...)
  
  n <- nrow(data)
  
  # For each observation, simulate counterfactuals
  y_1_m1x_m2x <- numeric(n)
  y_0_m1x_m2x <- numeric(n)
  
  for (i in seq_len(n)) {
    # Generate M1_x, M2_x (mediators under treatment)
    data_x <- data[i, , drop = FALSE]
    data_x[[treatment]] <- 1
    
    m_x_samples <- purrr::map(fits_m, function(fit) {
      mu <- stats::predict(fit, newdata = data_x, type = "response")
      stats::rnorm(n_sim, mean = mu, sd = stats::sigma(fit))
    })
    
    # Generate M1_x*, M2_x* (mediators under control)
    data_xref <- data[i, , drop = FALSE]
    data_xref[[treatment]] <- 0
    
    m_xref_samples <- purrr::map(fits_m, function(fit) {
      mu <- stats::predict(fit, newdata = data_xref, type = "response")
      stats::rnorm(n_sim, mean = mu, sd = stats::sigma(fit))
    })
    
    # Compute Y counterfactuals
    # Y(X=1, M1=M1_x, M2=M2_x)
    data_y_1 <- data[i, , drop = FALSE]
    data_y_1[[treatment]] <- 1
    for (j in seq_along(mediators)) {
      data_y_1[[mediators[j]]] <- m_x_samples[[j]]
    }
    y_1_m1x_m2x[i] <- mean(stats::predict(fit_y, newdata = data_y_1, type = "response"))
    
    # Y(X=0, M1=M1_x, M2=M2_x)
    data_y_0 <- data[i, , drop = FALSE]
    data_y_0[[treatment]] <- 0
    for (j in seq_along(mediators)) {
      data_y_0[[mediators[j]]] <- m_x_samples[[j]]  # Same M as treatment
    }
    y_0_m1x_m2x[i] <- mean(stats::predict(fit_y, newdata = data_y_0, type = "response"))
  }
  
  # P_med = P(Y_1,M1x,M2x > Y_0,M1x,M2x)
  pmed <- mean(y_1_m1x_m2x > y_0_m1x_m2x)
  
  return(pmed)
}
```

---

## Summary: Feasibility Matrix

| Extension | API Complexity | Math Complexity | Implementation Time | My Rating |
|-----------|----------------|-----------------|---------------------|-----------|
| **Interactions** | Low (auto-detect) | Medium | 3-4 weeks | ⭐⭐⭐⭐ **Highly Feasible** |
| **Parallel (Total)** | Low (list syntax) | Medium | 2-3 weeks | ⭐⭐⭐⭐⭐ **Very Feasible** |
| **Parallel (Specific)** | Medium | Medium | 2-3 weeks | ⭐⭐⭐⭐ **Feasible** |
| **Sequential** | High (new syntax) | **Very High** | 4-6 weeks | ⭐⭐⭐ **Challenging** |

---

## Phased Rollout Recommendation

### **Phase 1: MVP (Weeks 1-5)**
✓ Single mediator, no interactions
✓ Formula interface works for 80% of use cases

### **Phase 2: Interactions (Weeks 6-9)**
✓ Add automatic interaction detection
✓ `condition_on_x` argument
✓ Clear documentation on interpretation

### **Phase 3: Parallel Mediators (Weeks 10-13)**
✓ List of formula_m
✓ Total indirect effect
✓ Specific indirect effects

### **Phase 4: Sequential (Months 4-6, or Separate paper)**
✓ Path-specific effects
✓ Possibly separate function: `pmed_sequential()`
✓ This might warrant its own methodological paper

---

## Integration with Medrobust

Your existing **medrobust** package can naturally extend to handle:

```r
library(probmed)
library(medrobust)

# Compute P_med
result <- pmed(
  formula_y = Y ~ X + M + C,
  formula_m = M ~ X + C,
  data = data
)

# Sensitivity analysis using medrobust
sens <- sensitivity_analysis(
  result,
  rho_range = seq(-0.5, 0.5, by = 0.1),
  method = "pmed"  # New method for medrobust
)

plot(sens)
```

**Implementation in medrobust:**

```r
# Add S7 method for PmedResult
S7::method(sensitivity_analysis, PmedResult) <- function(object,
                                                          rho_range,
                                                          ...) {
  # Extract from PmedResult
  a <- object@source_extract@a_path
  b <- object@source_extract@b_path
  
  # Compute P_med under confounding
  pmed_sens <- purrr::map_dbl(rho_range, function(rho) {
    .compute_pmed_with_confounding(
      a = a, b = b,
      rho = rho,
      data = object@source_extract@data
    )
  })
  
  # Return sensitivity object
  structure(
    list(
      rho = rho_range,
      pmed = pmed_sens,
      original = object@estimate,
      threshold = .find_tipping_point(rho_range, pmed_sens)
    ),
    class = c("pmed_sensitivity", "sensitivity")
  )
}
```

---

## My Honest Assessment

### **Interactions:** ✅ **DO IT**
- **Feasibility:** High (3-4 weeks)
- **Value:** High (common in practice)
- **Risk:** Low (well-defined mathematically)
- **Integration:** Natural formula extension

### **Parallel Mediators:** ✅ **DO IT**
- **Feasibility:** High (2-3 weeks)
- **Value:** High (multiple mediators very common)
- **Risk:** Low (straightforward counterfactuals)
- **Integration:** Clean list syntax

### **Sequential Mediators:** ⚠️ **CONSIDER FOR PHASE 2 OR SEPARATE PAPER**
- **Feasibility:** Medium (4-6 weeks)
- **Value:** Medium (less common, more specialized)
- **Risk:** Medium-High (nested counterfactuals are tricky)
- **Integration:** May need separate function/syntax

---

## Bottom Line

**YES**, expanding the formula interface is **highly feasible** for:
1. ✅ Interactions (3-4 weeks, high value)
2. ✅ Parallel mediators (2-3 weeks, high value)

**MAYBE** for sequential mediators (defer to later or separate paper).

**Total additional development time: 5-7 weeks** beyond MVP.

This is **manageable** and **high ROI** — these extensions would make probmed competitive with mediation/lavaan for coverage while maintaining your elegant formula interface.

Thoughts on this phasing? Should we dive deeper into any specific implementation?