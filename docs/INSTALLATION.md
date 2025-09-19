# Installation Guide

## System Requirements

### Hardware
- ARM64 Linux system (Raspberry Pi 4 recommended)
- Minimum 2GB RAM
- Audio output device or network-connected speakers
- Optional: HDMI/optical input for surround sound sources

### Software Dependencies
- Linux kernel with ALSA support
- .NET Runtime (for audio processor)
- FFmpeg (for input processing)
- ALSA utilities
- Snapcast
- System utilities: lsof, netcat

## Installation Methods

### Method 1: Automated Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/Glider95/Cavern-Snapserver-Pipeline.git
cd Cavern-Snapserver-Pipeline

# Run the installation script
sudo scripts/install.sh
```

This will:
- Install all required dependencies
- Copy binaries to `/opt/cavern-pipeline`
- Install systemd service
- Configure ALSA loopback

### Method 2: Manual Installation

#### Step 1: Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    alsa-utils \
    lsof \
    snapserver \
    snapclient \
    ffmpeg \
    netcat-openbsd \
    dotnet-runtime-6.0
```

#### Step 2: Configure ALSA Loopback

```bash
# Load the loopback module
sudo modprobe snd-aloop

# Make it persistent
echo "snd-aloop" | sudo tee -a /etc/modules

# Configure ALSA aliases
sudo cp config/asound.conf.example /etc/asound.conf
```

#### Step 3: Install Pipeline

```bash
# Create installation directory
sudo mkdir -p /opt/cavern-pipeline

# Copy binaries and scripts
sudo cp -r linux-arm64/bin /opt/cavern-pipeline/
sudo cp scripts/run_pipeline.sh /opt/cavern-pipeline/
sudo chmod +x /opt/cavern-pipeline/run_pipeline.sh

# Set ownership
sudo chown -R root:root /opt/cavern-pipeline
```

#### Step 4: Install Service

```bash
# Install systemd service
sudo cp config/cavern-pipeline.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cavern-pipeline.service
```

## Verification

### Test ALSA Configuration

```bash
# List ALSA devices
aplay -l
arecord -l

# Test loopback
speaker-test -D loopout -c 2 -t sine
```

### Test Pipeline Components

```bash
# Check if binaries are executable
ls -la /opt/cavern-pipeline/bin/*/

# Test audio processor
/opt/cavern-pipeline/bin/audio-processor/audio-processor --help
```

### Start Service

```bash
# Start the service
sudo systemctl start cavern-pipeline

# Check status
sudo systemctl status cavern-pipeline

# View logs
journalctl -u cavern-pipeline -f
```

## Troubleshooting Installation

### Common Issues

1. **Missing .NET Runtime**
   ```bash
   # Install .NET 6.0 runtime
   wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt-get update
   sudo apt-get install -y dotnet-runtime-6.0
   ```

2. **ALSA Loopback Not Working**
   ```bash
   # Check if module is loaded
   lsmod | grep snd_aloop
   
   # Reload module
   sudo modprobe -r snd_aloop
   sudo modprobe snd-aloop
   ```

3. **Permission Issues**
   ```bash
   # Add user to audio group
   sudo usermod -a -G audio $USER
   
   # Set correct permissions
   sudo chown -R root:root /opt/cavern-pipeline
   sudo chmod +x /opt/cavern-pipeline/run_pipeline.sh
   ```

4. **Service Won't Start**
   ```bash
   # Check service logs
   journalctl -u cavern-pipeline --no-pager
   
   # Test manual execution
   sudo /opt/cavern-pipeline/run_pipeline.sh
   ```

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop cavern-pipeline
sudo systemctl disable cavern-pipeline
sudo rm /etc/systemd/system/cavern-pipeline.service
sudo systemctl daemon-reload

# Remove installation directory
sudo rm -rf /opt/cavern-pipeline

# Remove ALSA configuration (optional)
sudo rm /etc/asound.conf

# Remove loopback module from autoload (optional)
sudo sed -i '/snd-aloop/d' /etc/modules
```