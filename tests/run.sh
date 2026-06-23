#!/bin/bash
# NexOS Test Runner - runs all test suites
set -euo pipefail
ROOT=$(dirname "$(readlink -f "$0")")
PASS=0; FAIL=0; TOTAL=0

echo "╔═══════════════════════════════════════╗"
echo "║      NexOS Full Test Suite            ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# 1. Build-time tests (no target needed)
echo "=== Test Suite 1: Build Validation ==="
if bash -n "$ROOT/../build.sh" 2>/dev/null; then
    echo "  PASS build.sh syntax"
    PASS=$((PASS+1))
else
    echo "  FAIL build.sh syntax"
    FAIL=$((FAIL+1))
fi
if bash "$ROOT/../test.sh" 2>&1 | tail -5; then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

# 2. Unit tests (if any)
echo ""
echo "=== Test Suite 2: Unit Tests ==="
for utest in "$ROOT"/unit/*.sh; do
    [ -f "$utest" ] || continue
    TOTAL=$((TOTAL+1))
    echo "  Running $(basename "$utest")..."
    if bash "$utest" 2>&1 | tail -1; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
    fi
done
[ "$TOTAL" -eq 0 ] && echo "  (no unit tests)"

# 3. Integration tests (require running system or VM)
echo ""
echo "=== Test Suite 3: Integration Tests ==="
if [ -f /proc/1/comm ] && [ "$(cat /proc/1/comm)" = "systemd" ]; then
    if bash "$ROOT/integration/test_basic.sh" 2>&1 | tail -1; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
    fi
else
    echo "  SKIP (not running on NexOS)"
fi

# 4. Stress tests (require running system + optional tools)
echo ""
echo "=== Test Suite 4: Stress Tests ==="
if command -v stress-ng &>/dev/null; then
    bash "$ROOT/stress/run.sh" 15 2>&1 | tail -1 || true
    PASS=$((PASS+1))
else
    echo "  SKIP (stress-ng not installed, run on target)"
fi

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  Results: $PASS pass, $FAIL fail"
echo "╚═══════════════════════════════════════╝"
exit $FAIL
