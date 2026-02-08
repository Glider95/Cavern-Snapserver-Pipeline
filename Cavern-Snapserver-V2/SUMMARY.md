# Cavern-Snapserver-V2

Clean, production-ready spatial audio pipeline.

## Project Structure

```
Cavern-Snapserver-V2/
├── README.md                    # Main documentation
├── scripts/
│   ├── build.sh                 # Build all components
│   ├── run.sh                   # Start pipeline (production)
│   ├── play.sh <file>           # Play media file
│   └── test.sh                  # End-to-end tests
├── docs/
│   ├── PROTOCOL.md              # CavernPipe protocol specification
│   └── TROUBLESHOOTING.md       # Detailed troubleshooting
├── src/
│   ├── CavernPipeClient/        # Protocol bridge (C#)
│   └── PipeToFifo/              # FIFO writer (C#)
├── bin/
│   └── CavernPipeServer/        # Cavern renderer (pre-built)
├── config/
│   └── snapserver.conf          # Snapserver configuration
└── logs/                        # Runtime and build logs
```

## Quick Reference

### Build
```bash
./scripts/build.sh
```

### Run Pipeline
```bash
# Terminal 1
./scripts/run.sh

# Terminal 2  
./scripts/play.sh ~/Movies/demo.mkv
```

### Test
```bash
./scripts/test.sh
```

## Pipeline Flow

```
┌──────────┐
│  FFmpeg  │  Extracts raw Dolby/DTS bitstream
└────┬─────┘
     │ AC-3/E-AC-3/TrueHD
     ↓
┌────────────────────┐
│ CavernPipeClient   │  Protocol bridge: stdin ↔ CavernPipe socket
└────┬───────────────┘
     │ [Handshake] + [Length+Data] lockstep
     ↓
┌────────────────────┐
│ CavernPipeServer   │  Spatial audio renderer (Cavern engine)
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

## Key Features

- **Auto-codec detection**: AC-3, E-AC-3, TrueHD, DTS automatically recognized
- **Spatial rendering**: Full Cavern audio engine with object-based audio support
- **Lockstep protocol**: Reliable bidirectional communication
- **Initial burst**: Prevents decoder initialization deadlock
- **Multi-room sync**: Snapcast network distribution
- **Comprehensive logging**: All components log to `logs/`

## Configuration

Default settings in `scripts/run.sh`:
- **Channels**: 2 (stereo)
- **Sample Rate**: 48000 Hz
- **Bit Depth**: 16-bit

Override with environment variables:
```bash
OUTPUT_CHANNELS=6 SAMPLE_RATE=96000 ./scripts/run.sh
```

## Documentation

- **README.md**: Overview and quick start
- **docs/PROTOCOL.md**: CavernPipe protocol specification
- **docs/TROUBLESHOOTING.md**: Detailed troubleshooting guide

## Development

Built with:
- **.NET 8.0**: CavernPipeClient, PipeToFifo
- **Cavern**: Spatial audio engine
- **Snapcast**: Network audio distribution
- **FFmpeg**: Media extraction

## Credits

- [VoidXH/Cavern](https://github.com/VoidXH/Cavern) - Spatial audio engine
- [badaix/snapcast](https://github.com/badaix/snapcast) - Multi-room audio
