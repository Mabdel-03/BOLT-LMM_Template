#!/bin/bash
# Example Configuration: Quantitative Traits (Anthropometry)
# ============================================================
#
# Scenario: GWAS of BMI, Height, and Weight with age, sex, and 10 PCs
#
# This example shows:
# - Multiple quantitative phenotypes (continuous traits)
# - Standard covariate model with principal components
# - Single covariate set applied to all phenotypes
#
# Expected jobs: 3 phenotypes × 1 covariate set = 3 jobs
#
# ============================================================

# ============================================================================
# Configuration in 1_run_bolt_lmm.sbatch.sh
# ============================================================================

# Define phenotypes (quantitative traits, standardized recommended)
phenotypes=(BMI Height Weight)

# Define covariate sets
covar_sets=(Standard)  # Age + sex + 10 PCs

# SLURM array: 3 × 1 = 3 jobs
#SBATCH --array=1-3

# ============================================================================
# Covariate configuration in run_single_phenotype.sh
# ============================================================================

if [ "${covar_str}" == "Standard" ]; then
    # Quantitative covariates: age and 10 principal components
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    
    # Categorical covariates: sex only (not including array for quantitative traits)
    covar_col_args="--covarCol=sex"
fi

# ============================================================================
# Test run configuration in 0d_test_run.sbatch.sh
# ============================================================================

TEST_PHENOTYPE="BMI"  # Choose phenotype with good coverage
TEST_COVAR_SET="Standard"

# ============================================================================
# Phenotype Preparation Tips
# ============================================================================

# For quantitative traits:
# 1. Standardization (recommended): mean=0, SD=1
#    R: phenotype_std <- scale(phenotype)
#    Python: from scipy.stats import zscore; phenotype_std = zscore(phenotype)
#
# 2. Inverse-normal transformation (for non-normal distributions):
#    R: phenotype_int <- qnorm((rank(phenotype) - 0.5) / length(phenotype))
#
# 3. Outlier handling: Remove or winsorize extreme values (> 5 SD)

# ============================================================================
# Expected Output
# ============================================================================

# After successful run:
# results/
# └── Standard/
#     └── EUR/
#         ├── bolt_BMI.Standard.stats.gz
#         ├── bolt_BMI.Standard.log.gz
#         ├── bolt_Height.Standard.stats.gz
#         ├── bolt_Height.Standard.log.gz
#         ├── bolt_Weight.Standard.stats.gz
#         └── bolt_Weight.Standard.log.gz

# ============================================================================
# Interpreting Results
# ============================================================================

# For quantitative traits, BOLT-LMM reports:
# - BETA in phenotype units (or SD if standardized)
# - Example: BETA=0.05 SD → Each allele increases trait by 0.05 standard deviations
# - If original BMI units: BETA=0.5 → Each allele increases BMI by 0.5 kg/m²

# Key columns in stats file (same as binary traits):
# - SNP, CHR, BP, BETA, SE, P_BOLT_LMM, A1FREQ

# ============================================================================
# QC Checks
# ============================================================================

# From log file:
# 1. Sample size: Should match expected sample size
# 2. Heritability (h²): Varies by trait
#    - BMI: ~20-30%
#    - Height: ~60-80%
#    - Weight: ~20-30%
# 3. λ_GC: Should be 1.00-1.10 (higher for highly polygenic traits is okay)

# From stats file:
# 1. Check for known loci:
#    - BMI: FTO, MC4R
#    - Height: HMGA2, GDF5, many loci
# 2. QQ plot should show enrichment for polygenic traits
# 3. Manhattan plot should show clear peaks for significant associations

# Example QC:
# for pheno in BMI Height Weight; do
#     echo "=== ${pheno} ==="
#     zcat results/Standard/EUR/bolt_${pheno}.Standard.log.gz | grep "Analyzing"
#     zcat results/Standard/EUR/bolt_${pheno}.Standard.log.gz | grep "h2:"
#     zcat results/Standard/EUR/bolt_${pheno}.Standard.stats.gz | \
#         awk 'NR>1 && $NF < 5e-8' | wc -l | \
#         xargs -I {} echo "Genome-wide significant hits: {}"
# done

