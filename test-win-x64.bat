@echo off
REM Simple test script to verify Windows x64 Cavern pipeline components

echo ========================================
echo Testing Cavern Pipeline Windows x64
echo ========================================
echo.

set AUDIO_PROC=win-x64\bin\audio-processor\audio-processor.exe
set FIFO_TO_PIPE=win-x64\bin\FifoToPipe\FifoToPipe.exe  
set PIPE_TO_FIFO=win-x64\bin\PipeToFifo\PipeToFifo.exe

echo Checking if executables exist...

if not exist "%AUDIO_PROC%" (
    echo FAIL: audio-processor.exe not found
    echo Please run build-win-x64.bat first
    goto :error
)
echo OK: audio-processor.exe found

if not exist "%FIFO_TO_PIPE%" (
    echo FAIL: FifoToPipe.exe not found
    goto :error
)
echo OK: FifoToPipe.exe found

if not exist "%PIPE_TO_FIFO%" (
    echo FAIL: PipeToFifo.exe not found
    goto :error
)
echo OK: PipeToFifo.exe found

echo.
echo Checking executable properties...

for %%f in ("%AUDIO_PROC%" "%FIFO_TO_PIPE%" "%PIPE_TO_FIFO%") do (
    echo Testing %%f...
    "%~f0\..\test_exe.bat" "%%f"
    if errorlevel 1 goto :error
)

echo.
echo ========================================
echo All tests PASSED!
echo ========================================
echo.
echo The Windows x64 Cavern pipeline is ready to use.
echo Run 'win-x64\run_pipeline_demo.bat' to start the pipeline.
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