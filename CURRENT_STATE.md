# Current State - February 7, 2026

## What Has Been Done

### ✅ Working Components

1. **TrueHD to DAMF Conversion**
   - truehdd v0.4.0 built at `/tmp/truehdd/target/release/truehdd`
   - Converts TrueHD → DAMF format correctly
   - Cache system working at `~/.cavern-wireless/cache/`

2. **CavernPipeServer with File-Based Mode**
   - Modified `CavernPipeRenderer.cs` - Added `ReadHeader()` fix
   - Modified `CavernPipeProtocol.cs` - Supports negative UpdateRate
   - Modified `PipeHandler.cs` - Handles file-based mode
   - Builds successfully

3. **CavernPipeClient with Dual Mode**
   - File-based mode: `CavernPipeClient <file> <channels> <bitdepth>`
   - Streaming mode: `cat audio | CavernPipeClient <channels> <rate> <bitdepth>`
   - Builds successfully

4. **cavern-wireless.sh Script**
   - Auto-detects TrueHD codec
   - Extracts → converts → caches DAMF files
   - Fixed truehdd command format (`--output-path`)

### ⚠️ Partially Working

**Pipeline works but with issues:**
- File-based mode renders correctly (tested: 34MB/62s audio)
- PCM flows through FIFO to snapserver
- Snapclient connection works but may have sync issues

### ❌ Known Issues

1. **DLL Copy Problem**
   - `run.sh` uses `bin/CavernPipeServer/CavernPipeServer.Logic.dll` (old)
   - Build output goes to `bin/Release/net8.0/` (new)
   - Must copy DLL after each rebuild

2. "Invalid PCM length" at end-of-stream
   - Client error when server closes connection
   - Doesn't affect actual audio playback

3. SeekableQueueStream still broken
   - Container parsing fails in streaming mode
   - File-based mode is the workaround

## Test Commands That Work

```bash
# File-based mode (working)
cd CavernSamples/CavernPipeServer.Multiplatform
dotnet bin/Release/net8.0/CavernPipeServer.dll &

cd Cavern-Snapserver-V2/src/CavernPipeClient
dotnet bin/Release/net8.0/CavernPipeClient.dll \
  ~/.cavern-wireless/cache/9adc8adcf63783bab94b1957fea862cc.atmos \
  6 16 > /tmp/output.raw
# Result: 34MB file, 62 seconds of 6ch audio
```

## Files Modified

### Cavern (Upstream)
- `CavernSamples/Reusable/CavernPipeServer.Logic/CavernPipeRenderer.cs`
- `CavernSamples/Reusable/CavernPipeServer.Logic/CavernPipeProtocol.cs`
- `CavernSamples/Reusable/CavernPipeServer.Logic/PipeHandler.cs`

### Cavern-Snapserver-V2 (Integration)
- `src/CavernPipeClient/Program.cs` (complete rewrite)
- `scripts/cavern-wireless.sh` (new file)
- `scripts/play.sh` (modified for file-based mode)
- `scripts/run.sh` (default to 6 channels)
- `config/snapserver.conf` (6 channels)

## Cache Contents

```
~/.cavern-wireless/cache/
├── 52e52d61e236b1b7.atmos              # Working DAMF (62s)
├── 52e52d61e236b1b7.atmos.audio       # 159MB
├── 52e52d61e236b1b7.atmos.metadata    # 146KB
├── 9adc8adcf63783bab94b1957fea862cc.atmos         # Working DAMF (62s)
├── 9adc8adcf63783bab94b1957fea862cc.atmos.audio   # 103MB
├── 9adc8adcf63783bab94b1957fea862cc.atmos.metadata # 1.3MB
└── 9adc8adcf63783bab94b1957fea862cc.truehd        # 36MB (can delete)
```

## What Needs Fix

1. **Ensure DLL is copied after build**
   ```bash
   cp CavernSamples/CavernPipeServer.Multiplatform/bin/Release/net8.0/CavernPipeServer.Logic.dll \
      Cavern-Snapserver-V2/bin/CavernPipeServer/
   ```

2. **Test complete pipeline**
   ```bash
   ./scripts/run.sh
   ./scripts/play.sh ~/.cavern-wireless/cache/9adc8adcf63783bab94b1957fea862cc.atmos
   snapclient -h 127.0.0.1
   ```

3. **Verify audio output**
   - Check snapserver web UI: http://127.0.0.1:1780
   - Verify snapclient connects and receives audio

## Quick Verification

```bash
# 1. Check cache
ls -lh ~/.cavern-wireless/cache/*.atmos

# 2. Test file-based mode
cd CavernSamples/CavernPipeServer.Multiplatform
dotnet bin/Release/net8.0/CavernPipeServer.dll &
sleep 2

cd Cavern-Snapserver-V2/src/CavernPipeClient
dotnet bin/Release/net8.0/CavernPipeClient.dll \
  ~/.cavern-wireless/cache/9adc8adcf63783bab94b1957fea862cc.atmos \
  6 16 > /tmp/test.raw 2>&1

# Should produce ~34MB file
ls -lh /tmp/test.raw
```
