#!/usr/bin/env bash
set -euo pipefail

# Usage: audio-processor/packing.sh [linux-arm64|linux-arm] (default: linux-arm64)
RID="${1:-linux-arm64}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/dist/$RID"
BIN="$OUT/bin"

PROJECTS=(
  "CavernSamples/CavernPipeServer.Multiplatform"
  "audio-processor"
  "PipeInputClient"
  "PipeToFifo"
)

echo "==> Publishing for $RID..."
rm -rf "$OUT"
mkdir -p "$BIN"

for PROJ in "${PROJECTS[@]}"; do
  NAME="$(basename "$PROJ")"
  echo " -> $NAME"
  dotnet publish "$ROOT/$PROJ" -c Release -r "$RID" --self-contained true \
    -p:PublishSingleFile=true -p:PublishTrimmed=false \
    -o "$BIN/$NAME"
  chmod +x "$BIN/$NAME/"* || true
done

# Create runtime script (relative-path aware)
cat > "$OUT/run_pipeline.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
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
"$DIR/bin/CavernPipeServer.Multiplatform/CavernPipeServer" > "$LOG_DIR/cavern_pipe.log" 2>&1 &
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
"$DIR/bin/audio-processor/audio-processor" 2 eac3 > "$LOG_DIR/audio_processor.log" 2>&1 &
sleep 1

echo "### Step 6: Bridges ###"
"$DIR/bin/PipeInputClient/PipeInputClient" /tmp/dolby-in > "$LOG_DIR/pipe_input.log" 2>&1 &
"$DIR/bin/PipeToFifo/PipeToFifo" /tmp/snapcast-out > "$LOG_DIR/pipe_output.log" 2>&1 &

echo "### Step 7: Snapcast Output ###"
snapserver \
  -c /dev/null \
  --stream.source="pipe:///tmp/snapcast-out?name=processed-dolby&mode=read" \
  --server.port=1707 \
  --server.control=1705 \
  --tcp.port=1704 > "$LOG_DIR/snapserver_out.log" 2>&1 &

echo "Pipeline running. Logs: $LOG_DIR"
echo "Listen with: snapclient tcp://127.0.0.1:1704"
wait
SH
chmod +x "$OUT/run_pipeline.sh"

# systemd unit
cat > "$OUT/cavern-pipeline.service" << 'UNIT'
[Unit]
Description=Cavern Dolby pipeline
Wants=network-online.target
After=network-online.target sound.target

[Service]
Type=simple
User=pi
Group=audio
Environment=LIVE_ALSA=1
Environment=PULSE_SERVER=127.0.0.1:9
ExecStart=/opt/cavern-pipeline/run_pipeline.sh
Restart=on-failure
RestartSec=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UNIT

# Installer for Raspberry Pi
cat > "$OUT/install.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail
DEST="/opt/cavern-pipeline"
SRC="$(cd "$(dirname "$0")" && pwd)"
echo "Installing to $DEST ..."
sudo mkdir -p "$DEST"
sudo cp -a "$SRC/"* "$DEST/"
sudo chown -R root:root "$DEST"
sudo chmod +x "$DEST/run_pipeline.sh"

echo "Installing systemd unit ..."
sudo cp "$SRC/cavern-pipeline.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cavern-pipeline.service
echo "Done. Start with: sudo systemctl start cavern-pipeline"

echo "Installing runtime dependencies ..."
sudo apt-get update
sudo apt-get install -y alsa-utils lsof snapserver snapclient ffmpeg netcat-openbsd

echo "Tip: Ensure ALSA loopback is loaded and aliases exist:"
echo "  sudo modprobe snd-aloop"
echo "  sudo tee /etc/asound.conf >/dev/null <<'EOF'"
echo "pcm.loopout { type hw card Loopback device 0 subdevice 0 }"
echo "pcm.loopin  { type hw card Loopback device 1 subdevice 0 }"
echo "pcm.!default { type plug slave.pcm \"loopout\" }"
echo "EOF"
echo
echo "If Kodi/VLC is feeding loopout, this service will render/process via Cavern."
SH
chmod +x "$OUT/install.sh"

echo "==> Package ready: $OUT"
echo "Copy to Pi and install, e.g.:"
echo "  scp -r \"$OUT\" pi@raspberrypi:/tmp/"
echo "  ssh pi@raspberrypi " 