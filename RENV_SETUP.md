# renv Setup for medrobust Package Development

## Why renv for Package Development?

Using `renv` for the medrobust package ensures:
- All developers use the same package versions
- Reproducible builds and tests
- Isolated from system R library
- Easy rollback if updates break things
- Simplified CI/CD setup

---

## Initial Setup (First Time)

### 1. Install renv

```r
install.packages("renv")
```

### 2. Initialize renv in Project

```r
# In medrobust directory
setwd("path/to/medrobust")

# Initialize renv (creates renv/ directory and renv.lock)
renv::init()

# This will:
# - Create renv/library/ (project-specific packages)
# - Create renv.lock (package versions)
# - Create .Rprofile (activates renv on startup)
# - Scan DESCRIPTION and install dependencies
```

### 3. Install Development Dependencies

```r
# Install all package dependencies from DESCRIPTION
renv::install()

# Install additional development tools
renv::install(c(
  "devtools",
  "testthat",
  "roxygen2",
  "covr",
  "pkgdown",
  "quarto"
))

# For Quarto vignettes
renv::install("quarto")
```

### 4. Take Snapshot

```r
# Save current state of library
renv::snapshot()

# This updates renv.lock with all installed packages
```

---

## Daily Workflow with renv

### Starting Work

```r
# Open project - renv activates automatically
# If not, manually activate:
renv::activate()

# Check project status
renv::status()

# Restore packages if needed (e.g., after pulling changes)
renv::restore()
```

### Installing New Packages

```r
# Install package
renv::install("newpackage")

# Or install from GitHub
renv::install("username/repo")

# Update renv.lock
renv::snapshot()

# Commit renv.lock to git
```

### Updating Dependencies

```r
# Check for updates
renv::status()

# Update specific package
renv::update("dplyr")

# Update all packages
renv::update()

# Snapshot after updating
renv::snapshot()
```

### Development Cycle

```r
# 1. Restore environment
renv::restore()

# 2. Load package for development
devtools::load_all()

# 3. Make changes...

# 4. Test
devtools::test()

# 5. Check
devtools::check()

# 6. If you added dependencies to DESCRIPTION:
renv::install()  # Install new deps
renv::snapshot() # Update renv.lock
```

---

## Adding Dependencies to DESCRIPTION

When you add a new dependency:

```r
# Option 1: Edit DESCRIPTION manually, then:
renv::install()
renv::snapshot()

# Option 2: Use usethis
usethis::use_package("newpackage")
renv::install()
renv::snapshot()
```

---

## Collaborating with Others

### When Someone Else Updates Dependencies

```bash
# Pull latest changes including renv.lock
git pull

# In R:
renv::restore()  # Install packages from renv.lock
```

### Sharing Your Changes

```bash
# After renv::snapshot()
git add renv.lock
git commit -m "Update dependencies"
git push
```

---

## renv Files and Git

### What to Commit

✅ **DO commit:**
- `renv.lock` - Package versions (IMPORTANT!)
- `renv/activate.R` - Activation script
- `renv/settings.json` - renv settings
- `.Rprofile` - Project startup

❌ **DON'T commit (add to .gitignore):**
- `renv/library/` - Actual packages (too large)
- `renv/staging/` - Temporary files
- `renv/.cache/` - Package cache

### Update .gitignore

```gitignore
# renv
renv/library/
renv/local/
renv/staging/
renv/.cache/
```

---

## Troubleshooting

### renv Not Activating

```r
# Manually activate
renv::activate()

# Rebuild .Rprofile
renv::init()
```

### Package Installation Fails

```r
# Clear cache and retry
renv::purge("packagename")
renv::install("packagename")

# Or restore from clean state
renv::restore(clean = TRUE)
```

### Out of Sync with DESCRIPTION

```r
# Check differences
renv::status()

# Sync with DESCRIPTION
renv::hydrate()  # Install missing from DESCRIPTION
renv::snapshot() # Update lock file
```

### Starting Fresh

```r
# Remove all installed packages and reinstall
renv::restore(clean = TRUE)

# Or completely reset
renv::deactivate()
renv::init()
```

---

## CI/CD with renv (GitHub Actions)

### Example .github/workflows/R-CMD-check.yml

```yaml
name: R-CMD-check

on: [push, pull_request]

jobs:
  R-CMD-check:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: '4.3.0'

      - name: Install system dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libcurl4-openssl-dev

      - name: Restore renv
        shell: Rscript {0}
        run: |
          if (!requireNamespace("renv", quietly = TRUE)) {
            install.packages("renv")
          }
          renv::restore()

      - name: Check package
        shell: Rscript {0}
        run: |
          devtools::check()
```

---

## Best Practices

### DO:
- ✅ Run `renv::snapshot()` after installing/updating packages
- ✅ Run `renv::restore()` after pulling changes
- ✅ Commit `renv.lock` to version control
- ✅ Use `renv::status()` regularly to check for drift
- ✅ Keep renv updated: `renv::upgrade()`

### DON'T:
- ❌ Don't commit `renv/library/` directory
- ❌ Don't mix system and renv libraries
- ❌ Don't forget to snapshot after changes
- ❌ Don't ignore renv::status() warnings

---

## Quick Reference

```r
# Setup
renv::init()              # Initialize renv
renv::status()            # Check project status
renv::snapshot()          # Save package state
renv::restore()           # Restore from renv.lock

# Daily use
renv::install("pkg")      # Install package
renv::update("pkg")       # Update package
renv::remove("pkg")       # Remove package

# Maintenance
renv::clean()             # Remove unused packages
renv::upgrade()           # Upgrade renv itself
renv::repair()            # Fix issues

# Utilities
renv::dependencies()      # List all dependencies
renv::diagnostics()       # Run diagnostics
```

---

## medrobust-Specific Setup

### 1. Initial Setup

```r
# In medrobust directory
renv::init()

# Install core dependencies from DESCRIPTION
renv::install()

# Install development dependencies
renv::install(c(
  "devtools",
  "testthat",
  "roxygen2",
  "covr",
  "pkgdown",
  "quarto",
  "knitr",
  "rmarkdown"
))

# Snapshot
renv::snapshot()
```

### 2. Verify Setup

```r
# Check status
renv::status()  # Should show "No issues found"

# Test package build
devtools::load_all()
devtools::test()
devtools::check()
```

### 3. Commit to Git

```bash
git add renv.lock .Rprofile renv/activate.R renv/settings.json
git add .gitignore  # If updated
git commit -m "Initialize renv for reproducible development environment"
git push
```

---

## Resources

- [renv documentation](https://rstudio.github.io/renv/)
- [renv for package development](https://rstudio.github.io/renv/articles/packages.html)
- [Collaboration with renv](https://rstudio.github.io/renv/articles/collaborating.html)
