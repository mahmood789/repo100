# Testing Instructions

## Two Ways to Test the Package

### Option 1: Quick Local Test (Recommended First)
Tests the package locally using `devtools::load_all()` - faster and doesn't require GitHub download.

**Run in R:**
```r
source("TEST_DEVTOOLS_QUICK.R")
```

**Or double-click:**
```
(Run in R console since R.exe not in PATH)
```

**What it tests:**
- ✅ Package loads with devtools
- ✅ Manifest access (should show ~320 datasets)
- ✅ Regular dataset reading
- ✅ **Split file reading** (the 3 large files split into parts)
- ✅ Meta-meta-analysis function
- ✅ Results summary

**Expected output:**
```
✓ Manifest: 320 datasets
✓ Dataset IDs: 320
✓ Read dmetar_DepressionMortality - 18 rows

Testing SPLIT file functionality...
  Testing: zenodo_ECY17-1266_Autumn10x10km_17jan2018
    ✓ Successfully read 1057012 rows (from 2 parts)
  Testing: zenodo_TransportData
    ✓ Successfully read 1722357 rows (from 4 parts)
  Testing: zenodo_pbdb_dataPhanEnv.slim2
    ✓ Successfully read 1355439 rows (from 8 parts)

✓ Effect sizes extracted: [large number]
```

---

### Option 2: Full GitHub Installation Test
Tests installing the package fresh from GitHub and running all functionality.

**Run in R:**
```r
source("TEST_GITHUB_INSTALL.R")
```

**What it does:**
1. Uninstalls any existing version
2. Installs fresh from GitHub (`mahmood789/repo100@datasets-camr`)
3. Loads the package
4. Tests all functionality including split files
5. Runs meta-meta-analysis

**Expected duration:** 5-10 minutes (includes download time)

**Expected output:**
```
✓ Package successfully installed from GitHub
✓ Package loads correctly
✓ Manifest accessible (320 datasets)
✓ Dataset reading works
✓ Split file handling works transparently
✓ Meta-meta-analysis function works

ALL TESTS PASSED! ✅
```

---

## What We're Testing

### Critical Features:
1. **Split File Transparency**: The 3 large datasets were split into parts:
   - `zenodo_ECY17-1266_Autumn10x10km_17jan2018`: 2 parts (82 MB total)
   - `zenodo_TransportData`: 4 parts (241 MB total)
   - `zenodo_pbdb_dataPhanEnv.slim2`: 8 parts (618 MB total)

   **The test verifies** that `metareg_read()` automatically combines these parts without users knowing they're split.

2. **GitHub Compliance**: All files are under 100MB and successfully pushed to GitHub

3. **Full Functionality**: Meta-meta-analysis works with the expanded dataset collection

### If Tests Fail:

**Error: "Dataset not found"**
- Make sure you're in the correct directory
- For local test: Set `options(metahub.metareg_dir = "inst/extdata/metareg")`

**Error: "Installation failed"**
- Check internet connection
- Verify GitHub branch `datasets-camr` exists
- Try `force = TRUE` in install_github()

**Error: "Cannot combine parts"**
- This would indicate an issue with the metareg_read() split file logic
- Check that part files exist in `inst/extdata/metareg/`

---

## Quick Start

**Fastest way to test:**

```r
# In R console, from the repo100 directory:
source("TEST_DEVTOOLS_QUICK.R")
```

This will verify everything works before doing the full GitHub install test.

---

## For Others Installing from GitHub

Once tests pass, others can install with:

```r
# Install
devtools::install_github("mahmood789/repo100", ref = "datasets-camr")

# Use
library(repo100)
manifest <- metareg_manifest()
dat <- metareg_read("zenodo_TransportData")  # Automatically combines 4 parts!

# Run meta-meta-analysis
results <- metareg_meta_analysis()
```
