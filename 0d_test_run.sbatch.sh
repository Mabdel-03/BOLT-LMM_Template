#!/bin/bash
#SBATCH --job-name=bolt_test
#SBATCH --partition=YOUR_PARTITION  # CUSTOMIZE: Your HPC partition name
#SBATCH --mem=150G  # CUSTOMIZE: Adjust based on sample size
#SBATCH -n 32  # CUSTOMIZE: Number of threads
#SBATCH --time=6:00:00  # CUSTOMIZE: Adjust based on expected runtime
#SBATCH --output=0d.out
#SBATCH --error=0d.err
#SBATCH --mail-user=YOUR_EMAIL@institution.edu  # CUSTOMIZE: Your email address
#SBATCH --mail-type=BEGIN,END,FAIL

set -beEo pipefail

# ============================================================================
# BOLT-LMM Test Run
# ============================================================================
#
# Purpose: Validate the complete pipeline on ONE phenotype-covariate
#          combination before committing resources to full analysis
#
# What This Tests:
# - All input files exist and are correctly formatted
# - BOLT-LMM configuration is correct
# - Phenotype and covariate files are compatible
# - Expected output files are generated
# - No runtime errors occur
#
# ⚠️  CRITICAL: Do NOT proceed to full analysis if test fails!
#
# Customization:
# - Choose a representative phenotype (good sample size)
# - Choose a covariate set (preferably your primary model)
# - Lines ~60-70: Set TEST_PHENOTYPE and TEST_COVAR_SET
#
# ============================================================================

echo "========================================"
echo "BOLT-LMM Test Run"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Resources: ${SLURM_MEM_PER_NODE}MB RAM, ${SLURM_NTASKS} CPUs"
echo "Start time: $(date)"
echo "========================================"

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

# CUSTOMIZE: Set the correct path to your analysis directory
SRCDIR="/path/to/your/analysis/directory"
# Example: SRCDIR="/home/user/projects/my_gwas_analysis"

cd ${SRCDIR}

# Load paths configuration
if [ ! -f "${SRCDIR}/paths.sh" ]; then
    echo "ERROR: paths.sh not found in ${SRCDIR}" >&2
    exit 1
fi

source "${SRCDIR}/paths.sh"

# ============================================================================
# TEST CONFIGURATION
# ============================================================================

# ----------------------------------------------------------------------------
# CUSTOMIZE: Choose test phenotype and covariate set
# ----------------------------------------------------------------------------
# Pick a representative phenotype from your phenotype file
# Pick a covariate set defined in run_single_phenotype.sh
#
# Recommendations:
# - Choose a phenotype with good sample size (>10K cases for binary traits)
# - Choose your primary covariate model
# - Avoid phenotypes with very low prevalence or many missing values

TEST_PHENOTYPE="YOUR_TEST_PHENOTYPE"
# Example: TEST_PHENOTYPE="T2D"
# Example: TEST_PHENOTYPE="BMI"

TEST_COVAR_SET="YOUR_TEST_COVAR_SET"
# Example: TEST_COVAR_SET="Basic"
# Example: TEST_COVAR_SET="Extended_10PCs"

echo ""
echo "Test Configuration:"
echo "  Phenotype: ${TEST_PHENOTYPE}"
echo "  Covariate set: ${TEST_COVAR_SET}"
echo "  Population: ${POPULATION}"
echo ""
echo "This tests the full pipeline on the complete genome."
echo ""

# ============================================================================
# CLEAN UP PREVIOUS TEST OUTPUTS
# ============================================================================

echo "Removing any previous test outputs..."
out_dir="${RESULTS_DIR}/${TEST_COVAR_SET}/${POPULATION}"
out_file="${out_dir}/bolt_${TEST_PHENOTYPE}.${TEST_COVAR_SET}"

for ext in stats stats.gz log log.gz; do
    if [ -f "${out_file}.${ext}" ]; then
        echo "  Removing: ${out_file}.${ext}"
        rm -f "${out_file}.${ext}"
    fi
done

echo "✓ Ready for clean test run"
echo ""

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

echo "Running pre-flight checks..."
echo ""

error_found=false

# Check if genotype BED files exist
echo "1. Checking genotype files..."
if [ ! -f "${GENOTYPE_BFILE}.bed" ]; then
    echo "   ❌ ERROR: ${GENOTYPE_BFILE}.bed not found" >&2
    echo "      Did you run: sbatch 0a_convert_to_bed.sbatch.sh ?" >&2
    error_found=true
else
    echo "   ✓ Genotype files found"
fi

# Check if model SNPs file exists
echo "2. Checking model SNPs file..."
if [ ! -f "${MODEL_SNPS_FILE}" ]; then
    echo "   ❌ ERROR: ${MODEL_SNPS_FILE} not found" >&2
    echo "      Did you run: sbatch 0b_prepare_model_snps.sbatch.sh ?" >&2
    error_found=true
else
    n_model_snps=$(wc -l < "${MODEL_SNPS_FILE}")
    echo "   ✓ Model SNPs file found (${n_model_snps} SNPs)"
    
    if [ ${n_model_snps} -lt 100000 ]; then
        echo "   ⚠️  WARNING: Very few model SNPs (< 100K)" >&2
    fi
fi

# Check if filtered phenotype/covariate files exist
echo "3. Checking filtered phenotype/covariate files..."
if [ ! -f "${PHENO_FILE_FILTERED}" ]; then
    echo "   ❌ ERROR: ${PHENO_FILE_FILTERED} not found" >&2
    echo "      Did you run: bash filter_to_population.sh ?" >&2
    error_found=true
else
    echo "   ✓ Filtered phenotype file found"
fi

if [ ! -f "${COVAR_FILE_FILTERED}" ]; then
    echo "   ❌ ERROR: ${COVAR_FILE_FILTERED} not found" >&2
    echo "      Did you run: bash filter_to_population.sh ?" >&2
    error_found=true
else
    echo "   ✓ Filtered covariate file found"
fi

# Check if BOLT-LMM reference files exist
echo "4. Checking BOLT-LMM reference files..."
if [ ! -f "${LD_SCORES_FILE}" ]; then
    echo "   ❌ ERROR: ${LD_SCORES_FILE} not found" >&2
    error_found=true
else
    echo "   ✓ LD scores file found"
fi

if [ ! -f "${GENETIC_MAP_FILE}" ]; then
    echo "   ❌ ERROR: ${GENETIC_MAP_FILE} not found" >&2
    error_found=true
else
    echo "   ✓ Genetic map file found"
fi

echo ""

if [ "$error_found" = true ]; then
    echo "❌ Pre-flight checks FAILED" >&2
    echo ""
    echo "Please fix the errors above before running test" >&2
    exit 1
fi

echo "✅ All pre-flight checks passed"
echo ""

# ============================================================================
# RUN TEST
# ============================================================================

echo "========================================"
echo "Starting Test Run"
echo "========================================"
echo ""

bash ${SRCDIR}/run_single_phenotype.sh ${TEST_PHENOTYPE} ${TEST_COVAR_SET}

test_exit=$?

# ============================================================================
# EVALUATE RESULTS
# ============================================================================

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo ""

if [ ${test_exit} -eq 0 ]; then
    echo "✅ TEST PASSED!"
    echo ""
    
    # Verify output files
    echo "Verification:"
    if [ -f "${out_file}.stats.gz" ]; then
        echo "  ✓ Summary statistics file created"
        ls -lh ${out_file}.stats.gz
        
        # Count variants
        n_variants=$(zcat ${out_file}.stats.gz | tail -n +2 | wc -l)
        echo "  ✓ Number of variants analyzed: ${n_variants}"
        
        if [ ${n_variants} -lt 100000 ]; then
            echo "  ⚠️  WARNING: Very few variants (< 100K). Is this expected?"
        fi
    else
        echo "  ❌ ERROR: Stats file not created" >&2
        test_exit=1
    fi
    
    if [ -f "${out_file}.log.gz" ]; then
        echo "  ✓ Log file created"
        ls -lh ${out_file}.log.gz
        
        # Extract key information from log
        echo ""
        echo "Key information from log:"
        
        # Sample size
        sample_size=$(zcat ${out_file}.log.gz | grep -i "analyzing" | grep -oP '\d+(?= samples)' || echo "Not found")
        echo "  - Sample size: ${sample_size}"
        
        # Heritability
        h2_line=$(zcat ${out_file}.log.gz | grep -i "h2:" || echo "Heritability estimate not found")
        echo "  - ${h2_line}"
        
        # Check for warnings
        n_warnings=$(zcat ${out_file}.log.gz | grep -i "warning" | wc -l)
        if [ ${n_warnings} -gt 0 ]; then
            echo "  ⚠️  Found ${n_warnings} warning(s) in log file"
            echo "     Review log file for details: ${out_file}.log.gz"
        else
            echo "  ✓ No warnings in log file"
        fi
    else
        echo "  ❌ ERROR: Log file not created" >&2
        test_exit=1
    fi
    
    echo ""
    
    if [ ${test_exit} -eq 0 ]; then
        echo "========================================"
        echo "✅ ALL CHECKS PASSED"
        echo "========================================"
        echo ""
        echo "Next steps:"
        echo "1. Review the output files and log for any issues"
        echo "2. Check QC metrics:"
        echo "   - Sample size matches expectation?"
        echo "   - Heritability estimate reasonable?"
        echo "   - No concerning warnings?"
        echo "3. If everything looks good, submit full analysis:"
        echo "   sbatch 1_run_bolt_lmm.sbatch.sh"
        echo ""
    else
        echo "========================================"
        echo "⚠️  TEST PASSED WITH WARNINGS"
        echo "========================================"
        echo ""
        echo "Review the issues above before proceeding"
        echo ""
    fi
    
else
    echo "❌ TEST FAILED"
    echo ""
    echo "BOLT-LMM exited with error code ${test_exit}"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check SLURM error log: 0d.err"
    echo "2. Check BOLT-LMM log if it exists: ${out_file}.log"
    echo "3. Verify phenotype name matches column in phenotype file:"
    echo "   zcat ${PHENO_FILE_FILTERED} | head -1"
    echo "4. Verify covariate set is defined in run_single_phenotype.sh"
    echo "5. Check available memory (may need more than ${SLURM_MEM_PER_NODE}MB)"
    echo "6. See TROUBLESHOOTING.md for more help"
    echo ""
    echo "❌ DO NOT PROCEED TO FULL ANALYSIS"
    exit 1
fi

echo "End time: $(date)"
echo "========================================"

