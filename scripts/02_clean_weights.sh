#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 -i <raw_weights> -o <clean_weights>

Options:
  -i   Input raw weights file
  -o   Output cleaned weights file
EOF
  exit 1
}

# ---- defaults (optional) ----
INPUT=""
CLEAN=""

# ---- parse args ----
while getopts ":i:o:h" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
    o) CLEAN="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ---- validate args ----
if [[ -z "$INPUT" || -z "$CLEAN" ]]; then
  echo "[ERROR] Missing required arguments."
  usage
fi

echo "[STEP 1] Cleaning weight file..."
echo "  INPUT = $INPUT"
echo "  OUTPUT = $CLEAN"

# ---- run cleaning ----
grep -v -E "A T|T A|G C|C G" "$INPUT" \
  | awk 'NR==1 || NF>=3 {print $1, $2, $3}' \
  > "$CLEAN"

echo "[STEP 1] Cleaned weights written to: $CLEAN"
