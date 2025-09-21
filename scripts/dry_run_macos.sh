#!/usr/bin/env bash
set -euo pipefail

# Dry-run helper: prints the commands that run_pipeline_macos.sh would execute

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CAVERN_PIPE_SERVER_PROJ="$ROOT_DIR/src/CavernPipeServer.Multiplatform/CavernPipeServer.Multiplatform.csproj"

# C# Project Paths
AUDIO_PROCESSOR_PROJ="$ROOT_DIR/src/audio-processor/audio-processor.csproj"
PIPE_TO_FIFO_PROJ="$ROOT_DIR/src/PipeToFifo/PipeToFifo.csproj"
PIPE_INPUT_CLIENT_PROJ="$ROOT_DIR/src/PipeInputClient/PipeInputClient.csproj"

INPUT_FIFO=${INPUT_FIFO:-"/tmp/cavern_input.fifo"}
OUTPUT_FIFO=${OUTPUT_FIFO:-"/tmp/cavern_output.fifo"}

LOG_DIR=${LOG_DIR:-"$ROOT_DIR/logs"}
SNAPSERVER_CONFIG=${SNAPSERVER_CONFIG:-"$LOG_DIR/snapserver.conf"}
INPUT_FILE=${INPUT_FILE:-"/Users/gregorynicol/Downloads/Demos/demo.mkv"}

echo "DRY RUN: root dir = $ROOT_DIR"
echo
echo "Would create FIFOs: $INPUT_FIFO $OUTPUT_FIFO"
echo "Would create log dir: $LOG_DIR"
echo "Would write snapserver config to: $SNAPSERVER_CONFIG"
echo

echo "CavernPipeServer:"
echo "  Build: dotnet build $CAVERN_PIPE_SERVER_PROJ >> $LOG_DIR/cavernpipe.log 2>&1"
echo "  Execute: dotnet $ROOT_DIR/src/CavernPipeServer.Multiplatform/bin/Debug/net8.0/CavernPipeServer.dll >> $LOG_DIR/cavernpipe.log 2>&1 &"
echo

echo "AudioProcessor:"
echo "  Build: dotnet build $AUDIO_PROCESSOR_PROJ >> $LOG_DIR/audio-processor.log 2>&1"
echo "  Execute: dotnet $ROOT_DIR/src/audio-processor/bin/Debug/net8.0/audio-processor.dll >> $LOG_DIR/audio-processor.log 2>&1 &"
echo

echo "PipeToFifo:"
echo "  Build: dotnet build $PIPE_TO_FIFO_PROJ >> $LOG_DIR/pipetofifo.log 2>&1"
echo "  Execute: dotnet $ROOT_DIR/src/PipeToFifo/bin/Debug/net8.0/PipeToFifo.dll $OUTPUT_FIFO >> $LOG_DIR/pipetofifo.log 2>&1 &"
echo

echo "PipeInputClient:"
echo "  Build: dotnet build $PIPE_INPUT_CLIENT_PROJ >> $LOG_DIR/pipeinput.log 2>&1"
echo "  Execute: dotnet $ROOT_DIR/src/PipeInputClient/bin/Debug/net8.0/PipeInputClient.dll $INPUT_FIFO >> $LOG_DIR/pipeinput.log 2>&1 &"
echo

echo "Snapserver:"
echo "  Execute: snapserver -c $SNAPSERVER_CONFIG >> $LOG_DIR/snapserver.log 2>&1 &"
echo

echo "Demo feeder (mpv) would run this to stream $INPUT_FILE into $INPUT_FIFO:"
echo "  mpv --log-file=$LOG_DIR/mpv.log --ao=null --aid=2 --audio-spdif=ac3,eac3,truehd --stream-dump=$INPUT_FIFO $INPUT_FILE"
