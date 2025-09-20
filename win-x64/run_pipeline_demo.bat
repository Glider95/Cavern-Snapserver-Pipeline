@echo off
REM Cavern Audio Processor - Windows x64 Demo
REM This demonstrates the Cavern spatial audio processor on Windows

echo ========================================
echo Cavern Audio Processor - Windows x64
echo ========================================
echo.

REM Check if executable exists
if not exist "win-x64\bin\audio-processor\audio-processor.exe" (
    echo ERROR: Windows x64 executable not found!
    echo Please run build-win-x64.bat first to build the executable.
    echo.
    pause
    exit /b 1
)

echo Starting Cavern Audio Processor...
echo.
echo The processor will create two Windows named pipes:
echo   - \\.\pipe\cavern-audio-input  (for incoming audio)
echo   - \\.\pipe\cavern-audio-output (for processed spatial audio)
echo.
echo Default settings: 2 channels, EAC3 codec
echo.

REM Start the audio processor in a visible window
start "Cavern Audio Processor" "win-x64\bin\audio-processor\audio-processor.exe" 2 eac3

echo Audio processor started in a new window.
echo.
echo ==========================================
echo Media Player Integration Instructions:
echo ==========================================
echo.
echo To use with media players, you need additional tools like FFmpeg:
echo.
echo 1. Stream FROM media player TO Cavern processor:
echo    ffmpeg -f dshow -i audio="Stereo Mix" -f data \\.\pipe\cavern-audio-input
echo.
echo 2. Stream FROM Cavern processor TO speakers/file:
echo    ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav output.wav
echo.
echo 3. Complete pipeline example:
echo    # Terminal 1: Start processor (already running)
echo    # Terminal 2: Feed audio from file
echo    ffmpeg -i movie.mkv -map 0:a:0 -f data \\.\pipe\cavern-audio-input
echo    # Terminal 3: Play processed audio
echo    ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - ^| ffplay -
echo.
echo For VLC/other players: Configure audio output to "Stereo Mix" 
echo or use virtual audio cables like VB-Cable.
echo.
echo Press any key to continue...
pause >nul