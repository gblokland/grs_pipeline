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

echo "[STEP 3] Cleaning weights + mapping SNP IDs"
echo "  INPUT = $INPUT"
echo "  MAP   = $MAP"
echo "  OUT   = $CLEAN"

# Expected INPUT columns:
# SNP  effect_allele  other_allele  beta

awk -v MAP="$MAP" '
BEGIN {
  FS=OFS="\t"

  kept=drop_ambig=drop_nomap=drop_beta=drop_dup=total=0

  # ---- load variant map (chr:pos -> rsid) ----
  map_n=0
  while ((getline < MAP) > 0) {
    map_n++
    if (map_n == 1) continue   # skip header
    # columns: chr pos ref alt rsid
    key = $1 ":" $2
    map[key] = $5
  }
  close(MAP)
}

# ---- input header ----
FNR==1 {
  print "SNP","A1","A2","BETA"
  next
}

{
  total++

  snp=$1
  a1=toupper($2)
  a2=toupper($3)
  beta=$4

  # ambiguous SNPs
  if ((a1=="A" && a2=="T") || (a1=="T" && a2=="A") ||
      (a1=="G" && a2=="C") || (a1=="C" && a2=="G")) {
    drop_ambig++
    next
  }

  # ---- SNP ID handling ----
  if (snp ~ /^rs[0-9]+$/) {
    rsid = snp
  } else {
    # expect positional format chr:pos
    if (!(snp in map)) {
      drop_nomap++
      next
    }
    rsid = map[snp]
  }

  # beta must be numeric
  if (beta=="" || beta=="NA") {
    drop_beta++
    next
  }

  # deduplicate
  if (seen[rsid]++) {
    drop_dup++
    next
  }

  print rsid, a1, a2, beta
  kept++
}

END {
  print "=== WEIGHT CLEANING SUMMARY ===" > "/dev/stderr"
  print "Total variants read     :", total > "/dev/stderr"
  print "Kept variants           :", kept > "/dev/stderr"
  print "Dropped ambiguous       :", drop_ambig > "/dev/stderr"
  print "Dropped not in map      :", drop_nomap > "/dev/stderr"
  print "Dropped invalid beta    :", drop_beta > "/dev/stderr"
  print "Dropped duplicates      :", drop_dup > "/dev/stderr"
}
' "$INPUT" > "$CLEAN"

echo "[OK] Cleaned weights written to: $CLEAN"
echo "[STEP 3] Completed."
