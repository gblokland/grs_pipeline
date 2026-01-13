# Author: Gabriella Blokland, Maastricht University

## Example runs

### Minimal (auto-naming)
```
./run_grs_pipeline.sh gwas.sumstats.gz mydata
./run_grs_pipeline.sh gwas.sumstats.gz mydata [out_prefix] [quantiles] [pheno_file]
```
#Produces:
#weights_gwas_mydata.*
#results/grs_gwas_mydata.*
#results/final_grs_gwas_mydata.csv

### Explicit output name
```
./run_grs_pipeline.sh bmi_gwas_sumstats.gz mydata bmi_grs

#Test with T2D sumstats and unimputed genotype data, without phenotypes.csv
./run_grs_pipeline.sh /root/persistent/sumstats/DM_T2D/Xue_2018_NatComms-GCST006001-GCST007000/GCST006867/harmonised/30054458-GCST006867-EFO_0001360-build37.f.tsv.gz dmsa.randomid t2d_Xue2018

#Test with T2D sumstats and unimputed genotype data, with specification of quantiles, and phenotypes.csv
./run_grs_pipeline.sh /root/persistent/sumstats/DM_T2D/Xue_2018_NatComms-GCST006001-GCST007000/GCST006867/harmonised/30054458-GCST006867-EFO_0001360-build37.f.tsv.gz dmsa.randomid t2d_Xue2018 all /root/persistent/results/grs/phenotypes.csv

#Test with glaucoma sumstats and unimputed genotype data, with specification of quantiles, and phenotypes.csv
./run_grs_pipeline.sh /root/persistent/sumstats/Ophthalmology/glaucoma_Craig_2020_NatGenet/GCST009722/harmonised/31959993-GCST009722-EFO_0000516.h.tsv.gz dmsa.randomid glaucoma_Craig2020 all /root/persistent/results/grs/phenotypes.csv

#Test with CRP sumstats and unimputed genotype data, with specification of quantiles, and phenotypes.csv
./run_grs_pipeline.sh /root/persistent/sumstats/Biomarkers/CRP/35459240-GCST90029070-EFO_0004458-Build37.f.tsv.gz dmsa.randomid crp_Said2022 all /root/persistent/results/grs/phenotypes.csv

#Test with granulocyte sumstats and unimputed genotype data, with specification of quantiles, and phenotypes.csv
./run_grs_pipeline.sh /root/persistent/sumstats/Biomarkers/granulocyte/27863252-GCST004614-EFO_0007987-Build37.f.tsv.gz dmsa.randomid granulocyte_Astle2016 all /root/persistent/results/grs/phenotypes.csv

#Test with lymphocyte sumstats and unimputed genotype data, with specification of quantiles, and phenotypes.csv
./run_grs_pipeline.sh /root/persistent/sumstats/Biomarkers/lymphocyte/27863252-GCST004632-EFO_0007993-Build37.f.tsv.gz dmsa.randomid lymphocyte_Astle2016 all /root/persistent/results/grs/phenotypes.csv
```

#Produces:
#weights_bmi_grs.*
#results/grs_bmi_grs.*
#results/final_grs_bmi_grs.csv
