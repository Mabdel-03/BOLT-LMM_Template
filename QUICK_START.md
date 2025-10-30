# BOLT-LMM Template Quick Start Guide

**Get your GWAS analysis running in 30 minutes.**

---

## Prerequisites

Before starting, ensure you have:

- [ ] BOLT-LMM v2.4+ installed
- [ ] PLINK2 v2.0+ installed
- [ ] Genotype files in PLINK2 format (.pgen/.pvar/.psam)
- [ ] Phenotype file with FID, IID, and phenotype columns
- [ ] Covariate file with FID, IID, and covariate columns
- [ ] Population keep file (FID IID format, no header)
- [ ] Access to HPC cluster with SLURM

---

## 5-Step Setup

### Step 1: Copy Template (2 minutes)

```bash
# Copy template to your analysis directory
cp -r BOLT-LMM_Template/ my_gwas_analysis/
cd my_gwas_analysis/
```

### Step 2: Configure Paths (10 minutes)

Edit `paths.sh`:

```bash
# Base directories
UKB21942_DIR='/path/to/your/data'
ANALYSIS_NAME='MY_GWAS'
SRCDIR='/path/to/my_gwas_analysis'

# Genotype files
GENOTYPE_PFILE="${UKB21942_DIR}/geno/my_genotypes"

# BOLT-LMM installation
BOLT_LMM_DIR="/path/to/BOLT-LMM_v2.4"
LD_SCORES_FILE="${BOLT_LMM_DIR}/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"
GENETIC_MAP_FILE="${BOLT_LMM_DIR}/tables/genetic_map_hg19_withX.txt.gz"

# Phenotype and covariate files
PHENO_FILE="${UKB21942_DIR}/pheno/my_phenotypes.tsv.gz"
COVAR_FILE="${UKB21942_DIR}/sqc/my_covariates.tsv.gz"

# Population
KEEP_FILE="${UKB21942_DIR}/sqc/EUR.keep"
POPULATION="EUR"
```

### Step 3: Define Phenotypes and Covariates (10 minutes)

**A. Edit `run_single_phenotype.sh` (lines 73-130)**

Define your covariate sets:

```bash
if [ "${covar_str}" == "Basic" ]; then
    qcovar_col_args="--qCovarCol=age"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
    
elif [ "${covar_str}" == "Extended_10PCs" ]; then
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
fi
```

**B. Edit `1_run_bolt_lmm.sbatch.sh` (lines 48-65)**

Define your phenotypes and covariate sets:

```bash
# Your phenotype names (must match phenotype file columns)
phenotypes=(T2D CAD BMI)

# Your covariate sets (must match cases in run_single_phenotype.sh)
covar_sets=(Basic Extended_10PCs)

# Calculate total jobs: 3 phenotypes × 2 covariate sets = 6 jobs
# Update SLURM header: #SBATCH --array=1-6
```

### Step 4: Update SLURM Configuration (5 minutes)

Edit SLURM headers in all `*.sbatch.sh` files:

```bash
#SBATCH --partition=YOUR_PARTITION  # Your HPC partition
#SBATCH --mail-user=YOUR_EMAIL@institution.edu  # Your email
```

Also update `SRCDIR` in each script:
- `0a_convert_to_bed.sbatch.sh`
- `0b_prepare_model_snps.sbatch.sh`
- `0d_test_run.sbatch.sh`
- `1_run_bolt_lmm.sbatch.sh`
- `filter_to_population.sh`
- `run_single_phenotype.sh`

### Step 5: Set Test Configuration (3 minutes)

Edit `0d_test_run.sbatch.sh` (lines 60-70):

```bash
TEST_PHENOTYPE="T2D"  # Choose one of your phenotypes
TEST_COVAR_SET="Basic"  # Choose one of your covariate sets
```

---

## Run Pipeline

### Phase 1: Preprocessing (One-time, ~1 hour)

```bash
# 1. Convert genotypes to BOLT-LMM format
sbatch 0a_convert_to_bed.sbatch.sh
# Wait for completion (~5-10 min)

# 2. Prepare model SNPs for GRM
sbatch 0b_prepare_model_snps.sbatch.sh
# Wait for completion (~15-30 min)

# 3. Filter phenotype/covariate files to population
bash filter_to_population.sh
# Completes in ~1-2 min
```

### Phase 2: Validation (Critical, ~1-2 hours)

```bash
# Run test with one phenotype
sbatch 0d_test_run.sbatch.sh

# Monitor progress
tail -f 0d.out

# ⚠️  Wait for test to complete and verify success before proceeding!
```

**Check test results:**
```bash
# Should see "✅ TEST PASSED!" in 0d.out
cat 0d.out | grep -A 20 "Test Results"

# Review output files
ls -lh results/*/*/*.stats.gz
ls -lh results/*/*/*.log.gz
```

### Phase 3: Full Analysis (~hours to days depending on # phenotypes)

```bash
# If test passed, run full analysis
sbatch 1_run_bolt_lmm.sbatch.sh

# Monitor all jobs
squeue -u $USER

# Check individual job outputs
tail -f 1_*.out
```

---

## Verify Completion

### Check All Jobs Finished

```bash
# Count completed jobs
ls -1 results/*/*/*stats.gz | wc -l
# Should equal: N_phenotypes × N_covariate_sets

# Example: 3 phenotypes × 2 covariate sets = 6 files
```

### Quick QC Checks

```bash
# For each phenotype, check log file
zcat results/Basic/EUR/bolt_T2D.Basic.log.gz | grep -i "analyzing"
zcat results/Basic/EUR/bolt_T2D.Basic.log.gz | grep -i "h2:"
zcat results/Basic/EUR/bolt_T2D.Basic.log.gz | grep -i "warning"

# Check summary statistics
zcat results/Basic/EUR/bolt_T2D.Basic.stats.gz | head -20

# Count variants
zcat results/Basic/EUR/bolt_T2D.Basic.stats.gz | wc -l
```

---

## Common Customization Scenarios

### Single Phenotype, Basic Covariates

```bash
# 1_run_bolt_lmm.sbatch.sh:
phenotypes=(T2D)
covar_sets=(Basic)
#SBATCH --array=1-1  # 1 × 1 = 1 job

# run_single_phenotype.sh:
if [ "${covar_str}" == "Basic" ]; then
    qcovar_col_args="--qCovarCol=age"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
fi
```

### Multiple Phenotypes, Multiple Models

```bash
# 1_run_bolt_lmm.sbatch.sh:
phenotypes=(T2D CAD Stroke)
covar_sets=(Basic Extended_10PCs FullModel)
#SBATCH --array=1-9  # 3 × 3 = 9 jobs

# run_single_phenotype.sh:
# Define all 3 covariate sets (Basic, Extended_10PCs, FullModel)
```

### Quantitative Traits

```bash
# 1_run_bolt_lmm.sbatch.sh:
phenotypes=(BMI Height Weight)
covar_sets=(Standard)
#SBATCH --array=1-3  # 3 × 1 = 3 jobs

# No special configuration needed - BOLT-LMM auto-detects quantitative traits
```

---

## Resource Guidelines

### Memory Requirements

| Sample Size | Recommended RAM |
|-------------|-----------------|
| 50K         | 32-64 GB        |
| 100K        | 50-80 GB        |
| 250K        | 80-120 GB       |
| 500K        | 150-200 GB      |

### Runtime Estimates

Per phenotype, with 32 threads:
- 50K samples: 30-60 min
- 100K samples: 45-90 min
- 250K samples: 1-2 hours
- 500K samples: 1.5-3 hours

---

## Troubleshooting

### Test Run Fails

**Check:**
1. Phenotype name matches column in phenotype file
   ```bash
   zcat ${PHENO_FILE} | head -1
   ```
2. Covariate names match covariate file
   ```bash
   zcat ${COVAR_FILE} | head -1
   ```
3. All input files exist
   ```bash
   ls -lh ${GENOTYPE_BFILE}.bed
   ls -lh ${MODEL_SNPS_FILE}
   ```
4. SLURM error log
   ```bash
   cat 0d.err
   ```

### Out of Memory

**Solution:**
```bash
# Increase memory in SLURM headers
#SBATCH --mem=200G  # or higher
```

### High λ_GC (>1.10)

**Check:**
- Are you including enough PCs?
- Is population filtering correct?
- Check log file for warnings

**Solution:**
- Add more PCs to covariate model
- Review population ancestry filtering

### No Genome-Wide Significant Hits

**Consider:**
- Is heritability > 0? (check log file)
- Is sample size sufficient?
- Are you using HM3 variants only? (may miss imputed signals)
- Check QQ plot for any enrichment

---

## Next Steps After GWAS

### 1. Quality Control

```bash
# Calculate λ_GC
# Create QQ plots
# Create Manhattan plots
# Check heritability estimates
```

### 2. Identify Significant Hits

```bash
# Genome-wide significant: p < 5×10⁻⁸
zcat results/*/EUR/*.stats.gz | \
    awk '$NF < 5e-8' | \
    sort -k12,12g | \
    head -20
```

### 3. Downstream Analyses

- LD Score Regression (heritability, genetic correlation)
- Fine-mapping (FINEMAP, SuSiE)
- Functional annotation (FUMA, MAGMA)
- Polygenic risk scores (PRSice-2, LDpred2)

---

## File Locations Quick Reference

```
my_gwas_analysis/
├── paths.sh                    ← Configure all paths
├── run_single_phenotype.sh     ← Define covariate sets
├── 1_run_bolt_lmm.sbatch.sh   ← Define phenotypes & covariate sets
├── 0d_test_run.sbatch.sh      ← Set test phenotype/covariate
│
└── results/
    ├── Basic/
    │   └── EUR/
    │       ├── bolt_T2D.Basic.stats.gz
    │       └── bolt_T2D.Basic.log.gz
    └── Extended_10PCs/
        └── EUR/
            ├── bolt_T2D.Extended_10PCs.stats.gz
            └── bolt_T2D.Extended_10PCs.log.gz
```

---

## Getting Help

- **Detailed customization**: See `ADAPTATION_GUIDE.md`
- **Understanding BOLT-LMM**: See `BOLT_LMM_PRIMER.md`
- **Common issues**: See `TROUBLESHOOTING.md`
- **BOLT-LMM manual**: https://alkesgroup.broadinstitute.org/BOLT-LMM/

---

## Checklist

Before running full analysis:

- [ ] All paths configured in `paths.sh`
- [ ] Phenotypes defined in `1_run_bolt_lmm.sbatch.sh`
- [ ] Covariate sets defined in `run_single_phenotype.sh`
- [ ] Column names verified against phenotype/covariate files
- [ ] SLURM configuration updated (partition, email, array size)
- [ ] Test run completed successfully
- [ ] Output files reviewed and look reasonable

---

*For detailed instructions, see README.md and ADAPTATION_GUIDE.md*

*Last Updated: October 30, 2025*

