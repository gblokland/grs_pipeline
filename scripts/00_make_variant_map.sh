#!/bin/bash
# Make variant map for assigning rsIDs in place of positional IDs
wget https://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh37p13/VCF/00-All.vcf.gz
wget https://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b151_GRCh37p13/VCF/00-All.vcf.gz.tbi
bcftools query \
  -f '%CHROM\t%POS\t%REF\t%ALT\t%ID\n' \
  -i 'TYPE="snp" && N_ALT=1' \
  00-All.vcf.gz > variant_map_b37.tsv
#gzip variant_map_b37.tsv
#gunzip variant_map_b37.tsv


for i in {1..23}; do
plink2 --pfile ${datafile}_chr"$i" \
--update-name variant_map_b37.tsv \
--make-pgen --out ${datafile}_chr"$i"_rsid
done
#For example, if the --update-name file is
#chr1:1919191   rs123456
#chr1:64646464  rs222222
