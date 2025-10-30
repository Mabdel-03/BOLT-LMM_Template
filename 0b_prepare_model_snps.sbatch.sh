#!/bin/bash
#SBATCH --job-name=model_snps
#SBATCH --partition=YOUR_PARTITION  # CUSTOMIZE: Your HPC partition name
#SBATCH --mem=80G
#SBATCH -n 8
#SBATCH --time=2:00:00
#SBATCH --output=0b.out
#SBATCH --error=0b.err
#SBATCH --mail-user=YOUR_EMAIL@institution.edu  # CUSTOMIZE: Your email address
#SBATCH --mail-type=BEGIN,END,FAIL

set -beEo pipefail

# ============================================================================
# SLURM Job Script: Prepare Model SNPs for BOLT-LMM
# ============================================================================
#
# Purpose: Create a list of LD-pruned, high-quality SNPs for computing the
#          genetic relationship matrix (GRM) in BOLT-LMM
#
# Input:  PLINK2 genotype files (.pgen, .pvar.zst, .psam)
# Output: Text file with SNP IDs for model SNPs (~400-600K SNPs recommended)
#
# QC Filters Applied:
# - MAF >= 0.5% (common and low-frequency variants)
# - Missingness < 10% per SNP
# - HWE filter with sample-size adjustment
# - LD pruning: r² < 0.5 in 1000kb windows
# - Autosomes only (chr 1-22)
#
# Note: Model SNPs are used only for GRM computation, not for association
#       testing. Therefore, QC filters are more relaxed than typical GWAS QC.
#
# Customization: See paths.sh for all path configurations
#
# ============================================================================

echo "========================================"
echo "Job: Prepare Model SNPs for GRM"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "========================================"

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

# CUSTOMIZE: Activate your conda/virtual environment with PLINK2
# Option 1: Conda environment
# module load miniconda3/v4
# source /path/to/conda/bin/condainit
# conda activate YOUR_ENVIRONMENT_NAME

# Option 2: Module system
# module load plink2

# Option 3: Add PLINK2 to PATH
# export PATH="/path/to/plink2:${PATH}"

# Verify PLINK2 is available
if ! command -v plink2 &> /dev/null; then
    echo "ERROR: plink2 command not found" >&2
    echo "Please install PLINK2 or add it to your PATH" >&2
    echo "Download from: https://www.cog-genomics.org/plink/2.0/" >&2
    exit 1
fi

echo "PLINK2 version:"
plink2 --version

# ============================================================================
# FILE PATHS
# ============================================================================

output_prefix=$(dirname ${MODEL_SNPS_FILE})/$(basename ${MODEL_SNPS_FILE} .txt)

echo ""
echo "Configuration:"
echo "  Input genotype file: ${GENOTYPE_PFILE}"
echo "  Output model SNPs: ${MODEL_SNPS_FILE}"
echo "  Temporary prefix: ${output_prefix}"
echo ""

# ============================================================================
# VALIDATION
# ============================================================================

# Check if input files exist
echo "Checking input files..."
if [ ! -f "${GENOTYPE_PFILE}.pgen" ]; then
    echo "ERROR: Input pgen file not found: ${GENOTYPE_PFILE}.pgen" >&2
    echo ""
    echo "Please verify:"
    echo "1. GENOTYPE_PFILE is set correctly in paths.sh"
    echo "2. The .pgen file exists at the specified path"
    echo "3. You're running this on the correct system/mount" >&2
    exit 1
fi

echo "✓ Input files verified"
echo ""

# ============================================================================
# CLEAN UP OLD OUTPUT FILES
# ============================================================================

echo "Checking for existing output files..."
for file in "${MODEL_SNPS_FILE}" "${output_prefix}.prune.in" "${output_prefix}.prune.out" "${output_prefix}.log"; do
    if [ -f "$file" ]; then
        echo "  Removing old file: $file"
        rm -f "$file"
    fi
done
echo "✓ Ready for clean model SNP creation"
echo ""

# ============================================================================
# LD PRUNING
# ============================================================================

echo "Running LD pruning to select model SNPs..."
echo ""
echo "QC Filters:"
echo "  - MAF >= 0.5%"
echo "  - Missingness < 10%"
echo "  - HWE filter (sample-size adjusted)"
echo "  - LD pruning: r² < 0.5 in 1000kb windows, step 50 SNPs"
echo "  - Autosomes only (chr 1-22)"
echo ""
echo "Target: 400K-600K model SNPs for GRM computation"
echo "Memory allocated: ${SLURM_MEM_PER_NODE}MB"
echo ""
echo "This may take 15-45 minutes depending on the dataset size..."
echo ""

# Determine pvar compression flag
if [ -f "${GENOTYPE_PFILE}.pvar.zst" ]; then
    compression_flag="vzs"
elif [ -f "${GENOTYPE_PFILE}.pvar.gz" ]; then
    compression_flag="vzs"
else
    compression_flag=""
fi

# Run PLINK2 LD pruning
# CUSTOMIZE: You can adjust these parameters if needed:
# - --maf 0.005: Minimum allele frequency (0.5%)
# - --geno 0.10: Maximum missingness (10%)
# - --indep-pairwise 1000 50 0.5: Window size (kb), step, r² threshold
# For stricter LD pruning, use r² < 0.2
# For more relaxed, use r² < 0.8
plink2 \
    --pfile ${GENOTYPE_PFILE} ${compression_flag} \
    --chr 1-22 \
    --maf 0.005 \
    --geno 0.10 \
    --hwe 1e-5 0.001 keep-fewhet \
    --indep-pairwise 1000 50 0.5 \
    --out ${output_prefix} \
    --threads ${SLURM_NTASKS} \
    --memory $(( SLURM_MEM_PER_NODE * 95 / 100 ))

pruning_exit=$?

if [ ${pruning_exit} -ne 0 ]; then
    echo ""
    echo "ERROR: LD pruning failed with exit code ${pruning_exit}" >&2
    exit 1
fi

# ============================================================================
# PROCESS OUTPUT
# ============================================================================

echo ""
echo "Processing LD pruning output..."

# PLINK2 creates two files:
# - ${output_prefix}.prune.in  (SNPs to keep - this is what we want)
# - ${output_prefix}.prune.out (SNPs to exclude)

if [ ! -f "${output_prefix}.prune.in" ]; then
    echo "ERROR: LD pruning output not found: ${output_prefix}.prune.in" >&2
    exit 1
fi

# Rename the .prune.in file to our target name
mv "${output_prefix}.prune.in" "${MODEL_SNPS_FILE}"

echo "✓ Model SNPs file created: ${MODEL_SNPS_FILE}"
echo ""

# ============================================================================
# VALIDATION AND QC
# ============================================================================

# Count SNPs
n_snps=$(wc -l < "${MODEL_SNPS_FILE}")

echo "Summary:"
echo "  Number of model SNPs: ${n_snps}"
echo ""

# Check if SNP count is in recommended range
if [ ${n_snps} -lt 300000 ]; then
    echo "⚠️  WARNING: Fewer than 300K model SNPs (found ${n_snps})"
    echo ""
    echo "Recommendations:"
    echo "1. This may be okay for small variant sets (e.g., genotyping arrays)"
    echo "2. For imputed data, consider:"
    echo "   - Relaxing LD threshold: change --indep-pairwise 1000 50 0.5 to 0.8"
    echo "   - Lowering MAF threshold: change --maf 0.005 to 0.001"
    echo "   - Relaxing missingness: change --geno 0.10 to 0.15"
    echo ""
elif [ ${n_snps} -gt 700000 ]; then
    echo "⚠️  WARNING: More than 700K model SNPs (found ${n_snps})"
    echo ""
    echo "Recommendations:"
    echo "1. This is acceptable but may slow down BOLT-LMM"
    echo "2. For faster runtime, consider:"
    echo "   - Stricter LD threshold: change --indep-pairwise 1000 50 0.5 to 0.2"
    echo "   - Higher MAF threshold: change --maf 0.005 to 0.01"
    echo ""
else
    echo "✅ Model SNP count is in the recommended range (300K-700K)"
    echo ""
fi

# Clean up temporary files
if [ -f "${output_prefix}.prune.out" ]; then
    rm "${output_prefix}.prune.out"
fi

if [ -f "${output_prefix}.log" ]; then
    echo "LD pruning log saved to: ${output_prefix}.log"
fi

# ============================================================================
# PREVIEW MODEL SNPS
# ============================================================================

echo "Preview of model SNPs (first 10):"
head -10 ${MODEL_SNPS_FILE}
echo "..."
echo ""

# ============================================================================
# COMPLETION
# ============================================================================

echo "========================================"
echo "✅ MODEL SNPs PREPARATION COMPLETED"
echo "========================================"
echo "End time: $(date)"
echo ""
echo "Next steps:"
echo "1. Run: bash filter_to_population.sh"
echo "2. Test: sbatch 0d_test_run.sbatch.sh"
echo "3. Full analysis: sbatch 1_run_bolt_lmm.sbatch.sh"
echo ""

