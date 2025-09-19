# Cavern Snapserver Pipeline - Windows x64 Installation Guide

## Quick Start

1. **Download the repository** or get the `win-x64` folder
2. **No installation required** - all executables are self-contained
3. **Run the demo**: Double-click `win-x64\run_pipeline_demo.bat`

## What's Included

```
win-x64/
├── bin/
│   ├── audio-processor/
│   │   └── audio-processor.exe (12MB)  # Main Cavern spatial audio engine
│   ├── FifoToPipe/
│   │   └── FifoToPipe.exe (12MB)       # Audio input client
│   └── PipeToFifo/
│       └── PipeToFifo.exe (12MB)       # Audio output client
├── run_pipeline_demo.bat               # Simple demo launcher
├── run_pipeline.ps1                    # Advanced PowerShell script
└── README.md                           # Detailed documentation
```

## System Requirements

- **OS**: Windows 10/11 (x64)
- **RAM**: 100MB minimum  
- **CPU**: Any x64 processor
- **Dependencies**: None (self-contained)

## How It Works

The Cavern pipeline processes spatial audio through named pipes:

1. **audio-processor.exe** creates two Windows named pipes:
   - `\\.\pipe\cavern-audio-input` (for incoming audio)
   - `\\.\pipe\cavern-audio-output` (for processed audio)

2. **FifoToPipe.exe** feeds audio data to the input pipe
3. **PipeToFifo.exe** reads processed audio from the output pipe

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
# Terminal 1: Start processor
win-x64\bin\audio-processor\audio-processor.exe 2 eac3

# Terminal 2: Feed input
win-x64\bin\FifoToPipe\FifoToPipe.exe input_audio.raw

# Terminal 3: Capture output  
win-x64\bin\PipeToFifo\PipeToFifo.exe processed_audio.raw
```

## Integration Examples

### With FFmpeg
```batch
# Stream input via FFmpeg
ffmpeg -i movie.mkv -map 0:a:0 -c copy -f data - | win-x64\bin\FifoToPipe\FifoToPipe.exe -

# Capture output for streaming
win-x64\bin\PipeToFifo\PipeToFifo.exe - | ffmpeg -f data -i - -c copy output.mkv
```

### With VLC/Media Players
The pipeline can process audio from any source that can write to a file or pipe.

## Troubleshooting

**Q**: "Could not connect to pipe"  
**A**: Make sure audio-processor.exe is running first

**Q**: Access denied errors  
**A**: Try running as Administrator

**Q**: No audio processing  
**A**: Check input audio format is supported (EAC3/AC3/PCM)

## Building from Source

If you want to build from source:

```batch
git clone https://github.com/Glider95/Cavern-Snapserver-Pipeline
cd Cavern-Snapserver-Pipeline
build-win-x64.bat
```

The build process requires .NET 8.0 SDK.

## Technical Details

- **Framework**: .NET 8.0
- **Architecture**: x64 only
- **Deployment**: Self-contained, single-file
- **Size**: ~12MB per executable (includes .NET runtime)
- **Performance**: Optimized with trimming and native compilation

## Getting Help

- Check the detailed `win-x64\README.md`
- Review log files in PowerShell script mode
- Examine console output for error messages

---

**Note**: This Windows x64 build provides the same spatial audio processing capabilities as the Linux ARM64 version but adapted for Windows systems with native Windows named pipe support.