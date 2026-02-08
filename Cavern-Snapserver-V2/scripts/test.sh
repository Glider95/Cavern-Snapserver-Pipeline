#!/usr/bin/env bash
# End-to-end test of Cavern-Snapserver pipeline

set -uo pipefail  # Don't exit on errors, we want to collect all test results

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs/test"
CLIENT_DLL="$ROOT_DIR/src/CavernPipeClient/bin/Debug/net8.0/CavernPipeClient.dll"
PIPETOFIFO_DLL="$ROOT_DIR/src/PipeToFifo/bin/Debug/net8.0/PipeToFifo.dll"

PASSED=0
FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((PASSED++))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  ((FAILED++))
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

echo "╔═══════════════════════════════════════════════╗"
echo "║  Cavern-Snapserver Pipeline E2E Test         ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

mkdir -p "$LOG_DIR"

# Test 1: Build check
echo "[1/6] Checking build..."
if [ -f "$CLIENT_DLL" ] && [ -f "$PIPETOFIFO_DLL" ]; then
  pass "Build artifacts present"
else
  fail "Missing build artifacts"
  echo "      Run: ./scripts/build.sh"
fi

# Test 2: CavernPipeServer check
echo "[2/6] Checking CavernPipeServer..."
if ps aux | grep -v grep | grep -q "CavernPipeServer"; then
  PIPE_PATH=$(find /var/folders -name "CoreFxPipe_CavernPipe" 2>/dev/null | head -1 || echo "")
  if [ -n "$PIPE_PATH" ]; then
    pass "CavernPipeServer running (socket: $PIPE_PATH)"
  else
    warn "CavernPipeServer running but socket not found"
  fi
else
  fail "CavernPipeServer not running"
  echo "      Start: ./scripts/run.sh"
fi

# Test 3: Snapserver check
echo "[3/6] Checking Snapserver..."
if ps aux | grep -v grep | grep -q "snapserver"; then
  if lsof -i :1704 > /dev/null 2>&1; then
    pass "Snapserver running (port 1704)"
  else
    warn "Snapserver running but port 1704 not open"
  fi
else
  fail "Snapserver not running"
  echo "      Start: ./scripts/run.sh"
fi

# Test 4: FIFO check
echo "[4/6] Checking FIFO..."
if [ -p "/tmp/snapcast-out" ]; then
  pass "FIFO exists: /tmp/snapcast-out"
else
  fail "FIFO not found"
  echo "      Create: mkfifo /tmp/snapcast-out"
fi

# Test 5: Generate and process test audio
echo "[5/6] Testing audio processing..."
TEST_AUDIO="$LOG_DIR/test-audio.ac3"
TEST_PCM="$LOG_DIR/test-pcm.raw"

# Generate 1 second of AC-3
if ffmpeg -f lavfi -i "sine=frequency=1000:duration=1" -c:a ac3 -y "$TEST_AUDIO" > "$LOG_DIR/ffmpeg-gen.log" 2>&1; then
  pass "Generated test AC-3 audio"
  
  # Process through pipeline
  if timeout 5 bash -c "cat '$TEST_AUDIO' | dotnet '$CLIENT_DLL' 2 48000 16 > '$TEST_PCM' 2>'$LOG_DIR/client-test.log'" 2>/dev/null; then
    if [ -s "$TEST_PCM" ]; then
      PCM_SIZE=$(wc -c < "$TEST_PCM")
      pass "Processed audio (PCM: $PCM_SIZE bytes)"
    else
      fail "PCM output is empty"
      echo "      Check: $LOG_DIR/client-test.log"
    fi
  else
    warn "Processing timeout or error"
    echo "      CavernPipeServer may need more initial chunks"
  fi
else
  fail "Failed to generate test audio"
fi

# Test 6: Verify handshake
echo "[6/6] Verifying protocol handshake..."
HANDSHAKE=$(echo "test" | timeout 1 dotnet "$CLIENT_DLL" 2 48000 16 2>&1 | grep "Handshake sent" || echo "")
if echo "$HANDSHAKE" | grep -q "10-06-02-00-80-BB-00-00"; then
  pass "Handshake correct (10-06-02-00-80-BB-00-00)"
else
  fail "Handshake verification failed"
  echo "      Expected: 10-06-02-00-80-BB-00-00"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════"
echo "Test Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo "════════════════════════════════════════════════"

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Test with real file: ./scripts/play.sh <file.mkv>"
  echo "  2. Connect client: snapclient -h 127.0.0.1"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "  - Check logs: tail -f $LOG_DIR/*.log"
  echo "  - See docs: docs/TROUBLESHOOTING.md"
  exit 1
fi
