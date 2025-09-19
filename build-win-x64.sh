#!/bin/bash
# Build script for Windows x64 Cavern Snapserver Pipeline (cross-platform build)
set -euo pipefail

echo "Building Cavern Snapserver Pipeline for Windows x64..."

# Restore packages
echo "Restoring packages..."
dotnet restore
echo "Packages restored."

# Create output directories
mkdir -p "win-x64/bin/audio-processor"
mkdir -p "win-x64/bin/PipeToFifo"  
mkdir -p "win-x64/bin/FifoToPipe"

# Build audio-processor for Windows x64
echo "Building audio-processor..."
dotnet publish audio-processor/audio-processor.csproj -c Release -r win-x64 --self-contained true -o win-x64/bin/audio-processor

# Build PipeToFifo for Windows x64
echo "Building PipeToFifo..."
dotnet publish PipeToFifo/PipeToFifo.csproj -c Release -r win-x64 --self-contained true -o win-x64/bin/PipeToFifo

# Build FifoToPipe for Windows x64
echo "Building FifoToPipe..."
dotnet publish FifoToPipe/FifoToPipe.csproj -c Release -r win-x64 --self-contained true -o win-x64/bin/FifoToPipe

echo ""
echo "Build completed successfully!"
echo "Executables are located in win-x64/bin/"
echo ""
echo "To run the pipeline:"
echo "1. Start audio-processor: win-x64/bin/audio-processor/audio-processor.exe"
echo "2. Use FifoToPipe to feed audio input from files/streams"
echo "3. Use PipeToFifo to get processed output for streaming"
echo ""