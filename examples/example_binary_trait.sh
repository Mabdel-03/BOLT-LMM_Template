#!/bin/bash
# Example Configuration: Single Binary Trait (Type 2 Diabetes)
# ============================================================
#
# Scenario: GWAS of Type 2 Diabetes with basic covariates
#
# This example shows:
# - Binary phenotype (0=control, 1=case)
# - Basic covariate model (age, sex, genotyping array)
# - Single covariate set
# - European ancestry population
#
# Expected jobs: 1 phenotype × 1 covariate set = 1 job
#
# ============================================================

# ============================================================================
# Configuration in 1_run_bolt_lmm.sbatch.sh
# ============================================================================

# Define phenotypes (binary trait, coded 0/1)
phenotypes=(T2D)  # Type 2 Diabetes

# Define covariate sets
covar_sets=(Basic)  # Just basic covariates

# SLURM array: 1 × 1 = 1 job
#SBATCH --array=1-1

# ============================================================================
# Covariate configuration in run_single_phenotype.sh
# ============================================================================

if [ "${covar_str}" == "Basic" ]; then
    # Quantitative covariates: age only
    qcovar_col_args="--qCovarCol=age"
    
    # Categorical covariates: sex and genotyping array
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
fi

# ============================================================================
# Test run configuration in 0d_test_run.sbatch.sh
# ============================================================================

TEST_PHENOTYPE="T2D"
TEST_COVAR_SET="Basic"

# ============================================================================
# Expected Output
# ============================================================================

# After successful run:
# results/
# └── Basic/
#     └── EUR/
#         ├── bolt_T2D.Basic.stats.gz  (~1-5GB, summary statistics)
#         └── bolt_T2D.Basic.log.gz    (~100KB, BOLT-LMM log)

# ============================================================================
# Interpreting Results
# ============================================================================

# For binary traits, BOLT-LMM reports:
# - BETA on liability scale (continuous latent variable)
# - To convert to odds ratio: OR ≈ exp(BETA)
# - Example: BETA=0.05 → OR ≈ 1.051 (5.1% increased odds per allele)

# Key columns in stats file:
# - SNP: Variant identifier
# - CHR: Chromosome
# - BP: Base pair position
# - BETA: Effect size on liability scale
# - SE: Standard error
# - P_BOLT_LMM: P-value (USE THIS, not P_BOLT_LMM_INF)
# - A1FREQ: Effect allele frequency

# ============================================================================
# QC Checks
# ============================================================================

# From log file:
# 1. Sample size: Should be reasonable (>1000 cases, >1000 controls)
# 2. Heritability (h²): Should be > 0 and < 1
# 3. λ_GC: Should be 1.00-1.05
# 4. Warnings: Review any warnings or convergence issues

# Example QC commands:
# zcat results/Basic/EUR/bolt_T2D.Basic.log.gz | grep "Analyzing"
# zcat results/Basic/EUR/bolt_T2D.Basic.log.gz | grep "h2:"
# zcat results/Basic/EUR/bolt_T2D.Basic.log.gz | grep -i "warning"

# From stats file:
# 1. Number of variants: ~1-10M depending on your genotype data
# 2. Genome-wide significant hits: p < 5×10⁻⁸
# 3. Check top associations for known T2D loci

# Example:
# zcat results/Basic/EUR/bolt_T2D.Basic.stats.gz | wc -l
# zcat results/Basic/EUR/bolt_T2D.Basic.stats.gz | awk 'NR>1 && $NF < 5e-8' | wc -l

