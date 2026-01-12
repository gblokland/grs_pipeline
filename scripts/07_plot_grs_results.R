#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript 07_plot_grs_results.R <final_grs.csv> <output_prefix>")
}

input <- args[1]
out_prefix <- args[2]

dat <- read.csv(input)

# Expect columns: IID, GRS (from the postprocess step)
if (!"GRS_raw" %in% colnames(dat)) {
  stop("Input file must contain a column named GRS_raw")
}

# Expect columns: IID, GRS (from the postprocess step)
if (!"GRS_z" %in% colnames(dat)) {
  stop("Input file must contain a column named GRS_raw")
}

png(paste0(out_prefix, "_histogram.png"), width=800, height=600)
hist(dat$GRS_raw,
     main="Distribution of Genetic Risk Scores",
     xlab="GRS",
     ylab="Frequency")
dev.off()

png(paste0(out_prefix, "_boxplot.png"), width=800, height=600)
boxplot(dat$GRS_raw,
        main="Genetic Risk Score Boxplot",
        ylab="GRS")
dev.off()
