#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 -i <raw_weights> -o <clean_weights> -m <variant_map>

Options:
  -i   Input raw weights file (SNP EA OA BETA)
  -o   Output cleaned weights file (rsID EA OA BETA)
  -m   Variant map (positional_id -> rsID)
EOF
  exit 1
}

INPUT=""
CLEAN=""
MAP=""

while getopts ":i:o:m:h" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
    o) CLEAN="$OPTARG" ;;
    m) MAP="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [[ -z "$INPUT" || -z "$CLEAN" || -z "$MAP" ]]; then
  echo "[ERROR] Missing required arguments"
  usage
fi

echo "[STEP] Cleaning weights + mapping SNP IDs"
echo "  INPUT = $INPUT"
echo "  MAP   = $MAP"
echo "  OUT   = $CLEAN"

# Expected INPUT columns:
# SNP  effect_allele  other_allele  beta

awk -v MAP="$MAP" '
BEGIN {
  FS=OFS="\t"

  # Load variant map: positional_id -> rsID
  while ((getline < MAP) > 0) {
    if (NR==1 && $1 ~ /CHR|pos|rs/i) continue
    map[$1]=$2
  }
  close(MAP)
}

NR==1 {
  print "SNP","A1","A2","BETA"
  next
}

{
  snp=$1
  a1=toupper($2)
  a2=toupper($3)
  beta=$4

  # Drop ambiguous SNPs
  if ((a1=="A" && a2=="T") || (a1=="T" && a2=="A") ||
      (a1=="G" && a2=="C") || (a1=="C" && a2=="G")) next

  # Map positional SNP → rsID
  if (!(snp in map)) next
  rsid = map[snp]

  # Keep only valid betas
  if (beta=="" || beta=="NA") next

  print rsid, a1, a2, beta
}
' "$INPUT" \
| awk '!seen[$1]++' \
> "$CLEAN"

echo "[OK] Cleaned weights written to: $CLEAN"
