# Example Configurations

This directory contains example configurations for common BOLT-LMM analysis scenarios.

## Available Examples

### 1. Binary Trait Analysis
**File**: `example_binary_trait.sh`

Simple case-control GWAS example (Type 2 Diabetes):
- Single binary phenotype
- Basic covariate model
- Demonstrates liability scale interpretation

### 2. Quantitative Trait Analysis
**File**: `example_quantitative_trait.sh`

Multiple quantitative phenotypes (BMI, Height, Weight):
- Multiple continuous phenotypes
- Standard covariate model with PCs
- Tips on phenotype standardization

### 3. Sensitivity Analysis
**File**: `example_sensitivity_analysis.sh`

Covariate model sensitivity analysis (CAD):
- Single phenotype with multiple covariate models
- Progressive adjustment strategy
- Result comparison across models

## How to Use Examples

These are NOT executable scripts. They show configuration snippets that should be:

1. **Copied** into your actual template files:
   - `1_run_bolt_lmm.sbatch.sh` for phenotype/covariate arrays
   - `run_single_phenotype.sh` for covariate definitions
   - `0d_test_run.sbatch.sh` for test configuration

2. **Adapted** for your specific:
   - Phenotype column names
   - Covariate column names
   - Analysis goals

3. **Extended** as needed:
   - Add more phenotypes
   - Define additional covariate sets
   - Customize for your cohort

## Example Selection Guide

Choose the example that best matches your analysis:

| Your Analysis | Example to Use |
|---------------|----------------|
| Single disease GWAS | Binary Trait |
| Multiple disease GWAS | Binary Trait (extend to multiple phenotypes) |
| Anthropometry, blood biomarkers | Quantitative Trait |
| Want to test covariate effects | Sensitivity Analysis |
| Mixed binary & quantitative | Combine Binary + Quantitative |

## Quick Reference

### Common Covariate Patterns

**Minimal:**
```bash
qcovar_col_args="--qCovarCol=age"
covar_col_args="--covarCol=sex"
```

**Standard (recommended):**
```bash
qcovar_col_args="--qCovarCol=age --qCovarCol=PC1 ... --qCovarCol=PC10"
covar_col_args="--covarCol=sex --covarCol=genotyping_array"
```

**Full adjustment:**
```bash
qcovar_col_args="--qCovarCol=age --qCovarCol=BMI --qCovarCol=PC1 ... --qCovarCol=PC10"
covar_col_args="--covarCol=sex --covarCol=genotyping_array --covarCol=assessment_center"
```

### Array Size Calculator

```
Total jobs = N_phenotypes × N_covariate_sets

Examples:
- 1 × 1 = 1   → --array=1-1
- 3 × 1 = 3   → --array=1-3
- 1 × 3 = 3   → --array=1-3
- 3 × 2 = 6   → --array=1-6
- 10 × 3 = 30 → --array=1-30
```

## Need More Help?

- **Detailed guide**: See `../ADAPTATION_GUIDE.md`
- **Quick start**: See `../QUICK_START.md`
- **Full documentation**: See `../README.md`

---

*Last Updated: October 30, 2025*

