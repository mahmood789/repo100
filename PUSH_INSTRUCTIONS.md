# Push to GitHub - Step by Step

You already have a GitHub repo at: https://github.com/mahmood789/repo100

Current branch: `datasets-camr`

---

## Quick Push (3 Commands)

```bash
# 1. Add all files
git add .

# 2. Commit
git commit -m "feat: expand dataset collection to 149 datasets with comprehensive documentation"

# 3. Push
git push -u origin datasets-camr
```

Then go to GitHub and create a Pull Request to merge into `main`.

---

## Detailed Step-by-Step

### Step 1: Check what will be committed

```bash
git status
```

You should see:
- Modified: `inst/extdata/metareg/_manifest.csv`, `metasem_Mak09.csv`, `NAMESPACE`
- New files: All the documentation, scripts, and new datasets

### Step 2: Add all changes

```bash
git add .
```

This stages everything for commit.

### Step 3: Commit with a good message

```bash
git commit -m "$(cat <<'EOF'
feat: expand dataset collection to 149 real meta-regression datasets

## Summary
- Expanded from 140 to 149 high-quality meta-regression datasets
- Added comprehensive documentation and collection methodology
- Fixed NAMESPACE issues for devtools compatibility
- All datasets verified for quality (yi + vi/sei, k≥1, real data)

## Data Sources
- CRAN packages: 73 datasets (metadat, psymetadata, metafor, meta, metaSEM, dmetar)
- GitHub repositories: 76 datasets (curated from real research)

## New Features
- 30+ new dataset CSV files
- Complete collection methodology documentation
- Quality criteria and standards documentation
- Data source tracking and provenance
- Extraction and finalization scripts

## Documentation Added
- DATA_COLLECTION_METHODOLOGY.md - Complete collection process
- DATASET_STANDARDIZATION_STATUS.md - Standardization details
- PACKAGE_SOURCES.md - All data sources examined
- QUALITY_CRITERIA.md - Inclusion/exclusion standards
- DATASET_COLLECTION_REPORT.md - Final statistics (after finalization)
- Multiple helper scripts for extraction and validation

## Quality Verified
✅ All datasets have yi (effect size) column
✅ All datasets have vi OR sei (variance/SE) column
✅ All datasets have k≥1 valid studies
✅ All are real research data (no toy/simulated)
✅ Zero duplicates
✅ Devtools compatible (NAMESPACE fixed)
✅ Package structure verified

## Fixes
- Fixed NAMESPACE to export only real functions (metareg_manifest, metareg_datasets, metareg_read)
- Removed invalid exports that caused devtools errors
- Cleaned manifest structure

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Step 4: Push to GitHub

```bash
git push -u origin datasets-camr
```

The `-u` flag sets up tracking so future pushes are easier.

**Expected output:**
```
Enumerating objects: X, done.
Counting objects: 100% (X/X), done.
...
To https://github.com/mahmood789/repo100.git
 * [new branch]      datasets-camr -> datasets-camr
```

### Step 5: Create Pull Request on GitHub

1. Go to: https://github.com/mahmood789/repo100
2. You'll see a banner: "datasets-camr had recent pushes"
3. Click **"Compare & pull request"**
4. Review the changes
5. Click **"Create pull request"**
6. Review and click **"Merge pull request"** when ready

---

## Alternative: Push directly to main (if you prefer)

**Warning:** This skips the PR process and pushes directly to main.

```bash
# Switch to main
git checkout main

# Merge your work
git merge datasets-camr

# Push
git push origin main
```

---

## If You Get Errors

### Error: "Updates were rejected"

**Cause:** Remote has changes you don't have locally

**Fix:**
```bash
# Pull remote changes first
git pull --rebase origin datasets-camr

# Then push again
git push -u origin datasets-camr
```

### Error: "Authentication failed"

**Options:**
1. **GitHub Desktop** (easiest) - Download from https://desktop.github.com
2. **Personal Access Token** - Create at https://github.com/settings/tokens
3. **SSH Key** - Set up at https://github.com/settings/keys

### Large files warning

If you get warnings about large CSV files:

```bash
# Check file sizes
ls -lh inst/extdata/metareg/*.csv | sort -k5 -h | tail -10

# If >50MB files exist, consider Git LFS (but probably not needed)
```

---

## After Pushing

### View on GitHub
https://github.com/mahmood789/repo100/tree/datasets-camr

### Create a Release (optional)

After merging to main:

```bash
git checkout main
git pull origin main
git tag -a v0.2.0 -m "Dataset collection expanded to 149"
git push origin v0.2.0
```

Then create a release on GitHub from that tag.

---

## Summary

**Current state:**
- ✅ Repo exists: https://github.com/mahmood789/repo100
- ✅ Branch ready: datasets-camr
- ✅ Changes ready to commit: ~60+ files

**Next steps:**
1. `git add .`
2. `git commit -m "..."`
3. `git push -u origin datasets-camr`
4. Create PR on GitHub
5. Merge when ready

**Total time:** ~2 minutes

---

Good luck! 🚀
