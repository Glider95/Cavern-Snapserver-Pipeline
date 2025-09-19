@echo off
REM Cavern Snapserver Pipeline - Windows x64 Demo Script
REM This script demonstrates the audio processing pipeline on Windows

echo ========================================
echo Cavern Snapserver Pipeline - Windows x64
echo ========================================
echo.

REM Check if executables exist
if not exist "win-x64\bin\audio-processor\audio-processor.exe" (
    echo ERROR: Windows x64 executables not found!
    echo Please run build-win-x64.bat first to build the executables.
    echo.
    pause
    exit /b 1
)

echo Step 1: Starting Audio Processor...
echo The audio processor will wait for input and output connections.
echo.

REM Start the audio processor with default settings (2 channels, EAC3 codec)
start "Audio Processor" /MIN "win-x64\bin\audio-processor\audio-processor.exe" 2 eac3

echo Step 2: Audio processor started in background window.
echo.
echo Manual Usage Instructions:
echo.
echo To use the pipeline, you need to:
echo.
echo 1. Feed audio input using FifoToPipe:
echo    win-x64\bin\FifoToPipe\FifoToPipe.exe ^<input_file_or_pipe^>
echo.
echo 2. Get processed output using PipeToFifo:
echo    win-x64\bin\PipeToFifo\PipeToFifo.exe ^<output_file_or_pipe^>
echo.
echo Example workflow:
echo    # Terminal 1: Start input feeder
echo    win-x64\bin\FifoToPipe\FifoToPipe.exe audio_input.raw
echo.
echo    # Terminal 2: Start output consumer  
echo    win-x64\bin\PipeToFifo\PipeToFifo.exe processed_output.raw
echo.
echo Note: On Windows, named pipes work differently than Linux FIFOs.
echo The pipeline uses Windows named pipes for inter-process communication.
echo.
echo Press any key to continue...
pause >nul
echo.
echo Pipeline is ready for connections!
echo Check the Audio Processor window for status messages.
echo.
pause