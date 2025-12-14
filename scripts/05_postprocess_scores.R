#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)

usage <- function() {
  cat("
Usage:
  03_postprocess_scores.R <plink_sscore> <fam_file> <out_file>

Arguments:
  plink_sscore   PLINK2 .sscore file
  fam_file       PLINK .fam file
  out_file       Output CSV file
\n")
  quit(status = 1)
}

if (length(args) != 3) {
  usage()
}

sscore_file <- args[1]
fam_file    <- args[2]
out_file    <- args[3]

cat("[STEP 3] Postprocessing scores\n")
cat("  sscore =", sscore_file, "\n")
cat("  fam    =", fam_file, "\n")
cat("  out    =", out_file, "\n")

# ---- checks ----
if (!file.exists(sscore_file)) {
  stop("Missing sscore file: ", sscore_file)
}
if (!file.exists(fam_file)) {
  stop("Missing fam file: ", fam_file)
}

# ---- load data ----
sscore <- fread(sscore_file)
fam <- fread(fam_file, header = FALSE)

setnames(fam, 1:2, c("FID", "IID"))

# ---- merge ----
dt <- merge(
  fam[, .(FID, IID)],
  sscore,
  by = c("FID", "IID"),
  all.x = TRUE
)

# ---- compute scores ----
if (!"SCORE1_SUM" %in% names(dt)) {
  stop("Expected column SCORE1_SUM not found in sscore file")
}

dt[, GRS_raw := SCORE1_SUM]
dt[, GRS_z := as.numeric(scale(GRS_raw))]

# ---- write output ----
fwrite(dt, out_file)

cat("[STEP 3] Final scored dataset written to:", out_file, "\n")
