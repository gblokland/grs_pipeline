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
  -m variant_map_b37.tsv

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

echo
echo "=== PIPELINE FINISHED ==="
date
