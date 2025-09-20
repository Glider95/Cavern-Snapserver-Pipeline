#!/usr/bin/env bash
set -euo pipefail

# Detect if we're running from installed location or development directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/bin/CavernPipeServer.Multiplatform/CavernPipeServer" ]; then
    # Running from installed location (/opt/cavern-pipeline)
    BIN_DIR="$SCRIPT_DIR/bin"
elif [ -f "$(dirname "$SCRIPT_DIR")/linux-arm64/bin/CavernPipeServer.Multiplatform/CavernPipeServer" ]; then
    # Running from development directory
    BIN_DIR="$(dirname "$SCRIPT_DIR")/linux-arm64/bin"
else
    echo "ERROR: Cannot find binary directory. Please check installation."
    exit 1
fi

LOG_DIR="/var/log/cavern"  # system path if installed, fallback to /tmp
if [ ! -w "$(dirname "$LOG_DIR")" ]; then LOG_DIR="/tmp/cavern_logs"; fi
mkdir -p "$LOG_DIR"

echo "### Step 1: Cleanup ###"
PORTS=(1704 1705 1706 1707 1804 1805 1806 1807)
for PORT in "${PORTS[@]}"; do
  PID=$(lsof -ti tcp:$PORT 2>/dev/null || true)
  if [ -n "${PID:-}" ]; then kill -9 $PID || true; fi
done
pkill -f "CavernPipeServer.Multiplatform" >/dev/null 2>&1 || true
pkill -f "/tmp/dolby-in" >/dev/null 2>&1 || true
pkill -f "/tmp/snapcast-out" >/dev/null 2>&1 || true
rm -f /tmp/dolby-in /tmp/snapcast-out
mkdir -p "$LOG_DIR"
echo "Cleanup complete."

echo "### Step 2: FIFOs ###"
mkfifo /tmp/dolby-in || true
mkfifo /tmp/snapcast-out || true

echo "### Step 3: CavernPipe server ###"
"$BIN_DIR/CavernPipeServer.Multiplatform/CavernPipeServer" > "$LOG_DIR/cavern_pipe.log" 2>&1 &
CAVERN_PIPE_PID=$!
sleep 1

echo "### Step 4: Live ALSA capture (loopback) ###"
LIVE_ALSA="${LIVE_ALSA:-1}"
if [ "$LIVE_ALSA" = "1" ]; then
  # DD+/DD passthrough over 2ch/48k IEC61937
  arecord -D loopin -f S16_LE -c 2 -r 48000 -t raw > /tmp/dolby-in 2> "$LOG_DIR/arecord.log" &
  echo "arecord → /tmp/dolby-in"
else
  echo "LIVE_ALSA=0 set, expecting external writer to /tmp/dolby-in"
fi

echo "### Step 5: Audio Processor ###"
"$BIN_DIR/audio-processor/audio-processor" 2 eac3 > "$LOG_DIR/audio_processor.log" 2>&1 &
sleep 10

echo "### Step 6: Bridges ###"
"$BIN_DIR/PipeInputClient/PipeInputClient" /tmp/dolby-in > "$LOG_DIR/pipe_input.log" 2>&1 &
"$BIN_DIR/PipeToFifo/PipeToFifo" /tmp/snapcast-out > "$LOG_DIR/pipe_output.log" 2>&1 &

echo "### Step 7: Snapcast Output ###"
snapserver -c /dev/null --stream.source="pipe:///tmp/snapcast-out?name=processed-dolby&mode=read&buffer_ms=3000&codec=opus&chunk_ms=20&stream.buffer=5000&stream.reconnect_interval=1000" --server.control=1709 --http.port=1781 > "$LOG_DIR/snapserver_out.log" 2>&1 &

echo "Pipeline running. Logs: $LOG_DIR"
echo "Listen with: snapclient tcp://127.0.0.1:1704"
wait
