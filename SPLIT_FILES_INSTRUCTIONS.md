# Instructions to Split Large Files

The following 3 files are too large for GitHub (>100MB limit):
1. `zenodo_ECY17-1266_Autumn10x10km_17jan2018.csv` - 82 MB
2. `zenodo_TransportData.csv` - 241 MB
3. `zenodo_pbdb_dataPhanEnv.slim2.csv` - 619 MB

## To split these files, run ONE of the following:

### Option 1: In R Console
```r
source("SPLIT_LARGE_FILES.R")
```

### Option 2: Double-click
```
RUN_SPLIT_LARGE_FILES.bat
```

### Option 3: Command Line
```
R.exe --vanilla --no-save < SPLIT_LARGE_FILES.R
```

## What it does:
- Splits each large file into parts under 100MB
- Names them as `dataset_id_part1.csv`, `dataset_id_part2.csv`, etc.
- Deletes the original large files
- The code will be updated to automatically combine parts when reading

## After running:
The metareg_read() function will be updated to automatically detect and combine split files.
