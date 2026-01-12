#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  stop("Usage: Rscript 08_make_grs_html_report.R <grs_table.csv> <phenotype_file.csv> <out_dir> <out_prefix> <quantile_option>")
}

#grs_file   <- args[1]
#pheno_file <- args[2]
grs_file   <- normalizePath(args[1])
pheno_file <- normalizePath(args[2])
out_dir <- args[3]
out_prefix <- args[4]
q_option   <- args[5]

install_if_needed <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}
install_if_needed("rmarkdown")
library(rmarkdown)

report_params <- list(
  grs_table = grs_file,
  pheno_table = pheno_file,
  outdir = out_dir,
  prefix = out_prefix,
  quantiles = q_option
)

rmarkdown::render(
  input = "scripts/grs_report_template.Rmd",
  output_file = paste0(out_dir, "/", out_prefix, "_GRS_report.html"),
  params = report_params,
  # Setting knit_root_dir to the current directory can help resolve path issues
  knit_root_dir = getwd() 
)
