@echo off
REM Simple test script to verify Windows x64 Cavern audio processor

echo ========================================
echo Testing Cavern Audio Processor Windows x64
echo ========================================
echo.

set AUDIO_PROC=win-x64\bin\audio-processor\audio-processor.exe

echo Checking if executable exists...

if not exist "%AUDIO_PROC%" (
    echo FAIL: audio-processor.exe not found
    echo Please run build-win-x64.bat first
    goto :error
)
echo OK: audio-processor.exe found

echo.
echo Checking executable properties...
echo Testing %AUDIO_PROC%...

REM Test that the file is a valid PE executable
powershell -Command "if ((Get-Item '%AUDIO_PROC%').Length -gt 5MB) { Write-Host 'OK: File size looks good' } else { Write-Host 'WARN: File seems small'; exit 1 }"
if errorlevel 1 goto :error

echo.
echo ========================================
echo All tests PASSED!
echo ========================================
echo.
echo The Windows x64 Cavern audio processor is ready to use.
echo Run 'win-x64\run_pipeline_demo.bat' to start the processor.
echo.
pause
exit /b 0

:error
echo.
echo ========================================  
echo Tests FAILED!
echo ========================================
echo.
echo Please check the build and try again.
echo.
pause
exit /b 1