# Cavern Snapserver Pipeline

A comprehensive audio processing pipeline that integrates Cavern spatial audio processing with Snapcast for multi-room audio streaming. This system enables high-quality surround sound processing and distribution across multiple devices.

## Overview

The Cavern Snapserver Pipeline is designed to:
- Process surround sound audio using the Cavern audio engine
- Stream processed audio via Snapcast for synchronized multi-room playback
- Support multiple audio codecs including EAC3 (Dolby Digital Plus)
- Provide real-time audio processing with minimal latency

## Architecture

```
Input Audio → Audio Processor → Cavern Engine → Output Pipeline → Snapserver → Clients
     ↓              ↓               ↓              ↓            ↓         ↓
[ALSA/FIFO] → [Named Pipes] → [Spatial Audio] → [Named Pipes] → [Network] → [Devices]
```

### Components

1. **Audio Processor** (`src/audio-processor/`): Core C# application that handles audio format conversion and communicates with the Cavern engine
2. **Pipe Utilities** (`src/pipe-utilities/`): Helper applications for data flow between components
3. **Pipeline Scripts** (`scripts/`): Shell scripts for system orchestration and deployment
4. **Configuration** (`config/`): System configuration files and examples

## Directory Structure

```
├── src/                        # Source code
│   ├── audio-processor/        # Main audio processing application
│   │   ├── Program.cs          # Entry point and pipeline coordination
│   │   └── AudioConverter.cs   # Audio format conversion and stream handling
│   └── pipe-utilities/         # Helper utilities for data flow
│       ├── FifoToPipe.cs      # FIFO to named pipe bridge
│       └── PipeToFifo.cs      # Named pipe to FIFO bridge
├── scripts/                    # System scripts
│   ├── demo_run_pipeline.sh   # Demo/testing script
│   ├── install.sh             # System installation script
│   └── run_pipeline.sh        # Main pipeline execution script
├── config/                     # Configuration files
│   ├── asound.conf.example    # ALSA configuration example
│   └── cavern-pipeline.service # Systemd service configuration
├── linux-arm64/               # Platform-specific binaries and deployment
│   └── bin/                   # Compiled binaries for ARM64 Linux
└── docs/                       # Documentation
```

## Prerequisites

- Linux ARM64 system (Raspberry Pi 4 recommended)
- .NET Runtime (for audio processor)
- ALSA utilities
- Snapcast (snapserver and snapclient)
- FFmpeg
- ALSA loopback module

## Installation

### Quick Install (Raspberry Pi)

```bash
# Clone the repository
git clone https://github.com/Glider95/Cavern-Snapserver-Pipeline.git
cd Cavern-Snapserver-Pipeline

# Run the installation script
sudo scripts/install.sh
```

### Manual Setup

1. **Install dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y alsa-utils lsof snapserver snapclient ffmpeg netcat-openbsd
   ```

2. **Configure ALSA loopback:**
   ```bash
   sudo modprobe snd-aloop
   sudo cp config/asound.conf.example /etc/asound.conf
   ```

3. **Install the pipeline:**
   ```bash
   sudo mkdir -p /opt/cavern-pipeline
   sudo cp -r linux-arm64/* /opt/cavern-pipeline/
   sudo cp scripts/run_pipeline.sh /opt/cavern-pipeline/
   sudo chmod +x /opt/cavern-pipeline/run_pipeline.sh
   ```

4. **Install systemd service:**
   ```bash
   sudo cp config/cavern-pipeline.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable cavern-pipeline.service
   ```

## Usage

### Starting the Service

```bash
# Start the service
sudo systemctl start cavern-pipeline

# Check status
sudo systemctl status cavern-pipeline

# View logs
journalctl -u cavern-pipeline -f
```

### Manual Execution

```bash
# Run the pipeline manually
sudo /opt/cavern-pipeline/run_pipeline.sh

# Or with custom settings
LIVE_ALSA=0 /opt/cavern-pipeline/run_pipeline.sh
```

### Demo Mode

For testing with a sample file:

```bash
# Run the demo script (requires demo.mkv file)
scripts/demo_run_pipeline.sh
```

### Client Connection

Connect audio clients to the Snapcast server:

```bash
# On the same device
snapclient

# On remote devices
snapclient -h <server-ip>
```

## Configuration

### Environment Variables

- `LIVE_ALSA=1`: Use ALSA loopback for live audio capture (default)
- `LIVE_ALSA=0`: Expect external input to `/tmp/dolby-in` FIFO

### Audio Processing Parameters

The audio processor supports command-line arguments:

```bash
audio-processor [output_channels] [codec]

# Examples:
audio-processor 2 eac3          # 2-channel EAC3 output
audio-processor 8 dts           # 8-channel DTS output
audio-processor eac3            # Default 2-channel EAC3
```

### ALSA Configuration

The system uses ALSA loopback devices. The example configuration in `config/asound.conf.example` sets up:
- `loopout`: Output device for applications (Kodi, VLC, etc.)
- `loopin`: Input device for the pipeline
- Default PCM redirected to `loopout`

## Troubleshooting

### Common Issues

1. **Audio not processing:**
   - Check ALSA loopback module: `lsmod | grep snd_aloop`
   - Verify ALSA configuration: `aplay -l` and `arecord -l`

2. **Service fails to start:**
   - Check logs: `journalctl -u cavern-pipeline`
   - Verify file permissions and paths
   - Ensure all dependencies are installed

3. **No audio output:**
   - Test Snapcast connection: `snapclient -h 127.0.0.1`
   - Check pipeline logs in `/var/log/cavern/` or `/tmp/cavern_logs/`

### Log Locations

- System service logs: `journalctl -u cavern-pipeline`
- Pipeline logs: `/var/log/cavern/` or `/tmp/cavern_logs/`
- Individual component logs:
  - `cavern_pipe.log`: Cavern engine output
  - `audio_processor.log`: Audio processor output
  - `snapserver_out.log`: Snapcast server output

## Development

### Building from Source

The source code is written in C# and can be built using .NET:

```bash
# Audio processor
cd src/audio-processor
dotnet build

# Pipe utilities
cd src/pipe-utilities
dotnet build
```

### Architecture Details

The pipeline uses named pipes for inter-process communication:
- `cavern-audio-input`: Input to audio processor
- `cavern-audio-output`: Output from audio processor

Data flow:
1. Audio input (ALSA/FIFO) → `PipeInputClient` → `cavern-audio-input`
2. `audio-processor` processes audio via Cavern engine
3. `cavern-audio-output` → `PipeToFifo` → `/tmp/snapcast-out`
4. Snapserver streams from `/tmp/snapcast-out` to network clients

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the existing code style
4. Test thoroughly on target hardware
5. Submit a pull request

## License

[License information to be added]

## Acknowledgments

- [Cavern Audio Engine](https://github.com/VoidXH/Cavern) for spatial audio processing
- [Snapcast](https://github.com/badaix/snapcast) for synchronized audio streaming