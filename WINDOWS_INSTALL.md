# Cavern Audio Processor - Windows x64 Installation Guide

## Quick Start

1. **Download the repository** or get the `win-x64` folder
2. **No installation required** - executable is self-contained
3. **Run the demo**: Double-click `win-x64\run_pipeline_demo.bat`

## What's Included

```
win-x64/
├── bin/
│   └── audio-processor/
│       └── audio-processor.exe (12MB)    # Cavern spatial audio processor
├── run_pipeline_demo.bat                 # Simple demo launcher
├── run_pipeline.ps1                      # Advanced PowerShell script
└── README.md                             # Detailed documentation
```

## System Requirements

- **OS**: Windows 10/11 (x64)
- **RAM**: 100MB minimum  
- **CPU**: Any x64 processor
- **Dependencies**: None (self-contained)

## How It Works

The Cavern audio processor creates two Windows named pipes for spatial audio processing:

- `\\.\pipe\cavern-audio-input` (for incoming audio)
- `\\.\pipe\cavern-audio-output` (for processed spatial audio)

## Basic Usage

### Method 1: Demo Script (Easiest)
```batch
win-x64\run_pipeline_demo.bat
```

### Method 2: PowerShell (Advanced)
```powershell
win-x64\run_pipeline.ps1 -Channels 6 -Codec ac3
```

### Method 3: Manual (Expert)
```batch
win-x64\bin\audio-processor\audio-processor.exe [channels] [codec]
```

## Media Player Integration

### With FFmpeg (Recommended)

**1. Install FFmpeg** from https://ffmpeg.org/download.html

**2. Basic pipeline:**
```batch
# Terminal 1: Start processor
win-x64\bin\audio-processor\audio-processor.exe 2 eac3

# Terminal 2: Stream media file
ffmpeg -i movie.mkv -map 0:a:0 -f data \\.\pipe\cavern-audio-input

# Terminal 3: Play processed audio
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | ffplay -
```

**3. Save to file:**
```batch
ffmpeg -f data -i \\.\pipe\cavern-audio-output output.wav
```

### With VLC Media Player

**1. Install VB-Cable** (virtual audio cable) from https://vb-audio.com/Cable/

**2. Configure VLC:**
   - Tools → Preferences → Audio
   - Set Output to "CABLE Input"

**3. Capture and process VLC audio:**
```batch
# Terminal 1: Start processor
win-x64\bin\audio-processor\audio-processor.exe 2 eac3

# Terminal 2: Capture VLC output
ffmpeg -f dshow -i audio="CABLE Output" -f data \\.\pipe\cavern-audio-input

# Terminal 3: Play processed audio
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | ffplay -
```

### With Windows Media Player

**Use Stereo Mix (if available):**
```batch
# Enable Stereo Mix in Windows sound settings first
ffmpeg -f dshow -i audio="Stereo Mix" -f data \\.\pipe\cavern-audio-input
```

### Real-time System Audio Processing

For processing all system audio:

**1. Install Virtual Audio Cable software**

**2. Set as default Windows audio device**

**3. Capture and process:**
```batch
ffmpeg -f dshow -i audio="Your Virtual Cable" -f data \\.\pipe\cavern-audio-input
```

## Configuration Examples

### Stereo Processing
```batch
audio-processor.exe 2 eac3
```

### 5.1 Surround Sound
```batch
audio-processor.exe 6 eac3
```

### 7.1 Surround Sound
```batch
audio-processor.exe 8 eac3
```

## Troubleshooting

**Q**: "Could not connect to pipe"  
**A**: Make sure audio-processor.exe is running first

**Q**: "FFmpeg not recognized"  
**A**: Install FFmpeg and add to Windows PATH

**Q**: No audio in VLC method  
**A**: Check VB-Cable installation and VLC audio output settings

**Q**: Access denied errors  
**A**: Try running as Administrator

## Building from Source

If you want to build from source:

```batch
git clone https://github.com/Glider95/Cavern-Snapserver-Pipeline
cd Cavern-Snapserver-Pipeline
build-win-x64.bat
```

Requires .NET 8.0 SDK.

## Technical Details

- **Framework**: .NET 8.0
- **Architecture**: x64 only
- **Deployment**: Self-contained, single-file
- **Size**: ~12MB (includes .NET runtime)
- **Audio Processing**: Cavern spatial audio library
- **IPC**: Windows named pipes

## Advanced Usage

### Network Streaming
```batch
# Stream processed audio over network
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav tcp://192.168.1.100:4444
```

### Integration with Snapcast
```batch
# Feed to Snapcast server
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | snapserver --stream.source=pipe:///dev/stdin
```

### Gaming Audio Enhancement
```batch
# Process game audio (requires virtual audio cable)
audio-processor.exe 2 eac3
ffmpeg -f dshow -i audio="Game Audio" -f data \\.\pipe\cavern-audio-input
```

## Getting Help

- Check the detailed `win-x64\README.md`
- Review PowerShell script help: `win-x64\run_pipeline.ps1 -Help`
- Examine console output for error messages

---

**Note**: This Windows x64 build provides the same advanced Cavern spatial audio processing as the Linux version but optimized for Windows systems with native Windows named pipe support.