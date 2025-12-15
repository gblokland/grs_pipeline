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
    "chr": ["chromosome","chrom","chr"],
    "bp": ["bp","pos","base_pair_location"],
    "snp": ["snp","rsid","rs_id","rs","marker","id","variant_id"],
    "ea": ["effect_allele","ea","a1","allele1","alt"],
    "oa": ["other_allele","non_effect_allele","nea","a2","allele2","ref"],
    "beta": ["beta","effect","logor","log_odds"],
    "or": ["or","odds_ratio"],
    "p": ["p","pval","pvalue","p_value"],
    "se": ["se","stderr","standard_error"]
}

def detect(df, target):
    """
    Detect a column in df that matches the target using COLUMN_SYNONYMS.
    Checks both hm_ prefixed and plain columns.
    """
    for prefix in ["hm_", ""]:
        for col in df.columns:
            c = col.lower()
            for s in COLUMN_SYNONYMS[target]:
                if c.startswith(prefix+s):
                    return col
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

    # Detect columns
    col_snp = detect(df, "snp")
    col_ea  = detect(df, "ea")
    col_oa  = detect(df, "oa")
    col_beta = detect(df, "beta")

    if col_snp is None or col_ea is None or col_oa is None:
        raise ValueError(f"Could not detect required SNP/EA/OA columns. Columns: {df.columns.tolist()}")

    # Detect numeric effect size column
    col_beta = detect(df, "beta")

    if col_beta is not None:
        # Extract numeric part, remove text/range
        df["BETA"] = pd.to_numeric(df[col_beta].astype(str).str.extract(r'([0-9.eE+-]+)')[0], errors="coerce")
    else:
        # try OR or odds_ratio
        or_col = detect(df, "or")
        if or_col is not None:
            df["BETA"] = pd.to_numeric(df[or_col].astype(str).str.extract(r'([0-9.eE+-]+)')[0], errors="coerce").apply(np.log)
        else:
            raise ValueError("Could not detect numeric BETA or OR column")
    
    # Build output dataframe
    out = pd.DataFrame()
    out["SNP"] = df[col_snp]
    out["effect_allele"] = df[col_ea].str.upper()
    out["other_allele"] = df[col_oa].str.upper()
    out["beta"] = df[col_beta]

    # Drop rows with missing beta
    out = out.dropna(subset=["beta"])
    print("Rows after filtering:", len(out))

    # Write output
    out_path = os.path.join(args.outdir, args.outfile)
    out.to_csv(out_path, sep="\t", index=False)
    print(f"Wrote cleaned weights to: {out_path}")

if __name__ == "__main__":
    main()
