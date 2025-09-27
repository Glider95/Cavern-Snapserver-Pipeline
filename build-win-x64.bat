@echo off
REM Build script for Windows x64 Cavern Audio Processor
echo Building Cavern Audio Processor for Windows x64...

REM Restore packages
dotnet restore
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to restore packages
    exit /b 1
)

REM Create output directory
if not exist "win-x64\bin\audio-processor" mkdir "win-x64\bin\audio-processor"

REM Build audio-processor for Windows x64
echo Building audio-processor...
dotnet publish audio-processor\audio-processor.csproj -c Release -r win-x64 --self-contained true -o win-x64\bin\audio-processor
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to build audio-processor
    exit /b 1
)

echo.
echo Build completed successfully!
echo Executable is located in win-x64\bin\audio-processor\
echo.
echo To run: win-x64\bin\audio-processor\audio-processor.exe [channels] [codec]
echo Example: win-x64\bin\audio-processor\audio-processor.exe 2 eac3
echo.
pause