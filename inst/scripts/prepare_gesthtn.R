#!/usr/bin/env Rscript
# prep_gesthtn_data.R — provenance script for the medrobust `gesthtn` example
# dataset (see docs/SPEC-medrobust-gesthtn-data-2026-06.md).
#
# Downloads the FULL NCHS Natality (NBER mirror), constructs the A/M*/Y/C1
# analysis frame, draws a fixed-seed RANDOM sample, and writes a compact .rda
# ready to drop into medrobust via usethis::use_data(). Run from code/.
#
#   Rscript prep_gesthtn_data.R          # downloads full file (multi-GB) then samples
#   Rscript prep_gesthtn_data.R <csv>    # use an already-downloaded CSV
#
# NOTE: the bounded head-sample in 04_Data/raw/ is a NON-representative pilot;
# this script must use the FULL file for the shipped/representative sample.

YEAR     <- 2021L
URL      <- sprintf("https://data.nber.org/nvss/natality/csv/%d/natality%dus.csv", YEAR, YEAR)
N_SAMPLE <- 5000L
SEED     <- 20260614L
COLS     <- c("mager", "rf_ghype", "combgest", "priorlive")

args <- commandArgs(trailingOnly = TRUE)
src  <- if (length(args)) args[[1]] else {
  dst <- file.path("..", "04_Data", "raw", sprintf("natality%dus.csv", YEAR))
  if (!file.exists(dst)) {
    message("Downloading FULL natality file (multi-GB) -> ", dst)
    options(timeout = 3600)   # the file is ~1.7 GB; R's 60s default is far too short
    utils::download.file(URL, dst, mode = "wb", method = "libcurl")
  }
  dst
}

# Column-subset read keeps memory sane on the full file.
nat <- if (requireNamespace("data.table", quietly = TRUE)) {
  as.data.frame(data.table::fread(src, select = COLS))
} else utils::read.csv(src)[COLS]

build_analysis_df <- function(nat) {
  keep <- !is.na(nat$mager) & nat$rf_ghype %in% c("Y", "N") &
          !is.na(nat$combgest) & nat$combgest != 99 & !is.na(nat$priorlive)
  nat <- nat[keep, ]
  data.frame(
    A      = as.integer(nat$mager >= 35),
    M_star = as.integer(nat$rf_ghype == "Y"),
    Y      = as.integer(nat$combgest < 37),
    C1     = as.integer(nat$priorlive > 0)
  )
}

df <- build_analysis_df(nat)
set.seed(SEED)
gesthtn <- df[sample(nrow(df), min(N_SAMPLE, nrow(df))), ]
rownames(gesthtn) <- NULL

out <- file.path("..", "04_Data", "gesthtn.rda")
save(gesthtn, file = out, compress = "xz")
cat(sprintf("wrote %s : %d rows (from %d complete cases); M* prev %.3f, preterm %.3f\n",
            out, nrow(gesthtn), nrow(df), mean(gesthtn$M_star), mean(gesthtn$Y)))
cat("Drop into medrobust with: usethis::use_data(gesthtn, compress='xz') + R/data.R doc.\n")
