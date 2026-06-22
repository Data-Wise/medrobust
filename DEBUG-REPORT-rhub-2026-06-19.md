# medrobust rhub Debug Report — 2026-06-19

## Final Verdict: RESOLVED ✅

All 4 r-hub platforms pass on run **twill-brownbutterfly** (run
27854775371, sha 1b79f8f, dev branch).

------------------------------------------------------------------------

## Timeline of Runs

| Run name | SHA | ubuntu-clang | ubuntu-gcc12 | nosuggests | gcc-asan | Root cause |
|----|----|:--:|:--:|:--:|:--:|----|
| kaleidoscopic-bubblefish (27853569154) | 48f9ce8 | ✅ | ✅ | ❌ | ❌ | pak devel 0.10.0.9000 bootstrap broken |
| scarabaeiform-frog (27854573292) | 48f9ce8 | ✅ | ✅ | ❌ | ❌ | Same (dispatched before fix) |
| subterrestrial-mussel (27854677715) | 2c53ddb | ❌ | ❌ | ❌ | ❌ | `.Rprofile` crashed R startup |
| **twill-brownbutterfly (27854775371)** | **1b79f8f** | **✅** | **✅** | **✅** | **✅** | **All renv artifacts removed** |

------------------------------------------------------------------------

## Root Cause Analysis

Three layered failures, each masking the next:

### Layer 1 — pak devel regression (r-lib/pak \#887)

**Symptom:**
`Error in loadNamespace(x) : there is no package called 'pak'`
immediately after “Installing pak … OK” in the nosuggests and gcc-asan
containers.

**Root cause:** `r-hub/actions/setup-deps@v1` defaults to
`pak-version: devel`, installing pak 0.10.0.9000. This pre-release build
has a broken bootstrap — the binary installs but `loadNamespace('pak')`
fails because `install_extracted_binary()` or its `filelock` dependency
is not bundled correctly.

**Fix (commit 48f9ce8):** Added `pak-version: stable` to both
`setup-deps@v1` blocks in `.github/workflows/rhub.yaml`:

``` yaml
- uses: r-hub/actions/setup-deps@v1
  with:
    pak-version: stable
    token: ${{ secrets.RHUB_TOKEN }}
    job-config: ${{ matrix.config.job-config }}
```

**Why it didn’t fully fix the problem:** The next layer was then
exposed.

------------------------------------------------------------------------

### Layer 2 — renv.lock tracked in git redirects R_LIB_FOR_PAK

**Symptom:** nosuggests and gcc-asan still failed with pak namespace
errors even after pinning stable pak.

**Root cause:** `renv.lock` was tracked in git (committed during initial
package setup). The `setup-deps@v1` action detects `renv.lock` at repo
root and interprets the project as an renv project. It then sets
`R_LIB_FOR_PAK` to the renv library path
(`/github/home/.cache/R/renv/library/medrobust-86e8509d/...`). Pak
installs into that path successfully, but renv intercepts
[`.libPaths()`](https://rdrr.io/r/base/libPaths.html) and the namespace
load fails because the pak installation path is not on the search path
that `loadNamespace` uses.

**Fix (commit 2c53ddb):**

``` bash
git rm --cached renv.lock renv/activate.R renv/settings.json renv/.gitignore
```

Updated `.gitignore` to exclude all renv artifacts:

    renv.lock
    renv/

**Why it didn’t fully fix the problem:** `.Rprofile` (still tracked)
crashed R before setup-deps even ran.

------------------------------------------------------------------------

### Layer 3 — .Rprofile sources missing renv/activate.R

**Symptom:** All 4 platforms failed at `r-hub/actions/platform-info@v1`
with:

    Error in file(filename, "r", encoding = encoding) :
      cannot open the connection
    In addition: Warning message:
    In file(filename, "r", encoding = encoding) :
      cannot open file 'renv/activate.R': No such file or directory
    Execution halted

**Root cause:** `.Rprofile` (single line: `source("renv/activate.R")`)
was still tracked in git. R sources `.Rprofile` on every startup —
including during the `platform-info` step, which runs `Rscript`. Since
`renv/activate.R` no longer existed in the repo (removed in Layer 2
fix), every R invocation crashed before any package code ran.

**Fix (commit 1b79f8f):**

``` bash
git rm --cached .Rprofile RENV_SETUP.md
rm .Rprofile  # file only contained renv activation; no other content
```

Updated `.gitignore`:

    .Rprofile
    RENV_SETUP.md

------------------------------------------------------------------------

## Files Changed

| Commit | Files | Change |
|----|----|----|
| 48f9ce8 | `.github/workflows/rhub.yaml` | Add `pak-version: stable` to both setup-deps blocks |
| 2c53ddb | `.gitignore`, `renv.lock`, `renv/activate.R`, `renv/settings.json`, `renv/.gitignore` | Remove renv tracking; update gitignore |
| 1b79f8f | `.gitignore`, `.Rprofile`, `RENV_SETUP.md` | Remove .Rprofile + RENV_SETUP.md tracking; delete .Rprofile locally |
| 8392d45 | `cran-comments.md` | Update with clean twill-brownbutterfly results |

------------------------------------------------------------------------

## CRAN Readiness

- **R CMD check**: 0 errors, 0 warnings, 1 note (expected new-submission
  note)
- **win-builder R-release**: OK (token 0pY8ajL2oIoD)
- **win-builder R-oldrelease**: OK (token d0MT9b7E7wFP)
- **r-hub twill-brownbutterfly**: 4/4 platforms ✅
- **Status**: Ready for
  [`devtools::submit_cran()`](https://devtools.r-lib.org/reference/submit_cran.html)
