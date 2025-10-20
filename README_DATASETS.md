# Meta-Regression Dataset Collection

## Overview

This repository contains **one of the world's largest curated collections of meta-regression datasets**, specifically compiled and standardized for meta-regression analysis. Unlike general meta-analysis collections, every dataset in this collection includes moderator variables necessary for meta-regression.

## Collection Statistics

> **Note:** Run `source("GENERATE_COMPARISON_STATS.R")` in R to generate exact current statistics.

**Estimated Collection Size:**
- **Total Datasets:** ~320
- **Total Effect Sizes:** 500,000+
- **Total Unique Moderators:** 2,000+
- **Meta-Regression Ready:** 100% (all datasets include moderator variables)
- **Average Moderators per Dataset:** ~11
- **Research Domains Covered:** 15+

**Largest Datasets:**
- Up to 1.7 million rows (handled via split file technology)
- Median dataset size: ~50-100 effect sizes
- Maximum moderators in a single dataset: 50+

## What Makes This Collection Unique

### 1. **100% Meta-Regression Ready**
Every single dataset includes moderator variables. In comparison:
- metadat: ~30% meta-regression ready
- dmetar: ~80% meta-regression ready
- Cochrane: <5% meta-regression ready

### 2. **Standardized Format**
All datasets follow a consistent structure:
- `yi`: Effect size
- `vi`: Variance
- `sei`: Standard error (where available)
- Moderator variables with consistent naming
- Metadata columns (dataset_id, source, etc.)

### 3. **Multi-Domain Coverage**
Datasets span multiple research fields:
- **Medicine & Public Health**: Clinical trials, epidemiology, interventions
- **Psychology**: Behavioral studies, cognitive research, clinical psychology
- **Education**: Educational interventions, learning outcomes
- **Ecology & Environmental Science**: Species data, environmental effects, conservation
- **Social Sciences**: Social interventions, policy studies
- **Biology & Genetics**: Genomic studies, evolutionary biology
- **Agriculture**: Crop studies, agricultural interventions

### 4. **Large-Scale Dataset Support**
First R package to handle datasets exceeding GitHub's 100MB limit through transparent split-file technology:
- Files automatically split into <100MB chunks
- `metareg_read()` automatically combines split files
- Users don't need to know files are split

### 5. **Comprehensive Provenance**
Every dataset includes:
- Source package/repository
- Original dataset name
- Data signature (MD5 hash)
- Collection date
- License information

## Data Sources

Datasets were systematically collected from three main sources:

### 1. **CRAN R Packages** (~140 datasets)
Meta-analysis packages with curated datasets:
- **metadat**: Comprehensive meta-analysis dataset collection
- **dmetar**: "Doing Meta-Analysis in R" companion data
- **metafor**: Classic meta-analysis examples
- **metaplus**, **metaSEM**, **netmeta**, **robumeta**, **weightr**, and others

### 2. **GitHub Repositories** (~20 datasets)
Open-source meta-analysis research:
- **dmetar**: Additional datasets not on CRAN
- **metadat**: Development versions
- **metaforest**: Meta-forest analysis datasets

### 3. **Zenodo Research Repository** (~160 datasets)
Published research data:
- Ecology & environmental studies
- Genomic & biological datasets
- Social science meta-analyses
- Agricultural research
- Medical & epidemiological studies

## Dataset Structure

### Standard Columns
Every dataset includes at minimum:
- **yi**: Effect size (standardized)
- **vi**: Variance of effect size
- **dataset_id**: Unique identifier
- **source**: Origin (CRAN/GitHub/Zenodo)

### Moderator Variables
Moderators vary by dataset but include:
- Study characteristics (year, country, sample size)
- Intervention details (type, duration, intensity)
- Population characteristics (age, gender, diagnosis)
- Methodological variables (design, randomization, blinding)
- Domain-specific moderators (species, treatment, outcome measures)

### Example Dataset Structure
```r
library(repo100)

# Read a dataset
dat <- metareg_read("dmetar_DepressionMortality")

# Standard structure
str(dat)
# 'data.frame': 18 obs. of 11 variables:
#  $ yi        : num  # Effect size
#  $ vi        : num  # Variance
#  $ author    : chr  # Study author
#  $ year      : int  # Publication year
#  $ country   : chr  # Study country
#  $ ter       : int  # Tertile exposure
#  $ cer       : num  # Control event rate
#  $ ... additional moderators
```

## Installation

### From GitHub (Recommended)
```r
# Install devtools if needed
install.packages("devtools")

# Install from GitHub
devtools::install_github("mahmood789/repo100", ref = "datasets-camr")
```

### For Development
```r
# Clone the repository
# git clone https://github.com/mahmood789/repo100.git

# Load with devtools
library(devtools)
options(metahub.metareg_dir = "inst/extdata/metareg")
devtools::load_all()
```

## Usage

### Basic Usage

```r
library(repo100)

# List all datasets
manifest <- metareg_manifest()
head(manifest)

# Get dataset IDs
dataset_ids <- metareg_datasets()
length(dataset_ids)  # ~320

# Read a specific dataset
dat <- metareg_read("dmetar_ThirdWave")
head(dat)

# Check moderators
names(dat)
```

### Reading Split Datasets

Large datasets are automatically handled:

```r
# This dataset is split into 4 parts (>240 MB total)
# But you read it like any other dataset
dat <- metareg_read("zenodo_TransportData")

# metareg_read() automatically:
# 1. Detects the 4 split files
# 2. Reads all parts
# 3. Combines them into one dataframe
# Returns: 1,722,357 rows seamlessly
```

### Meta-Meta-Analysis

Run analysis across all datasets:

```r
# Run comprehensive meta-meta-analysis
results <- metareg_meta_analysis(
  output_dir = "my_analysis",
  save_plots = TRUE,
  save_reports = TRUE,
  verbose = TRUE
)

# Access results
results$all_effects       # All effect sizes
results$summary_stats     # Summary statistics
results$source_analysis   # By data source
results$moderator_freq    # Moderator frequency
```

## Quality Assurance

### Data Validation
Every dataset underwent:
1. **Format validation**: Checked for yi, vi/sei columns
2. **Type checking**: Ensured numeric effect sizes and variances
3. **Completeness**: Verified data integrity
4. **Signature generation**: MD5 hash for version control

### Excluded Data
Datasets were excluded if:
- Missing effect sizes (yi) or variances (vi/sei)
- Contained only raw study data (no computed effect sizes)
- Had fewer than 3 studies (k < 3)
- Were duplicates of existing datasets
- Had unresolvable errors or corruption

## Dataset Categories

### By Size
- **Small** (k < 20): ~80 datasets - Good for teaching/examples
- **Medium** (20 ≤ k < 100): ~180 datasets - Typical meta-analyses
- **Large** (100 ≤ k < 500): ~50 datasets - Large-scale reviews
- **Very Large** (k ≥ 500): ~10 datasets - Comprehensive databases

### By Domain
- **Medicine & Health**: ~120 datasets
- **Psychology & Education**: ~80 datasets
- **Ecology & Biology**: ~60 datasets
- **Social Sciences**: ~30 datasets
- **Other**: ~30 datasets

### By Effect Size Measure
- Risk Ratio (RR): ~40 datasets
- Odds Ratio (OR): ~35 datasets
- Standardized Mean Difference (SMD): ~90 datasets
- Correlation (COR): ~30 datasets
- Log Response Ratio: ~25 datasets
- Other measures: ~100 datasets

## Comparison with Other Collections

| Collection | Datasets | Meta-Reg Ready | Format | Access |
|------------|----------|----------------|--------|--------|
| **repo100** | **~320** | **✅ 100%** | **R Package** | **GitHub** |
| metadat | ~350 | ⚠️ 30% | R Package | CRAN |
| dmetar | ~40 | ✅ 80% | R Package | GitHub |
| Cochrane | 10,000+ | ❌ <5% | Database | Subscription |
| metafor | ~60 | ⚠️ 50% | R Package | CRAN |

**Key Advantages:**
- ✅ Highest meta-regression readiness (100%)
- ✅ Fully standardized across all datasets
- ✅ Largest R package collection for meta-regression
- ✅ Multi-source integration (CRAN + GitHub + Zenodo)
- ✅ Active development (2025)

See `COLLECTION_COMPARISON.md` for detailed comparison.

## Technical Features

### Split File Technology
Handles datasets exceeding GitHub's 100MB limit:
- Datasets automatically split into ~80MB chunks
- Named as `dataset_id_part1.csv`, `dataset_id_part2.csv`, etc.
- `metareg_read()` automatically detects and combines parts
- Completely transparent to users

**Split Datasets:**
1. `zenodo_ECY17-1266_Autumn10x10km_17jan2018` (2 parts, 82 MB)
2. `zenodo_TransportData` (4 parts, 241 MB)
3. `zenodo_pbdb_dataPhanEnv.slim2` (8 parts, 618 MB)

### Metadata Management
Comprehensive manifest system:
- `inst/extdata/metareg_manifest.csv`: Main catalog
- `inst/extdata/metareg/_manifest.csv`: Internal manifest
- Tracks: source, k (studies), n_mods (moderators), measure type, signature

### Helper Functions
- `metareg_manifest()`: Load complete catalog
- `metareg_datasets()`: List all dataset IDs
- `metareg_read(id)`: Read any dataset (handles splits automatically)
- `metareg_meta_analysis()`: Run comprehensive meta-meta-analysis

## Citation

If you use this collection in your research, please cite:

```
@software{repo100_metareg,
  author = {[Your Name]},
  title = {Meta-Regression Dataset Collection},
  year = {2025},
  publisher = {GitHub},
  url = {https://github.com/mahmood789/repo100}
}
```

And cite the original data sources as listed in the manifest.

## License

This collection aggregates data from multiple sources:
- CRAN packages: Individual package licenses (mostly GPL-2, GPL-3, MIT)
- GitHub datasets: Repository-specific licenses
- Zenodo datasets: As specified by original authors

This compilation and standardization: [Specify your license]

**Important:** When using individual datasets, always check and respect the original source licenses listed in the manifest.

## Contributing

Contributions welcome! To add new datasets:
1. Ensure data is in meta-regression format (yi, vi, moderators)
2. Add source information and license
3. Run validation scripts
4. Update manifest
5. Submit pull request

See `CONTRIBUTING.md` for detailed guidelines.

## Acknowledgments

This collection builds upon the excellent work of:
- Wolfgang Viechtbauer (metafor, metadat)
- Mathias Harrer (dmetar)
- All researchers who shared their data on CRAN, GitHub, and Zenodo

## Support

For questions, issues, or contributions:
- GitHub Issues: https://github.com/mahmood789/repo100/issues
- Documentation: See `TESTING_INSTRUCTIONS.md`, `METHODOLOGY.md`
- Examples: See `TEST_META_META_DEVTOOLS.R`

## Version History

- **2025-01-20**: Initial comprehensive collection
  - 320+ datasets from CRAN, GitHub, Zenodo
  - Split file support for datasets >100MB
  - Meta-meta-analysis function
  - Full standardization and documentation

---

**Last Updated:** 2025-01-20
**Collection Version:** 1.0
**R Package:** repo100
**GitHub Branch:** datasets-camr
