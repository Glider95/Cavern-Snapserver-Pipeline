#!/usr/bin/env bash
set -euo pipefail

# Demo runner for macOS: loops MPV to stream a demo file into the pipeline input FIFO.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INPUT_FIFO=${INPUT_FIFO:-"/tmp/cavern_input.fifo"}
LOG_DIR=${LOG_DIR:-"$HOME/cavern_logs"}
mkdir -p "$LOG_DIR"

INPUT_FILE=${INPUT_FILE:-"$HOME/Downloads/Demos/demo.mkv"}

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: Demo input file not found: $INPUT_FILE" >&2
  exit 1
fi

if [ ! -p "$INPUT_FIFO" ]; then
  echo "ERROR: Input FIFO does not exist: $INPUT_FIFO" >&2
  echo "Run run_pipeline_macos.sh first to create FIFOs and start the pipeline."
  exit 1
fi

echo "Starting demo MPV loop. Writing to $INPUT_FIFO"
while true; do
  echo "Starting MPV -> $INPUT_FIFO"
  mpv --log-file="$LOG_DIR/mpv.log" --ao=null --aid=2 --audio-spdif=ac3,eac3,truehd --stream-dump="$INPUT_FIFO" "$INPUT_FILE"
  echo "MPV exited. Restarting in 1s..."
  sleep 1
done
