#!/bin/bash
# Example Configuration: Sensitivity Analysis with Multiple Covariate Models
# ============================================================================
#
# Scenario: GWAS of CAD with 3 different covariate models to assess robustness
#
# This example shows:
# - Single phenotype analyzed with multiple covariate adjustments
# - Sensitivity analysis to check if associations are robust
# - Progressive covariate adjustment (minimal → standard → full)
#
# Expected jobs: 1 phenotype × 3 covariate sets = 3 jobs
#
# Use case: Compare results across models to ensure findings aren't driven
#           by specific covariate choices
#
# ============================================================================

# ============================================================================
# Configuration in 1_run_bolt_lmm.sbatch.sh
# ============================================================================

# Define phenotypes
phenotypes=(CAD)  # Coronary Artery Disease

# Define covariate sets (increasing complexity)
covar_sets=(Minimal Standard FullyAdjusted)

# SLURM array: 1 × 3 = 3 jobs
#SBATCH --array=1-3

# ============================================================================
# Covariate configuration in run_single_phenotype.sh
# ============================================================================

# Model 1: Minimal (age + sex + genotyping array)
if [ "${covar_str}" == "Minimal" ]; then
    qcovar_col_args="--qCovarCol=age"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"

# Model 2: Standard (Minimal + 10 PCs)
elif [ "${covar_str}" == "Standard" ]; then
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"

# Model 3: Fully Adjusted (Standard + BMI + smoking + lipids + blood pressure)
elif [ "${covar_str}" == "FullyAdjusted" ]; then
    qcovar_col_args="--qCovarCol=age --qCovarCol=BMI --qCovarCol=SBP --qCovarCol=total_cholesterol --qCovarCol=smoking_years --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"
fi

# ============================================================================
# Test run configuration in 0d_test_run.sbatch.sh
# ============================================================================

TEST_PHENOTYPE="CAD"
TEST_COVAR_SET="Standard"  # Test with middle complexity model

# ============================================================================
# Expected Output
# ============================================================================

# After successful run:
# results/
# ├── Minimal/
# │   └── EUR/
# │       ├── bolt_CAD.Minimal.stats.gz
# │       └── bolt_CAD.Minimal.log.gz
# ├── Standard/
# │   └── EUR/
# │       ├── bolt_CAD.Standard.stats.gz
# │       └── bolt_CAD.Standard.log.gz
# └── FullyAdjusted/
#     └── EUR/
#         ├── bolt_CAD.FullyAdjusted.stats.gz
#         └── bolt_CAD.FullyAdjusted.log.gz

# ============================================================================
# Comparing Results Across Models
# ============================================================================

# 1. Compare genome-wide significant hits
echo "Genome-wide significant variants by model:"
for model in Minimal Standard FullyAdjusted; do
    n_sig=$(zcat results/${model}/EUR/bolt_CAD.${model}.stats.gz | \
            awk 'NR>1 && $NF < 5e-8' | wc -l)
    echo "  ${model}: ${n_sig} variants"
done

# 2. Compare top hit effect sizes
echo -e "\nTop hit comparison:"
for model in Minimal Standard FullyAdjusted; do
    echo "=== ${model} ==="
    zcat results/${model}/EUR/bolt_CAD.${model}.stats.gz | \
        awk 'NR>1' | sort -k12,12g | head -1 | \
        awk '{print "  SNP:", $1, "BETA:", $9, "P:", $12}'
done

# 3. Check heritability estimates
echo -e "\nHeritability by model:"
for model in Minimal Standard FullyAdjusted; do
    h2=$(zcat results/${model}/EUR/bolt_CAD.${model}.log.gz | \
         grep "h2:" | head -1)
    echo "  ${model}: ${h2}"
done

# 4. Compare λ_GC across models
echo -e "\nGenomic inflation:"
for model in Minimal Standard FullyAdjusted; do
    # Extract and calculate λ_GC from summary statistics
    # (Calculation: median χ² / 0.456, or from log file if reported)
    echo "  ${model}: [check log file or calculate from stats]"
done

# ============================================================================
# Interpretation Guidelines
# ============================================================================

# Robust associations:
# - Should be genome-wide significant (p < 5×10⁻⁸) in ALL models
# - Effect sizes (BETA) should be similar across models
# - If BETA changes dramatically with full adjustment:
#   → May indicate confounding by adjusted variables
#   → Example: Effect attenuated with BMI adjustment suggests mediation

# Expected patterns:
# - Minimal model: May have slight inflation (higher λ_GC)
# - Standard model: Well-calibrated (λ_GC ≈ 1.00-1.05)
# - Fully adjusted: Similar to standard, possibly slightly lower h²

# Red flags:
# - Associations disappear with PC adjustment: Population stratification
# - Associations disappear with risk factor adjustment: Possible mediation
# - λ_GC > 1.10 in any model: Insufficient stratification control

# Reporting:
# - Present results from "Standard" as primary
# - Report "FullyAdjusted" for robustness
# - Discuss any SNPs that show sensitivity to covariate choice

# ============================================================================
# Advanced: Meta-regression of effect sizes
# ============================================================================

# Extract effect sizes for top SNPs across all three models
# and test for heterogeneity using meta-analysis tools

# Example workflow:
# 1. Identify genome-wide significant SNPs in Standard model
# 2. Extract BETA and SE for these SNPs from all three models
# 3. Test for heterogeneity using Q-statistic or I²
# 4. Identify SNPs with model-dependent effects

