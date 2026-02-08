# Cavern-Snapserver-V3

**Official CavernPipe Protocol Integration for Wireless Audio Pipeline**

This project integrates the **official CavernPipe protocol** into a wireless audio pipeline, replacing the custom implementation with the maintained protocol from the Cavern team.

## Overview

The pipeline extracts audio from media files, processes it using the **official CavernPipeServer**, and distributes it wirelessly via **Snapserver** to network clients (e.g., ESP32 devices).

### Architecture

```
Media File (Dolby/DTS)
    ↓
FFmpeg (Extracts raw bitstream)
    ↓
CavernPipeClient (Official Protocol)
    ↓
CavernPipeServer (Official, Spatial Audio Processing)
    ↓
PipeToFifo (Bridges to Snapserver)
    ↓
Snapserver (Network Distribution)
    ↓
Snapclients (ESP32, etc.)
```

## Key Features

- **Official CavernPipe Protocol**: Uses the maintained protocol from the Cavern team.
- **Spatial Audio Processing**: Full Cavern audio engine with object-based audio support.
- **Lockstep Communication**: Reliable bidirectional communication between client and server.
- **Initial Burst Optimization**: Prevents decoder initialization deadlock.
- **Multi-Room Sync**: Snapcast network distribution for synchronized playback.

## Prerequisites

### macOS
```bash
brew install dotnet-sdk snapcast ffmpeg
```

### Linux
```bash
sudo apt-get install dotnet-sdk-8.0 snapserver snapclient ffmpeg
```

## Quick Start

### 1. Build the Pipeline
```bash
./scripts/build.sh
```

### 2. Start the Pipeline
```bash
# Terminal 1: Start CavernPipeServer and Snapserver
./scripts/run.sh
```

### 3. Play a File
```bash
# Terminal 2: Play a media file
./scripts/play.sh ~/Movies/demo.mkv
```

### 4. Connect a Client
```bash
# Terminal 3: Connect a Snapclient
snapclient -h 127.0.0.1
```

## Configuration

Default settings in `scripts/run.sh`:
- **Channels**: 2 (stereo)
- **Sample Rate**: 48000 Hz
- **Bit Depth**: 16-bit

Override with environment variables:
```bash
OUTPUT_CHANNELS=6 SAMPLE_RATE=96000 BIT_DEPTH=24 ./scripts/run.sh
```

## Documentation

- **[PROTOCOL.md](docs/PROTOCOL.md)**: Official CavernPipe protocol specification.
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**: Detailed troubleshooting guide.

## Project Structure

```
Cavern-Snapserver-V3/
├── README.md                    # Main documentation
├── scripts/
│   ├── build.sh                 # Build all components
│   ├── run.sh                   # Start pipeline (production)
│   ├── play.sh <file>           # Play media file
│   └── test.sh                  # End-to-end tests
├── docs/
│   ├── PROTOCOL.md              # Official CavernPipe protocol
│   └── TROUBLESHOOTING.md       # Troubleshooting guide
├── src/
│   ├── CavernPipeClient/        # Official protocol client
│   └── PipeToFifo/              # FIFO bridge to Snapserver
├── bin/
│   └── CavernPipeServer/        # Official CavernPipeServer
├── config/
│   └── snapserver.conf          # Snapserver configuration
└── logs/                        # Runtime logs
```

## Pipeline Flow

```
┌──────────┐
│  FFmpeg  │  Extracts raw Dolby/DTS bitstream
└────┬─────┘
     │ AC-3/E-AC-3/TrueHD
     ↓
┌────────────────────┐
│ CavernPipeClient   │  Official protocol: stdin ↔ CavernPipe socket
└────┬───────────────┘
     │ [Handshake] + [Length+Data] lockstep
     ↓
┌────────────────────┐
│ CavernPipeServer   │  Official spatial audio renderer
└────┬───────────────┘
     │ [Length+PCM] responses
     ↓
┌────────────────────┐
│ CavernPipeClient   │  Receives PCM → stdout
└────┬───────────────┘
     │ PCM stream
     ↓
┌────────────────────┐
│   PipeToFifo       │  Writes to FIFO
└────┬───────────────┘
     │ /tmp/snapcast-out
     ↓
┌────────────────────┐
│   Snapserver       │  Network distribution
└────┬───────────────┘
     │ TCP/1704
     ↓
┌────────────────────┐
│  Snapclients       │  Synchronized multi-room playback
└────────────────────┘
```

## Development

Built with:
- **.NET 8.0**: CavernPipeClient, PipeToFifo
- **CavernPipeServer**: Official spatial audio engine
- **Snapcast**: Network audio distribution
- **FFmpeg**: Media extraction

## Credits

- **Cavern Audio Engine**: [VoidXH/Cavern](https://github.com/VoidXH/Cavern)
- **Snapcast**: [badaix/snapcast](https://github.com/badaix/snapcast)

## License

- **CavernPipeClient, PipeToFifo**: MIT License
- **CavernPipeServer**: See Cavern license
- **Snapcast**: GPLv3
