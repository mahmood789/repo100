# Dataset Standardization Status

**Package:** repo100
**Dataset Count:** 149
**Last Updated:** October 20, 2025

---

## Summary: Are Datasets Standardized?

**Short Answer:** Datasets have **structural standardization** but **not column name standardization**.

### What IS Standardized ✅

1. **File Format:** All datasets stored as CSV files
2. **Storage Location:** All in `inst/extdata/metareg/` directory
3. **File Naming:** Consistent pattern `{source}_{dataset_name}.csv`
4. **Required Columns:** All have effect size (yi) + variance (vi) OR standard error (sei)
5. **Data Type:** All are properly structured data.frames
6. **Quality:** All meet minimum criteria (k≥1, real data, no duplicates)
7. **Metadata:** All tracked in manifest with consistent fields

### What is NOT Standardized ❌

1. **Column Names:** Vary by original source
   - Effect size: yi, y, te, est, effect, d, g, r, z, logor, etc.
   - Variance: vi, v, var, variance, se2
   - Standard error: sei, se, sete, stderr

2. **Moderator Variables:** Different across datasets
   - Some have author, year, journal
   - Others have treatment, age, gender, etc.
   - No common set of moderators

3. **Effect Size Measures:** Multiple types
   - SMD (Standardized Mean Difference)
   - RR (Risk Ratio)
   - logor (Log Odds Ratio)
   - ZCOR (Fisher's Z)
   - PLO, HR, etc.

4. **Missing Data Encoding:** Varies (NA, NULL, empty strings)

---

## Detailed Standardization Report

### 1. Structural Standardization ✅

**Storage Structure:**
```
repo100/
├── inst/
│   └── extdata/
│       ├── metareg_manifest.csv          # Main manifest
│       └── metareg/
│           ├── _manifest.csv             # Working manifest
│           ├── metadat_dat.bcg.csv       # CRAN dataset
│           ├── metadat_dat.bangertdrowns2004.csv
│           ├── github_cooper1979.csv      # GitHub dataset
│           └── ... (149 total files)
```

**All Datasets Have:**
- ✅ Consistent CSV format
- ✅ UTF-8 encoding
- ✅ Header row with column names
- ✅ Rectangular structure (proper data.frame)

### 2. Required Columns ✅

**Every dataset contains:**
1. **Effect Size Column** (yi or equivalent)
2. **Variance OR Standard Error Column** (vi or sei or equivalent)

**Detection Method:**
- Pattern matching during extraction
- Validated programmatically
- See `DATA_COLLECTION_METHODOLOGY.md` for patterns

### 3. Manifest Standardization ✅

**Manifest Structure (100% consistent):**
```csv
dataset_id,source,source_pkg,source_object,source_title,repo,branch,
repo_license,k,measure,n_mods,moderators,signature
```

**Fields:**
- `dataset_id` - Unique identifier
- `source` - CRAN or GitHub
- `source_pkg` - Package name (for CRAN)
- `source_object` - Original object name
- `source_title` - Descriptive title
- `repo` - GitHub URL (if applicable)
- `branch` - Git branch (if applicable)
- `repo_license` - License information
- `k` - Number of studies
- `measure` - Effect size measure
- `n_mods` - Number of moderators
- `moderators` - Moderator variable names
- `signature` - Unique hash

---

## Column Name Variations

### Effect Size Columns (yi equivalents)
Common variations found across datasets:

| Column Name | Meaning | Frequency |
|-------------|---------|-----------|
| yi | Generic effect size | High |
| y | Effect size (short) | Medium |
| te | Treatment effect | Medium |
| d | Cohen's d / SMD | Medium |
| g | Hedges' g | Low |
| r | Correlation | Low |
| z | Fisher's Z | Low |
| logor | Log odds ratio | Medium |
| or | Odds ratio | Low |
| rr | Risk ratio | Low |

### Variance Columns (vi equivalents)

| Column Name | Meaning | Frequency |
|-------------|---------|-----------|
| vi | Variance | High |
| v | Variance (short) | Medium |
| var | Variance | Low |
| variance | Variance (long) | Low |
| se2 | SE squared | Low |

### Standard Error Columns (sei equivalents)

| Column Name | Meaning | Frequency |
|-------------|---------|-----------|
| sei | Standard error | High |
| se | Standard error (short) | High |
| sete | SE of treatment effect | Medium |
| stderr | Standard error | Low |

---

## Usage Implications

### Loading Datasets

**Current Approach (Non-Standardized Names):**
```r
# Load a dataset
library(readr)
dat <- read_csv("inst/extdata/metareg/metadat_dat.bcg.csv")

# Names vary by dataset!
names(dat)
# May be: yi, vi, author, year...
# OR: te, sete, study, treatment...
# OR: d, var_d, sample, intervention...
```

**What You Need to Do:**
```r
# Check column names first
names(dat)

# Find effect size column
yi_col <- grep("yi|^y$|te|^d$|^g$|logor", names(dat), ignore.case = TRUE)[1]

# Find variance column
vi_col <- grep("vi|^v$|var|se2", names(dat), ignore.case = TRUE)[1]

# Find SE column (if no vi)
se_col <- grep("sei|^se$|sete", names(dat), ignore.case = TRUE)[1]
```

### Recommended Helper Function

Add this to your package:
```r
#' Standardize meta-analysis dataset column names
#'
#' @param dat Data frame with meta-analysis data
#' @return Data frame with standardized names (yi, vi, sei)
#' @export
standardize_metareg <- function(dat) {
  nms <- tolower(names(dat))

  # Find yi
  yi_idx <- grep("yi|^y$|te|^d$|^g$|^r$|^z$|logor|^or$|rr|hr", nms)[1]
  if (!is.na(yi_idx)) names(dat)[yi_idx] <- "yi"

  # Find vi
  vi_idx <- grep("vi|^v$|^var$|variance|se2", nms)[1]
  if (!is.na(vi_idx)) names(dat)[vi_idx] <- "vi"

  # Find sei
  se_idx <- grep("sei|^se$|sete|stderr", nms)[1]
  if (!is.na(se_idx)) names(dat)[se_idx] <- "sei"

  dat
}
```

---

## Standardization Options

### Option A: Keep As-Is (Current Status)
**Pros:**
- ✅ Preserves original data exactly
- ✅ Maintains provenance
- ✅ No data transformation errors
- ✅ Users can access original column names

**Cons:**
- ❌ Users must handle column name variations
- ❌ Requires column detection logic
- ❌ Less convenient for quick analysis

**Recommended For:** Research applications, archival purposes

---

### Option B: Add Standardization Layer
**Implementation:**
1. Keep original CSV files unchanged
2. Add helper function `load_metareg_dataset(id)`
3. Function standardizes column names on load
4. Returns data with yi, vi, sei columns

**Pros:**
- ✅ Preserves originals
- ✅ Convenient for users
- ✅ Consistent interface

**Cons:**
- ❌ Requires maintenance
- ❌ Must update if new patterns found

**Recommended For:** User-facing package

---

### Option C: Full Standardization (Rewrite All CSVs)
**Implementation:**
1. Rename all yi/vi/sei columns to standard names
2. Rewrite all CSV files
3. Update manifest

**Pros:**
- ✅ Fully consistent
- ✅ Easy to use
- ✅ Simple code

**Cons:**
- ❌ LOSES original column names
- ❌ Less transparent provenance
- ❌ Potential errors in renaming
- ❌ Hard to verify against sources

**NOT RECOMMENDED** - Violates data integrity principles

---

## Recommendations

### For Package Users
**Current State:** You can use all datasets, but must check column names first.

**Example Workflow:**
```r
# 1. Load manifest
manifest <- read.csv(system.file("extdata/metareg_manifest.csv", package = "repo100"))

# 2. Browse available datasets
head(manifest[, c("dataset_id", "source_title", "k", "measure")])

# 3. Load a dataset
dat <- read.csv(system.file("extdata/metareg/metadat_dat.bcg.csv", package = "repo100"))

# 4. Check structure
str(dat)
names(dat)

# 5. Use with metafor (example)
library(metafor)
# Adjust column names as needed
rma(yi = yi, vi = vi, data = dat)
```

### For Package Development

**Immediate (No Changes Needed):**
- ✅ Current structure works with devtools
- ✅ `inst/extdata/` is standard R package location
- ✅ Files accessible via `system.file()`

**Recommended Enhancement:**
Add standardization helper function:
```r
#' Load and standardize a meta-regression dataset
#' @param dataset_id Character, dataset identifier
#' @export
load_metareg <- function(dataset_id) {
  path <- system.file("extdata/metareg", paste0(dataset_id, ".csv"),
                     package = "repo100")
  dat <- read.csv(path)
  standardize_metareg(dat)  # Apply standardization
}
```

---

## Devtools Compatibility

### Will it work from devtools? **YES ✅**

**Your package structure is correct:**
```r
# These will work:
devtools::load_all()           # ✅ Works
devtools::install()            # ✅ Works
devtools::check()              # ✅ Works

# Data accessible via:
system.file("extdata/metareg_manifest.csv", package = "repo100")
system.file("extdata/metareg/metadat_dat.bcg.csv", package = "repo100")
```

**Why it works:**
1. `inst/extdata/` is the STANDARD location for package data files
2. `inst/` contents are copied to package root during installation
3. Becomes `extdata/` in installed package
4. Accessible via `system.file()`

**Test it:**
```r
# From within package directory
devtools::load_all()

# Check data access
system.file("extdata", package = "repo100")
list.files(system.file("extdata/metareg", package = "repo100"))
```

---

## Summary Table

| Aspect | Status | Notes |
|--------|--------|-------|
| File Format | ✅ Standardized | All CSV |
| File Location | ✅ Standardized | inst/extdata/metareg/ |
| Required Columns | ✅ Present | yi + vi/sei |
| Column Names | ❌ NOT Standardized | Vary by source |
| Moderators | ❌ NOT Standardized | Vary by dataset |
| Data Quality | ✅ Verified | All meet criteria |
| Manifest | ✅ Standardized | Consistent structure |
| Devtools Compatible | ✅ YES | Standard R package structure |

---

## Conclusion

**Standardization Status: PARTIAL**

- ✅ **Structure:** Fully standardized (files, format, location)
- ✅ **Quality:** Fully standardized (all meet criteria)
- ✅ **Metadata:** Fully standardized (manifest)
- ❌ **Column Names:** NOT standardized (intentionally preserved)
- ✅ **Devtools:** Fully compatible

**Recommendation:** Keep current structure. Add optional standardization helper function for convenience.

---

**Last Updated:** October 20, 2025
**Package Version:** 0.1.0
