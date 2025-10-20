@echo off
echo ================================================
echo Expanding repo100 to 300 Real Datasets (v2)
echo With Enhanced Package Discovery
echo ================================================
echo.

cd /d "%~dp0"

echo Looking for R...
where R.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: R.exe not found in PATH
    echo Please install R or add it to your PATH
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo Found R! Running expansion script...
echo This will install and scan 16 meta-analysis packages.
echo Expected runtime: 10-30 minutes
echo.

R.exe --vanilla --quiet --no-save -e "source('scripts/expand_to_300_real.R')" 2>&1 | tee expansion_log.txt

echo.
echo ================================================
echo Script execution complete!
echo Check expansion_log.txt for details
echo ================================================
echo.
pause
