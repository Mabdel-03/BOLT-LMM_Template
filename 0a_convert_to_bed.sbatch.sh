#!/bin/bash
#SBATCH --job-name=convert_to_bed
#SBATCH --partition=YOUR_PARTITION  # CUSTOMIZE: Your HPC partition name
#SBATCH --mem=32G
#SBATCH -n 8
#SBATCH --time=2:00:00
#SBATCH --output=0a.out
#SBATCH --error=0a.err
#SBATCH --mail-user=YOUR_EMAIL@institution.edu  # CUSTOMIZE: Your email address
#SBATCH --mail-type=BEGIN,END,FAIL

set -beEo pipefail

# ============================================================================
# SLURM Job Script: Convert PLINK2 to PLINK1 Format for BOLT-LMM
# ============================================================================
#
# Purpose: Convert PLINK2 .pgen/.pvar/.psam files to PLINK1 .bed/.bim/.fam format
#          required by BOLT-LMM
#
# Input:  PLINK2 genotype files (.pgen, .pvar.zst, .psam)
# Output: PLINK1 genotype files (.bed, .bim, .fam)
#
# Note: This script only includes AUTOSOMES (chr 1-22) because BOLT-LMM
#       does not recognize sex chromosome codes (X, Y, MT)
#
# Customization: See paths.sh for all path configurations
#
# ============================================================================

echo "========================================"
echo "Job: Convert Genotypes to BED Format"
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

echo ""
echo "Configuration:"
echo "  Input genotype file: ${GENOTYPE_PFILE}"
echo "  Output BED file: ${GENOTYPE_BFILE}"
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

if [ ! -f "${GENOTYPE_PFILE}.psam" ]; then
    echo "ERROR: Input psam file not found: ${GENOTYPE_PFILE}.psam" >&2
    exit 1
fi

# Check for .pvar file (may be compressed)
pvar_found=false
for ext in pvar pvar.zst pvar.gz; do
    if [ -f "${GENOTYPE_PFILE}.${ext}" ]; then
        pvar_found=true
        echo "  Found: ${GENOTYPE_PFILE}.${ext}"
        break
    fi
done

if [ "$pvar_found" = false ]; then
    echo "ERROR: Input pvar file not found (tried .pvar, .pvar.zst, .pvar.gz)" >&2
    exit 1
fi

echo "✓ All input files verified"
echo ""

# ============================================================================
# CLEAN UP OLD OUTPUT FILES
# ============================================================================

echo "Checking for existing output files..."
for ext in bed bim fam log; do
    if [ -f "${GENOTYPE_BFILE}.${ext}" ]; then
        echo "  Removing old file: ${GENOTYPE_BFILE}.${ext}"
        rm -f "${GENOTYPE_BFILE}.${ext}"
    fi
done
echo "✓ Ready for clean conversion"
echo ""

# ============================================================================
# CONVERSION
# ============================================================================

echo "Running PLINK2 conversion..."
echo "Converting AUTOSOMES ONLY (chr 1-22) for BOLT-LMM compatibility"
echo ""
echo "This may take 5-15 minutes depending on the dataset size..."
echo ""

# Determine pvar compression flag
if [ -f "${GENOTYPE_PFILE}.pvar.zst" ]; then
    compression_flag="vzs"
elif [ -f "${GENOTYPE_PFILE}.pvar.gz" ]; then
    compression_flag="vzs"
else
    compression_flag=""
fi

# Run PLINK2 conversion
plink2 \
    --pfile ${GENOTYPE_PFILE} ${compression_flag} \
    --chr 1-22 \
    --make-bed \
    --out ${GENOTYPE_BFILE} \
    --threads ${SLURM_NTASKS} \
    --memory $(( SLURM_MEM_PER_NODE * 95 / 100 ))

conversion_exit=$?

if [ ${conversion_exit} -ne 0 ]; then
    echo ""
    echo "ERROR: PLINK2 conversion failed with exit code ${conversion_exit}" >&2
    exit 1
fi

# ============================================================================
# VERIFY OUTPUT
# ============================================================================

echo ""
echo "Verifying output files..."

if [ ! -f "${GENOTYPE_BFILE}.bed" ] || [ ! -f "${GENOTYPE_BFILE}.bim" ] || [ ! -f "${GENOTYPE_BFILE}.fam" ]; then
    echo "ERROR: Conversion failed - output files not created" >&2
    exit 1
fi

echo "✓ All output files created"
echo ""
echo "Output files:"
ls -lh ${GENOTYPE_BFILE}.bed
ls -lh ${GENOTYPE_BFILE}.bim
ls -lh ${GENOTYPE_BFILE}.fam
echo ""

# Count variants and samples
n_variants=$(wc -l < ${GENOTYPE_BFILE}.bim)
n_samples=$(wc -l < ${GENOTYPE_BFILE}.fam)

echo "Summary:"
echo "  Number of autosomal variants: ${n_variants}"
echo "  Number of samples: ${n_samples}"

# ============================================================================
# COMPLETION
# ============================================================================

echo ""
echo "========================================"
echo "✅ CONVERSION COMPLETED SUCCESSFULLY"
echo "========================================"
echo "End time: $(date)"
echo ""
echo "Next steps:"
echo "1. Run: sbatch 0b_prepare_model_snps.sbatch.sh"
echo "2. Then: bash filter_to_population.sh"
echo "3. Test: sbatch 0d_test_run.sbatch.sh"
echo ""

