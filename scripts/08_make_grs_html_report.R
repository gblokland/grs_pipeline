#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  stop("Usage: Rscript 08_make_grs_html_report.R <grs_table.csv> <phenotype_file.csv> <out_prefix> <quantile_option>")
}

grs_file   <- args[1]
pheno_file <- args[2]
out_prefix <- args[3]
q_option   <- args[4]

library(rmarkdown)

params <- list(
  grs_table = grs_file,
  pheno_table = pheno_file,
  prefix = out_prefix,
  quantiles = q_option
)

render(
  input = "scripts/grs_report_template.Rmd",
  output_file = paste0(out_prefix, "_GRS_report.html"),
  params = params,
  envir = new.env()
)