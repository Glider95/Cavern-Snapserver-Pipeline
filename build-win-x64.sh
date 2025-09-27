#!/bin/bash
# Build script for Windows x64 Cavern Audio Processor (cross-platform build)
set -euo pipefail

echo "Building Cavern Audio Processor for Windows x64..."

# Restore packages
echo "Restoring packages..."
dotnet restore
echo "Packages restored."

# Create output directory
mkdir -p "win-x64/bin/audio-processor"

# Build audio-processor for Windows x64
echo "Building audio-processor..."
dotnet publish audio-processor/audio-processor.csproj -c Release -r win-x64 --self-contained true -o win-x64/bin/audio-processor

echo ""
echo "Build completed successfully!"
echo "Executable is located in win-x64/bin/audio-processor/"
echo ""
echo "To run: win-x64/bin/audio-processor/audio-processor.exe [channels] [codec]"
echo "Example: win-x64/bin/audio-processor/audio-processor.exe 2 eac3"
echo ""