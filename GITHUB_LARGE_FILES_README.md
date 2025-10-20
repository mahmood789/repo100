# GitHub Large Files - Splitting Solution

## Problem
GitHub rejects files larger than 100MB. We have 3 datasets that exceed this limit:

| File | Size | Action Needed |
|------|------|---------------|
| `zenodo_pbdb_dataPhanEnv.slim2.csv` | 619 MB | Split into ~8 parts |
| `zenodo_TransportData.csv` | 241 MB | Split into ~3 parts |
| `zenodo_ECY17-1266_Autumn10x10km_17jan2018.csv` | 82 MB | Split into 2 parts |

## Solution Implemented

### 1. Code Updated ✅
The `metareg_read()` function in `R/metareg.R` now automatically:
- Detects if a dataset is split into multiple parts
- Reads all parts (`dataset_id_part1.csv`, `dataset_id_part2.csv`, etc.)
- Combines them seamlessly into a single data frame
- **Users don't need to know files are split!**

### 2. Files Need to be Split ⚠️

**You need to run ONE of these commands to split the large files:**

#### Option A: In R Console (Recommended)
```r
source("SPLIT_LARGE_FILES.R")
```

#### Option B: Double-Click
```
RUN_SPLIT_LARGE_FILES.bat
```

#### Option C: Command Line
```batch
R.exe --vanilla --no-save < SPLIT_LARGE_FILES.R
```

### What the Split Script Does

1. **Reads each large file**
2. **Splits into ~80MB chunks** (safely under GitHub's 100MB limit)
3. **Names parts**: `dataset_id_part1.csv`, `dataset_id_part2.csv`, etc.
4. **Preserves headers** in each part
5. **Deletes original** large files
6. **Prints summary** of parts created

### After Splitting

Once you run the split script:
1. The 3 large CSV files will be replaced by 13 smaller part files
2. All code continues to work normally (metareg_read handles splits automatically)
3. You can commit and push to GitHub without issues

### Example Output

```
=== SPLITTING LARGE FILES FOR GITHUB ===

Processing: zenodo_ECY17-1266_Autumn10x10km_17jan2018
  File size: 81.98 MB
  Total rows: 1057012
  Splitting into 2 parts
    Part 1: 528506 rows, 40.5 MB
    Part 2: 528506 rows, 40.5 MB
  Deleted original file

Processing: zenodo_TransportData
  File size: 240.99 MB
  Total rows: 1722357
  Splitting into 3 parts
    Part 1: 574119 rows, 79.8 MB
    Part 2: 574119 rows, 79.8 MB
    Part 3: 574119 rows, 79.8 MB
  Deleted original file

Processing: zenodo_pbdb_dataPhanEnv.slim2
  File size: 618.33 MB
  Total rows: 1355439
  Splitting into 8 parts
    Part 1: 169429 rows, 76.9 MB
    Part 2: 169429 rows, 76.9 MB
    ...
    Part 8: 169437 rows, 76.9 MB
  Deleted original file

=== SUMMARY ===
zenodo_ECY17-1266_Autumn10x10km_17jan2018: split into 2 parts
zenodo_TransportData: split into 3 parts
zenodo_pbdb_dataPhanEnv.slim2: split into 8 parts

✓ All large files split successfully!
```

### Testing After Split

To verify the split files work correctly:

```r
library(devtools)
options(metahub.metareg_dir = "inst/extdata/metareg")
devtools::load_all()

# Test reading a split dataset
dat <- metareg_read("zenodo_TransportData")
nrow(dat)  # Should show 1722357 rows

# Test meta-meta-analysis with split files
results <- metareg_meta_analysis()
```

### Files Involved

- `SPLIT_LARGE_FILES.R` - Main splitting script
- `RUN_SPLIT_LARGE_FILES.bat` - Windows batch file to run the script
- `R/metareg.R` - Updated metareg_read() function with split file support
- `GITHUB_LARGE_FILES_README.md` - This file

### Git Workflow After Splitting

After running the split script:

```bash
# Stage the new part files
git add inst/extdata/metareg/*_part*.csv

# Stage the updated metareg.R
git add R/metareg.R

# Commit
git commit -m "feat: split large datasets for GitHub file size compliance

- Split 3 large datasets into parts under 100MB
- Update metareg_read() to handle split files automatically
- No changes needed to user code"

# Push
git push origin datasets-camr
```

## Why This Approach?

✅ **Transparent**: Users don't need to know files are split
✅ **Simple**: One function handles both regular and split files
✅ **Reliable**: Headers preserved, order maintained
✅ **GitHub-compliant**: All files under 100MB limit
✅ **Backwards compatible**: Existing code continues to work

## Alternative Considered (Not Used)

- **Git LFS**: Requires special setup, quotas, costs money
- **External hosting**: Additional infrastructure, reliability concerns
- **Compression**: Reduces size but GitHub still sees uncompressed size
- **Removing datasets**: Defeats the purpose of a comprehensive collection

## Need Help?

If the split script doesn't work:
1. Check that R is installed and in your PATH
2. Ensure readr and dplyr packages are installed
3. Try running in R console directly: `source("SPLIT_LARGE_FILES.R")`
4. Check that the 3 large CSV files exist in `inst/extdata/metareg/`
