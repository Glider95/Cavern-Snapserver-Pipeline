#!/usr/bin/env bash
set -euo pipefail
DEST="/opt/cavern-pipeline"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "Installing to $DEST ..."
sudo mkdir -p "$DEST"

# Copy binaries and main script
sudo cp -a "$REPO_ROOT/linux-arm64/bin" "$DEST/"
sudo cp "$REPO_ROOT/scripts/run_pipeline.sh" "$DEST/"
sudo chown -R root:root "$DEST"
sudo chmod +x "$DEST/run_pipeline.sh"

echo "Installing systemd unit ..."
sudo cp "$REPO_ROOT/config/cavern-pipeline.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cavern-pipeline.service
echo "Done. Start with: sudo systemctl start cavern-pipeline"

echo "Installing runtime dependencies ..."
sudo apt-get update
sudo apt-get install -y alsa-utils lsof snapserver snapclient ffmpeg netcat-openbsd

echo "Tip: Ensure ALSA loopback is loaded and aliases exist:"
echo "  sudo modprobe snd-aloop"
echo "  sudo cp $REPO_ROOT/config/asound.conf.example /etc/asound.conf"
echo
echo "If Kodi/VLC is feeding loopout, this service will render/process via Cavern."
