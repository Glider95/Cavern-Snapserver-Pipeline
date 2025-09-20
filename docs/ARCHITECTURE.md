# Architecture Overview

## System Components

The Cavern Snapserver Pipeline consists of several interconnected components that work together to process and distribute spatial audio:

### 1. Audio Input Layer
- **ALSA Loopback**: Captures audio from applications via ALSA loopback device
- **FIFO Input**: Alternative input method for external audio sources (FFmpeg, etc.)

### 2. Audio Processing Layer
- **Audio Processor** (`src/audio-processor/Program.cs`): Main C# application that coordinates the pipeline
- **AudioConverter** (`src/audio-processor/AudioConverter.cs`): Handles audio format conversion and communication with Cavern engine
- **CavernPipeServer**: External Cavern spatial audio processing engine

### 3. Data Transport Layer
- **Named Pipes**: Inter-process communication between components
- **PipeInputClient**: Bridges FIFO input to named pipe
- **PipeToFifo**: Bridges named pipe output to FIFO

### 4. Output Distribution Layer
- **Snapserver**: Handles network distribution of processed audio
- **Snapclient**: Receives and plays audio on client devices

## Data Flow Diagram

```
[Audio Source] 
     ↓
[ALSA Loopback / FIFO]
     ↓
[PipeInputClient] → [cavern-audio-input] → [Audio Processor] → [CavernPipeServer]
                                                ↓
[Snapserver] ← [/tmp/snapcast-out] ← [PipeToFifo] ← [cavern-audio-output]
     ↓
[Network Distribution]
     ↓
[Snapclient(s)]
```

## Communication Protocols

### Named Pipes
- `cavern-audio-input`: Input to audio processor
- `cavern-audio-output`: Output from audio processor

### FIFO Files
- `/tmp/dolby-in`: Input FIFO for raw audio data
- `/tmp/snapcast-out`: Output FIFO for processed audio

### Audio Formats
- **Input**: Raw PCM, IEC61937 (Dolby Digital/DTS passthrough)
- **Processing**: Spatial audio processing via Cavern
- **Output**: Opus codec for network streaming

## Process Lifecycle

1. **Initialization**: Create FIFOs and start CavernPipeServer
2. **Input Setup**: Start ALSA capture or prepare for external input
3. **Processing**: Launch audio processor and bridge components
4. **Distribution**: Start Snapserver for network streaming
5. **Monitoring**: All components log to centralized location

## Configuration Points

- **Codec Selection**: EAC3, DTS, etc.
- **Channel Configuration**: 2, 5.1, 7.1 channel setups
- **Network Settings**: Snapcast ports and streaming parameters
- **Audio Parameters**: Sample rate, bit depth, buffer sizes