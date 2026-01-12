#!/bin/bash
# run_grs_pipeline.sh
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 <sumstats> <bedprefix> [out_prefix] [quantiles] [pheno_file]

Arguments:
  sumstats     GWAS summary statistics file
  bedprefix    PLINK prefix (without .bed/.bim/.fam)
  out_prefix   Output prefix (optional; auto-derived if omitted)
  quantiles    all | terciles | quartiles | quintiles | deciles (optional)
  pheno_file   /path/to/phenotypes.csv (optional)

Defaults:
  out_prefix  = <sumstats>_<bedprefix>
  quantiles   = all
  data_dir    = /root/persistent/data
  results_dir = /root/persistent/results/grs/$OUT
EOF
  exit 1
}

# ---- arguments ----
SUMSTATS=${1:-}
BEDPREFIX=${2:-}
OUT=${3:-}
QUANTILES="${4:-all}"
PHENO_TABLE="${5:-}"

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
RESULTS_DIR="/root/persistent/results/grs/$OUT"
REF_MAP="/root/persistent/ref_panels/hg19_GRCh37/variant_map_b37.tsv"

mkdir -p "$RESULTS_DIR"

echo "=== GRS PIPELINE START ==="
date
echo "SUMSTATS   = $SUMSTATS"
echo "BEDPREFIX  = $BEDPREFIX"
echo "OUT        = $OUT"
echo "QUANTILES  = $QUANTILES"
echo

# ---- sanity checks ----
for ext in bed bim fam; do
  [[ -f "${DATA_DIR}/${BEDPREFIX}.${ext}" ]] || {
    echo "ERROR: Missing ${BEDPREFIX}.${ext}"
    exit 1
  }
done

[[ -f "$SUMSTATS" ]] || {
  echo "ERROR: Sumstats file not found"
  exit 1
}

# ---- pipeline ----
if [[ ! -f "$REF_MAP" ]]; then
    bash scripts/00_make_variant_map.sh
fi

echo "=== PREPARING WEIGHTS ==="

python3 scripts/01_prepare_weights.py \
  --sumstats "$SUMSTATS" \
  --outdir "$RESULTS_DIR" \
  --outfile "weights_${OUT}.raw.txt"

echo "=== CHECKING INPUTS ==="

bash scripts/02_check_inputs.sh \
  -d "${DATA_DIR}/${BEDPREFIX}" \
  -w "${RESULTS_DIR}/weights_${OUT}.raw.txt"

echo "=== CLEANING WEIGHTS ==="

bash scripts/03_clean_weights.sh \
  -i "${RESULTS_DIR}/weights_${OUT}.raw.txt" \
  -o "${RESULTS_DIR}/weights_${OUT}.clean.txt" \
  -m "$REF_MAP"

echo "=== RUNNING PLINK SCORING ==="

bash scripts/04_run_plink_score.sh \
  -d "${DATA_DIR}/${BEDPREFIX}" \
  -w "${RESULTS_DIR}/weights_${OUT}.clean.txt" \
  -o "${RESULTS_DIR}/grs_${OUT}"

echo "=== POSTPROCESSING ==="

Rscript scripts/05_postprocess_scores.R \
  "${RESULTS_DIR}/grs_${OUT}.sscore" \
  "${DATA_DIR}/${BEDPREFIX}.fam" \
  "${RESULTS_DIR}/final_grs_${OUT}.csv"

echo "=== REPRODUCIBILITY ==="

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

echo "Quantile option = $QUANTILES"

# ---- R MARKDOWN REPORTING ----

echo
echo "=== CREATING R MARKDOWN REPORT ==="

#PHENO_TABLE="${DATA_DIR}/phenotypes.csv"
REPORT_PREFIX="report_${OUT}"

if [[ -n "${PHENO_TABLE}" && -f "${PHENO_TABLE}" ]]; then
  echo "Using phenotype table: ${PHENO_TABLE}"
  Rscript scripts/08_make_grs_html_report.R \
    "${RESULTS_DIR}/final_grs_${OUT}.csv" \
    "${PHENO_TABLE}" \
    "${RESULTS_DIR}" \
    "${REPORT_PREFIX}" \
    "${QUANTILES}"
else
  echo "No phenotype table provided – generating report without phenotypes"
  Rscript scripts/08_make_grs_html_report.R \
    "${RESULTS_DIR}/final_grs_${OUT}.csv" \
    "" \
    "${RESULTS_DIR}" \
    "${REPORT_PREFIX}" \
    "${QUANTILES}"
fi

# ---- ARCHIVE ALL OUTPUT ----

ARCHIVE_FILE="${RESULTS_DIR}/../${OUT}_grs_results.tar.gz"

echo
echo "=== CREATING ARCHIVE OF RESULTS ==="
tar -czf "$ARCHIVE_FILE" -C "$RESULTS_DIR" . 

if [[ -f "$ARCHIVE_FILE" ]]; then
    echo "Archive created successfully!"
    echo "You can download it here: $ARCHIVE_FILE"
else
    echo "ERROR: Failed to create archive."
    exit 1
fi

echo
echo "=== PIPELINE FINISHED ==="
date
