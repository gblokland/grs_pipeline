## Example runs

### Minimal (auto-naming)

./run_grs_pipeline.sh gwas.sumstats.gz mydata

#Produces:
#weights_gwas_mydata.*
#results/grs_gwas_mydata.*
#results/final_grs_gwas_mydata.csv

### Explicit output name

./run_grs_pipeline.sh gwas.sumstats.gz mydata bmi_grs

#Produces:
#weights_bmi_grs.*
#results/grs_bmi_grs.*
#results/final_grs_bmi_grs.csv
