#!/bin/bash
#
# Cavern Atmos Demo Pipeline
# 
# Full end-to-end streaming pipeline:
#   Dolby Atmos File → CavernPipeServer → FFmpeg → Snapserver → Snapclients
#
# Usage: ./demo_atmos_pipeline.sh [input_file]
#
# If no input file is specified, it will look for common Atmos test files.
#

set -e

# Configuration
SNAPSERVER_TCP_PORT=4953
SNAPSERVER_STREAM_PORT=1704
SNAPSERVER_HTTP_PORT=1780
LOG_DIR="/tmp/cavern_logs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Cleanup function
cleanup() {
    log_info "Cleaning up processes..."
    pkill -9 -f "CavernPipeServer" 2>/dev/null || true
    pkill -9 -f "CavernPipeClientStreaming" 2>/dev/null || true
    pkill -9 snapserver 2>/dev/null || true
    pkill -9 snapclient 2>/dev/null || true
    pkill -9 -f "ffmpeg.*${SNAPSERVER_TCP_PORT}" 2>/dev/null || true
    sleep 1
}

# Handle script termination
trap cleanup EXIT

# Prepare input file - extract audio stream to raw E-AC-3/AC3 format for CavernPipe
# CavernPipe expects raw Dolby bitstream, not container formats like MP4/MKV
prepare_input_file() {
    local input_file="$1"
    local extracted="/tmp/cavern-extracted-audio.eac3"
    
    # Get all audio stream info
    local audio_info=$(ffprobe "$input_file" 2>&1 | grep -E "Stream #0:[0-9]+.*Audio")
    
    # Check for E-AC-3 (Dolby Digital Plus / Dolby Atmos)
    local eac3_stream=$(echo "$audio_info" | grep -i "eac3" | head -1 | grep -oE "#0:[0-9]+" | cut -d: -f2)
    if [[ -n "$eac3_stream" ]]; then
        echo "[INFO] Extracting E-AC-3 audio from stream $eac3_stream to raw bitstream..." >&2
        ffmpeg -y -i "$input_file" -map 0:$eac3_stream -c copy "$extracted" </dev/null 2>/dev/null
        if [[ -f "$extracted" && -s "$extracted" ]]; then
            echo "$extracted"
            return 0
        fi
    fi
    
    # Check for AC3 (Dolby Digital)
    local ac3_stream=$(echo "$audio_info" | grep -E "Audio: ac3[^-]" | head -1 | grep -oE "#0:[0-9]+" | cut -d: -f2)
    if [[ -n "$ac3_stream" ]]; then
        echo "[INFO] Extracting AC3 audio from stream $ac3_stream to raw bitstream..." >&2
        local extracted_ac3="/tmp/cavern-extracted-audio.ac3"
        ffmpeg -y -i "$input_file" -map 0:$ac3_stream -c copy "$extracted_ac3" </dev/null 2>/dev/null
        if [[ -f "$extracted_ac3" && -s "$extracted_ac3" ]]; then
            echo "$extracted_ac3"
            return 0
        fi
    fi
    
    # Check for TrueHD (Dolby TrueHD / Dolby Atmos)
    local truehd_stream=$(echo "$audio_info" | grep -i "truehd" | head -1 | grep -oE "#0:[0-9]+" | cut -d: -f2)
    if [[ -n "$truehd_stream" ]]; then
        echo "[WARN] TrueHD detected - Cavern TrueHD decoder may have issues, trying anyway..." >&2
        local extracted_thd="/tmp/cavern-extracted-audio.thd"
        ffmpeg -y -i "$input_file" -map 0:$truehd_stream -c copy "$extracted_thd" </dev/null 2>/dev/null
        if [[ -f "$extracted_thd" && -s "$extracted_thd" ]]; then
            echo "$extracted_thd"
            return 0
        fi
    fi
    
    # If it's already a raw audio file (not a container), use directly
    local file_type=$(file -b "$input_file" | head -1)
    if echo "$file_type" | grep -qiE "ac-?3|dolby|audio"; then
        echo "[INFO] Input appears to be raw audio, using directly" >&2
        echo "$input_file"
        return 0
    fi
    
    echo "[ERROR] Could not extract supported Dolby audio from input file" >&2
    return 1
}

# Find input file
find_input_file() {
    local input_file="$1"
    
    if [[ -n "$input_file" && -f "$input_file" ]]; then
        echo "$input_file"
        return 0
    fi
    
    # Search for common Atmos test files
    local search_paths=(
        # "$HOME/Downloads/Dolby Atmos E-AC-3 5.1.2.mp4"
        # "$HOME/Downloads/Dolby Atmos 24.1.13 with 7.1.2 beds and objects.mp4"
        # "$HOME/Downloads/dolby-atmos-trailer_amaze_1080.mp4"
        # "$HOME/Downloads/audio only 7_1.mkv"
        "$HOME/Downloads/Demos/demo.mkv"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Check dependencies
check_dependencies() {
    log_step "Checking dependencies..."
    
    local missing=()
    
    command -v dotnet >/dev/null 2>&1 || missing+=("dotnet")
    command -v ffmpeg >/dev/null 2>&1 || missing+=("ffmpeg")
    command -v snapserver >/dev/null 2>&1 || missing+=("snapserver")
    command -v snapclient >/dev/null 2>&1 || missing+=("snapclient")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: brew install ${missing[*]}"
        exit 1
    fi
    
    log_info "All dependencies found"
}

# Build projects if needed
build_projects() {
    log_step "Building Cavern projects..."
    
    local server_dir="$PROJECT_ROOT/CavernSamples/CavernPipeServer.Multiplatform"
    local client_dir="$PROJECT_ROOT/CavernSamples/CavernPipeClientStreaming"
    
    # Check if streaming client exists, if not create it
    if [[ ! -d "$client_dir" ]]; then
        log_info "Creating CavernPipeClientStreaming project..."
        mkdir -p "$client_dir"
        cp "$PROJECT_ROOT/CavernSamples/CavernPipeClient/CavernPipeClient.csproj" "$client_dir/CavernPipeClientStreaming.csproj"
        
        # Create streaming version of the client
        cat > "$client_dir/Program.cs" << 'STREAMING_CLIENT'
// Streaming version of CavernPipeClient - outputs raw Float32 PCM to stdout
// Uses the same proven parameters as the working CavernPipeClient
using System.IO.Pipes;

using Cavern;
using Cavern.Format;
using Cavern.Format.Utilities;

if (args.Length < 1) {
    Console.Error.WriteLine("Usage: dotnet run -- <input file name>");
    Console.Error.WriteLine("Outputs raw Float32 PCM to stdout for piping to FFmpeg/Snapserver");
    return;
}

string inputFile = args[0];
Console.Error.WriteLine($"Processing: {inputFile}");

// Use the SAME parameters as the working CavernPipeClient:
// - OutputChannels = 6 (5.1 surround, same as Listener.Channels.Length default)
// - UpdateRate = 240 (Listener default)
// - MandatoryFrames = 6 (same as working client)
// FFmpeg will downmix to stereo for Snapcast
Listener listener = new();
int outputChannels = Listener.Channels.Length; // 6 for 5.1 surround
int updateRate = listener.UpdateRate; // 240 default
const int mandatoryFrames = 6; // Same as working client

AudioReader source = AudioReader.Open(inputFile);
source.ReadHeader();
long totalSamples = source.Length;
int sampleRate = source.SampleRate;
Console.Error.WriteLine($"Input: {totalSamples} samples, {sampleRate}Hz");
Console.Error.WriteLine($"Output: {outputChannels} channels Float32 (5.1 surround), UpdateRate={updateRate}, MandatoryFrames={mandatoryFrames}");
source.Dispose();

// Connection to CavernPipeServer
Console.Error.WriteLine("Connecting to CavernPipe server...");
using NamedPipeClientStream pipe = new("CavernPipe");
pipe.Connect();
Console.Error.WriteLine("Connected!");

// CavernPipe protocol header (8 bytes):
// Byte 0: BitDepth (Float32 = 32)
// Byte 1: MandatoryFrames (6, same as working client)
// Bytes 2-3: OutputChannels (6 for 5.1)
// Bytes 4-7: UpdateRate (240, Listener default)
byte[] pipeHeader = new byte[8];
pipeHeader[0] = (byte)BitDepth.Float32;
pipeHeader[1] = (byte)mandatoryFrames;
BitConverter.GetBytes((ushort)outputChannels).CopyTo(pipeHeader, 2);
BitConverter.GetBytes(updateRate).CopyTo(pipeHeader, 4);
pipe.Write(pipeHeader, 0, pipeHeader.Length);

// Open stdout for binary writing
using Stream stdout = Console.OpenStandardOutput();

// Sending the file to the pipe and receiving processed audio
using FileStream reader = File.OpenRead(inputFile);
long received = 0;
byte[] sendBuffer = new byte[1024 * 1024],
    receiveBuffer = [];

while (received < totalSamples) {
    int toSend = reader.Read(sendBuffer, 0, sendBuffer.Length);
    pipe.Write(BitConverter.GetBytes(toSend));
    pipe.Write(sendBuffer, 0, toSend);

    // If there is incoming data, write it to stdout
    int toReceive = pipe.ReadInt32();
    if (toReceive > 0) {
        int samples = toReceive / sizeof(float);
        if (receiveBuffer.Length < toReceive) {
            receiveBuffer = new byte[toReceive];
        }
        pipe.ReadAll(receiveBuffer, 0, toReceive);
        
        // Write raw PCM bytes directly to stdout
        stdout.Write(receiveBuffer, 0, toReceive);
        stdout.Flush();

        received += samples / outputChannels;
        Console.Error.Write($"\rProgress: {received * 100 / totalSamples}% ({received}/{totalSamples})");
    }
}

Console.Error.WriteLine("\nStreaming complete!");
STREAMING_CLIENT
    fi
    
    # Build server
    log_info "Building CavernPipeServer..."
    (cd "$server_dir" && dotnet build -c Release --nologo -v q) || {
        log_error "Failed to build CavernPipeServer"
        exit 1
    }
    
    # Build streaming client
    log_info "Building CavernPipeClientStreaming..."
    (cd "$client_dir" && dotnet build -c Release --nologo -v q) || {
        log_error "Failed to build CavernPipeClientStreaming"
        exit 1
    }
    
    log_info "Build complete"
}

# Create Snapserver config
create_snapserver_config() {
    log_step "Creating Snapserver configuration..."
    
    cat > /tmp/snapserver.conf << EOF
[stream]
source = tcp://0.0.0.0:${SNAPSERVER_TCP_PORT}?name=Cavern&sampleformat=48000:16:2&mode=server

[http]
enabled = true
bind_to_address = 0.0.0.0
port = ${SNAPSERVER_HTTP_PORT}

[server]
# Streaming port for clients (all network interfaces)
bind_to_address = 0.0.0.0
port = ${SNAPSERVER_STREAM_PORT}

[tcp]
# JSON-RPC control interface on separate port
enabled = true
bind_to_address = 0.0.0.0
port = 1705
EOF

    log_info "Config created at /tmp/snapserver.conf"
}

# Start CavernPipeServer
start_cavern_server() {
    log_step "Starting CavernPipeServer..."
    
    mkdir -p "$LOG_DIR"
    
    local server_dir="$PROJECT_ROOT/CavernSamples/CavernPipeServer.Multiplatform"
    cd "$server_dir"
    dotnet run -c Release -- 2 > "$LOG_DIR/cavernpipeserver.log" 2>&1 &
    CAVERN_SERVER_PID=$!
    cd - > /dev/null
    
    # Wait for server to initialize and check log for success message
    sleep 3
    
    if grep -q "waiting for client connection" "$LOG_DIR/cavernpipeserver.log" 2>/dev/null; then
        log_info "CavernPipeServer started successfully (PID: $CAVERN_SERVER_PID)"
    elif ! kill -0 $CAVERN_SERVER_PID 2>/dev/null; then
        log_error "CavernPipeServer failed to start"
        cat "$LOG_DIR/cavernpipeserver.log"
        exit 1
    else
        log_info "CavernPipeServer started (PID: $CAVERN_SERVER_PID)"
    fi
}

# Start Snapserver
start_snapserver() {
    log_step "Starting Snapserver..."
    
    snapserver -c /tmp/snapserver.conf > "$LOG_DIR/snapserver.log" 2>&1 &
    SNAPSERVER_PID=$!
    
    sleep 2
    
    if ! kill -0 $SNAPSERVER_PID 2>/dev/null; then
        log_error "Snapserver failed to start"
        cat "$LOG_DIR/snapserver.log"
        exit 1
    fi
    
    log_info "Snapserver started (PID: $SNAPSERVER_PID)"
    log_info "  - Audio input:  tcp://0.0.0.0:${SNAPSERVER_TCP_PORT}"
    log_info "  - Client stream: tcp://0.0.0.0:${SNAPSERVER_STREAM_PORT}"
    log_info "  - HTTP control: http://0.0.0.0:${SNAPSERVER_HTTP_PORT}"
}

# Start Snapclient
start_snapclient() {
    log_step "Starting local Snapclient..."
    
    # Use auto-discovery via Bonjour/mDNS (no URL needed)
    snapclient > "$LOG_DIR/snapclient.log" 2>&1 &
    SNAPCLIENT_PID=$!
    
    sleep 3
    
    if ! kill -0 $SNAPCLIENT_PID 2>/dev/null; then
        log_error "Snapclient failed to start"
        cat "$LOG_DIR/snapclient.log"
        exit 1
    fi
    
    # Verify connection was successful
    if grep -q "ServerSettings" "$LOG_DIR/snapclient.log" 2>/dev/null; then
        log_info "Snapclient connected successfully (PID: $SNAPCLIENT_PID)"
    else
        log_info "Snapclient started (PID: $SNAPCLIENT_PID)"
    fi
}

# Start streaming pipeline
start_streaming() {
    local input_file="$1"
    
    log_step "Starting audio streaming pipeline..."
    log_info "Input file: $input_file"
    
    local client_dir="$PROJECT_ROOT/CavernSamples/CavernPipeClientStreaming"
    
    # Pipeline: CavernPipeClientStreaming -> FFmpeg -> TCP to Snapserver
    # Note: CavernPipeServer outputs 5.1 surround (6 channels) Float32 at 48kHz
    # FFmpeg downmixes to stereo for Snapcast
    (cd "$client_dir" && dotnet run -c Release -- "$input_file" 2>"$LOG_DIR/cavern-streaming.log") | \
        ffmpeg -f f32le -ar 48000 -ch_layout "5.1" -i pipe:0 \
            -af "pan=stereo|FL=0.5*FL+0.25*FC+0.25*BL|FR=0.5*FR+0.25*FC+0.25*BR" \
            -f s16le -ar 48000 -ac 2 \
            tcp://127.0.0.1:${SNAPSERVER_TCP_PORT} \
            2>"$LOG_DIR/ffmpeg.log" &
    
    PIPELINE_PID=$!
    
    sleep 3
    
    log_info "Streaming pipeline started"
}

# Monitor pipeline
monitor_pipeline() {
    log_step "Pipeline is running. Press Ctrl+C to stop."
    echo ""
    echo "=============================================="
    echo "  CAVERN ATMOS STREAMING PIPELINE ACTIVE"
    echo "=============================================="
    echo ""
    echo "Connect additional Snapclients with:"
    echo "  snapclient tcp://$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_IP"):${SNAPSERVER_STREAM_PORT}"
    echo ""
    echo "Logs are in: $LOG_DIR/"
    echo "  - cavernpipeserver.log"
    echo "  - snapserver.log"  
    echo "  - snapclient.log"
    echo "  - cavern-streaming.log"
    echo "  - ffmpeg.log"
    echo ""
    
    # Monitor progress
    while true; do
        if [[ -f "$LOG_DIR/cavern-streaming.log" ]]; then
            local progress=$(grep -o "Progress: [0-9]*%" "$LOG_DIR/cavern-streaming.log" 2>/dev/null | tail -1)
            if [[ -n "$progress" ]]; then
                echo -ne "\r${BLUE}Streaming ${progress}${NC}    "
            fi
        fi
        
        # Check if streaming is complete
        if grep -q "Streaming complete" "$LOG_DIR/cavern-streaming.log" 2>/dev/null; then
            echo ""
            log_info "Streaming completed!"
            break
        fi
        
        # Check if pipeline crashed
        if ! ps -p $PIPELINE_PID > /dev/null 2>&1; then
            echo ""
            log_warn "Pipeline finished or crashed"
            break
        fi
        
        sleep 1
    done
    
    # Keep running to allow audio to finish playing through buffer
    log_info "Waiting for audio buffer to flush..."
    sleep 5
}

# Main
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          CAVERN ATMOS DEMO PIPELINE                         ║"
    echo "║  Dolby Atmos → Cavern Spatial Audio → Snapcast Streaming    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Find input file
    local input_file
    input_file=$(find_input_file "$1") || {
        log_error "No input file found!"
        echo ""
        echo "Usage: $0 <input_file>"
        echo ""
        echo "Supported formats: MP4, MKV with Dolby Atmos/E-AC-3/TrueHD audio"
        exit 1
    }
    
    log_info "Found input file: $input_file"
    
    # Kill any existing processes
    cleanup
    
    # Setup
    check_dependencies
    
    # Prepare input file (extract E-AC-3 if TrueHD is default)
    input_file=$(prepare_input_file "$input_file")
    log_info "Using audio source: $input_file"
    
    build_projects
    create_snapserver_config
    
    # Start components
    start_cavern_server
    start_snapserver
    start_snapclient
    start_streaming "$input_file"
    
    # Monitor
    monitor_pipeline
    
    log_info "Demo complete!"
}

main "$@"
