# Cavern Snapserver Pipeline

An audio processing pipeline that integrates Cavern spatial audio processing with Snapcast for multi-room audio streaming. Designed as a multiplatform solution (Windows x64, macOS, Linux) for processing Dolby bitstream audio (AC3, EAC3, TrueHD) using the Cavern audio engine.

**Architecture Flow**: Media Player → Dolby bitstream input → Cavern Decoder → PCM output → Snapcast Server → Network clients (including ESP32-based smart speakers)

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Build
- **Install system dependencies:**
  ```bash
  sudo apt-get update
  sudo apt-get install -y alsa-utils lsof snapserver snapclient ffmpeg netcat-openbsd
  ```
  - Takes ~30 seconds to 2 minutes depending on system

- **Install .NET dependencies (if building from source):**
  ```bash
  # .NET SDK for building (development)
  sudo apt-get install -y dotnet-sdk-8.0
  
  # .NET Runtime for running (production)
  sudo apt-get install -y dotnet-runtime-6.0
  ```

- **Build from source (C# components):**
  ```bash
  # Audio processor - takes ~6 seconds
  cd src/audio-processor
  dotnet new console --name audio-processor --force
  mv Program.cs AudioConverter.cs audio-processor/
  cd audio-processor && dotnet build
  
  # Publish for deployment (multiplatform) - takes ~6 seconds each
  dotnet publish -c Release -r win-x64                    # Windows x64
  dotnet publish -c Release -r linux-x64                  # Linux x64  
  dotnet publish -c Release -r osx-x64                    # macOS x64
  
  # Pipe utilities - takes ~2 seconds each
  cd ../../pipe-utilities
  dotnet new console --name PipeToFifo --force
  dotnet new console --name FifoToPipe --force
  mv PipeToFifo.cs PipeToFifo/Program.cs
  mv FifoToPipe.cs FifoToPipe/Program.cs
  cd PipeToFifo && dotnet build
  cd ../FifoToPipe && dotnet build
  ```

- **Install pipeline (automated):**
  ```bash
  # Full installation - takes ~2-5 minutes
  sudo scripts/install.sh
  ```

- **Configure ALSA loopback (required for Linux audio input):**
  ```bash
  # Load ALSA loopback module (Linux only)
  sudo modprobe snd-aloop
  
  # Make persistent (Linux only)
  echo "snd-aloop" | sudo tee -a /etc/modules
  
  # Configure ALSA aliases (Linux only)
  sudo cp config/asound.conf.example /etc/asound.conf
  ```

### Testing and Validation
- **Validate shell scripts:**
  ```bash
  # Syntax check - takes <1 second
  bash -n scripts/*.sh
  
  # Linting with shellcheck - takes <1 second
  shellcheck scripts/*.sh
  ```

- **Test build components:**
  ```bash
  # Test audio processor (will wait for pipes)
  cd src/audio-processor/audio-processor
  timeout 3s dotnet run -- 2 eac3
  
  # Test pipe utilities
  cd ../../pipe-utilities/PipeToFifo
  timeout 3s dotnet run -- /tmp/test-output
  ```

- **Run pipeline (development mode):**
  ```bash
  # From repository root - NEVER CANCEL, can take 5+ minutes to fully initialize
  # Cross-platform but may have different audio input requirements per OS
  scripts/run_pipeline.sh
  ```

- **Demo mode (requires demo.mkv in ~/Downloads/):**
  ```bash
  # Full demo pipeline - NEVER CANCEL, runs indefinitely
  scripts/demo_run_pipeline.sh
  ```

## Validation

### Manual Validation Requirements
- **ALWAYS test the full pipeline after making changes to core components**
- **Pipeline testing requirements**: The pipeline is designed to work across platforms but has different audio input requirements:
  - **Linux**: Requires ALSA loopback support for audio capture
  - **Windows**: Uses different audio APIs (platform-specific configuration needed)  
  - **macOS**: Uses Core Audio (platform-specific configuration needed)
  - **Input**: Expects Dolby bitstream (AC3, EAC3, TrueHD) from media players
  - **Output**: Produces PCM audio for Snapcast distribution to network clients

### Development Environment Validation
- **Build validation**: Always verify that `dotnet build` succeeds for all C# components
- **Script validation**: Always run `bash -n scripts/*.sh` and `shellcheck scripts/*.sh`
- **Component testing**: Test individual components with short timeouts to verify they start correctly
- **Log analysis**: Check `/tmp/cavern_logs/` or `/var/log/cavern/` for component startup logs

### Production Validation Scenarios
When working on target systems with proper audio setup:
1. **Full pipeline test**: Run `scripts/run_pipeline.sh` and verify all components start
2. **Audio flow test**: Use `scripts/demo_run_pipeline.sh` with a test file containing Dolby audio
3. **Client connection test**: Connect with `snapclient tcp://127.0.0.1:1704`
4. **Service test**: Verify systemd service with `sudo systemctl start cavern-pipeline` (Linux only)
5. **ESP32 client test**: Connect ESP32-based smart speakers using the snapclient implementation

## Critical Timing Information

### Build Commands - NEVER CANCEL
- `dotnet build`: Takes 2-6 seconds per component
- `dotnet publish`: Takes 5-10 seconds per component  
- `scripts/install.sh`: Takes 2-5 minutes (includes apt install)
- `apt-get install` for dependencies: Takes 30 seconds to 2 minutes

### Runtime Commands - NEVER CANCEL
- `scripts/run_pipeline.sh`: Takes 10-30 seconds to initialize, runs indefinitely
- `scripts/demo_run_pipeline.sh`: Takes 10-30 seconds to start, runs indefinitely  
- Pipeline startup: Components start sequentially with built-in delays
- **CRITICAL**: Pipeline processes run indefinitely - they are designed to be long-running services

### Expected Failures in Development
- **Platform-specific audio**: Audio input methods vary by platform (ALSA on Linux, different APIs on Windows/macOS)
- **ALSA module**: `sudo modprobe snd-aloop` will fail if module not available (Linux-specific)
- **Audio devices**: Platform-specific audio device enumeration and configuration
- **Pipeline execution**: May fail without proper audio setup but should create FIFOs and start initial components

## Common Tasks

### Code Changes Workflow
```bash
# 1. Always validate scripts first
bash -n scripts/*.sh
shellcheck scripts/*.sh

# 2. Build and test components
cd src/audio-processor/audio-processor && dotnet build
cd ../../pipe-utilities/PipeToFifo && dotnet build  
cd ../FifoToPipe && dotnet build

# 3. Test individual components (short timeout)
timeout 3s dotnet run -- 2 eac3  # from audio-processor directory

# 4. On target platforms: test full pipeline
scripts/run_pipeline.sh
```

### Dependencies and Architecture

#### Core Dependencies (always required)
- **Runtime**: .NET 6.0+ runtime, lsof, netcat-openbsd
- **Audio**: snapserver, snapclient, ffmpeg
- **System**: Platform-specific audio systems (ALSA on Linux, Core Audio on macOS, etc.)

#### Development Dependencies
- **Build**: .NET 8.0 SDK
- **Validation**: shellcheck, bash (Linux/macOS), PowerShell (Windows)
- **Optional**: git (for version control)

#### Binary Architecture
- **Cross-platform**: Built for Windows x64, Linux x64, macOS x64
- **Pre-built binaries**: Currently includes linux-arm64/bin/ (legacy, may be updated)
- **Target platforms**: Modern desktop/server systems with sufficient processing power
- **NOT suitable for**: Raspberry Pi or other low-power ARM devices

### Key File Locations

#### Source Code
- `src/audio-processor/`: Main audio processing logic (C#)
- `src/pipe-utilities/`: Data flow utilities (C#)
- `scripts/`: Pipeline orchestration (Bash)

#### Configuration
- `config/asound.conf.example`: ALSA configuration template
- `config/cavern-pipeline.service`: systemd service definition

#### Runtime
- `/opt/cavern-pipeline/`: Installation directory
- `/tmp/dolby-in`, `/tmp/snapcast-out`: FIFO files for data flow
- `/tmp/cavern_logs/` or `/var/log/cavern/`: Log files

#### Pre-built Binaries
- `linux-arm64/bin/CavernPipeServer.Multiplatform/`: Cavern audio engine (legacy directory structure)
- `linux-arm64/bin/audio-processor/`: Main processing component  
- `linux-arm64/bin/PipeInputClient/`, `linux-arm64/bin/PipeToFifo/`: Data bridges
- **Note**: Directory structure will be updated to support multiplatform binaries

### Troubleshooting Common Issues

#### Build Issues
- **Missing .NET SDK**: Install `dotnet-sdk-8.0`
- **Project file missing**: Run `dotnet new console --name <component>` first
- **Build failures**: Check for missing dependencies in project files

#### Pipeline Issues  
- **Platform-specific audio**: Different audio APIs and configurations per platform
- **Audio codec support**: Ensure media players can output Dolby bitstream (AC3, EAC3, TrueHD)
- **Named pipe errors**: Components start in sequence, some connection failures are normal during startup
- **Port conflicts**: Run cleanup step in `scripts/run_pipeline.sh` to kill conflicting processes

#### Validation Issues
- **Shellcheck warnings**: Minor issues acceptable, focus on syntax errors
- **Timeout on component tests**: Expected when components wait for connections
- **Missing log files**: Components may not create logs if they fail to start

### Environment Limitations
- **Development environments**: Can build and test syntax, but require proper audio setup for full pipeline testing
- **Production requirements**: Desktop/server-class hardware with multiplatform audio support
- **ESP32 clients**: Snapclient implementation available at https://github.com/Glider95/snapclient
- **Audio input**: Requires media players capable of Dolby bitstream output (AC3, EAC3, TrueHD)