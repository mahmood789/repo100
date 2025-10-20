# Using Meta-Meta-Analysis with devtools

## What Was Changed

I've created a proper R package function for the meta-meta-analysis that works with devtools:

### 1. **Updated DESCRIPTION** (DESCRIPTION:18-21)
Added required dependencies:
```
Imports:
    dplyr,
    readr,
    ggplot2
```

### 2. **Created R Package Function** (R/meta_meta_analysis.R)
Created `metareg_meta_analysis()` - a proper exported function that:
- Uses existing package helpers (`metareg_manifest()`, `metareg_read()`)
- Works with `system.file()` to find package data
- Can save outputs to any directory
- Returns results as R objects
- Fully documented with roxygen2

### 3. **Created Test Script** (TEST_META_META_DEVTOOLS.R)
Tests the function within devtools environment

## How to Use with devtools

### Option 1: Quick Test in R Console

```r
# Load package in development mode
library(devtools)
options(metahub.metareg_dir = "inst/extdata/metareg")  # Dev mode
devtools::load_all()

# Run meta-meta-analysis
results <- metareg_meta_analysis()

# Access results
head(results$all_effects)
results$summary_stats
```

### Option 2: Run Test Script

```r
source("TEST_META_META_DEVTOOLS.R")
```

This will:
1. Load the package with devtools
2. Test all helper functions
3. Run the full meta-meta-analysis
4. Create outputs in `test_output/` directory
5. Show summary of results

### Option 3: Run Without Saving Files

```r
library(devtools)
options(metahub.metareg_dir = "inst/extdata/metareg")
devtools::load_all()

# Run analysis, get results, but don't save files
results <- metareg_meta_analysis(
  save_plots = FALSE,
  save_reports = FALSE
)

# Explore results interactively
View(results$all_effects)
print(results$summary_stats)
```

## Function Arguments

```r
metareg_meta_analysis(
  output_dir = NULL,      # Where to save files (NULL = current directory)
  save_plots = TRUE,      # Create PNG visualizations?
  save_reports = TRUE,    # Create CSV reports?
  verbose = TRUE          # Print progress messages?
)
```

## What Gets Created

### CSV Reports (if save_reports = TRUE)
- `META_META_all_effect_sizes.csv` - All extracted effect sizes
- `META_META_dataset_summary.csv` - Summary of each dataset
- `META_META_moderator_frequency.csv` - Frequency of moderators
- `META_META_source_analysis.csv` - Analysis by data source

### PNG Visualizations (if save_plots = TRUE)
- `META_META_effect_size_distribution.png` - Histogram of effect sizes
- `META_META_dataset_size_distribution.png` - Distribution of dataset sizes
- `META_META_moderators_distribution.png` - Moderators per dataset
- `META_META_datasets_by_source.png` - Bar chart of top 10 sources

### Returned Object

```r
results <- list(
  all_effects = <data.frame>,      # All effect sizes (yi, vi, dataset_id, source)
  manifest = <data.frame>,          # Full manifest
  summary_stats = <list>,           # Summary statistics
  source_analysis = <data.frame>,   # Analysis by source
  moderator_freq = <data.frame>     # Moderator frequency table
)
```

## Checking the Package

Before pushing to GitHub:

```r
# Check package (comprehensive)
devtools::check()

# Or quick document + check
devtools::document()
devtools::check()
```

## After Installing the Package

Once you install the package (or someone else installs from GitHub):

```r
# Install
devtools::install_github("mahmood789/repo100")

# Load
library(repo100)

# Run meta-meta-analysis
results <- metareg_meta_analysis()

# Also works
results <- metareg_meta_analysis(
  output_dir = "my_analysis",
  save_plots = TRUE,
  save_reports = TRUE
)
```

## Differences from Standalone Script

| Feature | Standalone Script | Package Function |
|---------|------------------|------------------|
| File paths | Hardcoded `setwd()` | Uses `system.file()` |
| Data access | Direct file reading | Package helpers |
| Dependencies | `library()` calls | Declared in DESCRIPTION |
| Usage | `source("script.R")` | `metareg_meta_analysis()` |
| Portability | Local only | Works anywhere |
| Documentation | Comments | Roxygen2 docs |

## Troubleshooting

### Error: "metareg directory not found"
**Solution**: Set the dev option:
```r
options(metahub.metareg_dir = "inst/extdata/metareg")
```

### Error: "could not find function"
**Solution**: Make sure you loaded the package:
```r
devtools::load_all()
```

### Error: Package dependencies missing
**Solution**: Install them:
```r
install.packages(c("dplyr", "readr", "ggplot2"))
```

## Summary

✅ **Package function created**: `metareg_meta_analysis()`
✅ **Dependencies declared**: DESCRIPTION updated
✅ **Works with devtools**: Test with `devtools::load_all()`
✅ **Documented**: Full roxygen2 documentation
✅ **Tested**: Run `TEST_META_META_DEVTOOLS.R`
✅ **Ready for GitHub**: Can push and others can use

The standalone script (`META_META_ANALYSIS.R`) still works, but the package function is the proper way to use it within the R package ecosystem!
