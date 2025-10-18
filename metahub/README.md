# metahub

[![R-CMD-check](https://github.com/mahmood789/repo100/actions/workflows/check-metahub.yml/badge.svg)](https://github.com/mahmood789/repo100/actions/workflows/check-metahub.yml) [![pkgdown](https://github.com/mahmood789/repo100/actions/workflows/pkgdown-metahub.yml/badge.svg)](https://github.com/mahmood789/repo100/actions/workflows/pkgdown-metahub.yml) [![Website](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://mahmood789.github.io/repo100/)

Lightweight helpers to list, load, and analyze meta-analysis datasets via a registry.

## Install (dev)
```r
devtools::install_github('mahmood789/repo100/metahub')
```

## Quick start
```r
library(metahub)
head(list_datasets())
fit <- meta_run(load_dataset('metadat_dat.bcg'))
meta_forest(fit)
```
