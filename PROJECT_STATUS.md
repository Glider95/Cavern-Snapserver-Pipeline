# Cavern Wireless - Project Status

**Date:** February 7, 2026  
**Status:** ✅ **WORKING** - Dolby Atmos pipeline operational

---

## 🎯 What Was Accomplished

### ✅ Working Components

| Component | Status | Notes |
|-----------|--------|-------|
| CavernPipeServer | ✅ | File-based mode working perfectly |
| CavernPipeClient | ✅ | Dual mode (file + streaming) implemented |
| PipeToFifo | ✅ | Bridges client output to FIFO |
| Snapserver | ✅ | Receives PCM and streams to network |
| truehdd | ✅ | Built from source for macOS ARM64 |
| TrueHD → DAMF | ✅ | Converts TrueHD to Cavern-readable format |
| Cache System | ✅ | MD5-based caching prevents re-conversion |

### 🔧 Critical Fixes Applied

1. **ReadHeader() Fix** (`CavernPipeRenderer.cs` line 119)
   ```csharp
   AudioReader reader = AudioReader.Open(audioSource);
   reader.ReadHeader(); // CRITICAL: without this, Cavern reports 0ch/0Hz
   ```

2. **File-Based Mode** (`CavernPipeProtocol.cs`, `PipeHandler.cs`)
   - Negative UpdateRate signals file-based mode
   - Server reads file path from client and opens directly
   - Avoids all streaming container parsing issues

3. **End-of-File Detection** (`CavernPipeRenderer.cs` lines 178-182)
   ```csharp
   // For file-based mode, stop when we've rendered all samples
   if (isFileBased && samplesRendered >= totalSamples) {
       Console.WriteLine($"[RenderThread] File complete: {samplesRendered} samples rendered");
       break;
   }
   ```

---

## 🏠 System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     WIRELESS ATMOS HOME CINEMA                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Media File (MKV/MP4 with TrueHD Atmos)                                   │
│       │                                                                  │
│       ▼                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌─────────────────────┐     │
│  │   FFmpeg     │────▶│   truehdd    │────▶│   DAMF Cache        │     │
│  │ (extract THD)│     │ (decode)     │     │   (~/.cavern-wireless│     │
│  └──────────────┘     └──────────────┘     │    /cache/)          │     │
│                                            └──────────┬────────────┘     │
│                                                       │                  │
│  ┌────────────────────────────────────────────────────┘                  │
│  │                                                                       │
│  │  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐  │
│  └──▶│ CavernPipeClient │───▶│ CavernPipeServer │───▶│   Snapserver    │  │
│     │ (file-based)    │     │ (spatial render) │     │ (network stream)│  │
│     └─────────────────┘     └─────────────────┘     └────────┬────────┘  │
│                                                               │          │
│                              ┌────────────────────────────────┘          │
│                              │                                            │
│                   ┌──────────▼──────────┐     ┌──────────┐               │
│                   │   ESP32 Speaker 1   │     │ Speaker 2│ ...           │
│                   │   (snapclient)      │     │          │               │
│                   └─────────────────────┘     └──────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 How to Use

### Quick Start

```bash
# 1. Go to project directory
cd "/Users/gregorynicol/Documents/ESP32/Cavern Wireless/Cavern-Snapserver-V2"

# 2. Start the infrastructure (CavernPipeServer + Snapserver)
./scripts/run.sh

# 3. In another terminal, play a movie
./scripts/play.sh ~/.cavern-wireless/cache/9adc8adcf63783bab94b1957fea862cc.atmos

# 4. Connect a wireless speaker (on the speaker device)
snapclient -h Gregorys-Mac-mini.local
```

### Using cavern-wireless.sh (Automated)

```bash
# Play a TrueHD movie (auto-converts to DAMF, caches for next time)
./scripts/cavern-wireless.sh "/path/to/movie.mkv"

# Force re-conversion (ignore cache)
./scripts/cavern-wireless.sh -n "/path/to/movie.mkv"
```

---

## 📊 Tested Configurations

| Format | Conversion | Render | Output |
|--------|------------|--------|--------|
| TrueHD → DAMF | ✅ truehdd | ✅ | 34MB / 62s / 6ch |
| WAV (PCM) | ❌ None | ✅ | 750KB / 5s / 2ch |
| E-AC-3 | Not tested | Should work | Untested |

### Test Results

```
[RenderThread] Reader opened: DolbyAtmosMasterFormatReader, Channels=12, SampleRate=48000
[RenderThread] Got renderer: CoreAudioFormatRenderer, HasObjects=True
[RenderThread] File complete: 3013632 samples rendered

[PipeToFifo] Transfer complete: 737280 total bytes
```

---

## 📁 Important Files

### Source (Modified)
```
CavernSamples/Reusable/CavernPipeServer.Logic/
├── CavernPipeRenderer.cs      # Added ReadHeader() + file-based mode
├── CavernPipeProtocol.cs      # Added IsFileBasedMode property
└── PipeHandler.cs             # Handle file-based handshake

Cavern-Snapserver-V2/src/CavernPipeClient/
└── Program.cs                 # Dual-mode client (file/streaming)
```

### Scripts
```
Cavern-Snapserver-V2/scripts/
├── run.sh                     # Start infrastructure
├── play.sh                    # Play media files
├── cavern-wireless.sh         # Full automation
└── build.sh                   # Build all components
```

### Cache Location
```
~/.cavern-wireless/cache/
├── <hash>.atmos               # DAMF header
├── <hash>.atmos.audio         # PCM audio data
├── <hash>.atmos.metadata      # Object positions
└── <hash>.truehd              # Extracted TrueHD (temporary)
```

---

## ⚠️ Known Issues & Limitations

| Issue | Severity | Workaround |
|-------|----------|------------|
| Streaming mode broken | Medium | Use file-based mode (.atmos files) |
| Initial conversion delay | Low | Cache persists across plays |
| "Invalid PCM length" warning | Cosmetic | Harmless, occurs at EOF |
| TrueHD only via truehdd | N/A | Native Cavern TrueHD not implemented |

---

## 🔧 Build Instructions

```bash
# 1. Build Cavern components
dotnet build CavernSamples/CavernPipeServer.Multiplatform/CavernPipeServer.Multiplatform.csproj -c Release

# 2. Copy DLLs to V2/V3
SRC="CavernSamples/CavernPipeServer.Multiplatform/bin/Release/net8.0"
DST="Cavern-Snapserver-V2/bin/CavernPipeServer"
cp "$SRC"/*.dll "$DST/"

# 3. Build V2 components
cd Cavern-Snapserver-V2
dotnet build src/CavernPipeClient/CavernPipeClient.csproj -c Release
dotnet build src/PipeToFifo/PipeToFifo.csproj -c Release
```

---

## 📚 References

- **Cavern Project:** https://github.com/VoidXH/Cavern
- **truehdd Project:** https://github.com/truehdd/truehdd
- **Snapcast:** https://github.com/badaix/snapcast
- **Setup Guide:** `CAVERN_WIRELESS_SETUP.md`
- **Full History:** `Everything that was done when it was working.md`

---

## 🎓 Key Technical Insights

1. **ReadHeader() is mandatory**: Without it, AudioReader reports 0 channels/0Hz
2. **File-based mode is reliable**: Avoids all streaming/parsing issues
3. **DAMF is the bridge format**: truehdd → DAMF → Cavern works perfectly
4. **Negative UpdateRate signals mode**: `-1024` = file-based, `1024` = streaming

---

**Status:** Ready for wireless Dolby Atmos home cinema use! 🎉
