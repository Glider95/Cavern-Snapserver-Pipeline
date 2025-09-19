#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "### Step 1: Comprehensive Cleanup ###"
# Kill all running pipeline components and remove temporary files/logs
pkill -f ffmpeg || true
pkill -f snapserver || true
pkill -f CavernPipeServer.Multiplatform || true
pkill -f audio-processor || true
pkill -f PipeInputClient || true
pkill -f PipeToFifo || true
rm -f /tmp/dolby-in /tmp/snapcast-out /tmp/CoreFxPipe_CavernPipe || true
rm -rf /tmp/cavern_logs || true
echo "Cleanup complete."

echo "### Step 2: Start Audio Pipeline (run_pipeline.sh) ###"
# Start the main pipeline script in the background, redirecting output to a log file.
# LIVE_ALSA=0 ensures ffmpeg is used as input instead of ALSA capture.
LIVE_ALSA=0 "$REPO_ROOT/scripts/run_pipeline.sh" > /tmp/run_pipeline.log 2>&1 &
echo "Audio pipeline started. Logs: /tmp/run_pipeline.log"

# Give the pipeline a moment to initialize
sleep 2

echo "### Step 3: Start FFmpeg Stream ###"
# Start ffmpeg to stream audio from demo.mkv directly to /tmp/dolby-in.
# -y: Overwrite output files without asking.
# -re: Read input at native frame rate.
# -stream_loop -1: Loop the input indefinitely.
# -map 0:a:2: Select the third audio stream (index 2) from the input.
# -c copy: Copy the audio stream without re-encoding.
# -f data: Output raw data.
# /tmp/dolby-in: Output to the named pipe.
# Note: Update the path to your demo file as needed
ffmpeg -y -re -stream_loop -1 -i "$HOME/Downloads/demo.mkv" -map 0:a:2 -c copy -f data /tmp/dolby-in > /tmp/ffmpeg_stream.log 2>&1 &
echo "FFmpeg streaming started. Logs: /tmp/ffmpeg_stream.log"

echo "Pipeline fully operational. Listen with: snapclient tcp://127.0.0.1:1704"
