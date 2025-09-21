#!/usr/bin/env bash
set -euo pipefail

# macOS run script for Cavern-Snapserver-Pipeline
# This adapts the AudioWirelessPipeline macOS helper into this repo.

# --- Configuration ---
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CAVERN_PIPE_SERVER_PROJ="$ROOT_DIR/src/CavernPipeServer.Multiplatform/CavernPipeServer.Multiplatform.csproj"

# C# Project Paths
AUDIO_PROCESSOR_PROJ="$ROOT_DIR/src/audio-processor/audio-processor.csproj"
PIPE_TO_FIFO_PROJ="$ROOT_DIR/src/PipeToFifo/PipeToFifo.csproj"
PIPE_INPUT_CLIENT_PROJ="$ROOT_DIR/src/PipeInputClient/PipeInputClient.csproj"

# FIFOs
INPUT_FIFO=${INPUT_FIFO:-"/tmp/cavern_input.fifo"}
OUTPUT_FIFO=${OUTPUT_FIFO:-"/tmp/cavern_output.fifo"}

# Logs
LOG_DIR=${LOG_DIR:-"$ROOT_DIR/logs"}
mkdir -p "$LOG_DIR"

# Snapserver config location
SNAPSERVER_CONFIG=${SNAPSERVER_CONFIG:-"$LOG_DIR/snapserver.conf"}

# Input demo file (used by demo runner)
INPUT_FILE=${INPUT_FILE:-"$HOME/Downloads/Demos/demo.mkv"}

# Clean up on exit
pids=()
cleanup() {
  if [ ${#pids[@]} -gt 0 ]; then
    # Use kill -9 to ensure processes are terminated
    kill -9 "${pids[@]}" 2>/dev/null || true
  fi
  rm -f "$INPUT_FIFO" "$OUTPUT_FIFO"
}
trap cleanup EXIT

echo "Using ROOT_DIR=$ROOT_DIR"

echo "Creating FIFOs: $INPUT_FIFO $OUTPUT_FIFO"
rm -f "$INPUT_FIFO" "$OUTPUT_FIFO"
mkfifo "$INPUT_FIFO"
mkfifo "$OUTPUT_FIFO"

echo "Creating minimal snapserver config: $SNAPSERVER_CONFIG"
cat > "$SNAPSERVER_CONFIG" << EOF
# Minimal snapserver config for macOS
source = pipe://$OUTPUT_FIFO?name=Cavern
EOF

echo "Starting CavernPipeServer..."
dotnet build "$CAVERN_PIPE_SERVER_PROJ" >> "$LOG_DIR/cavernpipe.log" 2>&1
dotnet "$ROOT_DIR/src/CavernPipeServer.Multiplatform/bin/Debug/net8.0/CavernPipeServer.dll" >> "$LOG_DIR/cavernpipe.log" 2>&1 &
pids+=("$!")

sleep 1

echo "Starting AudioProcessor..."
dotnet build "$AUDIO_PROCESSOR_PROJ" >> "$LOG_DIR/audio-processor.log" 2>&1
dotnet "$ROOT_DIR/src/audio-processor/bin/Debug/net8.0/audio-processor.dll" >> "$LOG_DIR/audio-processor.log" 2>&1 &
pids+=("$!")

sleep 2

echo "Starting PipeToFifo bridge..."
dotnet build "$PIPE_TO_FIFO_PROJ" >> "$LOG_DIR/pipetofifo.log" 2>&1
dotnet "$ROOT_DIR/src/PipeToFifo/bin/Debug/net8.0/PipeToFifo.dll" "$OUTPUT_FIFO" >> "$LOG_DIR/pipetofifo.log" 2>&1 &
pids+=("$!")

echo "Starting PipeInputClient bridge..."
dotnet build "$PIPE_INPUT_CLIENT_PROJ" >> "$LOG_DIR/pipeinput.log" 2>&1
dotnet "$ROOT_DIR/src/PipeInputClient/bin/Debug/net8.0/PipeInputClient.dll" "$INPUT_FIFO" >> "$LOG_DIR/pipeinput.log" 2>&1 &
pids+=("$!")

echo "Starting Snapserver (using config $SNAPSERVER_CONFIG)"
snapserver -c "$SNAPSERVER_CONFIG" >> "$LOG_DIR/snapserver.log" 2>&1 &
pids+=("$!")

echo "Pipeline started. Logs are in $LOG_DIR"
echo "Press Ctrl+C to stop."

wait
