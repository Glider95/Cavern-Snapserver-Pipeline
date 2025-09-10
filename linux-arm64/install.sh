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
