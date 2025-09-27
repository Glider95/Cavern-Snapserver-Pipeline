# Development Guide

## Development Setup

### Prerequisites

- .NET 6.0 SDK or later
- Linux environment (for testing ALSA components)
- Git

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Glider95/Cavern-Snapserver-Pipeline.git
   cd Cavern-Snapserver-Pipeline
   ```

2. **Install dependencies (for testing):**
   ```bash
   sudo apt-get install -y alsa-utils snapserver snapclient ffmpeg
   ```

3. **Set up ALSA loopback (for development testing):**
   ```bash
   sudo modprobe snd-aloop
   sudo cp config/asound.conf.example /etc/asound.conf
   ```

## Building from Source

### Audio Processor

The main audio processor is written in C# and requires .NET runtime.

```bash
cd src/audio-processor

# Build (requires .NET SDK)
dotnet build

# Publish for deployment
dotnet publish -c Release -r linux-arm64 --self-contained

# Run locally (requires CavernPipeServer to be running)
dotnet run -- 2 eac3
```

### Pipe Utilities

The pipe utilities are also C# applications:

```bash
cd src/pipe-utilities

# Build individual utilities
dotnet build FifoToPipe.cs
dotnet build PipeToFifo.cs

# Or create simple projects and build
mkdir -p FifoToPipe PipeToFifo
echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net6.0</TargetFramework></PropertyGroup></Project>' > FifoToPipe/FifoToPipe.csproj
cp FifoToPipe.cs FifoToPipe/Program.cs
cd FifoToPipe && dotnet build
```

## Testing

### Development Testing

1. **Run the development pipeline:**
   ```bash
   # From repository root
   scripts/run_pipeline.sh
   ```

2. **Test with demo content:**
   ```bash
   # Requires demo.mkv file in ~/Downloads/
   scripts/demo_run_pipeline.sh
   ```

3. **Manual component testing:**
   ```bash
   # Test individual components
   cd linux-arm64/bin/audio-processor
   ./audio-processor 2 eac3

   # Test pipe utilities
   cd linux-arm64/bin/PipeToFifo
   ./PipeToFifo /tmp/test-output
   ```

### Unit Testing

Currently, the project doesn't have formal unit tests. Consider adding:

```bash
# Create test projects
mkdir -p test/audio-processor-tests
cd test/audio-processor-tests

# Create test project
dotnet new xunit
dotnet add reference ../../src/audio-processor/audio-processor.csproj
```

## Code Structure

### Audio Processor (`src/audio-processor/`)

- **Program.cs**: Main entry point, handles command-line arguments and pipeline coordination
- **AudioConverter.cs**: Core audio processing logic, manages communication with Cavern engine

Key methods:
- `Main()`: Entry point, argument parsing, pipe setup
- `ProcessAsync()`: Main processing loop
- `ProcessBridge()`: Handles communication with CavernPipeServer
- `ReadExact()`: Utility for reliable stream reading

### Pipe Utilities (`src/pipe-utilities/`)

- **FifoToPipe.cs**: Bridges FIFO files to named pipes
- **PipeToFifo.cs**: Bridges named pipes to FIFO files

Simple utility applications that handle data flow between different IPC mechanisms.

## Debugging

### Common Development Issues

1. **CavernPipeServer not found:**
   ```bash
   # Check if binary exists
   ls -la linux-arm64/bin/CavernPipeServer.Multiplatform/

   # Verify permissions
   chmod +x linux-arm64/bin/CavernPipeServer.Multiplatform/CavernPipeServer
   ```

2. **Named pipe connection failures:**
   ```bash
   # Check for existing pipes
   ls -la /tmp/CoreFxPipe_*

   # Clean up stale pipes
   rm -f /tmp/CoreFxPipe_*
   ```

3. **ALSA device issues:**
   ```bash
   # List available devices
   aplay -l
   arecord -l

   # Test loopback
   arecord -D loopin -f S16_LE -c 2 -r 48000 | aplay -D loopout
   ```

### Debug Logging

Enable verbose logging by modifying scripts:

```bash
# In run_pipeline.sh, add debug flags
set -x  # Enable bash debugging

# Redirect component output to see detailed logs
"$BIN_DIR/audio-processor/audio-processor" 2 eac3 | tee "$LOG_DIR/audio_processor_debug.log"
```

### Performance Profiling

Use system tools to monitor performance:

```bash
# Monitor CPU usage
top -p $(pgrep -f audio-processor)

# Monitor memory usage
ps aux | grep audio-processor

# Monitor I/O
iotop -p $(pgrep -f audio-processor)

# Network monitoring (for Snapcast)
netstat -tlnp | grep :1704
```

## Contributing

### Code Style

- **C#**: Follow Microsoft C# coding conventions
- **Shell Scripts**: Use bash best practices (shellcheck compliance)
- **Documentation**: Update relevant docs when making changes

### Development Workflow

1. **Create feature branch:**
   ```bash
   git checkout -b feature/description
   ```

2. **Make changes and test:**
   ```bash
   # Test locally
   scripts/run_pipeline.sh
   
   # Validate syntax
   bash -n scripts/*.sh
   ```

3. **Update documentation:**
   - Update README.md if adding features
   - Update CHANGELOG.md with changes
   - Add/update docs/ files as needed

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/description
   ```

5. **Create pull request**

### Adding New Features

When adding new components:

1. **Source code**: Add to appropriate `src/` subdirectory
2. **Binaries**: Update build process and `linux-arm64/bin/`
3. **Configuration**: Add config options to `config/` or document in `docs/CONFIGURATION.md`
4. **Scripts**: Update `scripts/run_pipeline.sh` if needed
5. **Documentation**: Update architecture and usage docs

### Release Process

1. **Update version numbers** in relevant files
2. **Update CHANGELOG.md** with release notes
3. **Test on target hardware** (Raspberry Pi)
4. **Create release binaries** for distribution
5. **Tag release** in git
6. **Update documentation** for any breaking changes