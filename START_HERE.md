# 🚀 START HERE - Run Dataset Expansion

I've created **3 easy ways** to run the expansion. Choose the one that works best for you:

---

## ⭐ OPTION 1: Copy-Paste (EASIEST)

1. **Open R or RStudio**
2. **Open this file:** `COPY_PASTE_TO_R.txt`
3. **Copy the entire contents**
4. **Paste into R console** and press Enter
5. **Wait 10-30 minutes** for completion

---

## ⭐ OPTION 2: Source Command in R

1. **Open R or RStudio**
2. **Run this single command:**
   ```r
   source("C:/Users/user/OneDrive - NHS/Documents/repo100/RUN_ALL.R")
   ```
3. **Press Enter when prompted** (after cleanup step)
4. **Wait 10-30 minutes** for completion

---

## ⭐ OPTION 3: Windows Batch File

1. **Double-click:** `RUN_ALL.bat`
2. **Wait 10-30 minutes** for completion
3. *(Note: Only works if R.exe is in your PATH)*

---

## 📊 What Will Happen

### Step 1: Cleanup (30 seconds)
- Removes ~8 datasets (5 incomplete + 3 toy)
- Current: 151 → After cleanup: ~143

### Step 2: Expansion (10-30 minutes)
- Scans **16 meta-analysis packages** for datasets
- Installs packages as needed (if not already installed)
- Filters out toy/simulated datasets
- Adds ~157 new real datasets
- Target: ~143 → 300

### Step 3: Verification
- Shows final count
- Shows breakdown by package

---

## 📦 Packages That Will Be Scanned

- metadat (50+ datasets)
- psymetadata (30+ datasets)
- metafor
- meta
- metaSEM
- dmetar
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

---

## ✅ Quality Criteria

All datasets will have:
- ✓ Effect size (yi) + variance/SE (vi/sei)
- ✓ At least 3 studies (k ≥ 3)
- ✓ Real research data (no toy/simulated)
- ✓ No duplicates
- ✓ Can have basic moderators (author, year, etc.)

---

## 🔍 Monitoring Progress

You'll see output like:
```
[Step 1] Loading current manifest...
Current datasets: 143

[Step 2] Discovering datasets from CRAN packages...
  Scanning metadat...
  Scanning psymetadata...
✓ Found 523 potential CRAN datasets

[Step 3] Filtering candidates...
✓ After removing known and toy datasets: 380

[Step 4] Processing datasets to reach 300...
Need 157 more datasets
  [1/200] metadat_dat.example...
    ✓ Added (k=20, mods=5)
  [2/200] meta_Olkin95...
    ✗ Already exists
  ...
```

---

## ❓ Troubleshooting

**Q: Some packages fail to install?**
A: That's OK. The script will skip them and continue.

**Q: I don't reach 300?**
A: The script will get as many as possible. If < 300, we may need to:
- Adjust quality filters
- Add more package sources
- Include GitHub datasets

**Q: Script stops with an error?**
A: Check the error message. Common issues:
- Working directory wrong → Run `setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")`
- Package installation failed → Install manually: `install.packages("packagename")`

---

## 📁 Files Created

All datasets saved to:
- `inst/extdata/metareg/*.csv` (individual datasets)
- `inst/extdata/metareg/_manifest.csv` (main registry)
- `inst/extdata/metareg_manifest.csv` (copy for package functions)

---

## 🎯 After Completion

Check your results:
```r
manifest <- readr::read_csv("inst/extdata/metareg/_manifest.csv")
nrow(manifest)  # Should be ~300

# View by package
dplyr::count(manifest, source_pkg, sort = TRUE)
```

---

**Ready? Choose an option above and let's get to 300 datasets! 🚀**
