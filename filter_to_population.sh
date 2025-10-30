#!/bin/bash
set -beEo pipefail

# ============================================================================
# Filter Phenotype and Covariate Files to Analysis Population
# ============================================================================
#
# Purpose: Create population-specific phenotype and covariate files by filtering
#          to individuals in the KEEP_FILE (e.g., EUR ancestry, QC-passed samples)
#
# Why: BOLT-LMM's --remove option can be slow and error-prone. Pre-filtering
#      phenotype and covariate files is faster and more reliable.
#
# Input:  - Original phenotype file (all samples)
#         - Original covariate file (all samples)
#         - Population keep file (FID IID list)
# Output: - Filtered phenotype file (population only)
#         - Filtered covariate file (population only)
#
# Customization: See paths.sh for all path configurations
#
# ============================================================================

echo "========================================"
echo "Filter Phenotype & Covariate Files"
echo "========================================"
echo ""

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
# DISPLAY CONFIGURATION
# ============================================================================

echo "Configuration:"
echo "  Analysis: ${ANALYSIS_NAME}"
echo "  Population: ${POPULATION}"
echo ""
echo "Input files:"
echo "  Keep file: ${KEEP_FILE}"
echo "  Phenotypes: ${PHENO_FILE}"
echo "  Covariates: ${COVAR_FILE}"
echo ""
echo "Output files:"
echo "  Filtered phenotypes: ${PHENO_FILE_FILTERED}"
echo "  Filtered covariates: ${COVAR_FILE_FILTERED}"
echo ""

# ============================================================================
# VALIDATION
# ============================================================================

# Check if keep file exists
if [ ! -f "${KEEP_FILE}" ]; then
    echo "ERROR: Keep file not found: ${KEEP_FILE}" >&2
    echo ""
    echo "Please verify:"
    echo "1. KEEP_FILE is set correctly in paths.sh"
    echo "2. The keep file exists at the specified path"
    echo "3. Keep file format: space-delimited, two columns (FID IID), no header" >&2
    exit 1
fi

# Check if phenotype file exists
if [ ! -f "${PHENO_FILE}" ]; then
    echo "ERROR: Phenotype file not found: ${PHENO_FILE}" >&2
    echo ""
    echo "Please verify:"
    echo "1. PHENO_FILE is set correctly in paths.sh"
    echo "2. The phenotype file exists at the specified path" >&2
    exit 1
fi

# Check if covariate file exists
if [ ! -f "${COVAR_FILE}" ]; then
    echo "ERROR: Covariate file not found: ${COVAR_FILE}" >&2
    echo ""
    echo "Please verify:"
    echo "1. COVAR_FILE is set correctly in paths.sh"
    echo "2. The covariate file exists at the specified path" >&2
    exit 1
fi

echo "✓ All input files verified"
echo ""

# ============================================================================
# COUNT SAMPLES
# ============================================================================

# Count samples in keep file
n_keep=$(wc -l < "${KEEP_FILE}")
echo "Population samples: ${n_keep}"
echo ""

# ============================================================================
# FILTER PHENOTYPE FILE
# ============================================================================

echo "Filtering phenotype file..."
echo "This may take 1-2 minutes for large files..."
echo ""

# Create temporary ID lookup file (just IIDs from keep file)
temp_iids=$(mktemp)
awk '{print $2}' "${KEEP_FILE}" > ${temp_iids}

# Determine if phenotype file is gzipped
if [[ "${PHENO_FILE}" == *.gz ]]; then
    cat_cmd="zcat"
else
    cat_cmd="cat"
fi

# Filter phenotype file
{
    # Extract and write header
    ${cat_cmd} "${PHENO_FILE}" | head -1
    
    # Extract data rows and filter using grep
    # -F: fixed strings (not regex)
    # -f: patterns from file
    # -w: whole word match (IID must be complete match)
    ${cat_cmd} "${PHENO_FILE}" | tail -n +2 | grep -F -f ${temp_iids}
    
} | gzip > "${PHENO_FILE_FILTERED}"

# Count output samples
n_pheno_out=$(zcat "${PHENO_FILE_FILTERED}" | tail -n +2 | wc -l)

echo "✓ Filtered phenotype file created"
echo "  Input samples: $(${cat_cmd} "${PHENO_FILE}" | tail -n +2 | wc -l)"
echo "  Output samples: ${n_pheno_out}"
echo ""

# ============================================================================
# FILTER COVARIATE FILE
# ============================================================================

echo "Filtering covariate file..."
echo "This may take 1-2 minutes for large files..."
echo ""

# Determine if covariate file is gzipped
if [[ "${COVAR_FILE}" == *.gz ]]; then
    cat_cmd_cov="zcat"
else
    cat_cmd_cov="cat"
fi

# Filter covariate file
{
    # Header
    ${cat_cmd_cov} "${COVAR_FILE}" | head -1
    
    # Data rows filtered to population
    ${cat_cmd_cov} "${COVAR_FILE}" | tail -n +2 | grep -F -f ${temp_iids}
    
} | gzip > "${COVAR_FILE_FILTERED}"

# Count output samples
n_covar_out=$(zcat "${COVAR_FILE_FILTERED}" | tail -n +2 | wc -l)

echo "✓ Filtered covariate file created"
echo "  Input samples: $(${cat_cmd_cov} "${COVAR_FILE}" | tail -n +2 | wc -l)"
echo "  Output samples: ${n_covar_out}"
echo ""

# Clean up temporary file
rm -f ${temp_iids}

# ============================================================================
# SUMMARY AND VALIDATION
# ============================================================================

echo ""
echo "========================================"
echo "✅ FILTERING COMPLETED"
echo "========================================"
echo ""
echo "Summary:"
echo "  Population samples requested: ${n_keep}"
echo "  Phenotype file output: ${n_pheno_out}"
echo "  Covariate file output: ${n_covar_out}"
echo ""

# Check for sample count mismatches
if [ ${n_pheno_out} -ne ${n_keep} ]; then
    echo "⚠️  NOTE: Phenotype sample count doesn't match keep file count"
    echo "   This is EXPECTED if some individuals have missing phenotype data"
    echo "   BOLT-LMM will analyze only individuals with non-missing phenotypes"
    echo ""
fi

if [ ${n_covar_out} -ne ${n_keep} ]; then
    echo "⚠️  NOTE: Covariate sample count doesn't match keep file count"
    echo "   This is EXPECTED if some individuals have missing covariate data"
    echo "   BOLT-LMM will exclude individuals with missing covariates"
    echo ""
fi

# Check for zero samples
if [ ${n_pheno_out} -eq 0 ]; then
    echo "❌ ERROR: No samples in filtered phenotype file!" >&2
    echo "   Possible issues:"
    echo "   - IID column name mismatch between keep file and phenotype file"
    echo "   - No sample overlap between keep file and phenotype file"
    echo "   - Different ID formatting (e.g., with/without prefixes)"
    exit 1
fi

if [ ${n_covar_out} -eq 0 ]; then
    echo "❌ ERROR: No samples in filtered covariate file!" >&2
    echo "   Possible issues:"
    echo "   - IID column name mismatch between keep file and covariate file"
    echo "   - No sample overlap between keep file and covariate file"
    echo "   - Different ID formatting (e.g., with/without prefixes)"
    exit 1
fi

# ============================================================================
# PREVIEW OUTPUT
# ============================================================================

echo "Preview of filtered phenotype file (first 5 rows):"
zcat "${PHENO_FILE_FILTERED}" | head -6
echo ""

echo "Preview of filtered covariate file (first 5 rows):"
zcat "${COVAR_FILE_FILTERED}" | head -6
echo ""

# ============================================================================
# NEXT STEPS
# ============================================================================

echo "========================================"
echo "Next Steps"
echo "========================================"
echo ""
echo "1. Test the pipeline:"
echo "   sbatch 0d_test_run.sbatch.sh"
echo ""
echo "2. If test succeeds, run full analysis:"
echo "   sbatch 1_run_bolt_lmm.sbatch.sh"
echo ""
echo "Note: The filtered files will be automatically used by"
echo "      run_single_phenotype.sh (no additional configuration needed)"
echo ""

