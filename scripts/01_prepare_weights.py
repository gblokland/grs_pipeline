#!/usr/bin/env python3
# Simplified prepare_weights script
import pandas as pd
import argparse, re

COLUMN_SYNONYMS = {
    "snp": ["snp","rsid","rs_id","rs","marker","id"],
    "ea": ["effect_allele","ea","a1","allele1","alt"],
    "oa": ["other_allele","nea","a2","allele2","ref"],
    "beta": ["beta","effect","logor","log_odds"],
    "p": ["p","pval","pvalue"],
    "se": ["se","stderr"]
}

def detect(df,target):
    for col in df.columns:
        c=col.lower()
        for s in COLUMN_SYNONYMS[target]:
            if c==s or c.startswith(s):
                return col
    return None

parser=argparse.ArgumentParser()
parser.add_argument("--sumstats",required=True)
parser.add_argument("--out",required=True)
args=parser.parse_args()

df=pd.read_csv(args.sumstats,sep=None,engine="python")

col_snp=detect(df,"snp")
col_ea=detect(df,"ea")
col_oa=detect(df,"oa")
col_beta=detect(df,"beta")

out=pd.DataFrame()
out["SNP"]=df[col_snp]
out["effect_allele"]=df[col_ea].str.upper()
out["other_allele"]=df[col_oa].str.upper()
out["beta"]=df[col_beta].astype(float)
out.to_csv(args.out+".weights.txt",sep="\t",index=False)
print("Wrote",args.out+".weights.txt")
