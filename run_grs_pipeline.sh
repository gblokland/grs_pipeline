#!/bin/bash
# run_grs_pipeline.sh
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 <sumstats> <bedprefix> [out_prefix]

Arguments:
  sumstats     GWAS summary statistics file
  bedprefix    PLINK prefix (without .bed/.bim/.fam)
  out_prefix   Output prefix (optional; auto-derived if omitted)

Defaults:
  data dir     = /root/persistent/data/
  results dir  = /root/persistent/results/
EOF
  exit 1
}

# ---- arguments ----
SUMSTATS=${1:-}
BEDPREFIX=${2:-}
OUT=${3:-}

if [[ -z "$SUMSTATS" || -z "$BEDPREFIX" ]]; then
  usage
fi

# ---- defaults ----
if [[ -z "$OUT" ]]; then
  SUMBASE=$(basename "$SUMSTATS")
  SUMBASE=${SUMBASE%%.*}
  BEDBASE=$(basename "$BEDPREFIX")
  OUT="${SUMBASE}_${BEDBASE}"
fi

DATA_DIR="/root/persistent/data"
RESULTS_DIR="/root/persistent/results/grs"

mkdir -p "$RESULTS_DIR"

echo "=== GRS PIPELINE START ==="
date
echo "SUMSTATS   = $SUMSTATS"
echo "BEDPREFIX  = $BEDPREFIX"
echo "OUT        = $OUT"
echo

# ---- pipeline ----
if [ ! -f /root/persistent/ref_panels/hg19_GRCh37/variant_map_b37.tsv ]; then
    bash scripts/00_make_variant_map.sh
fi

python3 scripts/01_prepare_weights.py \
  --sumstats "$SUMSTATS" \
  --outdir "$RESULTS_DIR" \
  --outfile "weights_${OUT}.raw.txt"

bash scripts/02_check_inputs.sh \
  -d "${DATA_DIR}/${BEDPREFIX}" \
  -w "${RESULTS_DIR}/weights_${OUT}.raw.txt"

bash scripts/03_clean_weights.sh \
  -i "${RESULTS_DIR}/weights_${OUT}.raw.txt" \
  -o "${RESULTS_DIR}/weights_${OUT}.clean.txt" \
  -m /root/persistent/ref_panels/hg19_GRCh37/variant_map_b37.tsv

bash scripts/04_run_plink_score.sh \
  -d "${DATA_DIR}/${BEDPREFIX}" \
  -w "${RESULTS_DIR}/weights_${OUT}.clean.txt" \
  -o "${RESULTS_DIR}/grs_${OUT}"

Rscript scripts/05_postprocess_scores.R \
  "${RESULTS_DIR}/grs_${OUT}.sscore" \
  "${DATA_DIR}/${BEDPREFIX}.fam" \
  "${RESULTS_DIR}/final_grs_${OUT}.csv"

bash scripts/06_reproducibility_log.sh \
  -w "${RESULTS_DIR}/weights_${OUT}.clean.txt" \
  -o "${RESULTS_DIR}/reproducibility_${OUT}.log"

# ---- PLOTTING SECTION ----

# Run the plotting script
echo
echo "=== GENERATING PLOTS ==="

Rscript scripts/07_plot_grs_results.R \
  "${RESULTS_DIR}/final_grs_${OUT}.csv" \
  "${RESULTS_DIR}/plots_${OUT}"

# ---- optional extra argument for quantile choice ----
# Options are:
# QUANTILES="terciles"
# QUANTILES="quartiles"
# QUANTILES="quintiles"
# QUANTILES="deciles"
# QUANTILES="all"  #default is all of the above

QUANTILES=${4:-"all"}

echo "Quantile option = $QUANTILES"

# ---- R MARKDOWN REPORTING ----

echo
echo "=== CREATING R MARKDOWN REPORT ==="

PHENO_TABLE="${DATA_DIR}/phenotypes.csv"

Rscript scripts/08_make_grs_html_report.R \
  "${RESULTS_DIR}/final_grs_${OUT}.csv" \
  "$PHENO_TABLE" \
  "${RESULTS_DIR}/report_${OUT}" \
  "$QUANTILES"

echo
echo "=== PIPELINE FINISHED ==="
date
