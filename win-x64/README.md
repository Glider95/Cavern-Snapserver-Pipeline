# Cavern Snapserver Pipeline - Windows x64

This directory contains the Windows x64 build of the Cavern Snapserver Pipeline, which provides advanced audio processing using the Cavern audio library for spatial audio rendering.

## Components

The Windows x64 build includes three main executables:

1. **audio-processor.exe** - Main audio processing engine that handles Cavern spatial audio rendering
2. **FifoToPipe.exe** - Input client that feeds audio data to the processor via named pipes
3. **PipeToFifo.exe** - Output client that receives processed audio from the processor

## Building

To build the Windows x64 executables from source:

```batch
# From the repository root
build-win-x64.bat
```

Or on Linux/macOS for cross-compilation:
```bash
# From the repository root  
./build-win-x64.sh
```

## Usage

### Quick Start

1. Run the demo script to see the pipeline in action:
   ```batch
   win-x64\run_pipeline_demo.bat
   ```

### Manual Usage

1. **Start the audio processor:**
   ```batch
   win-x64\bin\audio-processor\audio-processor.exe [channels] [codec]
   ```
   - `channels`: Number of output channels (default: 2)
   - `codec`: Audio codec - "eac3", "ac3", etc. (default: "eac3")

2. **Feed audio input:**
   ```batch
   win-x64\bin\FifoToPipe\FifoToPipe.exe [input_source]
   ```
   - `input_source`: Path to audio file or pipe (default: "/tmp/snapcast-in")

3. **Consume processed output:**
   ```batch
   win-x64\bin\PipeToFifo\PipeToFifo.exe [output_destination]
   ```
   - `output_destination`: Path where processed audio will be written

### Example Workflow

```batch
# Terminal 1: Start the audio processor
win-x64\bin\audio-processor\audio-processor.exe 2 eac3

# Terminal 2: Feed audio input (replace with your audio file)
win-x64\bin\FifoToPipe\FifoToPipe.exe audio_input.raw

# Terminal 3: Capture processed output
win-x64\bin\PipeToFifo\PipeToFifo.exe processed_output.raw
```

## Named Pipes on Windows

The Windows version uses Windows named pipes for inter-process communication:

- **Input pipe**: `\\.\pipe\cavern-audio-input`
- **Output pipe**: `\\.\pipe\cavern-audio-output`

These are created automatically by the audio-processor when it starts.

## Audio Formats

The pipeline processes audio in the following formats:

- **Input**: Raw audio data (typically PCM or compressed formats like EAC3/AC3)
- **Output**: Processed spatial audio (format depends on codec settings)
- **Sample Rate**: 48 kHz (standard)
- **Bit Depth**: 16-bit (configurable)

## Integration with Snapcast

To integrate with Snapcast on Windows:

1. Use FFmpeg or similar tool to stream audio to the input
2. Configure Snapcast server to read from the output pipe
3. The pipeline will provide spatial audio processing between input and output

## Dependencies

The executables are self-contained and include all necessary .NET runtime dependencies. No additional installation is required.

## Supported Codecs

- **EAC3** (Dolby Digital Plus) - Default
- **AC3** (Dolby Digital)
- **PCM** - Raw audio

## Troubleshooting

### Common Issues

1. **"Could not connect to pipe"**: Ensure audio-processor is running first
2. **Access denied**: Run with administrator privileges if needed
3. **Audio not processing**: Check that input audio format is supported

### Logs

Each component outputs status information to the console. Monitor these for debugging.

## Performance

The Windows x64 build is optimized for performance with:
- Single-file deployment for fast startup
- Self-contained runtime (no .NET installation required)  
- Trimmed assemblies for smaller size
- Native code generation where possible

## See Also

- Linux ARM64 version in `../linux-arm64/`
- Source code in `../audio-processor/`, `../FifoToPipe/`, `../PipeToFifo/`
- Build scripts: `../build-win-x64.bat` and `../build-win-x64.sh`