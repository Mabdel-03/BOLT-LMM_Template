#!/bin/bash
#SBATCH --job-name=bolt_gwas  # CUSTOMIZE: Your job name
#SBATCH --partition=YOUR_PARTITION  # CUSTOMIZE: Your HPC partition name
#SBATCH --mem=100G  # CUSTOMIZE: Adjust based on sample size (see ADAPTATION_GUIDE.md)
#SBATCH -n 32  # CUSTOMIZE: Number of threads (match --numThreads in run_single_phenotype.sh)
#SBATCH --time=47:00:00  # CUSTOMIZE: Adjust based on expected runtime
#SBATCH --output=1_%a.out  # %a is replaced with array task ID
#SBATCH --error=1_%a.err
#SBATCH --array=1-6  # CUSTOMIZE: Set to N_phenotypes × N_covariate_sets
#SBATCH --mail-user=YOUR_EMAIL@institution.edu  # CUSTOMIZE: Your email address
#SBATCH --mail-type=BEGIN,END,FAIL,ARRAY_TASKS

set -beEo pipefail

# ============================================================================
# SLURM Array Job: BOLT-LMM GWAS Analysis
# ============================================================================
#
# Purpose: Run BOLT-LMM for multiple phenotype-covariate combinations
#          using SLURM job arrays for parallel execution
#
# Job Array Structure:
#   Total jobs = N_phenotypes × N_covariate_sets
#   Each array task runs one phenotype-covariate combination
#
# Example Configurations:
#   - 1 phenotype × 2 covariate sets = 2 jobs → --array=1-2
#   - 3 phenotypes × 1 covariate set = 3 jobs → --array=1-3
#   - 3 phenotypes × 2 covariate sets = 6 jobs → --array=1-6
#   - 10 phenotypes × 3 covariate sets = 30 jobs → --array=1-30
#
# Customization Points:
# 1. SLURM header (lines 1-12): Resources, partition, email
# 2. Phenotypes array (line ~50): List your phenotype names
# 3. Covariate sets array (line ~60): List your covariate set names
# 4. Array mapping logic (lines ~70-90): Adjust if needed
#
# See ADAPTATION_GUIDE.md for detailed instructions
#
# ============================================================================

echo "========================================"
echo "BOLT-LMM GWAS Analysis"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Node: ${SLURM_NODELIST}"
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
# DEFINE PHENOTYPES AND COVARIATE SETS
# ============================================================================

# ----------------------------------------------------------------------------
# CUSTOMIZE: Define your phenotypes
# ----------------------------------------------------------------------------
# List all phenotype column names from your phenotype file
# These must match exactly (case-sensitive) with column names in PHENO_FILE
#
# Examples:
#   Binary phenotypes: T2D, CAD, Stroke, Depression
#   Quantitative phenotypes: BMI, Height, SBP, DBP
#
phenotypes=(PHENOTYPE1 PHENOTYPE2 PHENOTYPE3)
# Example for binary traits: phenotypes=(T2D CAD Stroke)
# Example for quantitative: phenotypes=(BMI Height Weight)
# Example for mixed: phenotypes=(T2D BMI CAD Height)

# ----------------------------------------------------------------------------
# CUSTOMIZE: Define your covariate sets
# ----------------------------------------------------------------------------
# List all covariate set names
# These must match the cases defined in run_single_phenotype.sh (line ~70-130)
#
# Common covariate sets:
#   Basic: Minimal covariates (age, sex, array)
#   Extended_10PCs: Basic + 10 principal components
#   FullModel: All relevant covariates for your analysis
#
covar_sets=(COVAR_SET1 COVAR_SET2)
# Example: covar_sets=(Basic Extended_10PCs)
# Example: covar_sets=(NoPCs 10PCs 20PCs)
# Example: covar_sets=(Basic FullModel)

# ----------------------------------------------------------------------------
# Validate array size
# ----------------------------------------------------------------------------
n_pheno=${#phenotypes[@]}
n_covar=${#covar_sets[@]}
total_jobs=$((n_pheno * n_covar))

echo ""
echo "Configuration:"
echo "  Number of phenotypes: ${n_pheno}"
echo "  Number of covariate sets: ${n_covar}"
echo "  Total jobs: ${total_jobs}"
echo ""

if [ ${SLURM_ARRAY_TASK_ID} -gt ${total_jobs} ]; then
    echo "ERROR: Array task ID ${SLURM_ARRAY_TASK_ID} exceeds total jobs ${total_jobs}" >&2
    echo "Update SLURM --array parameter to: --array=1-${total_jobs}" >&2
    exit 1
fi

# ============================================================================
# MAP ARRAY TASK ID TO PHENOTYPE AND COVARIATE SET
# ============================================================================

# ----------------------------------------------------------------------------
# STANDARD MAPPING (works for most cases)
# ----------------------------------------------------------------------------
# Layout: Cycle through covariate sets for each phenotype
# Task 1: phenotypes[0] × covar_sets[0]
# Task 2: phenotypes[0] × covar_sets[1]
# Task 3: phenotypes[1] × covar_sets[0]
# Task 4: phenotypes[1] × covar_sets[1]
# etc.

pheno_idx=$(( (SLURM_ARRAY_TASK_ID - 1) / n_covar ))
covar_idx=$(( (SLURM_ARRAY_TASK_ID - 1) % n_covar ))

phenotype=${phenotypes[$pheno_idx]}
covar_str=${covar_sets[$covar_idx]}

# ----------------------------------------------------------------------------
# ALTERNATIVE MAPPING (if you need custom combinations)
# ----------------------------------------------------------------------------
# Uncomment and customize if you need specific phenotype-covariate pairings
# that don't follow the standard grid layout

# if [ ${SLURM_ARRAY_TASK_ID} -eq 1 ]; then
#     phenotype="PHENO1"; covar_str="COVAR_SET1"
# elif [ ${SLURM_ARRAY_TASK_ID} -eq 2 ]; then
#     phenotype="PHENO1"; covar_str="COVAR_SET2"
# elif [ ${SLURM_ARRAY_TASK_ID} -eq 3 ]; then
#     phenotype="PHENO2"; covar_str="COVAR_SET1"
# # Add more cases as needed
# else
#     echo "ERROR: Invalid array task ID: ${SLURM_ARRAY_TASK_ID}" >&2
#     exit 1
# fi

# ============================================================================
# DISPLAY JOB CONFIGURATION
# ============================================================================

echo "Processing:"
echo "  Phenotype: ${phenotype}"
echo "  Covariate set: ${covar_str}"
echo "  Population: ${POPULATION}"
echo ""

# ============================================================================
# RUN BOLT-LMM
# ============================================================================

echo "Executing run_single_phenotype.sh..."
echo ""

bash ${SRCDIR}/run_single_phenotype.sh ${phenotype} ${covar_str}

exit_code=$?

# ============================================================================
# REPORT STATUS
# ============================================================================

echo ""
echo "========================================"
if [ ${exit_code} -eq 0 ]; then
    echo "✅ SUCCESS: ${phenotype} with ${covar_str}"
    echo ""
    echo "Output files:"
    ls -lh ${RESULTS_DIR}/${covar_str}/${POPULATION}/bolt_${phenotype}.${covar_str}.stats.gz 2>/dev/null || echo "  Stats file not found"
    ls -lh ${RESULTS_DIR}/${covar_str}/${POPULATION}/bolt_${phenotype}.${covar_str}.log.gz 2>/dev/null || echo "  Log file not found"
else
    echo "❌ FAILED: ${phenotype} with ${covar_str}"
    echo "Exit code: ${exit_code}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check SLURM error log: 1_${SLURM_ARRAY_TASK_ID}.err"
    echo "2. Check BOLT-LMM log if it exists"
    echo "3. Verify phenotype and covariate names match file columns"
    echo "4. See TROUBLESHOOTING.md for common issues"
fi

echo "End time: $(date)"
echo "========================================"

exit ${exit_code}

