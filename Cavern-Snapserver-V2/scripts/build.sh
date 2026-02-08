#!/usr/bin/env bash
# Build all Cavern-Snapserver components

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"

mkdir -p "$LOG_DIR"

echo "╔═══════════════════════════════════════════════╗"
echo "║  Building Cavern-Snapserver Components       ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Check CavernPipeServer (pre-built)
echo "[1/3] Checking CavernPipeServer (pre-built)..."
CAVERN_BIN="$ROOT_DIR/bin/CavernPipeServer"
if [ -f "$CAVERN_BIN/CavernPipeServer.dll" ]; then
  echo "      ✓ CavernPipeServer found"
else
  echo "      ✗ ERROR: CavernPipeServer.dll not found at $CAVERN_BIN"
  echo "        Please copy pre-built CavernPipeServer to bin/CavernPipeServer/"
  exit 1
fi

# Build CavernPipeClient
echo "[2/3] Building CavernPipeClient..."
cd "$ROOT_DIR/src/CavernPipeClient"
if dotnet build CavernPipeClient.csproj > "$LOG_DIR/build-client.log" 2>&1; then
  echo "      ✓ CavernPipeClient built"
else
  echo "      ✗ Build failed. Log: $LOG_DIR/build-client.log"
  exit 1
fi

# Build PipeToFifo
echo "[3/3] Building PipeToFifo..."
cd "$ROOT_DIR/src/PipeToFifo"
if dotnet build PipeToFifo.csproj > "$LOG_DIR/build-pipetofifo.log" 2>&1; then
  echo "      ✓ PipeToFifo built"
else
  echo "      ✗ Build failed. Log: $LOG_DIR/build-pipetofifo.log"
  exit 1
fi

echo ""
echo "════════════════════════════════════════════════"
echo "Build complete!"
echo ""
echo "Next steps:"
echo "  1. Run pipeline  : ./scripts/run.sh"
echo "  2. Test pipeline : ./scripts/test.sh"
echo "  3. Play file     : ./scripts/play.sh <file.mkv>"
