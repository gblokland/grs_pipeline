#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 -d <plink_prefix> -w <weights_file> -o <out_prefix>

Options:
  -d   PLINK data prefix (expects .bed/.bim/.fam)
  -w   Cleaned weights file
  -o   Output prefix (directory + basename)
EOF
  exit 1
}

# ---- parse args ----
DATA=""
WEIGHTS=""
OUT=""

while getopts ":d:w:o:h" opt; do
  case $opt in
    d) DATA="$OPTARG" ;;
    w) WEIGHTS="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ---- validate args ----
if [[ -z "$DATA" || -z "$WEIGHTS" || -z "$OUT" ]]; then
  echo "[ERROR] Missing required arguments."
  usage
fi

OUTDIR=$(dirname "$OUT")
mkdir -p "$OUTDIR"

echo "[STEP 4] Running PLINK2 scoring..."
echo "  DATA    = $DATA"
echo "  WEIGHTS = $WEIGHTS"
echo "  OUT     = $OUT"

plink2 \
  --bfile "$DATA" \
  --score "$WEIGHTS" 1 2 4 header \
  --out "$OUT"
  #--score "$WEIGHTS" 1 2 3 header \

echo "[STEP 4] Completed."
echo "  Output file: ${OUT}.sscore"
