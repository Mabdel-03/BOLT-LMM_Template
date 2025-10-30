# Path configuration for BOLT-LMM analysis
# ==========================================
# 
# This file contains all path configurations for your BOLT-LMM analysis.
# CUSTOMIZE all paths before running the pipeline.
#
# See ADAPTATION_GUIDE.md for detailed instructions.

# ============================================================================
# BASE DIRECTORIES
# ============================================================================

# CUSTOMIZE: Base directory for your cohort data (e.g., UK Biobank, other cohort)
# This should point to the root directory containing genotype, phenotype, and covariate files
UKB21942_DIR='/path/to/your/data/directory'
# Example: UKB21942_DIR='/home/user/data/ukbb'
# Example: UKB21942_DIR='/scratch/myproject/genetic_data'

# CUSTOMIZE: Your analysis name (used for output directories and file naming)
# Use a short, descriptive name without spaces (use underscores or hyphens)
ANALYSIS_NAME='MY_GWAS_ANALYSIS'
# Example: ANALYSIS_NAME='T2D_GWAS'
# Example: ANALYSIS_NAME='BMI_European_Ancestry'
# Example: ANALYSIS_NAME='Blood_Pressure_GWAS'

# CUSTOMIZE: Analysis source directory (where these scripts are located)
# This is typically the directory where you copied this template
SRCDIR='/path/to/your/analysis/directory'
# Example: SRCDIR='/home/user/projects/my_gwas_analysis'
# Example: SRCDIR='/scratch/myproject/bolt_lmm_runs/analysis_2025'

# Temporary directory (optional, for intermediate files)
# Some HPC systems have fast local scratch space
TMP_DIR='/tmp'
# Example: TMP_DIR='/scratch/tmp'

# ============================================================================
# GENOTYPE FILES
# ============================================================================

# CUSTOMIZE: Genotype file base path (without extension)
# For PLINK2 format: Specify path without .pgen/.pvar/.psam extensions
# The conversion script (0a_convert_to_bed.sbatch.sh) will create .bed/.bim/.fam files
GENOTYPE_PFILE="${UKB21942_DIR}/geno/YOUR_GENOTYPE_DIR/YOUR_GENOTYPE_BASENAME"
# Example: GENOTYPE_PFILE="${UKB21942_DIR}/geno/ukb_genoHM3/ukb_genoHM3"
# This assumes: ukb_genoHM3.pgen, ukb_genoHM3.pvar.zst, ukb_genoHM3.psam exist
#
# Example: GENOTYPE_PFILE="${UKB21942_DIR}/geno/merged_imputed/chr_all"
# This assumes: chr_all.pgen, chr_all.pvar.zst, chr_all.psam exist

# CUSTOMIZE: Output PLINK1 genotype files (will be created by 0a_convert_to_bed.sbatch.sh)
# This is typically the same path as GENOTYPE_PFILE with "_bed" suffix
GENOTYPE_BFILE="${GENOTYPE_PFILE}_bed"
# Example: GENOTYPE_BFILE="${UKB21942_DIR}/geno/ukb_genoHM3/ukb_genoHM3_bed"
# After conversion: ukb_genoHM3_bed.bed, ukb_genoHM3_bed.bim, ukb_genoHM3_bed.fam

# CUSTOMIZE: Model SNPs file (will be created by 0b_prepare_model_snps.sbatch.sh)
# This is typically the same path as GENOTYPE_PFILE with "_modelSNPs.txt" suffix
MODEL_SNPS_FILE="${GENOTYPE_PFILE}_modelSNPs.txt"
# Example: MODEL_SNPS_FILE="${UKB21942_DIR}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt"

# ============================================================================
# BOLT-LMM SOFTWARE AND REFERENCE FILES
# ============================================================================

# CUSTOMIZE: BOLT-LMM installation directory
# Download from: https://alkesgroup.broadinstitute.org/BOLT-LMM/
BOLT_LMM_DIR="/path/to/BOLT-LMM_v2.X"
# Example: BOLT_LMM_DIR="/home/user/software/BOLT-LMM_v2.4"
# Example: BOLT_LMM_DIR="/opt/software/BOLT-LMM_v2.5"

# BOLT-LMM tables directory (contains LD scores and genetic maps)
BOLT_TABLES_DIR="${BOLT_LMM_DIR}/tables"

# CUSTOMIZE: LD scores file for BOLT-LMM calibration
# This file comes with BOLT-LMM installation (in tables/ directory)
# Choose based on your population ancestry:
# - European ancestry (EUR): LDSCORE.1000G_EUR.GRCh38.tab.gz or LDSCORE.1000G_EUR.tab.gz
# - East Asian ancestry (EAS): LDSCORE.1000G_EAS.tab.gz
# - African ancestry (AFR): LDSCORE.1000G_AFR.tab.gz
# - Admixed American (AMR): LDSCORE.1000G_AMR.tab.gz
LD_SCORES_FILE="${BOLT_TABLES_DIR}/LDSCORE.1000G_EUR.GRCh38.tab.gz"
# Example for GRCh37/hg19: LD_SCORES_FILE="${BOLT_TABLES_DIR}/LDSCORE.1000G_EUR.tab.gz"
# Example for East Asian: LD_SCORES_FILE="${BOLT_TABLES_DIR}/LDSCORE.1000G_EAS.tab.gz"

# CUSTOMIZE: Genetic map file for position interpolation
# This file comes with BOLT-LMM installation (in tables/ directory)
# Must match your genome build:
# - GRCh37/hg19: genetic_map_hg19_withX.txt.gz (most common for UK Biobank and older data)
# - GRCh38: genetic_map_hg38_withX.txt.gz (if available and your data is GRCh38)
GENETIC_MAP_FILE="${BOLT_TABLES_DIR}/genetic_map_hg19_withX.txt.gz"
# Example for GRCh38: GENETIC_MAP_FILE="${BOLT_TABLES_DIR}/genetic_map_hg38_withX.txt.gz"

# ============================================================================
# PHENOTYPE AND COVARIATE FILES
# ============================================================================

# CUSTOMIZE: Phenotype file path
# Format: Tab-delimited text file with header row
# Required columns: FID (family ID), IID (individual ID), then phenotype columns
# Can be gzipped (.gz or .tsv.gz)
# Example file structure:
#   FID    IID    T2D    BMI    Height
#   FAM1   IND1   0      25.3   170.2
#   FAM2   IND2   1      28.1   165.5
PHENO_FILE="${UKB21942_DIR}/pheno/YOUR_PHENOTYPE_FILE.tsv.gz"
# Example: PHENO_FILE="${UKB21942_DIR}/pheno/disease_phenotypes.tsv.gz"
# Example: PHENO_FILE="${UKB21942_DIR}/pheno/quantitative_traits.tsv.gz"
# Example: PHENO_FILE="${UKB21942_DIR}/pheno/all_phenotypes_2025.tsv.gz"

# CUSTOMIZE: Covariate file path
# Format: Tab-delimited text file with header row
# Required columns: FID, IID, then covariate columns
# Common covariates: age, sex, genotyping_array, PC1-PC10, BMI, etc.
# Can be gzipped (.gz or .tsv.gz)
# Example file structure:
#   FID    IID    age    sex    PC1      PC2      genotyping_array
#   FAM1   IND1   45     1      0.002    -0.001   UKBL
#   FAM2   IND2   52     2      0.003    0.000    UKBB
COVAR_FILE="${UKB21942_DIR}/sqc/YOUR_COVARIATE_FILE.tsv.gz"
# Example: COVAR_FILE="${UKB21942_DIR}/sqc/covariates_with_pcs.tsv.gz"
# Example: COVAR_FILE="${UKB21942_DIR}/sqc/sqc_20220316.tsv.gz"

# ============================================================================
# POPULATION DEFINITION
# ============================================================================

# CUSTOMIZE: Population keep file (defines analysis sample)
# Format: Space-delimited text file with two columns, no header
# Columns: FID IID (one individual per row)
# This file specifies which individuals to include in the analysis
# Common uses: ancestry filtering (e.g., EUR only), QC-passed samples
# Example file structure:
#   FAM1 IND1
#   FAM2 IND2
#   FAM3 IND3
KEEP_FILE="${UKB21942_DIR}/sqc/population/YOUR_POPULATION.keep"
# Example: KEEP_FILE="${UKB21942_DIR}/sqc/population/EUR.keep" (European ancestry)
# Example: KEEP_FILE="${UKB21942_DIR}/sqc/population/EAS.keep" (East Asian ancestry)
# Example: KEEP_FILE="${UKB21942_DIR}/sqc/population/QC_pass.keep" (all QC-passed)

# CUSTOMIZE: Population name (used for output directory naming)
# This should be a short identifier matching your KEEP_FILE
POPULATION="YOUR_POP"
# Example: POPULATION="EUR" (if using EUR.keep)
# Example: POPULATION="EAS" (if using EAS.keep)
# Example: POPULATION="ALL" (if using all samples)
# Example: POPULATION="QC_pass" (if using QC-filtered samples)

# ============================================================================
# OUTPUT CONFIGURATION
# ============================================================================

# Output directory structure (usually don't need to change)
# Results will be organized as: ${RESULTS_DIR}/<COVAR_SET>/<POPULATION>/
RESULTS_DIR="${SRCDIR}/results"

# Population-filtered files (created by filter_to_population.sh)
# These are phenotype and covariate files filtered to your analysis population
PHENO_FILE_FILTERED="${SRCDIR}/$(basename ${PHENO_FILE%.tsv.gz}).${POPULATION}.tsv.gz"
COVAR_FILE_FILTERED="${SRCDIR}/$(basename ${COVAR_FILE%.tsv.gz}).${POPULATION}.tsv.gz"

# ============================================================================
# COMPUTATIONAL RESOURCES (optional customization)
# ============================================================================

# CUSTOMIZE: Default number of threads for BOLT-LMM
# Recommended: 16-32 for best balance of speed and resource usage
# Higher values (up to 100) can be faster but with diminishing returns
DEFAULT_THREADS=32
# Example: DEFAULT_THREADS=16 (conservative, works on most systems)
# Example: DEFAULT_THREADS=100 (maximum performance if resources available)

# CUSTOMIZE: Default memory allocation (in MB)
# Rule of thumb: ~0.1-0.3 GB per 1,000 samples
# 100K samples: 50,000 MB (50GB)
# 500K samples: 150,000 MB (150GB)
DEFAULT_MEMORY=50000
# Example: DEFAULT_MEMORY=32000 (32GB, for smaller cohorts)
# Example: DEFAULT_MEMORY=150000 (150GB, for large biobank-scale cohorts)

# ============================================================================
# VALIDATION
# ============================================================================

# Check that key directories exist (run this after setting paths)
# Uncomment the following lines to validate your configuration:

# if [ ! -d "${UKB21942_DIR}" ]; then
#     echo "ERROR: UKB21942_DIR does not exist: ${UKB21942_DIR}" >&2
#     exit 1
# fi

# if [ ! -d "${BOLT_LMM_DIR}" ]; then
#     echo "ERROR: BOLT_LMM_DIR does not exist: ${BOLT_LMM_DIR}" >&2
#     exit 1
# fi

# if [ ! -f "${PHENO_FILE}" ]; then
#     echo "ERROR: PHENO_FILE does not exist: ${PHENO_FILE}" >&2
#     exit 1
# fi

# if [ ! -f "${COVAR_FILE}" ]; then
#     echo "ERROR: COVAR_FILE does not exist: ${COVAR_FILE}" >&2
#     exit 1
# fi

# if [ ! -f "${KEEP_FILE}" ]; then
#     echo "ERROR: KEEP_FILE does not exist: ${KEEP_FILE}" >&2
#     exit 1
# fi

# ============================================================================
# END OF CONFIGURATION
# ============================================================================

# Export all variables for use in subscripts
export UKB21942_DIR ANALYSIS_NAME SRCDIR TMP_DIR
export GENOTYPE_PFILE GENOTYPE_BFILE MODEL_SNPS_FILE
export BOLT_LMM_DIR BOLT_TABLES_DIR LD_SCORES_FILE GENETIC_MAP_FILE
export PHENO_FILE COVAR_FILE KEEP_FILE POPULATION
export RESULTS_DIR PHENO_FILE_FILTERED COVAR_FILE_FILTERED
export DEFAULT_THREADS DEFAULT_MEMORY

echo "Paths configuration loaded for analysis: ${ANALYSIS_NAME}"
echo "Population: ${POPULATION}"
echo "Source directory: ${SRCDIR}"

