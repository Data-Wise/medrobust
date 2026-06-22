# Quarto Vignettes Setup for medrobust

## Why Quarto for Package Vignettes?

Quarto (.qmd) offers advantages over R Markdown (.Rmd): - ✅
**Modern** - Next-generation scientific publishing - ✅ **Better
rendering** - Enhanced HTML, PDF output - ✅ **More features** - Better
code highlighting, callouts, tabsets - ✅ **Cross-language** - Python,
Julia support (if needed later) - ✅ **Better defaults** - Modern, clean
appearance - ✅ **Active development** - Posit’s future direction

------------------------------------------------------------------------

## Prerequisites

### 1. Install Quarto CLI

**Download from:** <https://quarto.org/docs/get-started/>

**Or via command line:**

``` bash
# macOS (via Homebrew)
brew install quarto

# Windows (via Chocolatey)
choco install quarto

# Linux (Debian/Ubuntu)
sudo curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
sudo dpkg -i quarto-linux-amd64.deb

# Verify installation
quarto --version
```

### 2. Install R Package

``` r

# Install quarto R package
install.packages("quarto")

# Or with renv
renv::install("quarto")
renv::snapshot()
```

------------------------------------------------------------------------

## Setup Quarto Vignettes in medrobust

### 1. Update DESCRIPTION File

Add Quarto support to your DESCRIPTION:

``` r
# Edit DESCRIPTION to include:
VignetteBuilder: quarto, knitr
Suggests:
    quarto,
    knitr,
    rmarkdown
```

### 2. Create Vignettes Directory Structure

``` bash
# Create directories if they don't exist
mkdir -p vignettes
```

### 3. Create \_quarto.yml Configuration

Create `vignettes/_quarto.yml`:

``` yaml
project:
  type: default

format:
  html:
    toc: true
    toc-depth: 3
    code-fold: false
    code-tools: true
    theme: cosmo
    self-contained: true

execute:
  echo: true
  warning: false
  message: false
  cache: false

knitr:
  opts_chunk:
    collapse: true
    comment: "#>"
    fig.path: "figures/"
    fig.width: 7
    fig.height: 5
```

------------------------------------------------------------------------

## Creating Vignette Files

### Template 1: Introduction Vignette

Create `vignettes/introduction.qmd`:

``` markdown
---
title: "Introduction to medrobust"
format:
  html:
    toc: true
    code-fold: false
vignette: >
  %\VignetteIndexEntry{Introduction to medrobust}
  %\VignetteEngine{quarto::html}
  %\VignetteEncoding{UTF-8}
---

## Introduction

The `medrobust` package provides tools for conducting sensitivity analysis for causal mediation effects when the exposure or mediator is measured with differential misclassification.

## Installation

```{r}
#| eval: false
# Install from GitHub
devtools::install_github("username/medrobust")
```

## Quick Start

\`\`\`{r} \#\| message: false library(medrobust)

# Load example data

data(“arsenic_synthetic”) head(arsenic_synthetic)

    ## Basic Analysis

    ### Define Sensitivity Region

    ```{r}
    sens_reg <- sensitivity_region(
      sn0_range = c(0.80, 0.90),
      sp0_range = c(0.80, 0.90),
      psi_sn_range = c(1.0, 2.0),
      psi_sp_range = c(1.0, 1.0)
    )
    print(sens_reg)

### Compute Bounds

`{r} #| cache: true bounds <- bound_ne( data = arsenic_synthetic, exposure = "A_star", mediator = "M", outcome = "Y", confounders = c("age", "male"), misclassified_variable = "exposure", sensitivity_region = sens_reg, n_grid = 30 )`

### View Results

`{r} print(bounds) summary(bounds)`

### Access Properties

With S7 objects, use the `@` operator:

\`\`\`{r} \# NIE bounds <bounds@NIE>\_lower <bounds@NIE>\_upper

# NDE bounds

<bounds@NDE>\_lower <bounds@NDE>\_upper

# Falsification

<bounds@falsified>\_proportion

    ## Using Pre-defined Grids

    ```{r}
    data("example_param_grids")

    # Use realistic scenario
    realistic_bounds <- bound_ne(
      data = arsenic_synthetic,
      exposure = "A_star",
      mediator = "M",
      outcome = "Y",
      confounders = c("age", "male"),
      misclassified_variable = "exposure",
      sensitivity_region = example_param_grids$realistic,
      n_grid = 30
    )

## Session Info

`{r} sessionInfo()`

    ### Template 2: Simulation Studies Vignette

    Create `vignettes/simulation-studies.qmd`:

    ```markdown
    ---
    title: "Simulation Studies with medrobust"
    format:
      html:
        toc: true
        code-fold: false
    vignette: >
      %\VignetteIndexEntry{Simulation Studies with medrobust}
      %\VignetteEngine{quarto::html}
      %\VignetteEncoding{UTF-8}
    ---

    ## Overview

    This vignette demonstrates how to use `medrobust` for simulation studies and methods validation.

    ## Setup

    ```{r}
    #| message: false
    library(medrobust)
    library(dplyr)
    library(ggplot2)

## Simulating Data

### Basic Simulation

Generate data with known differential misclassification:

`{r} sim_data <- simulate_dm_data( n = 500, true_params = list( beta_AM = 0.405, # OR = 1.5 theta_AY = 0.405, theta_MY = 0.405 ), dm_params = list( sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0 ), misclass_type = "exposure", confounders = 2, seed = 12345 )`

### Examine Results

\`\`\`{r} \# S7 print method print(sim_data)

# Access properties

<sim_data@true>\_effects$`NIE_OR
sim_data@true_effects`$NDE_OR

    ### Visualize Misclassification

    ```{r}
    #| fig-width: 8
    #| fig-height: 5
    # Confusion matrix
    if (!is.null(sim_data@misclassification_applied)) {
      print(sim_data@misclassification_applied$confusion_matrix)

      cat("\nMisclassification Rate:",
          round(100 * sim_data@misclassification_applied$misclassification_rate, 1),
          "%\n")
    }

## Analyzing Simulated Data

`{r} #| cache: true bounds <- bound_ne( data = sim_data@observed, exposure = "A_star", mediator = "M", outcome = "Y", confounders = c("C1", "C2"), misclassified_variable = "exposure", sensitivity_region = list( sn0_range = c(0.80, 0.90), sp0_range = c(0.80, 0.90), psi_sn_range = c(1.0, 2.0), psi_sp_range = c(1.0, 1.0) ), n_grid = 30 )`

### Check Coverage

\`\`\`{r} \# Is true effect in bounds? nie_covered \<-
(<sim_data@true>\_effects\$NIE \>= bounds@NIE_lower) &&
(sim_data@true_effects\$NIE \<= <bounds@NIE>\_upper)

nde_covered \<- (<sim_data@true>\_effects\$NDE \>= bounds@NDE_lower) &&
(sim_data@true_effects\$NDE \<= <bounds@NDE>\_upper)

cat(“NIE Coverage:”, nie_covered, “”) cat(“NDE Coverage:”, nde_covered,
“”)

    ## Monte Carlo Simulation

    ::: {.callout-note}
    This example runs a small simulation. Increase `n_reps` for real studies.
    :::

    ```{r}
    #| cache: true
    n_reps <- 10  # Use 1000+ for real studies
    results <- vector("list", n_reps)

    for (i in 1:n_reps) {
      # Generate data
      sim <- simulate_dm_data(
        n = 200,
        true_params = list(beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405),
        dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0),
        misclass_type = "exposure",
        seed = i,
        return_truth = FALSE
      )

      # Compute bounds
      b <- bound_ne(
        data = sim@observed,
        exposure = "A_star",
        mediator = "M",
        outcome = "Y",
        confounders = "C1",
        misclassified_variable = "exposure",
        sensitivity_region = list(
          sn0_range = c(0.80, 0.90),
          sp0_range = c(0.80, 0.90),
          psi_sn_range = c(1.0, 2.0),
          psi_sp_range = c(1.0, 1.0)
        ),
        n_grid = 20,
        verbose = FALSE
      )

      results[[i]] <- data.frame(
        NIE_lower = b@NIE_lower,
        NIE_upper = b@NIE_upper,
        NDE_lower = b@NDE_lower,
        NDE_upper = b@NDE_upper
      )
    }

    # Combine results
    results_df <- bind_rows(results)
    summary(results_df)

## Session Info

`{r} sessionInfo()`

    ### Template 3: Power Analysis Vignette

    Create `vignettes/power-analysis.qmd`:

    ```markdown
    ---
    title: "Power Analysis and Sample Size Determination"
    format:
      html:
        toc: true
        code-fold: false
    vignette: >
      %\VignetteIndexEntry{Power Analysis and Sample Size Determination}
      %\VignetteEngine{quarto::html}
      %\VignetteEncoding{UTF-8}
    ---

    ## Overview

    This vignette shows how to conduct power analysis for partial identification bounds.

    ## Setup

    ```{r}
    #| message: false
    library(medrobust)
    library(ggplot2)

## Quick Power Analysis

This example uses small `n_sim` for speed. Use `n_sim = 100+` for real
analyses.

`{r} #| cache: true power_result <- power_analysis( true_params = list( beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405 ), dm_params = list( sn0 = 0.85, sp0 = 0.85, psi_sn = 1.5, psi_sp = 1.0 ), sensitivity_region = list( sn0_range = c(0.80, 0.90), sp0_range = c(0.80, 0.90), psi_sn_range = c(1.0, 2.0), psi_sp_range = c(1.0, 1.0) ), misclass_type = "exposure", sample_sizes = c(200, 400, 600), target_power = 0.80, target_width = 0.3, n_sim = 10, # Use 100+ for real studies parallel = FALSE )`

## Results

`{r} # S7 print method print(power_result)`

### Power Curve

`{r} # View power curve data power_result@power_curve`

### Recommendations

\`\`\`{r} \# Sample size for target power
<power_result@recommended>\_n_power

# Sample size for target width

<power_result@recommended>\_n_width

    ## Visualization

    ```{r}
    #| fig-width: 8
    #| fig-height: 10
    #| warning: false
    # S7 plot method
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      plot(power_result)
    }

## Comparing Scenarios

- Scenario 1: Weak DM
- Scenario 2: Strong DM

`{r} #| cache: true #| eval: false power_weak <- power_analysis( true_params = list(beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405), dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 1.2, psi_sp = 1.0), sensitivity_region = list( sn0_range = c(0.80, 0.90), sp0_range = c(0.80, 0.90), psi_sn_range = c(1.0, 1.5), psi_sp_range = c(1.0, 1.0) ), sample_sizes = c(200, 400, 600), n_sim = 10 )`

`{r} #| cache: true #| eval: false power_strong <- power_analysis( true_params = list(beta_AM = 0.405, theta_AY = 0.405, theta_MY = 0.405), dm_params = list(sn0 = 0.85, sp0 = 0.85, psi_sn = 2.5, psi_sp = 1.0), sensitivity_region = list( sn0_range = c(0.80, 0.90), sp0_range = c(0.80, 0.90), psi_sn_range = c(1.5, 3.0), psi_sp_range = c(1.0, 1.0) ), sample_sizes = c(200, 400, 600), n_sim = 10 )`

## Session Info

`{r} sessionInfo()`

    ---

    ## Building Vignettes

    ### During Development

    ```r
    # Build individual vignette
    quarto::quarto_render("vignettes/introduction.qmd")

    # Build all vignettes
    devtools::build_vignettes()

### Build Package with Vignettes

``` r

# Build package including vignettes
devtools::build(vignettes = TRUE)

# Install with vignettes
devtools::install(build_vignettes = TRUE)

# Check package (includes vignette check)
devtools::check()
```

------------------------------------------------------------------------

## Viewing Vignettes

``` r

# List available vignettes
vignette(package = "medrobust")

# View specific vignette
vignette("introduction", package = "medrobust")
vignette("simulation-studies", package = "medrobust")
vignette("power-analysis", package = "medrobust")
```

------------------------------------------------------------------------

## Best Practices for Quarto Vignettes

### 1. Use YAML Headers

Always include proper vignette metadata:

``` yaml
---
title: "Your Vignette Title"
format:
  html:
    toc: true
    code-fold: false
vignette: >
  %\VignetteIndexEntry{Your Vignette Title}
  %\VignetteEngine{quarto::html}
  %\VignetteEncoding{UTF-8}
---
```

### 2. Use Code Chunk Options

Quarto uses `#|` for chunk options:

\`\`\`{r} \#\| echo: true \#\| eval: false \#\| warning: false \#\|
message: false \#\| cache: true \#\| fig-width: 8 \#\| fig-height: 6

# Your code here

    ### 3. Use Callouts

    Quarto has great callout blocks:

    ```markdown
    ::: {.callout-note}
    This is a note.
    :::

    ::: {.callout-warning}
    This is a warning.
    :::

    ::: {.callout-important}
    This is important.
    :::

    ::: {.callout-tip}
    This is a tip.
    :::

### 4. Use Tabsets

Organize content with tabs:

``` markdown
::: {.panel-tabset}

### Tab 1
Content for tab 1

### Tab 2
Content for tab 2

:::
```

### 5. Cache Long Computations

`{r} #| cache: true # Long-running code`

------------------------------------------------------------------------

## Troubleshooting

### Quarto CLI Not Found

``` r

# Check if Quarto is installed
quarto::quarto_version()

# If not, install from: https://quarto.org
```

### Vignettes Not Building

``` r

# Check DESCRIPTION has:
# VignetteBuilder: quarto, knitr

# Try rendering manually
quarto::quarto_render("vignettes/introduction.qmd")

# Check for errors
devtools::check(vignettes = TRUE)
```

### Cache Issues

``` bash
# Clear Quarto cache
cd vignettes
quarto clean

# In R
unlink("vignettes/*_cache", recursive = TRUE)
```

------------------------------------------------------------------------

## Resources

- [Quarto documentation](https://quarto.org/)
- [Quarto for R packages](https://quarto.org/docs/extensions/nbdev.html)
- [R Markdown to Quarto](https://quarto.org/docs/faq/rmarkdown.html)
