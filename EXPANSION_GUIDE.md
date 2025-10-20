# Dataset Expansion Guide

## Current Status

**Current dataset count:** 151 (including 5 incomplete entries)
**Target:** 300 real meta-regression datasets
**Need:** 149 more datasets

### What Changed

I've enhanced the expansion script to scan **16 meta-analysis packages** instead of just 5:

**New packages added:**
- MAd
- metaplus
- rmeta
- metamisc
- clubSandwich
- robumeta
- weightr
- PublicationBias
- metaBMA
- RoBMA

**Original packages:**
- metadat
- metafor
- meta
- metaSEM
- psymetadata
- dmetar

## How to Run the Expansion

### Option 1: Quick Run in R/RStudio (Recommended)

1. Open R or RStudio
2. Set working directory to repo root:
   ```r
   setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")
   ```
3. Run:
   ```r
   source("QUICK_RUN.R")
   ```

### Option 2: Windows Batch File

Double-click: `RUN_EXPANSION_V2.bat`

### Option 3: Direct R Command

```r
source("scripts/expand_to_300_real.R")
```

## Cleanup First (Recommended)

Before expanding, clean up toy datasets and incomplete entries:

```r
source("scripts/cleanup_manifest.R")
```

This will:
- Remove 5 incomplete manifest entries
- Remove toy/simulated datasets from dmetar package (~3-4 datasets)
- Remove any duplicates
- Expected to reduce count from 151 to ~143 real datasets

## Full Workflow

```r
# 1. Clean up existing manifest
source("scripts/cleanup_manifest.R")

# 2. Expand to 300 datasets
source("scripts/expand_to_300_real.R")

# 3. Check results
manifest <- readr::read_csv("inst/extdata/metareg/_manifest.csv")
nrow(manifest)  # Should be close to or at 300
```

## What the Script Does

1. **Discovers datasets** from 16 CRAN packages
2. **Filters out:**
   - Already known datasets
   - Toy/simulated datasets (keywords: toy, simulated, synthetic, demo, etc.)
   - Datasets without yi + (vi OR sei) columns
   - Datasets with fewer than 3 studies (k < 3)
3. **Accepts:**
   - Real research datasets
   - Basic moderators like author, year, country (you specified this is OK)
   - Various effect size measures (RR, SMD, ZCOR, logor, etc.)
4. **Saves:**
   - Each dataset as CSV in `inst/extdata/metareg/`
   - Updates both manifest files

## Expected Runtime

- **Cleanup:** 10-30 seconds
- **Expansion:** 10-30 minutes (depending on how many packages need installation)

## Monitoring Progress

The script prints detailed progress:
```
[Step 1] Loading current manifest...
[Step 2] Discovering datasets from CRAN packages...
[Step 3] Filtering candidates...
[Step 4] Processing datasets to reach 300...
  [1/50] metadat_dat.example...
    ✓ Added (k=20, mods=5)
  [2/50] meta_Olkin95...
    ✗ Already exists
```

## Troubleshooting

### Package Installation Fails

Some packages may fail to install. This is OK - the script will skip them and continue.

### Fewer Than Expected Datasets Added

If you don't reach 300, it means:
- The 16 packages don't have enough qualifying datasets
- Many are toy/simulated datasets
- Many don't have proper yi/vi/sei structure

**Solution:** We may need to add more packages or adjust quality filters.

### Check What Was Added

```r
library(dplyr)
manifest <- readr::read_csv("inst/extdata/metareg/_manifest.csv")

# View by package
manifest %>%
  count(source_pkg, sort = TRUE)

# View recently added (last 20)
manifest %>%
  tail(20) %>%
  select(dataset_id, source_pkg, k, n_mods)
```

## Files Created/Modified

- `scripts/expand_to_300_real.R` - Enhanced with 16 packages
- `scripts/cleanup_manifest.R` - New cleanup script
- `QUICK_RUN.R` - Easy run script for R/RStudio
- `RUN_EXPANSION_V2.bat` - Enhanced batch file
- `inst/extdata/metareg/_manifest.csv` - Updated manifest
- `inst/extdata/metareg_manifest.csv` - Updated manifest copy
- `inst/extdata/metareg/*.csv` - Individual dataset files

## Quality Criteria

All datasets must meet:
- ✅ Has effect size column (yi/y/te/estimate/etc.)
- ✅ Has variance OR standard error (vi/sei)
- ✅ At least 3 studies (k ≥ 3)
- ✅ Not toy/simulated/synthetic
- ✅ From established R packages (CRAN)
- ✅ No duplicates

Moderators:
- ✅ Accepts datasets with basic moderators (author, year, country)
- ✅ Accepts datasets with 0 moderators (you can generate them later)

## Next Steps After Reaching 300

1. Verify no duplicates: `dplyr::distinct(dataset_id)`
2. Verify all are real (no toy datasets)
3. Document source packages
4. Update package documentation
5. Run R CMD check
6. Update NEWS.md
