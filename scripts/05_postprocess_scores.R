#!/usr/bin/env Rscript

install_if_needed <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

install_if_needed("data.table")

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

cat("[STEP 5] Postprocessing scores\n")
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

# ---- fix PLINK header quirks ----
setnames(sscore, "#FID", "FID", skip_absent = TRUE)
setnames(fam, 1:2, c("FID", "IID"))

# ---- sanity checks ----
required_cols <- c("FID", "IID", "SCORE1_AVG")
missing <- setdiff(required_cols, names(sscore))
if (length(missing)) {
  stop("Missing required columns in sscore file: ", paste(missing, collapse = ", "))
}

# ---- merge ----
dt <- merge(
  fam[, .(FID, IID)],
  sscore,
  by = c("FID", "IID"),
  all.x = TRUE
)

# ---- compute scores ----
dt[, GRS_raw := SCORE1_AVG]
dt[, GRS_z   := as.numeric(scale(GRS_raw))]

# ---- write output ----
fwrite(dt, out_file)

cat("[STEP 5] Final scored dataset written to:", out_file, "\n")
