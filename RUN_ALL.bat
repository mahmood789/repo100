@echo off
setlocal

echo ============================================================
echo   repo100 Dataset Expansion to 300 Real Datasets
echo ============================================================
echo.

cd /d "%~dp0"

echo Step 1: Looking for R.exe...
where R.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WARNING: R.exe not found in PATH
    echo.
    echo Please run this script in R instead:
    echo   1. Open R or RStudio
    echo   2. Run: source("C:/Users/user/OneDrive - NHS/Documents/repo100/RUN_ALL.R")
    echo.
    pause
    exit /b 1
)

echo ✓ Found R.exe
echo.
echo Step 2: Running cleanup and expansion scripts...
echo This may take 10-30 minutes (includes package installation)
echo.

R.exe --vanilla --no-save --quiet < RUN_ALL.R

echo.
echo ============================================================
echo Process completed!
echo ============================================================
echo.
pause
