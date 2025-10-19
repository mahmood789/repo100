# repo100

**A curated collection of meta-regression–ready datasets** (currently **137** sets).

Each dataset is a CSV with `yi`, `vi`, `measure`, and harmonized moderators in `inst/extdata/metareg/`.
See `_manifest.csv` for a summary and provenance.

## Install

```r
remotes::install_github('mahmood789/repo100')
```

## Quick start

```r
m <- metareg_manifest()
head(m[, c('dataset_id','k','measure','n_mods')])
ids <- metareg_datasets()
d  <- metareg_read(ids[1])
metafor::rma(yi, vi, data = d)
```

## Licensing
- Package code: MIT.
- Datasets: CC-BY-4.0 unless otherwise indicated in `_manifest.csv` (`repo_license`).
