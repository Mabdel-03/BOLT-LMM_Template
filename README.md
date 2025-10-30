# BOLT-LMM Analysis Pipeline Template

**A generalizable template for running BOLT-LMM genome-wide association studies (GWAS) with customizable phenotypes and covariates.**

---

## Overview

This is a template pipeline for performing BOLT-LMM association analyses based on best practices from Day et al. (2018) and other large-scale biobank studies. It provides a complete workflow from genotype preparation through GWAS analysis with mixed linear models.

### Key Features

- ✅ **Modular design**: Easily adaptable for different phenotypes and covariates
- ✅ **HPC-optimized**: SLURM batch submission with configurable resources
- ✅ **Binary and quantitative traits**: Automatic detection and appropriate modeling
- ✅ **Population stratification control**: Via genetic relationship matrix (GRM)
- ✅ **Validated workflow**: Based on published methodologies
- ✅ **Comprehensive documentation**: Step-by-step adaptation guide

---

## Pipeline Workflow

The pipeline consists of 4 main phases:

```
┌─────────────────────────────────────────────────────────────┐
│                    PREPROCESSING PHASE                       │
│  (One-time setup, ~1-2 hours)                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 0a: Genotype Format Conversion      │
    │  Script: 0a_convert_to_bed.sbatch.sh     │
    │  Input:  PLINK2 .pgen/pvar/psam files    │
    │  Output: PLINK1 .bed/bim/fam files       │
    │  Time:   ~5-10 minutes                    │
    └───────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 0b: Model SNP Selection             │
    │  Script: 0b_prepare_model_snps.sbatch.sh │
    │  Process: LD pruning (r² < 0.5)          │
    │  Output: ~400-600K SNPs for GRM          │
    │  Time:   ~15-30 minutes                   │
    └───────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 0c: Population Filtering            │
    │  Script: filter_to_population.sh          │
    │  Process: Filter pheno/covar files        │
    │  Output: Population-specific files        │
    │  Time:   ~1-2 minutes                     │
    └───────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    VALIDATION PHASE                          │
│  (Critical checkpoint before full analysis)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 0d: Test Run                        │
    │  Script: 0d_test_run.sbatch.sh           │
    │  Process: Run BOLT-LMM on full genome     │
    │  Validates: One phenotype-covariate combo │
    │  Time:   ~1-2 hours                       │
    └───────────────────────────────────────────┘
                            ↓
                    ⚠️  TEST MUST PASS  ⚠️
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    ANALYSIS PHASE                            │
│  (Main computational workload)                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 1: Full BOLT-LMM Analysis           │
    │  Script: 1_run_bolt_lmm.sbatch.sh        │
    │  Jobs:   N_phenotypes × N_covar_sets     │
    │  Time:   1-2 hours per job               │
    └───────────────────────────────────────────┘
```

---

## Quick Start

### 1. Copy and Customize Template

```bash
# Copy template to your analysis directory
cp -r BOLT-LMM_Template/ my_gwas_analysis/
cd my_gwas_analysis/

# Follow the ADAPTATION_GUIDE.md to customize for your analysis
```

### 2. Set Up Configuration

Edit `paths.sh` to specify your data paths and BOLT-LMM installation.

### 3. Customize Phenotypes and Covariates

Edit the following scripts to define your phenotypes and covariate models:
- `run_single_phenotype.sh` (lines marked with `# CUSTOMIZE:`)
- `1_run_bolt_lmm.sbatch.sh` (phenotype and covariate arrays)

### 4. Run Pipeline

```bash
# On your HPC cluster:

# Step 1: Convert genotypes (one-time)
sbatch 0a_convert_to_bed.sbatch.sh

# Step 2: Prepare model SNPs (one-time)
sbatch 0b_prepare_model_snps.sbatch.sh

# Step 3: Filter to your population (one-time)
bash filter_to_population.sh

# Step 4: Test with one phenotype
sbatch 0d_test_run.sbatch.sh

# Step 5: If test passes, run full analysis
sbatch 1_run_bolt_lmm.sbatch.sh
```

---

## File Structure

```
BOLT-LMM_Template/
├── README.md                           ← This file
├── ADAPTATION_GUIDE.md                 ← Detailed customization instructions ⭐⭐⭐
├── QUICK_START.md                      ← Fast reference guide
├── BOLT_LMM_PRIMER.md                  ← Understanding BOLT-LMM methodology
├── TROUBLESHOOTING.md                  ← Common issues and solutions
│
├── paths.sh                            ← Configuration file (CUSTOMIZE!)
│
├── 0a_convert_to_bed.sbatch.sh        ← Genotype conversion
├── 0b_prepare_model_snps.sbatch.sh    ← Model SNP preparation
├── 0c_filter_to_population.sh         ← Population filtering
├── 0d_test_run.sbatch.sh              ← Validation test
│
├── run_single_phenotype.sh             ← Core BOLT-LMM execution script (CUSTOMIZE!)
├── 1_run_bolt_lmm.sbatch.sh           ← Array job submission (CUSTOMIZE!)
│
├── environment.yml                     ← Conda environment specification
└── examples/
    ├── config_binary_traits.sh         ← Example for binary phenotypes
    └── config_quantitative_traits.sh   ← Example for quantitative phenotypes
```

---

## What You Need to Customize

### 🔴 Required Changes

**Before running any analysis, you MUST customize:**

1. **`paths.sh`** - All file paths and software locations
2. **`run_single_phenotype.sh`** - Phenotype names, covariate columns, directory paths
3. **`1_run_bolt_lmm.sbatch.sh`** - Phenotype array, covariate sets, job array size
4. **`0d_test_run.sbatch.sh`** - Test phenotype and covariate set
5. **All SLURM headers** - Email address, partition, resource requirements

### 📝 Placeholder Format

All customization points are marked with:
```bash
# CUSTOMIZE: Description of what to change
PLACEHOLDER_VARIABLE="CHANGE_THIS"
```

**See `ADAPTATION_GUIDE.md` for complete list of placeholders and instructions.**

---

## Software Requirements

### Core Software

- **BOLT-LMM v2.4+**: Mixed model association testing
  - Download: https://alkesgroup.broadinstitute.org/BOLT-LMM/
  - Tables: LD scores and genetic map files (included with BOLT-LMM)
  
- **PLINK2 v2.0+**: Genotype format conversion and QC
  - Download: https://www.cog-genomics.org/plink/2.0/

- **Python 3.8+**: Data filtering and processing
  - Required packages: pandas, numpy

### HPC Requirements

- SLURM job scheduler
- Typical resources per job:
  - Memory: 50-150GB (depends on sample size)
  - CPUs: 8-100 threads
  - Walltime: 1-6 hours per job

---

## Input Data Requirements

### Genotype Files

**Format**: PLINK2 `.pgen/.pvar/.psam` or PLINK1 `.bed/.bim/.fam`

**Requirements**:
- Build: GRCh37/hg19 or GRCh38 (must match genetic map)
- Variants: Autosomes only (chr 1-22)
- Quality control: Pre-QC'd genotypes recommended
- Sample size: Works with 1K to 500K+ individuals

### Phenotype File

**Format**: Tab-delimited text file (gzipped recommended)

**Structure**:
```
FID    IID    PHENO1    PHENO2    PHENO3
FAM1   IND1   0.5       1         NA
FAM2   IND2   -0.3      0         1.2
```

**Requirements**:
- Header row with column names
- FID and IID columns (family ID and individual ID)
- One column per phenotype
- Missing values: `NA`, `-9`, or empty
- Binary traits: Code as 0/1 or 1/2 (BOLT-LMM auto-detects)
- Quantitative traits: Recommend standardization (mean=0, SD=1)

### Covariate File

**Format**: Tab-delimited text file (gzipped recommended)

**Structure**:
```
FID    IID    age    sex    PC1      PC2      array
FAM1   IND1   45     1      0.02     -0.01    UKBL
FAM2   IND2   52     2      0.03     0.00     UKBB
```

**Requirements**:
- Header row with column names
- FID and IID columns
- Quantitative covariates: Age, PCs, etc.
- Categorical covariates: Sex, genotyping array, batch, etc.
- Missing values: `NA` or empty

### Population Keep File

**Format**: Space-delimited text file (no header)

**Structure**:
```
FAM1 IND1
FAM2 IND2
FAM3 IND3
```

**Requirements**:
- Two columns: FID IID
- One individual per row
- Defines analysis population (e.g., EUR ancestry)

---

## Output Files

### Primary Output: Summary Statistics

**File**: `results/<COVAR_SET>/<POPULATION>/bolt_<PHENOTYPE>.<COVAR_SET>.stats.gz`

**Format**: Tab-delimited, gzipped

**Key Columns**:
| Column | Description |
|--------|-------------|
| `SNP` | Variant identifier |
| `CHR` | Chromosome |
| `BP` | Base pair position |
| `ALLELE1` | Effect allele (tested) |
| `ALLELE0` | Reference allele |
| `A1FREQ` | Effect allele frequency |
| `BETA` | Effect size (liability scale for binary traits) |
| `SE` | Standard error |
| `P_BOLT_LMM` | P-value from non-infinitesimal model (USE THIS!) |

**Typical size**: 1-5GB per phenotype (~1-12M variants)

### Secondary Output: Log Files

**File**: `results/<COVAR_SET>/<POPULATION>/bolt_<PHENOTYPE>.<COVAR_SET>.log.gz`

**Contains**:
- BOLT-LMM configuration
- Sample sizes and filtering
- Heritability estimates
- Convergence information
- Warnings and errors

---

## Understanding BOLT-LMM Results

### Binary Traits

BOLT-LMM uses a **liability threshold model** for binary (case-control) traits:

- **Effect size (BETA)**: On the liability scale (continuous latent variable)
- **Interpretation**: Each copy of effect allele changes liability by BETA standard deviations
- **Conversion to odds ratio**: OR ≈ exp(BETA) for small effects
- **Example**: BETA=0.05 → OR ≈ 1.051 (5.1% increased odds per allele)

### Quantitative Traits

For continuous traits:

- **Effect size (BETA)**: In phenotype units (or SD if standardized)
- **Interpretation**: Each copy of effect allele changes phenotype by BETA units
- **Example**: BETA=0.5 SD → Half standard deviation increase per allele

### P-value Interpretation

- Use **`P_BOLT_LMM`** column (non-infinitesimal model)
- Genome-wide significance: p < 5×10⁻⁸
- Suggestive significance: p < 1×10⁻⁵

**Read `BOLT_LMM_PRIMER.md` for detailed methodology explanation.**

---

## Adaptation Examples

### Example 1: Binary Phenotype (Case-Control)

**Scenario**: GWAS of Type 2 Diabetes with age, sex, PCs, array as covariates

**Customization**:
```bash
# In run_single_phenotype.sh:
phenotype=$1  # "T2D" (coded 0=control, 1=case)
covar_str=$2  # "AgeSex10PCs"

# Covariate configuration:
if [ "${covar_str}" == "AgeSeх10PCs" ]; then
    qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 --qCovarCol=PC2 ... --qCovarCol=PC10"
    covar_col_args="--covarCol=sex --covarCol=array"
fi

# In 1_run_bolt_lmm.sbatch.sh:
phenotypes=(T2D)
covar_sets=(AgeSex10PCs)
# Total jobs: 1 × 1 = 1 job
```

### Example 2: Quantitative Phenotype

**Scenario**: GWAS of BMI with age, sex, assessment center as covariates

**Customization**:
```bash
# In run_single_phenotype.sh:
phenotype=$1  # "BMI" (standardized to mean=0, SD=1)
covar_str=$2  # "AgeSexCenter"

# Covariate configuration:
if [ "${covar_str}" == "AgeSexCenter" ]; then
    qcovar_col_args="--qCovarCol=age"
    covar_col_args="--covarCol=sex --covarCol=assessment_center"
fi

# In 1_run_bolt_lmm.sbatch.sh:
phenotypes=(BMI)
covar_sets=(AgeSexCenter)
```

### Example 3: Multiple Phenotypes, Multiple Models

**Scenario**: GWAS of 3 blood pressure traits with 2 covariate sets each

**Customization**:
```bash
# In 1_run_bolt_lmm.sbatch.sh:
phenotypes=(SBP DBP PP)  # Systolic, Diastolic, Pulse Pressure
covar_sets=(Basic Extended)  # Basic=age+sex+array, Extended=Basic+BMI+10PCs

# Total jobs: 3 × 2 = 6 jobs
# SLURM array: --array=1-6
```

**See `ADAPTATION_GUIDE.md` for complete customization instructions and more examples.**

---

## Quality Control Recommendations

### Pre-Analysis QC

**Genotype QC** (should be done before using this pipeline):
- Sample call rate > 95%
- Variant call rate > 95%
- MAF > 0.001 (for full imputed data) or > 0.005 (for array data)
- HWE p > 1×10⁻⁶
- Heterozygosity outliers removed
- Sex check concordance
- Related individuals: **Keep them!** (BOLT-LMM models relatedness)

**Phenotype QC**:
- Check distributions (histograms, QQ plots)
- Identify and handle outliers
- For quantitative traits: Consider inverse-normal transformation
- For binary traits: Check case/control balance (≥100 cases recommended)

### Post-GWAS QC

**From BOLT-LMM log files**:
- λ_GC (genomic inflation): Expect 1.00-1.05
- Heritability estimate: Should be > 0 and reasonable
- Sample size: Verify matches expectation
- Convergence: Check for warnings

**From summary statistics**:
- QQ plots: Calibration of p-values
- Manhattan plots: Distribution of associations
- λ_GC calculation: Median χ² / 0.456

**Red flags**:
- λ_GC > 1.10: Possible population stratification or batch effects
- h² = 0 or h² > 1: Model convergence issues
- Very few variants: File truncation or processing error

---

## Computational Resources

### Typical Resource Usage

**Per-job requirements** (for ~400K samples, ~1M variants):

| Step | Memory | CPUs | Walltime |
|------|--------|------|----------|
| 0a: Genotype conversion | 32GB | 8 | 30 min |
| 0b: Model SNPs | 64GB | 8 | 1 hour |
| 0c: Population filter | 4GB | 1 | 5 min |
| 0d: Test run | 50GB | 16 | 2 hours |
| 1: Full analysis (per job) | 50-150GB | 16-100 | 1-3 hours |

**Scaling factors**:
- Memory: ~0.1-0.3 GB per 1K samples
- Walltime: ~1-2 hours per 100K samples per phenotype
- Multithreading: Scales well up to ~32 cores, diminishing returns beyond

**Total pipeline time**:
- Preprocessing: 1-2 hours (one-time)
- Test run: 1-2 hours
- Full analysis: N_phenotypes × N_covar_sets × 1-2 hours
  - Example: 3 phenotypes × 2 covariate sets = 6-12 hours
  - With concurrent jobs: ~2 hours wall-clock time

---

## Downstream Analyses

After completing GWAS, recommended next steps:

### 1. Heritability Estimation

**Tool**: LD Score Regression (LDSC)

```bash
ldsc.py \
    --h2 my_phenotype.bolt.stats.gz \
    --ref-ld-chr eur_w_ld_chr/ \
    --w-ld-chr eur_w_ld_chr/ \
    --out my_phenotype.h2
```

### 2. Genetic Correlations

**Tool**: LD Score Regression (LDSC)

```bash
ldsc.py \
    --rg pheno1.bolt.stats.gz,pheno2.bolt.stats.gz \
    --ref-ld-chr eur_w_ld_chr/ \
    --w-ld-chr eur_w_ld_chr/ \
    --out pheno1_pheno2.rg
```

### 3. Fine-Mapping

**Tools**: FINEMAP, SuSiE, PAINTOR

**Purpose**: Identify likely causal variants within associated loci

### 4. Functional Annotation

**Tools**: FUMA GWAS, MAGMA, PoPS

**Purpose**:
- Gene-based association testing
- Pathway enrichment analysis
- Tissue-specific expression patterns

### 5. Polygenic Risk Scores

**Tools**: PRSice-2, LDpred2, PRS-CS

**Purpose**: Construct genetic risk scores for prediction

### 6. Visualization

**Tools**: LocusZoom, qqman (R), matplotlib (Python)

**Key plots**:
- Manhattan plot: Genome-wide associations
- QQ plot: Test calibration
- Regional association plots: Fine-mapping
- Miami plot: Compare two GWAS

---

## Troubleshooting

### Common Issues

**Issue: Out of Memory Error**
```
Solution: Increase --mem in SLURM header
- For 100K samples: 32GB usually sufficient
- For 500K samples: 50-150GB may be needed
```

**Issue: BOLT-LMM Convergence Failure**
```
Check:
1. Phenotype distribution (histograms, check for outliers)
2. Covariate correlations (detect collinearity)
3. Model SNPs file exists and has 300K-700K SNPs
4. Sample overlap between phenotype, covariate, and genotype files
5. Binary trait coding (should be 0/1 or 1/2)
```

**Issue: High λ_GC (>1.10)**
```
Possible causes:
1. Insufficient population stratification control
2. Batch effects in phenotype or genotypes
3. Phenotype measurement issues
4. Case/control imbalance (for binary traits)

Solutions:
1. Include more PCs in covariate model
2. Check population filtering stringency
3. Review phenotype harmonization across batches
4. Check BOLT-LMM log for warnings
```

**Issue: No Genome-Wide Significant Hits**
```
Considerations:
1. Is phenotype heritable? Check h² estimate
2. Is sample size sufficient? Power calculations
3. Are you using HM3 variants only? (May miss imputed signals)
4. Check λ_GC - is test well-calibrated?
5. Check QQ plot - any enrichment at tail?
```

**See `TROUBLESHOOTING.md` for more issues and solutions.**

---

## Best Practices

### DO:

✅ Test on one phenotype before running full analysis  
✅ Check BOLT-LMM log files for warnings and heritability estimates  
✅ Validate sample sizes match expectations  
✅ Keep related individuals in analysis (BOLT-LMM models relatedness)  
✅ Use genome-wide significance threshold: p < 5×10⁻⁸  
✅ Report genomic inflation factor (λ_GC) in publications  
✅ Make QQ plots and Manhattan plots  
✅ For binary traits, interpret BETA on liability scale  

### DON'T:

❌ Skip the test run (Step 0d)  
❌ Remove related individuals (BOLT-LMM handles relatedness)  
❌ Use only a few PCs if population is heterogeneous  
❌ Forget to check case/control counts for binary traits  
❌ Interpret liability-scale BETA as observed-scale effect  
❌ Run multiple testing correction within loci (use conditional analysis instead)  
❌ Trust results with λ_GC > 1.10 without investigation  

---

## Citation

If you use this template, please cite:

### This Template
```
[Your Name]. (2025). BOLT-LMM Analysis Pipeline Template. 
GitHub: [Your Repository URL]
```

### BOLT-LMM Software
```
Loh, P.-R., et al. (2015). Efficient Bayesian mixed-model analysis increases 
association power in large cohorts. Nature Genetics, 47(3), 284-290.

Loh, P.-R., et al. (2018). Mixed-model association for biobank-scale datasets. 
Nature Genetics, 50(7), 906-908.
```

### Methodological Framework (if applicable)
```
Day, F. R., et al. (2018). Elucidating the genetic basis of social interaction 
and isolation. Nature Communications, 9(1), 2457.
```

---

## Additional Resources

### Documentation Files

- **`ADAPTATION_GUIDE.md`**: Complete customization instructions ⭐⭐⭐
- **`QUICK_START.md`**: Fast command reference
- **`BOLT_LMM_PRIMER.md`**: Understanding mixed models and BOLT-LMM
- **`TROUBLESHOOTING.md`**: Common issues and solutions

### External Resources

- **BOLT-LMM Manual**: https://alkesgroup.broadinstitute.org/BOLT-LMM/BOLT-LMM_manual.html
- **PLINK2 Documentation**: https://www.cog-genomics.org/plink/2.0/
- **UK Biobank**: https://biobank.ndph.ox.ac.uk/ (if using UKB data)
- **LD Score Regression**: https://github.com/bulik/ldsc

### Community Support

- **BOLT-LMM Google Group**: https://groups.google.com/g/bolt-lmm-user-group
- **PLINK Google Group**: https://groups.google.com/g/plink2-users

---

## Version History

- **v1.0.0** (2025): Initial template release
  - Modular design with placeholders
  - Comprehensive documentation
  - Example configurations
  - Tested on binary and quantitative traits

---

## License

This template is released under the MIT License. See LICENSE file for details.

**Note**: The underlying software (BOLT-LMM, PLINK2) and any data you use have their own licensing terms that must be respected.

---

## Acknowledgments

- BOLT-LMM development team (Broad Institute / Harvard)
- PLINK development team (Christopher Chang, et al.)
- Day et al. (2018) for establishing BOLT-LMM best practices for UK Biobank
- UK Biobank research team and participants (if applicable to your analysis)

---

*Last Updated: October 30, 2025*
