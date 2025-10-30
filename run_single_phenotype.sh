#!/bin/bash
set -beEo pipefail

# ============================================================================
# BOLT-LMM Single Phenotype Runner
# ============================================================================
#
# Purpose: Run BOLT-LMM for one phenotype with one covariate set
#          Processes the full genome in a single run
#
# Usage: bash run_single_phenotype.sh <PHENOTYPE> <COVAR_SET>
# Example: bash run_single_phenotype.sh T2D Basic
#          bash run_single_phenotype.sh BMI Extended_10PCs
#
# Input:  - Genotype files (.bed/.bim/.fam)
#         - Phenotype file (filtered to population)
#         - Covariate file (filtered to population)
#         - Model SNPs file
#         - LD scores file
#         - Genetic map file
# Output: - Summary statistics (.stats.gz)
#         - Log file (.log.gz)
#
# Customization Points:
# 1. Directory paths (lines ~30-40)
# 2. Covariate configurations (lines ~70-130) ⭐⭐⭐ MOST IMPORTANT
# 3. BOLT-LMM command options (lines ~170-200)
#
# See ADAPTATION_GUIDE.md for detailed customization instructions
#
# ============================================================================

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

if [ $# -ne 2 ]; then
    echo "Usage: $0 <PHENOTYPE> <COVAR_SET>" >&2
    echo ""
    echo "Arguments:"
    echo "  PHENOTYPE  : Name of phenotype column in phenotype file"
    echo "  COVAR_SET  : Name of covariate set (must match cases below)"
    echo ""
    echo "Example:"
    echo "  $0 T2D Basic"
    echo "  $0 BMI Extended_10PCs"
    exit 1
fi

phenotype=$1
covar_str=$2

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

# CUSTOMIZE: Set the correct path to your analysis directory
SRCDIR="/path/to/your/analysis/directory"
# Example: SRCDIR="/home/user/projects/my_gwas_analysis"

# Load paths configuration
if [ ! -f "${SRCDIR}/paths.sh" ]; then
    echo "ERROR: paths.sh not found in ${SRCDIR}" >&2
    echo "Make sure you've created and configured paths.sh" >&2
    exit 1
fi

source "${SRCDIR}/paths.sh"

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

# CUSTOMIZE: Activate your conda/virtual environment with BOLT-LMM
# Option 1: Conda environment
# module load miniconda3/v4
# source /path/to/conda/bin/condainit
# conda activate YOUR_ENVIRONMENT_NAME

# Option 2: Module system
# module load bolt-lmm

# Option 3: Add BOLT-LMM to PATH
# export PATH="/path/to/BOLT-LMM_v2.X/bin:${PATH}"

# Verify BOLT-LMM is available
if ! command -v bolt &> /dev/null; then
    echo "ERROR: bolt command not found" >&2
    echo "Please install BOLT-LMM or add it to your PATH" >&2
    echo "Download from: https://alkesgroup.broadinstitute.org/BOLT-LMM/" >&2
    exit 1
fi

# ============================================================================
# OUTPUT CONFIGURATION
# ============================================================================

echo "========================================"
echo "Running BOLT-LMM for ${phenotype}"
echo "Covariate model: ${covar_str}"
echo "Population: ${POPULATION}"
echo "========================================"

# Output directory structure: results/<COVAR_SET>/<POPULATION>/
out_dir="${RESULTS_DIR}/${covar_str}/${POPULATION}"
mkdir -p ${out_dir}

# Output file naming: bolt_<PHENOTYPE>.<COVAR_SET>
out_file="${out_dir}/bolt_${phenotype}.${covar_str}"

# ============================================================================
# CLEAN UP PREVIOUS OUTPUTS
# ============================================================================

echo "Checking for existing output files..."
for ext in stats stats.gz log log.gz; do
    if [ -f "${out_file}.${ext}" ]; then
        echo "  Removing old file: ${out_file}.${ext}"
        rm -f "${out_file}.${ext}"
    fi
done
echo "✓ Ready for clean run"
echo ""

# ============================================================================
# COVARIATE CONFIGURATION
# ============================================================================
# ⭐⭐⭐ THIS IS THE MOST IMPORTANT CUSTOMIZATION SECTION ⭐⭐⭐
#
# Define your covariate sets here. Each covariate set specifies which
# covariates to include in the BOLT-LMM model.
#
# IMPORTANT NOTES:
# 1. Column names must match EXACTLY (case-sensitive) with your covariate file
# 2. Quantitative covariates: Use --qCovarCol (age, BMI, PCs, etc.)
# 3. Categorical covariates: Use --covarCol (sex, array, batch, etc.)
# 4. Each covariate needs its own --qCovarCol or --covarCol argument
# 5. List all arguments in one variable (see examples below)
#
# To add a new covariate set, add a new elif block following the pattern below
# ============================================================================

# CUSTOMIZE: Define your covariate sets here
# Add as many covariate sets as you need for your analysis

# ----------------------------------------------------------------------------
# EXAMPLE 1: Basic model (minimal covariates)
# ----------------------------------------------------------------------------
if [ "${covar_str}" == "Basic" ]; then
    # CUSTOMIZE: Quantitative covariates (continuous variables)
    # Change column names to match your covariate file
    qcovar_col_args="--qCovarCol=age"
    
    # CUSTOMIZE: Categorical covariates (discrete variables)
    # Change column names to match your covariate file
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"

# ----------------------------------------------------------------------------
# EXAMPLE 2: Extended model with principal components
# ----------------------------------------------------------------------------
elif [ "${covar_str}" == "Extended_10PCs" ]; then
    # CUSTOMIZE: Add PC1-PC10 as quantitative covariates
    # Change PC column names to match your covariate file
    # Common formats: PC1-PC10, PCA1-PCA10, UKB_PC1-UKB_PC10
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    
    covar_col_args="--covarCol=sex --covarCol=genotyping_array"

# ----------------------------------------------------------------------------
# EXAMPLE 3: Full model with additional covariates
# ----------------------------------------------------------------------------
elif [ "${covar_str}" == "FullModel" ]; then
    # CUSTOMIZE: Include age, BMI, smoking, and PCs as quantitative
    qcovar_col_args="--qCovarCol=age --qCovarCol=BMI --qCovarCol=smoking_years --qCovarCol=PC1 --qCovarCol=PC2 --qCovarCol=PC3 --qCovarCol=PC4 --qCovarCol=PC5 --qCovarCol=PC6 --qCovarCol=PC7 --qCovarCol=PC8 --qCovarCol=PC9 --qCovarCol=PC10"
    
    # CUSTOMIZE: Include sex, array, and assessment center as categorical
    covar_col_args="--covarCol=sex --covarCol=genotyping_array --covarCol=assessment_center"

# ----------------------------------------------------------------------------
# CUSTOMIZE: Add your own covariate sets below
# ----------------------------------------------------------------------------
# Template for adding new covariate set:
# elif [ "${covar_str}" == "YOUR_COVAR_SET_NAME" ]; then
#     qcovar_col_args="--qCovarCol=COVAR1 --qCovarCol=COVAR2 ..."
#     covar_col_args="--covarCol=COVAR3 --covarCol=COVAR4 ..."

# ----------------------------------------------------------------------------
# ERROR: Unknown covariate set
# ----------------------------------------------------------------------------
else
    echo "ERROR: Unknown covar_str: ${covar_str}" >&2
    echo ""
    echo "Available covariate sets:" >&2
    echo "  - Basic" >&2
    echo "  - Extended_10PCs" >&2
    echo "  - FullModel" >&2
    echo ""
    echo "To add a new covariate set, edit this script (run_single_phenotype.sh)" >&2
    echo "and add a new elif block in the COVARIATE CONFIGURATION section" >&2
    exit 1
fi

# ============================================================================
# DISPLAY CONFIGURATION
# ============================================================================

echo "Configuration:"
echo "  Genotype: ${GENOTYPE_BFILE}"
echo "  Phenotype: ${phenotype}"
echo "  Phenotype file: ${PHENO_FILE_FILTERED}"
echo "  Covariate file: ${COVAR_FILE_FILTERED}"
echo "  Covariate set: ${covar_str}"
echo "  Model SNPs: ${MODEL_SNPS_FILE}"
echo "  Output: ${out_file}.stats"
echo ""

# ============================================================================
# INPUT FILE VALIDATION
# ============================================================================

echo "Verifying input files..."
error_found=false

# Check genotype files
for ext in bed bim fam; do
    file="${GENOTYPE_BFILE}.${ext}"
    if [ ! -f "$file" ]; then
        echo "ERROR: Required file not found: $file" >&2
        error_found=true
    fi
done

# Check phenotype file
if [ ! -f "${PHENO_FILE_FILTERED}" ]; then
    echo "ERROR: Phenotype file not found: ${PHENO_FILE_FILTERED}" >&2
    echo "Did you run: bash filter_to_population.sh ?" >&2
    error_found=true
fi

# Check covariate file
if [ ! -f "${COVAR_FILE_FILTERED}" ]; then
    echo "ERROR: Covariate file not found: ${COVAR_FILE_FILTERED}" >&2
    echo "Did you run: bash filter_to_population.sh ?" >&2
    error_found=true
fi

# Check model SNPs
if [ ! -f "${MODEL_SNPS_FILE}" ]; then
    echo "ERROR: Model SNPs file not found: ${MODEL_SNPS_FILE}" >&2
    echo "Did you run: sbatch 0b_prepare_model_snps.sbatch.sh ?" >&2
    error_found=true
fi

# Check LD scores
if [ ! -f "${LD_SCORES_FILE}" ]; then
    echo "ERROR: LD scores file not found: ${LD_SCORES_FILE}" >&2
    error_found=true
fi

# Check genetic map
if [ ! -f "${GENETIC_MAP_FILE}" ]; then
    echo "ERROR: Genetic map file not found: ${GENETIC_MAP_FILE}" >&2
    error_found=true
fi

if [ "$error_found" = true ]; then
    echo ""
    echo "Please fix the errors above before running BOLT-LMM" >&2
    exit 1
fi

echo "✓ All input files verified"
echo ""

# ============================================================================
# RUN BOLT-LMM
# ============================================================================

echo "Starting BOLT-LMM analysis..."
echo "This will analyze the full genome (~1-10M variants depending on your data)"
echo ""
echo "Expected runtime: 1-3 hours (varies by sample size and # threads)"
echo ""

# CUSTOMIZE: Adjust BOLT-LMM parameters if needed
# Most common customizations:
# - --numThreads: Number of threads (should match SLURM -n parameter)
# - --covarMaxLevels: Maximum levels for categorical covariates (default: 10)
# - --verboseStats: Add this flag to output additional columns

bolt \
    --bfile=${GENOTYPE_BFILE} \
    --phenoFile=${PHENO_FILE_FILTERED} \
    --phenoCol=${phenotype} \
    --covarFile=${COVAR_FILE_FILTERED} \
    ${qcovar_col_args} \
    ${covar_col_args} \
    --covarMaxLevels=30 \
    --modelSnps=${MODEL_SNPS_FILE} \
    --LDscoresFile=${LD_SCORES_FILE} \
    --geneticMapFile=${GENETIC_MAP_FILE} \
    --lmm \
    --LDscoresMatchBp \
    --numThreads=${DEFAULT_THREADS} \
    --statsFile=${out_file}.stats \
    --verboseStats \
    2>&1 | tee ${out_file}.log

bolt_exit_code=$?

echo ""
echo "BOLT-LMM exit code: ${bolt_exit_code}"

# ============================================================================
# ERROR HANDLING
# ============================================================================

if [ ${bolt_exit_code} -ne 0 ]; then
    echo ""
    echo "❌ ERROR: BOLT-LMM failed with exit code ${bolt_exit_code}" >&2
    echo ""
    echo "Common issues:" >&2
    echo "1. Phenotype column name mismatch (check: ${phenotype})" >&2
    echo "2. Covariate column name mismatch" >&2
    echo "3. Insufficient memory" >&2
    echo "4. Convergence failure (check log file)" >&2
    echo ""
    echo "Check the log file for details:" >&2
    echo "  ${out_file}.log" >&2
    exit 1
fi

# ============================================================================
# COMPRESS OUTPUT
# ============================================================================

echo ""
echo "Compressing output files..."

# Compress summary statistics
if [ -f "${out_file}.stats" ] && [ -s "${out_file}.stats" ]; then
    gzip -f ${out_file}.stats
    echo "✓ Created: ${out_file}.stats.gz"
else
    echo "⚠️  WARNING: Stats file is empty or not found" >&2
fi

# Compress log file
if [ -f "${out_file}.log" ] && [ -s "${out_file}.log" ]; then
    gzip -f ${out_file}.log
    echo "✓ Created: ${out_file}.log.gz"
else
    echo "⚠️  WARNING: Log file is empty or not found" >&2
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "========================================"
echo "✅ COMPLETED: ${phenotype} with ${covar_str}"
echo "========================================"
echo ""
echo "Output files:"
if [ -f "${out_file}.stats.gz" ]; then
    ls -lh ${out_file}.stats.gz
    
    # Count variants
    n_variants=$(zcat ${out_file}.stats.gz | tail -n +2 | wc -l)
    echo "  Variants analyzed: ${n_variants}"
fi

if [ -f "${out_file}.log.gz" ]; then
    ls -lh ${out_file}.log.gz
    
    # Extract heritability estimate (if available)
    h2_line=$(zcat ${out_file}.log.gz | grep -i "h2:" || true)
    if [ ! -z "$h2_line" ]; then
        echo "  ${h2_line}"
    fi
fi

echo ""
echo "Next steps:"
echo "1. Review log file for warnings and heritability estimate"
echo "2. Create QQ plot and Manhattan plot"
echo "3. Check genomic inflation factor (λ_GC)"
echo "4. Identify genome-wide significant hits (p < 5×10⁻⁸)"
echo ""

