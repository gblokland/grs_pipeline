#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 -w <weights_file> -o <log_file>

Options:
  -w   Weights file to checksum
  -o   Output log file
EOF
  exit 1
}

WEIGHTS=""
LOG=""

# ---- parse args ----
while getopts ":w:o:h" opt; do
  case $opt in
    w) WEIGHTS="$OPTARG" ;;
    o) LOG="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ---- validate args ----
if [[ -z "$WEIGHTS" || -z "$LOG" ]]; then
  echo "[ERROR] Missing required arguments."
  usage
fi

if [[ ! -f "$WEIGHTS" ]]; then
  echo "[ERROR] Weights file not found: $WEIGHTS"
  exit 1
fi

LOGDIR=$(dirname "$LOG")
mkdir -p "$LOGDIR"

echo "[LOG] Writing reproducibility log..."
echo "  WEIGHTS = $WEIGHTS"
echo "  LOG     = $LOG"

{
  echo "Date: $(date)"
  echo
  echo "PLINK2 version:"
  plink2 --version
  echo
  echo "Weights checksum (md5):"
  md5sum "$WEIGHTS"
} > "$LOG"

echo "[LOG] Log created at: $LOG"
