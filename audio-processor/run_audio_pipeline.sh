#!/bin/bash

# --- Definitive Audio Pipeline Script v8 (Correct Porting) ---

LOG_DIR="/tmp/cavern_logs"

echo "### Step 1: Ultimate Cleanup ###"
# Corrected port list for cleanup
PORTS=(1704 1705 1706 1707 1804 1805 1806 1807)
for PORT in "${PORTS[@]}"; do
    PID=$(lsof -ti tcp:$PORT)
    if [ -n "$PID" ]; then kill -9 "$PID"; fi
done
pkill -f "dotnet run --project" >/dev/null 2>&1
rm -f /tmp/dolby-in /tmp/snapcast-out
rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"
echo "Cleanup complete."
echo

# --- Step 2: FIFOs ---
echo "### Step 2: Creating FIFOs..."
mkfifo /tmp/dolby-in
mkfifo /tmp/snapcast-out
echo "FIFOs created."
echo

echo "### Step 3: Starting CavernPipe server..."
dotnet run --project /Users/gregorynicol/Documents/ESP32/Cavern/CavernSamples/CavernPipeServer.Multiplatform > "$LOG_DIR/cavern_pipe.log" 2>&1 &
CAVERN_PIPE_PID=$!
sleep 2

# --- Step 3 & 4: Live ALSA capture from loopback instead of Snapcast demo ---
if [ "${LIVE_ALSA:-1}" = "1" ]; then
  echo "### Live capture from ALSA loopback → /tmp/dolby-in ..."
  # For DD+/DD passthrough (IEC61937 over 2ch/48k)
  arecord -D loopin -f S16_LE -c 2 -r 48000 -t raw > /tmp/dolby-in 2> "$LOG_DIR/arecord.log" &
  echo "arecord is feeding /tmp/dolby-in"
else
  # Fallback: Snapcast demo source (original behavior)
  echo "### Step 3 & 4: Starting Snapcast Input..."
  snapserver \
    -c /dev/null \
    --stream.source="file:///Users/gregorynicol/Downloads/Demos/demo.mkv?name=dolby" \
    --server.port=1807 \
    --server.control=1805 \
    --tcp.port=1806 > /dev/null 2>&1 &
  while ! nc -z 127.0.0.1 1806; do sleep 0.1; done
  snapclient "tcp://127.0.0.1:1806" --player file:/tmp/dolby-in > /dev/null 2>&1 &
  echo "Snapcast input is running, streaming on port 1806."
fi

echo "### Step 5: Starting Audio Processor (Server)..."
# For live DD+/DD passthrough, keep codec as eac3 (or ac3)
dotnet run --project /Users/gregorynicol/Documents/ESP32/Cavern/audio-processor 2 eac3 > "$LOG_DIR/audio_processor.log" 2>&1 &
sleep 1
echo "Audio Processor is running."
echo

# --- Step 6: Bridge Clients ---
echo "### Step 6: Starting Bridge Clients..."
dotnet run --project /Users/gregorynicol/Documents/ESP32/Cavern/PipeInputClient /tmp/dolby-in > "$LOG_DIR/pipe_input.log" 2>&1 &
dotnet run --project /Users/gregorynicol/Documents/ESP32/Cavern/PipeToFifo /tmp/snapcast-out > "$LOG_DIR/pipe_output.log" 2>&1 &
echo "Bridges are running."
echo

# --- Step 7: Snapcast Output (Silently) ---
echo "### Step 7: Starting Snapcast Output..."
snapserver \
  -c /dev/null \
  --stream.source="pipe:///tmp/snapcast-out?name=processed-dolby&mode=read" \
  --server.port=1707 \
  --server.control=1705 \
  --tcp.port=1704 > /dev/null 2>&1 & # The final streaming port is 1704
echo "Snapcast output is running, streaming on port 1704."
echo

# ---

echo "### Pipeline is running! ###"
echo "The terminal is now clean. All components are running in the background."
echo "To listen to the processed audio, run:"
# Corrected final instruction
echo "snapclient tcp://127.0.0.1:1706"
echo
echo "To monitor logs, run:"
echo "tail -f $LOG_DIR/*.log"