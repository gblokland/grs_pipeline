#!/usr/bin/env python3
"""
prepare_weights.py - Prepare GWAS summary statistics for GRS pipeline

Usage:
  python prepare_weights.py --sumstats path/to/file.tsv.gz --outdir results/grs --outfile weights_t2d.raw.txt
"""

import pandas as pd
import numpy as np
import argparse
import os
import re

# Column synonyms
COLUMN_SYNONYMS = {
    "chr": ["chr","chromosome","chrom"],
    "bp": ["bp","pos","base_pair_location","base_pair_position"],
    "snp": ["snp","rsid","rs_id","rs","marker","id","variant_id"],
    "ea": ["ea","effect_allele","a1","allele1","alt","alternative_allele"],
    "oa": ["oa","nea","other_allele","non_effect_allele","a2","allele2","ref","reference_allele"],
    "eaf": ["eaf","effect_allele_frequency","allele_frequency","af","maf"],
    "beta": ["beta","effect","logor","log_odds"],
    "or": ["or","odds_ratio","oddsratio"],
    "p": ["p","pval","p_val","pvalue","p_value"],
    "se": ["se","stderr","std_err","standard_error"],
    "cilb": ["cilb","ci_lower","ci_lb"],
    "ciub": ["ciub","ci_upper","ci_ub"]
}

def detect(df, target):
    synonyms = COLUMN_SYNONYMS[target]
    cols = {c.lower(): c for c in df.columns}

    # exact match first (highest priority)
    for s in synonyms:
        if s in cols:
            return cols[s]

    # hm_ prefixed exact match
    for s in synonyms:
        key = "hm_" + s
        if key in cols:
            return cols[key]

    return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sumstats", required=True, help="Input summary stats (.tsv, .csv, optionally gzipped)")
    parser.add_argument("--outdir", required=False, default=".", help="Output directory")
    parser.add_argument("--outfile", required=False, default="weights_clean.txt", help="Output file name")
    args = parser.parse_args()

    # Ensure output directory exists
    os.makedirs(args.outdir, exist_ok=True)

    # Load dataframe
    try:
        df = pd.read_csv(args.sumstats, sep="\t", compression="infer", low_memory=False)
    except Exception:
        df = pd.read_csv(args.sumstats, sep=",", compression="infer", low_memory=False)

    print("Columns detected:", df.columns.tolist())
    print("Rows before filtering:", len(df))

    # Detect SNP and allele columns
    col_snp = detect(df, "snp")
    col_ea  = detect(df, "ea")
    col_oa  = detect(df, "oa")

    if col_snp is None or col_ea is None or col_oa is None:
        raise ValueError(f"Could not detect required SNP/EA/OA columns. Columns: {df.columns.tolist()}")

    # Detect numeric effect size column
    col_beta = detect(df, "beta")

    #if col_beta is not None:
    #    # Extract numeric part, remove text/range
    #    df["beta"] = pd.to_numeric(df[col_beta].astype(str).str.extract(r'([0-9.eE+-]+)')[0], errors="coerce")
    #else:
    #    # try OR or odds_ratio
    #    or_col = detect(df, "or")
    #    if or_col is not None:
    #        df["beta"] = pd.to_numeric(df[or_col].astype(str).str.extract(r'([0-9.eE+-]+)')[0], errors="coerce").apply(np.log)
    #    else:
    #        raise ValueError("Could not detect numeric BETA or OR column")
    
    if col_beta is not None:
        df["beta"] = pd.to_numeric(df[col_beta], errors="coerce")
    else:
        col_or = detect(df, "or")
        if col_or is None:
            raise ValueError("No BETA or OR column detected")
        df["beta"] = pd.to_numeric(df[col_or], errors="coerce").apply(np.log)

    if df["beta"].notna().sum() == 0:
        raise ValueError(
            f"Detected beta column '{col_beta}' but all values are non-numeric"
        )
        
    # Build output dataframe
    out = pd.DataFrame()
    out["SNP"] = df[col_snp]
    out["effect_allele"] = df[col_ea].str.upper()
    out["other_allele"] = df[col_oa].str.upper()
    out["beta"] = df["beta"]

    # Drop rows with missing beta
    out = out.dropna(subset=["beta"])
    print("Rows after filtering:", len(out))

    # Write output
    out_path = os.path.join(args.outdir, args.outfile)
    out.to_csv(out_path, sep="\t", index=False)
    print(f"Wrote cleaned weights to: {out_path}")

if __name__ == "__main__":
    main()
