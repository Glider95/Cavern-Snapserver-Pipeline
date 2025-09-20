# Configuration Guide

## Overview

The Cavern Snapserver Pipeline can be configured through environment variables, command-line arguments, and configuration files.

## Environment Variables

### LIVE_ALSA
Controls the audio input source.

```bash
# Use ALSA loopback for live capture (default)
LIVE_ALSA=1

# Expect external input to /tmp/dolby-in FIFO
LIVE_ALSA=0
```

**Usage Examples:**
```bash
# Live ALSA capture
sudo systemctl start cavern-pipeline

# External input mode (for demo/testing)
LIVE_ALSA=0 /opt/cavern-pipeline/run_pipeline.sh
```

### PULSE_SERVER
Configure PulseAudio server (if using PulseAudio).

```bash
# Local PulseAudio
PULSE_SERVER=127.0.0.1:9

# Remote PulseAudio
PULSE_SERVER=192.168.1.100:4713
```

## Audio Processor Configuration

The audio processor accepts command-line arguments for output format configuration.

### Syntax
```bash
audio-processor [output_channels] [codec]
```

### Parameters

- **output_channels**: Number of output channels (default: 2)
  - `2`: Stereo
  - `6`: 5.1 surround
  - `8`: 7.1 surround

- **codec**: Output codec (default: eac3)
  - `eac3`: Dolby Digital Plus
  - `dts`: DTS
  - `pcm`: Uncompressed PCM

### Examples

```bash
# 2-channel EAC3 (default)
audio-processor

# 2-channel EAC3 (explicit)
audio-processor 2 eac3

# 5.1 surround DTS
audio-processor 6 dts

# 7.1 surround PCM
audio-processor 8 pcm

# Only codec specified (default 2 channels)
audio-processor eac3
```

## ALSA Configuration

### Basic Loopback Setup

The `config/asound.conf.example` file provides a basic loopback configuration:

```conf
pcm.loopout { type hw card Loopback device 0 subdevice 0 }
pcm.loopin  { type hw card Loopback device 1 subdevice 0 }
pcm.!default { type plug slave.pcm "loopout" }
```

### Advanced ALSA Configuration

For more complex setups, you can extend the ALSA configuration:

```conf
# High-quality resampling
defaults.pcm.rate_converter "samplerate_best"

# Multiple loopback devices
pcm.loop1out { type hw card Loopback device 0 subdevice 0 }
pcm.loop1in  { type hw card Loopback device 1 subdevice 0 }
pcm.loop2out { type hw card Loopback device 0 subdevice 1 }
pcm.loop2in  { type hw card Loopback device 1 subdevice 1 }

# Software mixing
pcm.dmixer {
    type dmix
    ipc_key 1024
    slave.pcm "hw:0,0"
    slave.period_time 0
    slave.period_size 1024
    slave.buffer_size 4096
}
```

## Snapcast Configuration

### Server Configuration

The pipeline starts Snapserver with the following default configuration:

```bash
snapserver -c /dev/null \
  --stream.source="pipe:///tmp/snapcast-out?name=processed-dolby&mode=read&buffer_ms=3000&codec=opus&chunk_ms=20&stream.buffer=5000&stream.reconnect_interval=1000" \
  --server.control=1709 \
  --http.port=1781
```

### Configuration Parameters

- **buffer_ms**: Client-side buffer in milliseconds
- **codec**: Audio codec for streaming (opus, flac, pcm)
- **chunk_ms**: Audio chunk size in milliseconds
- **stream.buffer**: Stream buffer size
- **stream.reconnect_interval**: Reconnection interval in milliseconds

### Custom Snapcast Configuration

Create a custom configuration file:

```json
{
  "server": {
    "host": "0.0.0.0",
    "port": 1704,
    "control_port": 1709,
    "http": {
      "enabled": true,
      "port": 1781
    }
  },
  "streams": [
    {
      "name": "processed-dolby",
      "source": "pipe:///tmp/snapcast-out?mode=read",
      "codec": "opus",
      "buffer_ms": 3000
    }
  ]
}
```

## Systemd Service Configuration

### Service Parameters

Edit `/etc/systemd/system/cavern-pipeline.service`:

```ini
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
```

### Custom Environment Variables

Add additional environment variables to the service:

```ini
Environment=LIVE_ALSA=1
Environment=LOG_LEVEL=INFO
Environment=CAVERN_CHANNELS=8
Environment=CAVERN_CODEC=eac3
```

## Logging Configuration

### Log Locations

- **System service**: `journalctl -u cavern-pipeline`
- **Pipeline logs**: `/var/log/cavern/` or `/tmp/cavern_logs/`

### Individual Component Logs

- `cavern_pipe.log`: Cavern engine output
- `audio_processor.log`: Audio processor
- `arecord.log`: ALSA capture
- `pipe_input.log`: Input bridge
- `pipe_output.log`: Output bridge
- `snapserver_out.log`: Snapcast server

### Log Level Configuration

Modify the run_pipeline.sh script to adjust logging verbosity:

```bash
# Enable debug logging
export LOG_LEVEL=DEBUG

# Redirect stderr to separate files
command 2> "$LOG_DIR/component_debug.log"
```

## Network Configuration

### Firewall Rules

Open required ports for Snapcast:

```bash
# Allow Snapcast client connections
sudo ufw allow 1704/tcp

# Allow Snapcast control
sudo ufw allow 1709/tcp

# Allow web interface
sudo ufw allow 1781/tcp
```

### Multi-Interface Configuration

For systems with multiple network interfaces:

```bash
# Bind to specific interface
snapserver --server.host=192.168.1.100

# Bind to all interfaces
snapserver --server.host=0.0.0.0
```

## Performance Tuning

### Audio Latency

Reduce audio latency by adjusting buffer sizes:

```bash
# Smaller buffers = lower latency
--stream.buffer=2000
--buffer_ms=1000
--chunk_ms=10

# Larger buffers = more stability
--stream.buffer=8000
--buffer_ms=5000
--chunk_ms=40
```

### CPU Usage

Optimize for different CPU capabilities:

```bash
# Low CPU usage
audio-processor 2 pcm

# Higher quality processing
audio-processor 8 eac3
```

### Memory Usage

Adjust system limits for high-channel-count audio:

```ini
# In systemd service file
LimitNOFILE=65536
LimitMEMLOCK=infinity
```