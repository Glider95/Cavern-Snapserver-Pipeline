# Cavern Wireless - Setup Guide for New Agent

## Project Overview

**Goal**: Create a Dolby Atmos spatial audio pipeline for wireless speakers using:
- **Cavern** (.NET audio engine) - spatial audio rendering
- **Snapserver/Snapclient** - network audio distribution
- **truehdd** (Rust) - TrueHD → DAMF conversion
- **CavernPipe** - custom named pipe protocol

## Critical Architecture

### File-Based Mode (RECOMMENDED)
Instead of streaming audio data through pipes (which has container parsing issues), the client sends a **file path** to the server which opens the file directly.

**Protocol**: 
- Negative UpdateRate in handshake = file-based mode
- Client sends: `handshake (8 bytes) + path_length (4 bytes) + path_bytes (N bytes)`
- Server opens file directly, renders, streams PCM back

### Why File-Based Mode?
- Container formats (MKV, TrueHD) fail when streamed through SeekableQueueStream
- File-based mode uses AudioReader.Open(filePath) which works correctly
- Eliminates all streaming/buffering complexity

## Critical Fixes Required

### 1. CavernPipeRenderer.cs - ReadHeader() Fix
**Location**: `CavernSamples/Reusable/CavernPipeServer.Logic/CavernPipeRenderer.cs`

**CRITICAL**: Must add `reader.ReadHeader()` after opening AudioReader:
```csharp
AudioReader reader = AudioReader.Open(audioSource);
reader.ReadHeader(); // WITHOUT THIS: Cavern reports 0ch/0Hz
Renderer renderer = reader.GetRenderer();
```

### 2. CavernPipeProtocol.cs - File Mode Support
**Location**: `CavernSamples/Reusable/CavernPipeServer.Logic/CavernPipeProtocol.cs`

Add file-based mode detection:
```csharp
public bool IsFileBasedMode => UpdateRate < 0;

public CavernPipeProtocol(Stream source) {
    // ... existing code ...
    UpdateRate = source.ReadInt32();
    // Allow negative UpdateRate for file-based mode
    if (UpdateRate == 0) throw new SyncException();
    int absRate = UpdateRate < 0 ? -UpdateRate : UpdateRate;
    MandatoryBytesToSend = mandatoryFrames * OutputChannels * absRate * ((int)OutputFormat / 8);
}
```

### 3. PipeHandler.cs - Handle File Mode
**Location**: `CavernSamples/Reusable/CavernPipeServer.Logic/PipeHandler.cs`

In `ThreadProc()`, after creating renderer:
```csharp
if (renderer.Protocol.IsFileBasedMode) {
    // Read file path from client
    int pathLength = server.ReadInt32();
    byte[] pathBytes = new byte[pathLength];
    ReadAll(pathBytes, pathLength);
    
    // Write to Input for renderer to read
    renderer.Input.Write(BitConverter.GetBytes(pathLength), 0, 4);
    renderer.Input.Write(pathBytes, 0, pathLength);
    
    // Start renderer and pump output
    renderer.Start();
    await PumpOutputToClient(renderer, canceler.Token);
    continue;
}
```

### 4. CavernPipeClient - Dual Mode Support
**Location**: `Cavern-Snapserver-V2/src/CavernPipeClient/Program.cs`

Must support both modes:
- **File mode**: `args[0]` is file path → send negative UpdateRate
- **Streaming mode**: read stdin → send positive UpdateRate

```csharp
// Handshake format: [bitDepth(1), mandatoryFrames(1), channels(2), updateRate(4)]
// File mode: updateRate = -1024
// Stream mode: updateRate = 1024

byte[] handshake = new byte[8];
handshake[0] = bitDepth;
handshake[1] = 6; // mandatoryFrames
BitConverter.GetBytes((ushort)channels).CopyTo(handshake, 2);
BitConverter.GetBytes(isFileMode ? -1024 : 1024).CopyTo(handshake, 4);
```

## Component Locations

### Cavern (Upstream Repository)
```
Cavern/                          # Core audio engine
Cavern.Format/                   # Audio format support
CavernSamples/
  CavernPipeServer.Multiplatform/   # Server executable
  Reusable/CavernPipeServer.Logic/  # Server logic (PipeHandler, CavernPipeRenderer)
  CavernPipeClient/                 # Simple test client (original)
```

### Cavern-Snapserver-V2 (Your Integration)
```
Cavern-Snapserver-V2/
  src/
    CavernPipeClient/          # MODIFIED - Dual mode client
    PipeToFifo/                # Bridges client stdout to FIFO
  scripts/
    run.sh                     # Starts CavernPipeServer + Snapserver
    play.sh                    # Plays media files
    cavern-wireless.sh         # Main orchestration with TrueHD conversion
  config/
    snapserver.conf            # 6 channels: sampleformat=48000:16:6
```

### truehdd (External Dependency)
```
/tmp/truehdd/                  # Build from source
  target/release/truehdd       # Executable
```

## Build Instructions

### 1. Build Cavern Components
```bash
cd CavernSamples/CavernPipeServer.Multiplatform
dotnet build -c Release

# Copy Logic DLL to V2 bin folder
cp bin/Release/net8.0/CavernPipeServer.Logic.dll \
   ../../Cavern-Snapserver-V2/bin/CavernPipeServer/
```

### 2. Build V2 Components
```bash
cd Cavern-Snapserver-V2/src/CavernPipeClient
dotnet build -c Release

cd ../PipeToFifo
dotnet build -c Release
```

### 3. Build truehdd (if not exists)
```bash
cd /tmp
git clone https://github.com/alexdutton/truehdd.git
cd truehdd
cargo build --release
```

## Running the Pipeline

### Option 1: Using run.sh + play.sh (Development)
```bash
# Terminal 1: Start infrastructure
cd Cavern-Snapserver-V2
./scripts/run.sh

# Terminal 2: Play file
./scripts/play.sh /path/to/audio.mkv
# For DAMF files, play.sh uses file-based mode automatically
```

### Option 2: Using cavern-wireless.sh (Production)
```bash
# Auto-detects TrueHD, converts to DAMF, caches, plays
cd Cavern-Snapserver-V2
./scripts/cavern-wireless.sh ~/Downloads/Demos/demo.mkv
```

## Testing Individual Components

### Test File-Based Mode Directly
```bash
# Start server
cd CavernSamples/CavernPipeServer.Multiplatform
dotnet bin/Release/net8.0/CavernPipeServer.dll &

# Play DAMF file
cd Cavern-Snapserver-V2/src/CavernPipeClient
dotnet bin/Release/net8.0/CavernPipeClient.dll \
  ~/.cavern-wireless/cache/<hash>.atmos 6 16 > output.raw

# Should produce ~41MB for 72 seconds of 6ch/16-bit/48kHz audio
```

### Check Snapclient Connection
```bash
# Query snapserver status
curl http://127.0.0.1:1780/jsonrpc \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"Server.GetStatus","id":1}'

# Connect client
snapclient -h 127.0.0.1 -p 1704
```

## Cache Structure

Converted files stored in `~/.cavern-wireless/cache/`:
```
<md5_hash>.atmos           # DAMF header
<md5_hash>.atmos.audio     # PCM audio data
<md5_hash>.atmos.metadata  # Object position metadata
<md5_hash>.truehd          # Extracted TrueHD (temporary)
```

## Common Issues

### "Sync word check has failed"
- CavernPipeRenderer started before file path was written to Input
- Fix: Ensure PipeHandler writes path BEFORE calling renderer.Start()

### "No supported file format was detected"
- Missing `reader.ReadHeader()` call
- AudioReader reports 0 channels/0Hz without it

### "Invalid PCM length" in client
- Usually at end-of-stream, can be ignored
- Client should handle 0-length as EOF

### "Broken pipe"
- Server closed connection before client finished
- Check server logs for exceptions

### Snapclient not connecting
- Check `config/snapserver.conf` has `sampleformat=48000:16:6` (not :2)
- Verify snapserver is listening: `lsof -i :1704`

## File Locations Summary

| Component | Source | Build Output |
|-----------|--------|--------------|
| CavernPipeServer | `CavernSamples/CavernPipeServer.Multiplatform/` | `bin/Release/net8.0/` |
| CavernPipeClient | `Cavern-Snapserver-V2/src/CavernPipeClient/` | `bin/Release/net8.0/` |
| PipeToFifo | `Cavern-Snapserver-V2/src/PipeToFifo/` | `bin/Release/net8.0/` |
| CavernPipeServer.Logic | `CavernSamples/Reusable/CavernPipeServer.Logic/` | Must copy to both locations |

## Critical Files to Modify

1. **CavernSamples/Reusable/CavernPipeServer.Logic/CavernPipeRenderer.cs**
   - Add `reader.ReadHeader()`
   - Add `OpenFileFromPath()` method
   - Support both streaming and file-based modes

2. **CavernSamples/Reusable/CavernPipeServer.Logic/CavernPipeProtocol.cs**
   - Add `IsFileBasedMode` property
   - Accept negative UpdateRate

3. **CavernSamples/Reusable/CavernPipeServer.Logic/PipeHandler.cs**
   - Handle file-based mode handshake
   - Read file path, write to Input, start renderer, pump output

4. **Cavern-Snapserver-V2/src/CavernPipeClient/Program.cs**
   - Detect file vs streaming mode from args
   - Send appropriate handshake (negative/positive UpdateRate)

5. **Cavern-Snapserver-V2/config/snapserver.conf**
   - Set 6 channels: `sampleformat=48000:16:6`

6. **Cavern-Snapserver-V2/scripts/play.sh**
   - Detect `.atmos` extension
   - Use file-based mode for DAMF files
   - Use streaming mode for other formats

## Verification Steps

After setup, verify with:
```bash
# 1. Convert TrueHD to DAMF
truehdd decode --output-path ~/.cavern-wireless/cache/test \
  ~/.cavern-wireless/cache/<hash>.truehd

# 2. Test file-based mode directly
cd CavernSamples/CavernPipeServer.Multiplatform
dotnet bin/Release/net8.0/CavernPipeServer.dll &
cd Cavern-Snapserver-V2/src/CavernPipeClient
dotnet bin/Release/net8.0/CavernPipeClient.dll \
  ~/.cavern-wireless/cache/test.atmos 6 16 > /tmp/output.raw

# 3. Verify output size
ls -lh /tmp/output.raw  # Should be ~34MB for 62s audio

# 4. Test full pipeline with snapclient
./scripts/run.sh &
./scripts/play.sh ~/.cavern-wireless/cache/test.atmos
snapclient -h 127.0.0.1
```

## Notes for New Agent

- **Always copy CavernPipeServer.Logic.dll** after rebuilding Cavern
- The V2 `bin/CavernPipeServer/` folder has its own copy of the DLL
- File-based mode is the ONLY reliable way to play TrueHD/DAMF
- UpdateRate=1024 gives ~21ms latency (good balance)
- The protocol uses negative UpdateRate to signal file-based mode
- truehdd creates `.atmos`, `.atmos.audio`, `.atmos.metadata` files
