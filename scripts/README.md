# Scripts for Dataset Management

This directory contains scripts for managing and expanding the repo100 meta-regression dataset collection.

## Overview

The repo100 package aims to provide 300+ curated meta-regression datasets. These scripts help:
1. Fix existing issues in the manifest
2. Discover new datasets from CRAN and GitHub
3. Process and standardize datasets
4. Expand the collection to reach the 300 dataset target

## Current Status

- **Current datasets**: 137 (as of last update)
- **Target**: 300 datasets
- **Needed**: 163 more datasets

## Scripts

### 1. `quick_fix_incomplete.R`

**Purpose**: Quick fix for 5 incomplete manifest entries

**Usage**:
```r
source("scripts/quick_fix_incomplete.R")
```

**What it does**:
- Fixes metadata for 5 datasets with incomplete manifest entries:
  - meta_Fleiss93
  - meta_Fleiss93cont
  - metadat_dat.colditz1994
  - metadat_dat.lim2014
  - netmeta_Senn2013
- Updates both manifest files
- Takes < 5 seconds to run

**Run this first** if you want to quickly test that the package functions work correctly.

### 2. `fix_and_expand_datasets.R`

**Purpose**: Comprehensive script to fix all issues and expand to 300 datasets

**Usage**:
```r
source("scripts/fix_and_expand_datasets.R")
```

**What it does**:
1. **Fixes incomplete entries** (same as quick_fix_incomplete.R)
2. **Discovers datasets** from CRAN packages:
   - metadat (100+ datasets)
   - psymetadata (50+ datasets)
   - metafor (30+ datasets)
   - meta (20+ datasets)
   - dmetar (10+ datasets)
   - metaSEM (5+ datasets)
3. **Classifies datasets** by:
   - Effect size availability (yi, vi, sei)
   - Study count (k)
   - Moderator count (p_mods)
   - Measure type (RR, SMD, ZCOR, etc.)
4. **Filters datasets**:
   - Must have yi + (vi OR sei)
   - Must have k ≥ 3 studies
   - Preference for datasets with moderators
5. **Processes and saves**:
   - Saves datasets as CSV to `inst/extdata/metareg/`
   - Updates manifest with complete metadata
   - Generates unique signatures

**Expected runtime**: 10-30 minutes (depending on internet speed and package availability)

**Requirements**:
- R packages: dplyr, tibble, purrr, readr, stringr, tidyr, metafor, digest
- Internet connection (for installing meta-analysis packages)
- ~100MB disk space for new datasets

## Issues Fixed

### 1. Empty Manifest File
**Problem**: `inst/extdata/metareg_manifest.csv` was empty
**Fix**: Copied from `inst/extdata/metareg/_manifest.csv`
**Status**: ✅ Fixed

### 2. Incomplete Manifest Entries
**Problem**: 5 datasets had NA values in manifest
**Fix**: Analyzed CSV files and populated metadata
**Status**: ✅ Script created (run quick_fix_incomplete.R)

### 3. Varying Column Names
**Problem**: Different datasets use different column naming conventions
**Fix**:
- `classify_df()` function normalizes column names
- Handles variants: yi/y/te/estimate, vi/V/variance, sei/sete/se
**Status**: ✅ Implemented in script

### 4. Missing API/Discovery Scripts
**Problem**: No scripts for discovering new datasets
**Fix**: Created comprehensive discovery system
**Status**: ✅ Script created

### 5. Insufficient Dataset Count
**Problem**: Only 137 datasets, need 300
**Fix**: Automated discovery from 6 CRAN packages
**Status**: ⏳ Run fix_and_expand_datasets.R to complete

## Dataset Sources

### CRAN Packages (Primary Source)
- **metadat**: Meta-analysis datasets (100+ available)
- **psymetadata**: Psychology meta-analyses (50+ available)
- **metafor**: Meta-analysis package datasets (30+ available)
- **meta**: Meta-analysis datasets (20+ available)
- **dmetar**: Toy/example datasets (10+ available)
- **metaSEM**: Structural equation modeling meta-analyses (5+ available)

### GitHub (Future Enhancement)
The script can be extended to search GitHub repositories for CSV files with meta-analysis data. This requires:
- GITHUB_PAT environment variable
- gh R package
- Additional filtering for data quality

## Output Files

After running the scripts, you will have:

```
inst/extdata/
├── metareg_manifest.csv          # Main manifest (copy)
└── metareg/
    ├── _manifest.csv              # Primary manifest
    ├── dmetar_*.csv              # Datasets from dmetar
    ├── meta_*.csv                # Datasets from meta
    ├── metadat_*.csv             # Datasets from metadat
    ├── psymetadata_*.csv         # Datasets from psymetadata
    ├── metaSEM_*.csv             # Datasets from metaSEM
    └── netmeta_*.csv             # Datasets from netmeta
```

## Manifest Structure

The manifest CSV contains:
- `dataset_id`: Unique identifier (package_object format)
- `source`: Source type ("CRAN" or "GitHub")
- `source_pkg`: Package name
- `source_object`: Original object name
- `source_title`: Dataset title/description
- `repo`: GitHub repo (for GitHub sources)
- `branch`: GitHub branch (for GitHub sources)
- `repo_license`: License information
- `k`: Number of studies/effect sizes
- `measure`: Effect size measure (RR, SMD, ZCOR, etc.)
- `n_mods`: Number of potential moderators
- `moderators`: Pipe-separated list of moderator names
- `signature`: Unique hash for data integrity

## Validation

After running the scripts, validate with:

```r
library(repo100)

# Check manifest
m <- metareg_manifest()
nrow(m)  # Should be ~300

# Check a sample dataset
ids <- metareg_datasets()
d <- metareg_read(ids[1])
str(d)

# Run a quick meta-analysis
library(metafor)
rma(yi, vi, data = d)
```

## Troubleshooting

### Error: Package not installed
**Solution**: The script auto-installs required packages. If it fails:
```r
install.packages(c("dplyr", "tibble", "purrr", "readr", "stringr", "tidyr", "metafor", "digest"))
```

### Error: Cannot load dataset
**Solution**: Some datasets in CRAN packages may not be suitable. The script automatically skips these.

### Warning: Fewer than 300 datasets
**Solution**:
1. Run the script again (some packages may need time to install)
2. Consider adding GitHub search capability
3. Manually curate additional datasets

### Manifest columns don't match
**Solution**: The script handles column name variations automatically via `normalise_names()` function.

## Future Enhancements

1. **GitHub API Integration**: Search GitHub for meta-analysis CSV files
2. **Quality Metrics**: Add automated quality scoring for datasets
3. **Deduplication**: Check for duplicate datasets across sources
4. **Incremental Updates**: Only process new datasets on re-run
5. **Parallel Processing**: Speed up dataset processing
6. **Web Dashboard**: Visual interface for dataset discovery and curation

## Contributing

To add new dataset sources:
1. Create a discovery function similar to `discover_cran_datasets()`
2. Add classification logic in `classify_df()`
3. Update manifest schema if needed
4. Test with sample datasets
5. Document in this README

## Contact

For issues or questions about these scripts, see the main repo100 documentation.
