#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 -d <plink_prefix> -w <weights_file>

Options:
  -d   PLINK data prefix (expects .bed/.bim/.fam)
  -w   Weights file
EOF
  exit 1
}

# ---- defaults (optional) ----
DATA_PREFIX=""
WEIGHTS=""

# ---- parse args ----
while getopts ":d:w:h" opt; do
  case $opt in
    d) DATA_PREFIX="$OPTARG" ;;
    w) WEIGHTS="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ---- validate args ----
if [[ -z "$DATA_PREFIX" || -z "$WEIGHTS" ]]; then
  echo "[ERROR] Missing required arguments."
  usage
fi

echo "[CHECK] Validating inputs..."
echo "  DATA_PREFIX = $DATA_PREFIX"
echo "  WEIGHTS     = $WEIGHTS"

# ---- tool check ----
if ! command -v plink2 &>/dev/null; then
  echo "[ERROR] plink2 not found in PATH."
  exit 1
fi

# ---- PLINK files ----
for ext in bed bim fam; do
  if [[ ! -f "${DATA_PREFIX}.${ext}" ]]; then
    echo "[ERROR] Missing file: ${DATA_PREFIX}.${ext}"
    exit 1
  fi
done

# ---- weights ----
if [[ ! -f "$WEIGHTS" ]]; then
  echo "[ERROR] Missing weight file: $WEIGHTS"
  exit 1
fi

echo "[CHECK] All inputs OK."
