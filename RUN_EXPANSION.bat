@echo off
echo ================================================
echo Expanding repo100 to 300 Real Datasets
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
echo.

R.exe --vanilla --quiet --no-save -e "source('scripts/expand_to_300_real.R')"

echo.
echo ================================================
echo Script execution complete!
echo ================================================
echo.
pause
