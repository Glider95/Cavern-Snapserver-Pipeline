@echo off
REM Build script for Windows x64 Cavern Snapserver Pipeline
echo Building Cavern Snapserver Pipeline for Windows x64...

REM Restore packages
dotnet restore
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to restore packages
    exit /b 1
)

REM Create output directories
if not exist "win-x64\bin\audio-processor" mkdir "win-x64\bin\audio-processor"
if not exist "win-x64\bin\PipeToFifo" mkdir "win-x64\bin\PipeToFifo"
if not exist "win-x64\bin\FifoToPipe" mkdir "win-x64\bin\FifoToPipe"

REM Build audio-processor for Windows x64
echo Building audio-processor...
dotnet publish audio-processor\audio-processor.csproj -c Release -r win-x64 --self-contained true -o win-x64\bin\audio-processor
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to build audio-processor
    exit /b 1
)

REM Build PipeToFifo for Windows x64
echo Building PipeToFifo...
dotnet publish PipeToFifo\PipeToFifo.csproj -c Release -r win-x64 --self-contained true -o win-x64\bin\PipeToFifo
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to build PipeToFifo
    exit /b 1
)

REM Build FifoToPipe for Windows x64
echo Building FifoToPipe...
dotnet publish FifoToPipe\FifoToPipe.csproj -c Release -r win-x64 --self-contained true -o win-x64\bin\FifoToPipe
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to build FifoToPipe
    exit /b 1
)

echo.
echo Build completed successfully!
echo Executables are located in win-x64\bin\
echo.
echo To run the pipeline:
echo 1. Start audio-processor: win-x64\bin\audio-processor\audio-processor.exe
echo 2. Use FifoToPipe to feed audio input
echo 3. Use PipeToFifo to get processed output
echo.
pause