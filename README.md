
# repo100

**A curated collection of meta-regression–ready datasets** (currently
**137** sets).

Each dataset is a CSV with `yi`, `vi`, `measure`, and harmonized
moderators in `inst/extdata/metareg/`. See `_manifest.csv` for a summary
and provenance.

## Install

``` r
remotes::install_github('mahmood789/repo100')
```

## Quick start

``` r
# helper functions are installed with the package
m <- metareg_manifest()
head(m[, c("dataset_id","k","measure","n_mods")])
ids <- metareg_datasets()
d  <- metareg_read(ids[1])
str(d[, c("slab","yi","vi","measure")])
metafor::rma(yi, vi, data = d)  # simple random-effects model
```

## Methods (brief)

- Included if: at least one non-constant moderator; effect sizes
  available as (`yi`,`vi`) or derivable; and `k ≥ 8` (primary pass) or
  `k ≥ 10` (strict pass).
- Datasets sourced from CRAN packages, MetaPsy, selected GitHub orgs,
  targeted code search, and local whitelists.
- Deduplication via a content signature on sorted rounded `(yi,vi)`
  pairs.
- Manifest records source package/object/title and repo license when
  available.

## Licensing

- Package code: MIT.
- Datasets: CC-BY-4.0 unless otherwise indicated in `_manifest.csv`
  (`repo_license`).

## Citation

If you use this package, please cite the package and the original data
sources listed in the manifest.
