# How to Push to GitHub

Follow these steps to push your updated package to GitHub.

---

## Pre-Push Checklist

Before pushing, make sure:

1. ✅ **Test with devtools** - Run `TEST_DEVTOOLS.R` first
2. ✅ **Finalize collection** - Run `FINALIZE_COLLECTION.R` to clean manifest
3. ✅ **Review changes** - Check what you're committing

---

## Step 1: Test with Devtools

**In R, run:**
```r
source("C:/Users/user/OneDrive - NHS/Documents/repo100/TEST_DEVTOOLS.R")
```

**Expected output:**
- ✓ devtools::load_all() works
- ✓ Data files accessible
- ✓ Package check passed (or skipped)

**If tests fail:** Fix errors before proceeding

---

## Step 2: Finalize Collection (IMPORTANT!)

**In R, run:**
```r
source("C:/Users/user/OneDrive - NHS/Documents/repo100/FINALIZE_COLLECTION.R")
```

**This will:**
- Remove 5 incomplete manifest entries
- Clean duplicates
- Generate final statistics
- Create DATASET_COLLECTION_REPORT.md
- Save clean manifests

**Expected output:**
- Final Count: 149 datasets
- ✅ No duplicates
- ✅ No incomplete entries
- ✅ All CSV files present

---

## Step 3: Review What Will Be Pushed

**Current branch:** `datasets-camr`

**In terminal or Git Bash:**
```bash
git status
```

**You should see:**
- Modified files (2): `inst/extdata/metareg/_manifest.csv`, `metasem_Mak09.csv`
- Untracked files: All the new documentation and CSV files

---

## Step 4: Add All Files to Git

**Option A: Add everything (recommended)**
```bash
git add .
```

**Option B: Add selectively**
```bash
# Add documentation
git add *.md *.R *.txt *.bat

# Add data files
git add inst/extdata/metareg_manifest.csv
git add inst/extdata/metareg/*.csv

# Add scripts folder
git add scripts/
```

---

## Step 5: Create Commit

**Create a comprehensive commit message:**

```bash
git commit -m "$(cat <<'EOF'
feat: Expand dataset collection to 149 real meta-regression datasets

## Summary
- Expanded from 140 to 149 high-quality meta-regression datasets
- Added datasets from metadat, psymetadata, metaSEM, and other CRAN packages
- All datasets verified for quality (yi + vi/sei, k≥1, real data)
- No duplicates, no toy datasets

## Data Sources
- CRAN packages: 73 datasets (metadat, psymetadata, metafor, meta, metaSEM, dmetar)
- GitHub repos: 76 datasets (curated from real research)

## New Files Added
- 30+ new dataset CSV files
- Comprehensive documentation (methodology, quality criteria, sources)
- Extraction and finalization scripts
- Quality assurance tools

## Documentation
- DATA_COLLECTION_METHODOLOGY.md - Complete collection process
- DATASET_STANDARDIZATION_STATUS.md - Standardization details
- PACKAGE_SOURCES.md - All sources examined
- QUALITY_CRITERIA.md - Inclusion/exclusion standards
- DATASET_COLLECTION_REPORT.md - Final statistics
- FINAL_STATUS.md - Collection status

## Quality Verified
✅ All datasets have yi (effect size) column
✅ All datasets have vi OR sei (variance/SE) column
✅ All datasets have k≥1 valid studies
✅ All are real research data (no toy/simulated)
✅ Zero duplicates
✅ Devtools compatible

## Testing
- Package tested with devtools::load_all() ✅
- All data files accessible ✅
- Manifest integrity verified ✅

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Step 6: Push to GitHub

**Push to your current branch:**
```bash
git push -u origin datasets-camr
```

**If you want to push to main instead:**
```bash
# First merge into main (or create PR on GitHub)
git checkout main
git merge datasets-camr
git push origin main
```

---

## Step 7: Verify on GitHub

1. Go to: https://github.com/mahmood789/repo100
2. Check that your branch appears: `datasets-camr`
3. Verify files are uploaded
4. Check the commit message looks good

---

## Creating a Pull Request (Optional)

If you want to merge via PR:

1. Push the branch: `git push -u origin datasets-camr`
2. Go to GitHub: https://github.com/mahmood789/repo100
3. Click "Compare & pull request"
4. Add PR description (use commit message as template)
5. Merge when ready

**Or use GitHub CLI:**
```bash
gh pr create --title "Expand dataset collection to 149 datasets" --body "$(cat <<'EOF'
## Summary
Expanded from 140 to 149 high-quality meta-regression datasets from CRAN packages and GitHub repositories.

## Changes
- 30+ new dataset CSV files
- Comprehensive documentation
- Quality criteria and methodology
- Extraction scripts

## Testing
✅ Devtools compatible
✅ All data files verified
✅ Quality standards met

See commit message for full details.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Quick Reference Commands

**Full workflow:**
```bash
# 1. Check status
git status

# 2. Add all files
git add .

# 3. Commit with message
git commit -m "feat: Expand dataset collection to 149 real meta-regression datasets

Expanded from 140 to 149 high-quality datasets. All verified for quality.

- CRAN: 73 datasets (metadat, psymetadata, etc.)
- GitHub: 76 datasets (curated research)
- Added comprehensive documentation
- Devtools compatible

✅ All datasets have yi + vi/sei
✅ All k≥1 real studies
✅ Zero duplicates

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Push to GitHub
git push -u origin datasets-camr
```

---

## Troubleshooting

### Error: "Updates were rejected"
**Cause:** Remote has changes you don't have locally

**Fix:**
```bash
git pull --rebase origin datasets-camr
git push -u origin datasets-camr
```

### Error: "Large files detected"
**Cause:** CSV files might be large

**Fix:** Check file sizes, consider using Git LFS if needed
```bash
# Check file sizes
du -sh inst/extdata/metareg/*.csv | sort -h | tail -20

# If very large (>50MB), consider Git LFS
git lfs track "*.csv"
git add .gitattributes
```

### Error: "Authentication failed"
**Fix:**
- Use GitHub Desktop
- Or configure credentials: https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories

---

## After Pushing

**Update documentation site (if using pkgdown):**
```r
# In R
library(pkgdown)
build_site()
```

**Tag a release (optional):**
```bash
git tag -a v0.2.0 -m "Dataset collection expanded to 149"
git push origin v0.2.0
```

---

## Current State

**Branch:** datasets-camr
**Files to commit:** ~60+ (documentation + datasets + scripts)
**Datasets:** 149 (after finalization)
**Ready to push:** After running FINALIZE_COLLECTION.R

---

**Next Steps:**
1. ✅ Test with devtools (run TEST_DEVTOOLS.R)
2. ✅ Finalize collection (run FINALIZE_COLLECTION.R)
3. ✅ Add files (git add .)
4. ✅ Commit (git commit -m "...")
5. ✅ Push (git push -u origin datasets-camr)

Good luck! 🚀
