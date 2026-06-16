#!/usr/bin/env Rscript
# =====================================================================
# prepare_nhanes_pa.R -- provenance script for the medrobust `nhanes_pa`
# example dataset (exposure-side mirror of gesthtn; see GitHub issue #12 and
# SPEC-nhanes-pa-example-2026-06-15.md).
#
# Triad (all binary; the EXPOSURE is the misclassified/surrogate one):
#   A_star = self-reported physical INACTIVITY (recall/report-prone, no biomarker)
#            1 = fails 2018 aerobic guideline (<150 min/wk moderate-equivalent
#                leisure-time activity), 0 = meets it.
#   M      = elevated systemic inflammation, hs-CRP >= 3 mg/L  (LAB-measured = error-free)
#   Y      = prevalent CVD: any of CHD / angina / MI / stroke (MCQ160C/D/E/F)
#   C1     = age >= 50 yrs    C2 = female    C3 = obese (BMI >= 30)
#
# Pools cycles 2015-2016 (_I) + 2017-2018 (_J). Public, no auth. Pull via nhanesA.
# Builds the FULL complete-case sample (no random sampling -> no seed needed) and
# writes it into the package via usethis::use_data(). RUN FROM THE REPO ROOT:
#
#   Rscript inst/scripts/prepare_nhanes_pa.R    # nhanesA network pull -> data/nhanes_pa.rda
#
# Requires the `nhanesA` (Suggests) and `usethis` packages and network access to
# the CDC NHANES servers. Mirrors the medrobust gesthtn prepare-script pattern.
# =====================================================================

suppressPackageStartupMessages(library(nhanesA))

# numeric-code pull (translated = FALSE) so we can compute on 1/2 (Yes/No) codes
fetch_nhanes <- function(nm) {
  d <- tryCatch(nhanes(nm, translated = FALSE), error = function(e) {
    message("fetch failed: ", nm, " (", conditionMessage(e), ")"); NULL })
  if (is.null(d)) stop("could not fetch ", nm)
  d
}

# Yes/No (1/2) NHANES code -> 1/0, with 7/9 (refused/don't know) -> NA
yn <- function(x) { x[x %in% c(7, 9)] <- NA; ifelse(x == 1, 1L, ifelse(x == 2, 0L, NA_integer_)) }
# wide numeric field (minutes/day): blank out the 4-/5-digit refused/dk sentinels.
# NB: do NOT mask 77/99 here -- 77 or 99 minutes/day is a legitimate value.
num <- function(x) { x[x %in% c(7777, 9999, 77777, 99999)] <- NA; suppressWarnings(as.numeric(x)) }
# bounded day-count field (valid 1-7): refused 77 / don't-know 99 are the sentinels here.
days <- function(x) { x[x %in% c(77, 99)] <- NA; suppressWarnings(as.numeric(x)) }

build_cycle <- function(suf) {                  # suf = "I" (2015-16) or "J" (2017-18)
  demo <- fetch_nhanes(paste0("DEMO_",  suf))[, c("SEQN", "RIDAGEYR", "RIAGENDR")]
  crp  <- fetch_nhanes(paste0("HSCRP_", suf))[, c("SEQN", "LBXHSCRP")]
  bmx  <- fetch_nhanes(paste0("BMX_",   suf))[, c("SEQN", "BMXBMI")]
  mcq  <- fetch_nhanes(paste0("MCQ_",   suf))
  paq  <- fetch_nhanes(paste0("PAQ_",   suf))

  # --- A_star: leisure-time aerobic activity, moderate-equivalent min/wk ---
  # vigorous recreational: PAQ650 (did any) -> PAQ655 (days) x PAD660 (min/day)
  # moderate recreational: PAQ665 (did any) -> PAQ670 (days) x PAD675 (min/day)
  vig <- ifelse(yn(paq$PAQ650) == 1, days(paq$PAQ655) * num(paq$PAD660), 0)
  mod <- ifelse(yn(paq$PAQ665) == 1, days(paq$PAQ670) * num(paq$PAD675), 0)
  vig[is.na(vig)] <- 0; mod[is.na(mod)] <- 0
  equiv_mod_min <- mod + 2 * vig                 # 2018 PAG: vigorous counts double
  # inactive iff a valid gate answer exists and equiv < 150
  gate_ok <- !is.na(yn(paq$PAQ650)) & !is.na(yn(paq$PAQ665))
  paq_df <- data.frame(SEQN = paq$SEQN,
                       A_star = ifelse(gate_ok, as.integer(equiv_mod_min < 150), NA_integer_))

  # --- Y: prevalent CVD = any of CHD/angina/MI/stroke ---
  cvd_cols <- c("MCQ160C", "MCQ160D", "MCQ160E", "MCQ160F")
  cvd_cols <- cvd_cols[cvd_cols %in% names(mcq)]
  ybin <- sapply(mcq[cvd_cols], yn)
  Y <- ifelse(rowSums(ybin == 1, na.rm = TRUE) > 0, 1L,
              ifelse(rowSums(!is.na(ybin)) > 0, 0L, NA_integer_))
  mcq_df <- data.frame(SEQN = mcq$SEQN, Y = Y)

  d <- Reduce(function(a, b) merge(a, b, by = "SEQN", all = TRUE),
              list(demo, crp, bmx, paq_df, mcq_df))
  data.frame(
    SEQN   = d$SEQN,
    cycle  = suf,
    A_star = d$A_star,
    M      = ifelse(is.na(d$LBXHSCRP), NA_integer_, as.integer(d$LBXHSCRP >= 3)),
    Y      = d$Y,
    # Binary confounders crossed into bound_ne strata (8 cells; feasibility-checked 2026-06-15).
    C1     = ifelse(is.na(d$RIDAGEYR), NA_integer_, as.integer(d$RIDAGEYR >= 50)),   # age >= 50
    C2     = ifelse(is.na(d$RIAGENDR), NA_integer_, as.integer(d$RIAGENDR == 2)),    # female
    C3     = ifelse(is.na(d$BMXBMI),   NA_integer_, as.integer(d$BMXBMI   >= 30)),   # obese (BMI>=30)
    age    = d$RIDAGEYR
  )
}

cat("Pulling NHANES 2015-2016 (_I) and 2017-2018 (_J) via nhanesA ...\n")
pooled <- rbind(build_cycle("I"), build_cycle("J"))

# adults only (PAQ/MCQ are adult items), then complete cases on the modeled binaries
pooled <- pooled[!is.na(pooled$age) & pooled$age >= 20, ]
keep <- c("A_star", "M", "Y", "C1", "C2", "C3")
cc <- pooled[stats::complete.cases(pooled[, keep]), ]

# ship the FULL complete-case sample (no sampling, no seed): integer 0/1 columns only
nhanes_pa <- cc[, keep]
nhanes_pa[] <- lapply(nhanes_pa, as.integer)
rownames(nhanes_pa) <- NULL

cat(sprintf("\nAnalytic N = %d (pooled, adults 20+, complete cases)\n", nrow(nhanes_pa)))
cat("A_star (inactive) prevalence:", round(mean(nhanes_pa$A_star), 3), "\n")
cat("M (hs-CRP>=3) prevalence:    ", round(mean(nhanes_pa$M), 3), "\n")
cat("Y (CVD) prevalence:          ", round(mean(nhanes_pa$Y), 3), "\n")
cat("C1 (age>=50) prevalence:     ", round(mean(nhanes_pa$C1), 3), "\n")
cat("C2 (female) prevalence:      ", round(mean(nhanes_pa$C2), 3), "\n")
cat("C3 (obese BMI>=30) prevalence:", round(mean(nhanes_pa$C3), 3), "\n")
cat("8-stratum (C1xC2xC3) sizes:  ", paste(sort(as.vector(table(nhanes_pa$C1, nhanes_pa$C2, nhanes_pa$C3))), collapse = ", "), "\n")
cat("\nA_star x Y cross-tab:\n"); print(table(A_star = nhanes_pa$A_star, Y = nhanes_pa$Y))

# write into the package's data/ (run from repo root)
usethis::use_data(nhanes_pa, compress = "xz", overwrite = TRUE)
cat("\nWrote data/nhanes_pa.rda\n")
