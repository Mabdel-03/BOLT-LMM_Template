# BOLT-LMM Template Adaptation Guide

**Complete instructions for customizing the template for your specific GWAS analysis.**

---

## Overview

This guide provides step-by-step instructions for adapting the BOLT-LMM template to your specific analysis. All customization points are marked with `# CUSTOMIZE:` comments in the scripts.

**Read this guide completely before starting your analysis.**

---

## Table of Contents

1. [Quick Customization Checklist](#quick-customization-checklist)
2. [File-by-File Customization Guide](#file-by-file-customization-guide)
3. [Covariate Configuration](#covariate-configuration)
4. [Phenotype Specifications](#phenotype-specifications)
5. [Population Filtering](#population-filtering)
6. [Resource Optimization](#resource-optimization)
7. [Validation and Testing](#validation-and-testing)
8. [Common Adaptation Scenarios](#common-adaptation-scenarios)

---

## Quick Customization Checklist

Before running any analysis, complete these steps:

### ✅ Step 1: Configuration File (`paths.sh`)

- [ ] Set `UKB21942_DIR` to your data directory
- [ ] Set `ANALYSIS_NAME` to your analysis identifier
- [ ] Set `SRCDIR` to your analysis working directory
- [ ] Set genotype file base path
- [ ] Set BOLT-LMM installation path and table files
- [ ] Set phenotype file path
- [ ] Set covariate file path
- [ ] Set population keep file path

### ✅ Step 2: Phenotype Configuration

- [ ] Define phenotype names in `1_run_bolt_lmm.sbatch.sh`
- [ ] Specify phenotype file column names in `run_single_phenotype.sh`
- [ ] Verify binary/quantitative trait coding

### ✅ Step 3: Covariate Configuration

- [ ] Define covariate set names in `1_run_bolt_lmm.sbatch.sh`
- [ ] Configure quantitative covariates in `run_single_phenotype.sh`
- [ ] Configure categorical covariates in `run_single_phenotype.sh`
- [ ] Verify covariate file column names match script

### ✅ Step 4: SLURM Configuration

- [ ] Update email address in all `*.sbatch.sh` files
- [ ] Set partition name (if different from `kellis`)
- [ ] Adjust memory requirements if needed
- [ ] Adjust CPU/thread counts if needed
- [ ] Adjust walltime limits if needed

### ✅ Step 5: Job Array Configuration

- [ ] Calculate total jobs: `N_phenotypes × N_covariate_sets`
- [ ] Update `--array=1-N` in `1_run_bolt_lmm.sbatch.sh`
- [ ] Verify phenotype-covariate mapping logic

### ✅ Step 6: Test Run

- [ ] Specify test phenotype in `0d_test_run.sbatch.sh`
- [ ] Specify test covariate set in `0d_test_run.sbatch.sh`
- [ ] Run test and verify output before full analysis

---

## File-by-File Customization Guide

### 1. `paths.sh` - Configuration File

**Purpose**: Central configuration for all file paths and software locations.

**Customization Points**:

```bash
# CUSTOMIZE: Base directory for your UKB data (or other cohort data)
# This should point to the root directory containing genotype, phenotype, and covariate files
UKB21942_DIR='/path/to/your/data/directory'
# Example: UKB21942_DIR='/home/user/data/ukbb'

# CUSTOMIZE: Your analysis name (used for output directories and file naming)
# Use a short, descriptive name without spaces
ANALYSIS_NAME='MY_GWAS_ANALYSIS'
# Example: ANALYSIS_NAME='T2D_GWAS' or ANALYSIS_NAME='BMI_European'

# CUSTOMIZE: Analysis source directory (where these scripts are located)
# This is typically where you copied the template
SRCDIR='/path/to/your/analysis/directory'
# Example: SRCDIR='/home/user/projects/my_gwas_analysis'

# CUSTOMIZE: Genotype file base path (without .bed/.bim/.fam extension)
# For PLINK2 format: path without .pgen/.pvar/.psam
# The conversion script will create .bed/.bim/.fam files in the same directory
GENOTYPE_PFILE="${UKB21942_DIR}/geno/YOUR_GENOTYPE_BASENAME"
# Example: GENOTYPE_PFILE="${UKB21942_DIR}/geno/ukb_merged"
# This assumes files: ukb_merged.pgen, ukb_merged.pvar.zst, ukb_merged.psam

# CUSTOMIZE: BOLT-LMM installation directory
BOLT_LMM_DIR="/path/to/BOLT-LMM_v2.X"
# Example: BOLT_LMM_DIR="/home/user/software/BOLT-LMM_v2.4"
# Download from: https://alkesgroup.broadinstitute.org/BOLT-LMM/

# CUSTOMIZE: LD scores file for BOLT-LMM calibration
# This file comes with BOLT-LMM installation (in tables/ directory)
# For European ancestry: LDSCORE.1000G_EUR.GRCh38.tab.gz (if using GRCh38)
#                        LDSCORE.1000G_EUR.tab.gz (if using GRCh37)
LD_SCORES_FILE="${BOLT_LMM_DIR}/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"
# For other ancestries, use appropriate LD score file:
# - LDSCORE.1000G_EAS.tab.gz (East Asian)
# - LDSCORE.1000G_AFR.tab.gz (African)
# - LDSCORE.1000G_AMR.tab.gz (Admixed American)

# CUSTOMIZE: Genetic map file for position interpolation
# This file comes with BOLT-LMM installation (in tables/ directory)
# Must match your genome build:
# - GRCh37/hg19: genetic_map_hg19_withX.txt.gz
# - GRCh38: genetic_map_hg38_withX.txt.gz (if available)
GENETIC_MAP_FILE="${BOLT_LMM_DIR}/tables/genetic_map_hg19_withX.txt.gz"

# CUSTOMIZE: Phenotype file path
# Should be tab-delimited with header: FID IID PHENO1 PHENO2 ...
# Can be gzipped (.gz or .tsv.gz)
PHENO_FILE="${UKB21942_DIR}/pheno/YOUR_PHENOTYPE_FILE.tsv.gz"
# Example: PHENO_FILE="${UKB21942_DIR}/pheno/all_phenotypes.tsv.gz"

# CUSTOMIZE: Covariate file path
# Should be tab-delimited with header: FID IID age sex PC1 PC2 ...
# Can be gzipped (.gz or .tsv.gz)
COVAR_FILE="${UKB21942_DIR}/sqc/YOUR_COVARIATE_FILE.tsv.gz"
# Example: COVAR_FILE="${UKB21942_DIR}/sqc/covariates_with_pcs.tsv.gz"

# CUSTOMIZE: Population keep file (defines analysis sample)
# Format: FID IID (space-separated, no header)
# One individual per line
KEEP_FILE="${UKB21942_DIR}/sqc/YOUR_POPULATION.keep"
# Example: KEEP_FILE="${UKB21942_DIR}/sqc/EUR.keep" (European ancestry)
#          KEEP_FILE="${UKB21942_DIR}/sqc/ALL.keep" (all samples)

# CUSTOMIZE: Population name (for output directory naming)
POPULATION="YOUR_POP"
# Example: POPULATION="EUR" or POPULATION="EAS" or POPULATION="ALL"
```

**Validation**:
```bash
# After editing paths.sh, verify all files exist:
source paths.sh
ls -lh ${GENOTYPE_PFILE}.pgen ${GENOTYPE_PFILE}.pvar* ${GENOTYPE_PFILE}.psam
ls -lh ${PHENO_FILE}
ls -lh ${COVAR_FILE}
ls -lh ${KEEP_FILE}
ls -lh ${LD_SCORES_FILE}
ls -lh ${GENETIC_MAP_FILE}
```

---

### 2. `run_single_phenotype.sh` - Core BOLT-LMM Execution

**Purpose**: Runs BOLT-LMM for one phenotype with one covariate set.

**Customization Points**:

#### A. Directory Paths (Lines ~15-20)

```bash
# CUSTOMIZE: Base directory paths
# These should match paths.sh
REPODIR="/path/to/your/base/directory"
SRCDIR="/path/to/your/analysis/directory"
ukb21942_d="${REPODIR}"  # Or point to data directory

# CUSTOMIZE: Keep set name (for population filtering)
keep_set="YOUR_POP"  # Should match POPULATION in paths.sh
# Example: keep_set="EUR"
```

#### B. Output Directory (Lines ~25-30)

```bash
# Output directory structure: results/<COVAR_SET>/<POPULATION>/
out_dir="${SRCDIR}/results/${covar_str}/${keep_set}"
mkdir -p ${out_dir}

# Output file naming: bolt_<PHENOTYPE>.<COVAR_SET>
out_file="${out_dir}/bolt_${phenotype}.${covar_str}"
```

#### C. Input File Paths (Lines ~45-55)

```bash
# CUSTOMIZE: Genotype file base path (without extension)
genotype_bfile="${ukb21942_d}/geno/YOUR_GENOTYPE_DIR/YOUR_GENOTYPE_BASENAME_bed"
# Example: genotype_bfile="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed"
# This should point to: .bed, .bim, .fam files created by 0a_convert_to_bed.sbatch.sh

# CUSTOMIZE: Model SNPs file (created by 0b_prepare_model_snps.sbatch.sh)
model_snps_file="${ukb21942_d}/geno/YOUR_GENOTYPE_DIR/YOUR_GENOTYPE_BASENAME_modelSNPs.txt"
# Example: model_snps_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt"

# CUSTOMIZE: LD scores and genetic map files (from BOLT-LMM installation)
ld_scores_file="/path/to/BOLT-LMM/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"
genetic_map_file="/path/to/BOLT-LMM/tables/genetic_map_hg19_withX.txt.gz"

# CUSTOMIZE: Population-filtered phenotype and covariate files
# These are created by filter_to_population.sh
pheno_file_pop="${SRCDIR}/YOUR_PHENOTYPE_FILE.${keep_set}.tsv.gz"
covar_file_pop="${SRCDIR}/YOUR_COVARIATE_FILE.${keep_set}.tsv.gz"
# Example: pheno_file_pop="${SRCDIR}/phenotypes.EUR.tsv.gz"
#          covar_file_pop="${SRCDIR}/covariates.EUR.tsv.gz"
```

#### D. Covariate Configuration (Lines ~57-85)

**This is the most important customization section!**

```bash
# CUSTOMIZE: Define your covariate sets
# Each covariate set specifies which covariates to include in the model
# You can define as many covariate sets as needed

# Example 1: Basic model (age + sex + genotyping array)
if [ "${covar_str}" == "Basic" ]; then
    # CUSTOMIZE: Quantitative covariates (continuous variables)
    # Each covariate needs its own --qCovarCol argument
    # Column names must match exactly with your covariate file
    qcovar_col_args="--qCovarCol=age"
    
    # CUSTOMIZE: Categorical covariates (discrete variables)
    # Each covariate needs its own --covarCol argument
    # Column names must match exactly with your covariate file
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"

# Example 2: Extended model with principal components
elif [ "${covar_str}" == "Extended_10PCs" ]; then
    # CUSTOMIZE: Add PC1-PC10 as quantitative covariates
    # List each PC separately
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"

# Example 3: Model with additional covariates
elif [ "${covar_str}" == "FullModel" ]; then
    # CUSTOMIZE: Include age, BMI, and 10 PCs as quantitative
    qcovar_col_args="--qCovarCol=age --qCovarCol=BMI --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    
    # CUSTOMIZE: Include sex, array, and assessment center as categorical
    covar_col_args="--covarCol=sex --covarCol=genotyping_array --covarCol=assessment_center"

# Add more covariate sets as needed
else
    echo "ERROR: Unknown covar_str: ${covar_str}" >&2
    echo "Available options: Basic, Extended_10PCs, FullModel" >&2
    exit 1
fi
```

**Important Notes on Covariates**:

1. **Column Names**: Must match exactly (case-sensitive) with your covariate file header
2. **Quantitative vs Categorical**: 
   - Quantitative: Age, BMI, PCs, continuous measurements → use `--qCovarCol`
   - Categorical: Sex, batch, center, array type → use `--covarCol`
3. **Multiple Arguments**: Each covariate needs its own `--qCovarCol` or `--covarCol` flag
4. **PC Naming**: Common formats: `PC1, PC2, ...` or `PCA1, PCA2, ...` or `UKB_PC1, UKB_PC2, ...`
5. **No Missing Values**: BOLT-LMM will exclude individuals with missing covariate values

#### E. BOLT-LMM Command (Lines ~110-130)

Usually no customization needed, but you may want to adjust:

```bash
# CUSTOMIZE: Number of threads (should match SLURM -n parameter)
--numThreads=100

# CUSTOMIZE: Maximum levels for categorical covariates
# Increase if you have high-cardinality categorical variables
--covarMaxLevels=30

# Optional: Add --verboseStats for additional output columns
# (allele frequencies, INFO scores, etc.)
--verboseStats
```

---

### 3. `1_run_bolt_lmm.sbatch.sh` - Array Job Submission

**Purpose**: Submits SLURM array job for all phenotype-covariate combinations.

**Customization Points**:

#### A. SLURM Header (Lines 1-11)

```bash
#!/bin/bash
#SBATCH --job-name=YOUR_JOB_NAME  # CUSTOMIZE: Short descriptive name
#SBATCH --partition=YOUR_PARTITION  # CUSTOMIZE: Your HPC partition
#SBATCH --mem=150G  # CUSTOMIZE: Adjust based on sample size
#SBATCH -n 100  # CUSTOMIZE: Number of threads (match --numThreads in run_single_phenotype.sh)
#SBATCH --time=47:00:00  # CUSTOMIZE: Adjust based on complexity
#SBATCH --output=1_%a.out  # %a is array task ID
#SBATCH --error=1_%a.err
#SBATCH --array=1-N  # CUSTOMIZE: Set to N_phenotypes × N_covariate_sets
#SBATCH --mail-user=YOUR_EMAIL@institution.edu  # CUSTOMIZE: Your email
#SBATCH --mail-type=BEGIN,END,FAIL,ARRAY_TASKS
```

**Array Size Calculation**:
```
Total jobs = Number of phenotypes × Number of covariate sets
Example: 3 phenotypes × 2 covariate sets = 6 jobs → --array=1-6
```

#### B. Directory Path (Line ~30)

```bash
# CUSTOMIZE: Analysis directory (should match SRCDIR in paths.sh)
SRCDIR="/path/to/your/analysis/directory"
cd ${SRCDIR}
```

#### C. Phenotypes and Covariate Sets (Lines ~35-40)

```bash
# CUSTOMIZE: Define your phenotypes
# List all phenotype column names from your phenotype file
phenotypes=(PHENO1 PHENO2 PHENO3)
# Example: phenotypes=(T2D CAD BMI)

# CUSTOMIZE: Define your covariate sets  
# These must match the cases in run_single_phenotype.sh
covar_sets=(COVAR_SET1 COVAR_SET2)
# Example: covar_sets=(Basic Extended_10PCs)
```

#### D. Array Task Mapping (Lines ~42-55)

**For simple case (works for most scenarios)**:
```bash
# Assuming phenotypes × covar_sets layout:
# Task 1-N_pheno: First covariate set with each phenotype
# Task (N_pheno+1)-(2*N_pheno): Second covariate set with each phenotype
# etc.

n_pheno=${#phenotypes[@]}
covar_idx=$(( (SLURM_ARRAY_TASK_ID - 1) / n_pheno ))
pheno_idx=$(( (SLURM_ARRAY_TASK_ID - 1) % n_pheno ))

phenotype=${phenotypes[$pheno_idx]}
covar_str=${covar_sets[$covar_idx]}
```

**For complex mapping, customize the logic**:
```bash
# Example: Specific phenotype-covariate combinations only
if [ ${SLURM_ARRAY_TASK_ID} -eq 1 ]; then
    phenotype="T2D"; covar_str="Basic"
elif [ ${SLURM_ARRAY_TASK_ID} -eq 2 ]; then
    phenotype="T2D"; covar_str="Extended_10PCs"
elif [ ${SLURM_ARRAY_TASK_ID} -eq 3 ]; then
    phenotype="BMI"; covar_str="FullModel"
# ... etc
fi
```

---

### 4. `0d_test_run.sbatch.sh` - Validation Test

**Purpose**: Test the pipeline on one phenotype-covariate combination before full analysis.

**Customization Points**:

```bash
# CUSTOMIZE: SLURM header (similar to 1_run_bolt_lmm.sbatch.sh)
#SBATCH --mail-user=YOUR_EMAIL@institution.edu

# CUSTOMIZE: Test phenotype and covariate set
# Choose a representative phenotype (preferably with good sample size)
echo "Testing with YOUR_TEST_PHENOTYPE phenotype, YOUR_TEST_COVAR covariate set"

# CUSTOMIZE: Clean up previous test outputs
rm -f ${SRCDIR}/results/YOUR_TEST_COVAR/${POPULATION}/bolt_YOUR_TEST_PHENOTYPE.YOUR_TEST_COVAR.stats*
rm -f ${SRCDIR}/results/YOUR_TEST_COVAR/${POPULATION}/bolt_YOUR_TEST_PHENOTYPE.YOUR_TEST_COVAR.log*

# CUSTOMIZE: Run test
bash run_single_phenotype.sh YOUR_TEST_PHENOTYPE YOUR_TEST_COVAR
# Example: bash run_single_phenotype.sh T2D Basic

# CUSTOMIZE: Verify output files
ls -lh results/YOUR_TEST_COVAR/${POPULATION}/bolt_YOUR_TEST_PHENOTYPE.YOUR_TEST_COVAR.stats.gz
ls -lh results/YOUR_TEST_COVAR/${POPULATION}/bolt_YOUR_TEST_PHENOTYPE.YOUR_TEST_COVAR.log.gz
```

---

### 5. `0a_convert_to_bed.sbatch.sh` - Genotype Conversion

**Customization Points**:

```bash
# CUSTOMIZE: SLURM header
#SBATCH --mail-user=YOUR_EMAIL@institution.edu
#SBATCH --partition=YOUR_PARTITION

# CUSTOMIZE: Directory paths
REPODIR="/path/to/your/base/directory"
ukb21942_d="${REPODIR}"

# CUSTOMIZE: Input and output paths
genotype_dir="${ukb21942_d}/geno/YOUR_GENOTYPE_DIR"
input_pfile="${genotype_dir}/YOUR_GENOTYPE_BASENAME"
output_bfile="${genotype_dir}/YOUR_GENOTYPE_BASENAME_bed"
# Example: input_pfile="${genotype_dir}/ukb_merged"
#          output_bfile="${genotype_dir}/ukb_merged_bed"
```

---

### 6. `0b_prepare_model_snps.sbatch.sh` - Model SNP Selection

**Customization Points**:

```bash
# CUSTOMIZE: SLURM header
#SBATCH --mail-user=YOUR_EMAIL@institution.edu  
#SBATCH --partition=YOUR_PARTITION
#SBATCH --mem=80G  # May need more for very large cohorts

# CUSTOMIZE: Input and output paths
genotype_dir="${ukb21942_d}/geno/YOUR_GENOTYPE_DIR"
genotype_pfile="${genotype_dir}/YOUR_GENOTYPE_BASENAME"
output_snplist="${genotype_dir}/YOUR_GENOTYPE_BASENAME_modelSNPs.txt"

# CUSTOMIZE: LD pruning parameters (optional)
# Current settings: --indep-pairwise 1000 50 0.5
# - Window size: 1000kb
# - Step size: 50 SNPs
# - r² threshold: 0.5
# Adjust if you want stricter (0.2) or more relaxed (0.8) LD pruning
```

---

### 7. `filter_to_population.sh` - Population Filtering

**Customization Points**:

```bash
# CUSTOMIZE: Directory paths
ukb21942_d='/path/to/your/data/directory'
SRCDIR="/path/to/your/analysis/directory"

# CUSTOMIZE: Input files
keep_file="${ukb21942_d}/sqc/YOUR_POPULATION.keep"
pheno_file="${ukb21942_d}/pheno/YOUR_PHENOTYPE_FILE.tsv.gz"
covar_file="${ukb21942_d}/sqc/YOUR_COVARIATE_FILE.tsv.gz"

# CUSTOMIZE: Output files (population-specific)
pheno_pop="${SRCDIR}/YOUR_PHENOTYPE_FILE.${POPULATION}.tsv.gz"
covar_pop="${SRCDIR}/YOUR_COVARIATE_FILE.${POPULATION}.tsv.gz"
# Example: pheno_pop="${SRCDIR}/phenotypes.EUR.tsv.gz"
```

---

## Covariate Configuration

### Understanding Covariate Types

**Quantitative Covariates** (`--qCovarCol`):
- Continuous variables
- Examples: age, BMI, height, principal components
- BOLT-LMM centers these automatically

**Categorical Covariates** (`--covarCol`):
- Discrete variables with levels
- Examples: sex (1/2), genotyping array (UKB_A/UKB_B), assessment center
- BOLT-LMM creates dummy variables automatically
- Use `--covarMaxLevels` to set maximum number of levels (default=10)

### Common Covariate Configurations

#### Minimal Model
```bash
qcovar_col_args="--qCovarCol=age"
covar_col_args="--covarCol=sex"
```

#### Standard GWAS Model
```bash
qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
covar_col_args="--covarCol=sex --covarCol=genotyping_array"
```

#### UKB Standard Model (Day et al. 2018)
```bash
qcovar_col_args="--qCovarCol=age --qCovarCol=UKB_PC1 --qCovarCol=UKB_PC2 --qCovarCol=UKB_PC3 --qCovarCol=UKB_PC4 --qCovarCol=UKB_PC5 --qCovarCol=UKB_PC6 --qCovarCol=UKB_PC7 --qCovarCol=UKB_PC8 --qCovarCol=UKB_PC9 --qCovarCol=UKB_PC10"
covar_col_args="--covarCol=sex --covarCol=genotyping_array --covarCol=assessment_centre"
```

#### Model with Adjustment Variables
```bash
qcovar_col_args="--qCovarCol=age --qCovarCol=BMI --qCovarCol=smoking_years --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5"
covar_col_args="--covarCol=sex --covarCol=genotyping_array"
```

### Verifying Covariate Column Names

```bash
# Check your covariate file header
zcat YOUR_COVARIATE_FILE.tsv.gz | head -1

# Example output:
# FID	IID	age	sex	genotyping_array	PC1	PC2	PC3	PC4	PC5	PC6	PC7	PC8	PC9	PC10

# Use these exact names in your --qCovarCol and --covarCol arguments
```

---

## Phenotype Specifications

### Binary Phenotypes (Case-Control)

**Coding Requirements**:
- 0/1 coding: 0=control, 1=case (preferred)
- 1/2 coding: 1=control, 2=case (BOLT-LMM auto-detects)
- Missing: `NA`, `-9`, or empty

**Example Phenotype File**:
```
FID    IID     T2D    CAD    Stroke
FAM1   IND1    0      1      NA
FAM2   IND2    1      0      0
FAM3   IND3    0      0      0
```

**BOLT-LMM Behavior**:
- Automatically detects binary traits
- Applies liability threshold model
- Reports BETA on liability scale (not odds ratio)
- Conversion: OR ≈ exp(BETA) for small effects

### Quantitative Phenotypes

**Preparation Recommendations**:
- **Standardization**: Transform to mean=0, SD=1 (improves convergence)
- **Inverse-normal transformation**: For non-normal distributions
- **Outlier handling**: Remove or winsorize extreme values (> 5 SD)

**Example Phenotype File**:
```
FID    IID     BMI       Height    SBP
FAM1   IND1    0.52      1.23      -0.34
FAM2   IND2    -0.31     -0.45     0.67
FAM3   IND3    1.12      0.89      0.12
```

**BOLT-LMM Behavior**:
- Uses linear mixed model
- BETA is in phenotype units (or SD if standardized)
- No transformation applied by BOLT-LMM

### Mixed Analysis (Binary + Quantitative)

You can analyze both types in the same pipeline:

```bash
# In 1_run_bolt_lmm.sbatch.sh:
phenotypes=(T2D BMI CAD Height)  # Mix of binary and quantitative

# BOLT-LMM will auto-detect type for each phenotype
```

---

## Population Filtering

### Single Population

**Setup**:
```bash
# In paths.sh:
KEEP_FILE="${UKB21942_DIR}/sqc/EUR.keep"
POPULATION="EUR"

# Run filter_to_population.sh once
bash filter_to_population.sh

# This creates:
# - phenotypes.EUR.tsv.gz
# - covariates.EUR.tsv.gz
```

### Multiple Populations

If you want to run the same analysis in multiple ancestries:

**Option 1: Separate directories** (recommended)
```bash
# Create separate analysis directories
mkdir GWAS_EUR GWAS_EAS GWAS_AFR

# In each directory, set paths.sh appropriately:
# GWAS_EUR/paths.sh:
KEEP_FILE="${UKB21942_DIR}/sqc/EUR.keep"
POPULATION="EUR"

# GWAS_EAS/paths.sh:
KEEP_FILE="${UKB21942_DIR}/sqc/EAS.keep"
POPULATION="EAS"

# Run pipeline separately in each directory
```

**Option 2: Sequential runs** (same directory)
```bash
# Run for EUR
KEEP_FILE="EUR.keep" POPULATION="EUR" bash filter_to_population.sh
# ... run GWAS ...

# Run for EAS
KEEP_FILE="EAS.keep" POPULATION="EAS" bash filter_to_population.sh
# ... run GWAS ...
```

---

## Resource Optimization

### Memory Requirements

**Rule of thumb**: ~0.1-0.3 GB per 1,000 samples

| Sample Size | Recommended RAM |
|-------------|-----------------|
| 10,000 | 16-32 GB |
| 50,000 | 32-64 GB |
| 100,000 | 50-80 GB |
| 250,000 | 80-120 GB |
| 500,000 | 150-200 GB |

**Adjust in SLURM headers**:
```bash
#SBATCH --mem=150G  # Increase/decrease as needed
```

### CPU/Thread Optimization

BOLT-LMM scales well with multithreading:

- **Up to 16 threads**: Near-linear speedup
- **16-32 threads**: Diminishing returns
- **>32 threads**: Minimal additional benefit

**Recommended settings**:
```bash
# For quick turnaround:
#SBATCH -n 32
--numThreads=32

# For maximum throughput (if resources available):
#SBATCH -n 100
--numThreads=100

# For limited resources:
#SBATCH -n 8
--numThreads=8
```

### Walltime Estimation

**Factors affecting runtime**:
- Sample size
- Number of variants
- Number of covariates
- CPU threads
- I/O speed

**Rough estimates** (per phenotype, 100 threads):
- 50K samples, 1M variants: 30-60 min
- 100K samples, 1M variants: 45-90 min
- 250K samples, 1M variants: 1-2 hours
- 500K samples, 1M variants: 1.5-3 hours

**SLURM walltime setting**:
```bash
# Conservative (recommended for first runs):
#SBATCH --time=24:00:00

# Aggressive (if you know expected runtime):
#SBATCH --time=06:00:00
```

---

## Validation and Testing

### Test Run Checklist

Before running full analysis, verify:

1. **Test run completes successfully**
```bash
sbatch 0d_test_run.sbatch.sh
# Check: 0d.out and 0d.err files
```

2. **Output files created**
```bash
ls -lh results/*/*/bolt_*.stats.gz
ls -lh results/*/*/bolt_*.log.gz
```

3. **Check BOLT-LMM log file**
```bash
zcat results/YOUR_COVAR/YOUR_POP/bolt_YOUR_PHENO.YOUR_COVAR.log.gz | less

# Look for:
# - Sample size (matches expectation?)
# - Heritability estimate (h² > 0? reasonable?)
# - Convergence (any warnings?)
# - λ_GC / genomic inflation (1.00-1.05 expected)
```

4. **Check summary statistics**
```bash
zcat results/YOUR_COVAR/YOUR_POP/bolt_YOUR_PHENO.YOUR_COVAR.stats.gz | head -20

# Verify:
# - Header line present
# - Data rows present
# - Columns: SNP CHR BP BETA SE P_BOLT_LMM, etc.
# - P-values in range (0, 1)
# - Effect sizes reasonable
```

5. **Validate sample size**
```bash
# From log file, check:
# "Analyzing N samples"
# Compare to expected sample size
```

### What to Check After Full Analysis

**For each phenotype**:
- [ ] Output files created (stats.gz and log.gz)
- [ ] File sizes reasonable (~1-5 GB for stats)
- [ ] No error messages in SLURM .err files
- [ ] λ_GC in reasonable range (1.00-1.10)
- [ ] Heritability estimate > 0 and < 1
- [ ] No convergence warnings in log

**QC plots** (create these post-GWAS):
- [ ] QQ plot shows good calibration
- [ ] Manhattan plot shows expected distribution
- [ ] No systematic inflation across chromosomes

---

## Common Adaptation Scenarios

### Scenario 1: Single Binary Phenotype, Basic Covariates

**Goal**: GWAS of Type 2 Diabetes with age, sex, array as covariates

**Customization**:

1. **paths.sh**:
```bash
ANALYSIS_NAME='T2D_GWAS'
PHENO_FILE="${UKB21942_DIR}/pheno/diabetes_phenotypes.tsv.gz"
POPULATION="EUR"
```

2. **run_single_phenotype.sh**:
```bash
# Phenotype file has column: T2D (0=control, 1=case)

if [ "${covar_str}" == "AgeSexArray" ]; then
    qcovar_col_args="--qCovarCol=age"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
fi
```

3. **1_run_bolt_lmm.sbatch.sh**:
```bash
phenotypes=(T2D)
covar_sets=(AgeSexArray)
# Total jobs: 1 × 1 = 1
#SBATCH --array=1-1
```

### Scenario 2: Multiple Quantitative Phenotypes, PCs

**Goal**: GWAS of BMI, Height, Weight with age, sex, 10 PCs

**Customization**:

1. **paths.sh**:
```bash
ANALYSIS_NAME='Anthropometry_GWAS'
PHENO_FILE="${UKB21942_DIR}/pheno/body_measurements.tsv.gz"
```

2. **run_single_phenotype.sh**:
```bash
# Phenotype file has columns: BMI, Height, Weight (standardized)

if [ "${covar_str}" == "Standard" ]; then
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    covar_col_args="--covarCol=sex"
fi
```

3. **1_run_bolt_lmm.sbatch.sh**:
```bash
phenotypes=(BMI Height Weight)
covar_sets=(Standard)
# Total jobs: 3 × 1 = 3
#SBATCH --array=1-3
```

### Scenario 3: Sensitivity Analysis with Multiple Covariate Models

**Goal**: GWAS of CAD with basic model vs. PC-adjusted model vs. fully-adjusted model

**Customization**:

1. **run_single_phenotype.sh**:
```bash
if [ "${covar_str}" == "Basic" ]; then
    qcovar_col_args="--qCovarCol=age"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
    
elif [ "${covar_str}" == "PC_Adjusted" ]; then
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
    
elif [ "${covar_str}" == "Fully_Adjusted" ]; then
    qcovar_col_args="--qCovarCol=age --qCovarCol=BMI --qCovarCol=SBP --qCovarCol=smoking_years --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
fi
```

2. **1_run_bolt_lmm.sbatch.sh**:
```bash
phenotypes=(CAD)
covar_sets=(Basic PC_Adjusted Fully_Adjusted)
# Total jobs: 1 × 3 = 3
#SBATCH --array=1-3
```

### Scenario 4: Large-Scale Multi-Phenotype Study

**Goal**: GWAS of 50 blood biomarkers with standard covariate model

**Customization**:

1. **1_run_bolt_lmm.sbatch.sh**:
```bash
# List all 50 phenotypes
phenotypes=(
    CRP IL6 TNFa Albumin ...
    # (list all 50)
)
covar_sets=(Standard)
# Total jobs: 50 × 1 = 50
#SBATCH --array=1-50

# Increase resources since many jobs:
#SBATCH --mem=100G
#SBATCH -n 32
#SBATCH --time=12:00:00
```

---

## Final Checklist Before Full Analysis

### Configuration
- [ ] All paths in `paths.sh` verified and files exist
- [ ] Phenotype names match column names in phenotype file
- [ ] Covariate names match column names in covariate file
- [ ] Covariate sets correctly defined in `run_single_phenotype.sh`
- [ ] Array size matches `N_phenotypes × N_covariate_sets`

### Testing
- [ ] Test run completed successfully (`0d_test_run.sbatch.sh`)
- [ ] Output files created and non-empty
- [ ] Log file shows reasonable heritability and sample size
- [ ] No error messages in SLURM error logs

### Resources
- [ ] SLURM partition appropriate for your HPC
- [ ] Memory allocation sufficient for sample size
- [ ] Walltime limit appropriate for expected runtime
- [ ] Email notifications configured

### Documentation
- [ ] Documented your phenotype definitions
- [ ] Documented your covariate model rationale
- [ ] Documented your QC criteria
- [ ] Noted any deviations from template

---

## Getting Help

If you encounter issues:

1. **Check TROUBLESHOOTING.md** for common problems
2. **Review SLURM error logs** (*.err files) for specific error messages
3. **Check BOLT-LMM log files** for warnings or convergence issues
4. **Verify input files** match expected format and column names
5. **Test with smaller subset** to isolate the issue

**BOLT-LMM Documentation**: https://alkesgroup.broadinstitute.org/BOLT-LMM/BOLT-LMM_manual.html

---

*Last Updated: October 30, 2025*

