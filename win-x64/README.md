# Cavern Audio Processor - Windows x64

This directory contains the Windows x64 build of the Cavern Audio Processor, which provides advanced spatial audio processing using the Cavern audio library.

## What's Included

The Windows x64 build includes one main executable:

- **audio-processor.exe** - Cavern spatial audio processing engine that creates Windows named pipes for input/output

## Building

To build the Windows x64 executable from source:

```batch
# From the repository root
build-win-x64.bat
```

Or on Linux/macOS for cross-compilation:
```bash
# From the repository root  
./build-win-x64.sh
```

## Quick Start

1. Run the demo script:
   ```batch
   win-x64\run_pipeline_demo.bat
   ```

2. Or use PowerShell for advanced options:
   ```powershell
   win-x64\run_pipeline.ps1 -Help
   ```

## Manual Usage

Start the audio processor:
```batch
win-x64\bin\audio-processor\audio-processor.exe [channels] [codec]
```

- `channels`: Number of output channels (default: 2)
- `codec`: Audio codec - "eac3", "ac3", etc. (default: "eac3")

**Example:**
```batch
win-x64\bin\audio-processor\audio-processor.exe 6 eac3
```

## Media Player Integration

### Named Pipes Created

When the audio processor starts, it creates two Windows named pipes:
- **Input**: `\\.\pipe\cavern-audio-input` - Send audio data here for processing
- **Output**: `\\.\pipe\cavern-audio-output` - Receive processed spatial audio

### Using with FFmpeg

**Basic Pipeline:**
```batch
# Terminal 1: Start the processor
win-x64\bin\audio-processor\audio-processor.exe 2 eac3

# Terminal 2: Stream media file to processor
ffmpeg -i movie.mkv -map 0:a:0 -f data \\.\pipe\cavern-audio-input

# Terminal 3: Play processed audio
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | ffplay -
```

**Save processed audio to file:**
```batch
ffmpeg -f data -i \\.\pipe\cavern-audio-output output.wav
```

**Stream to network (for Snapcast/similar):**
```batch
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav tcp://localhost:4444
```

### Using with VLC Media Player

1. **Install Virtual Audio Cable** (e.g., VB-Cable, Virtual Audio Cable)

2. **Configure VLC:**
   - Tools → Preferences → Audio
   - Set Output to your virtual audio cable

3. **Capture VLC output:**
   ```batch
   # Capture from virtual cable and send to Cavern
   ffmpeg -f dshow -i audio="CABLE Output" -f data \\.\pipe\cavern-audio-input
   ```

4. **Play processed audio:**
   ```batch
   ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | ffplay -
   ```

### Using with Windows Media Players

**Method 1: Screen/Audio Capture**
```batch
# Capture system audio (requires Stereo Mix enabled)
ffmpeg -f dshow -i audio="Stereo Mix" -f data \\.\pipe\cavern-audio-input
```

**Method 2: File-based Processing**
```batch
# Extract audio from media file
ffmpeg -i your_movie.mkv -map 0:a:0 -f data \\.\pipe\cavern-audio-input
```

### Real-time Audio Setup

For real-time audio processing with minimal latency:

```batch
# Low-latency streaming with small buffer
ffmpeg -f dshow -i audio="Your Audio Device" -ac 2 -ar 48000 -f data -bufsize 32k \\.\pipe\cavern-audio-input
```

## Audio Formats Supported

- **Input**: Raw PCM audio data, compressed formats (EAC3/AC3)
- **Output**: Processed spatial audio (format depends on codec settings)
- **Sample Rate**: 48 kHz (recommended)
- **Channels**: Configurable (2, 6, 8 channels supported)

## Advanced Configuration

### Channel Configurations
- **2 channels**: Stereo output with spatial processing
- **6 channels**: 5.1 surround sound
- **8 channels**: 7.1 surround sound

### Codec Options
- **eac3**: Dolby Digital Plus (recommended)
- **ac3**: Dolby Digital (legacy)

### Example Configurations
```batch
# Stereo output with EAC3
audio-processor.exe 2 eac3

# 5.1 surround with AC3
audio-processor.exe 6 ac3

# 7.1 surround with EAC3
audio-processor.exe 8 eac3
```

## Troubleshooting

### Common Issues

1. **"Could not connect to pipe"**: Ensure audio-processor.exe is running first
2. **Access denied**: Run as Administrator if needed
3. **No audio processing**: Check input audio format compatibility
4. **FFmpeg not found**: Install FFmpeg and add to PATH

### Performance Tips

- Use 48 kHz sample rate for best performance
- Keep buffer sizes small for real-time processing
- Close unnecessary applications to reduce audio latency

## Integration Examples

### Home Theater Setup
```batch
# Movie playback with 5.1 processing
audio-processor.exe 6 eac3
ffmpeg -i movie.mkv -map 0:a:0 -f data \\.\pipe\cavern-audio-input
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f alsa hw:1,0
```

### Streaming Setup
```batch
# Process and stream to Snapcast
audio-processor.exe 2 eac3
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | snapserver --stream.source=pipe:///dev/stdin
```

### Gaming Audio Enhancement
```batch
# Capture game audio and enhance
audio-processor.exe 2 eac3
ffmpeg -f dshow -i audio="Game Audio Device" -f data \\.\pipe\cavern-audio-input
ffmpeg -f data -i \\.\pipe\cavern-audio-output -f directsound
```

## Technical Details

- **Framework**: .NET 8.0 (self-contained)
- **Size**: ~12MB (includes .NET runtime)
- **Architecture**: x64 only
- **IPC**: Windows named pipes
- **Deployment**: Single-file executable

## Dependencies

None! The executable is self-contained and includes all necessary .NET runtime components.

## See Also

- Linux ARM64 version in `../linux-arm64/`
- Source code in `../audio-processor/`
- Build scripts: `../build-win-x64.bat` and `../build-win-x64.sh`