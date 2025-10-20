# Dataset Collection Summary Report

**Generated:** 2025-10-20

## Overview

This collection contains **146 real meta-regression datasets** from:
- **70 CRAN packages** (verified R data packages)
- **76 GitHub repositories** (real research data)

## Quality Criteria

All datasets meet these requirements:
- ✅ Contains effect size (yi) column
- ✅ Contains variance (vi) OR standard error (sei) column
- ✅ Has at least k≥1 valid studies
- ✅ Real research data (no toy/simulated datasets)
- ✅ No duplicates

## Statistics

### Dataset Size
- **Median studies per dataset:** 50.5
- **Mean studies per dataset:** 202.8
- **Range:** 4 - 2439 studies

### Moderators
- **Datasets with moderators:** 146 (100%)
- **Mean moderators per dataset:** 13.5

## Data Sources

### CRAN Packages (70 datasets)

- **metadat:** 36 datasets
- **psymetadata:** 22 datasets
- **metaSEM:** 7 datasets
- **dmetar:** 3 datasets
- **meta:** 2 datasets

### GitHub Repositories (76 datasets)

Curated collection from real research repositories.

## Effect Size Measures

- **from_dataset:** 54 datasets
- **estimate:** 41 datasets
- **effect:** 13 datasets
- **ZCOR:** 11 datasets
- **est:** 10 datasets
- **PLO:** 5 datasets
- **RR:** 4 datasets
- **SMD:** 3 datasets
- **logor:** 3 datasets
- **te:** 2 datasets

## Files

- **Manifest:** `inst/extdata/metareg_manifest.csv`
- **Individual datasets:** `inst/extdata/metareg/*.csv`
- **Total files:** 146 CSV files

## Usage

```r
# Load the manifest
library(readr)
manifest <- read_csv('inst/extdata/metareg_manifest.csv')

# View available datasets
head(manifest)

# Load a specific dataset
dataset <- read_csv('inst/extdata/metareg/metadat_dat.bcg.csv')
```

## Quality Assurance

✅ All datasets verified for:
- Proper meta-analysis structure (yi/vi/sei)
- Minimum data quality (k≥1)
- No duplicates
- No toy/simulated data
- Real research applications

---

**Collection finalized:** 2025-10-20

