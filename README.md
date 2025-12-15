## Example runs

### Minimal (auto-naming)

```
./run_grs_pipeline.sh gwas.sumstats.gz mydata
```

#### Produces:
#### weights_gwas_mydata.*
#### results/grs_gwas_mydata.*
#### results/final_grs_gwas_mydata.csv

### Explicit output name

```
./run_grs_pipeline.sh gwas.sumstats.gz mydata bmi_grs
./run_grs_pipeline.sh ~/sumstats/DM_T2D/Xue_2018_NatComms-GCST006001-GCST007000/GCST006867/harmonised/30054458-GCST006867-EFO_0001360-build37.f.tsv.gz dmsa_b37 t2d_Xue2018
```

#### Produces:
#### weights_bmi_grs.*
#### results/grs_bmi_grs.*
#### results/final_grs_bmi_grs.csv
