#!/bin/bash
# NexOS Stress Test Suite
# Run under varying load to validate stability
set -euo pipefail
DURATION="${1:-60}"
CLEANUP="${2:-true}"
PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); echo -e "  \033[0;32mPASS\033[0m $1"; }
fail() { FAIL=$((FAIL+1)); echo -e "  \033[0;31mFAIL\033[0m $1"; }
warn() { echo -e "  \033[1;33mWARN\033[0m $1"; }

echo "=== NexOS Stress Tests (${DURATION}s) ==="
echo ""

# 1. CPU stress (nproc threads)
echo "[1/6] CPU stress (${DURATION}s)"
if command -v stress-ng &>/dev/null; then
    stress-ng --cpu 0 --cpu-method matrixprod -t "${DURATION}s" --metrics 2>&1 | tail -1
    pass "CPU stress completed"
else
    skip "stress-ng not installed"
fi

# 2. Memory pressure
echo "[2/6] Memory stress (${DURATION}s)"
if command -v stress-ng &>/dev/null; then
    stress-ng --vm 2 --vm-bytes 80% -t "${DURATION}s" --metrics 2>&1 | tail -1
    pass "Memory stress completed"
else
    # Fallback: malloc/free loop
    python3 -c "
import os, time, sys
end = time.time() + ${DURATION}
while time.time() < end:
    try:
        x = bytearray(1024*1024*100)  # 100M
        del x
    except: pass
" 2>/dev/null && pass "Memory test (Python)" || fail "Memory test failed"
fi

# 3. Disk I/O
echo "[3/6] Disk stress (30s)"
if command -v fio &>/dev/null; then
    fio --name=stress-write --ioengine=libaio --direct=1 --bs=4k \
        --size=512M --numjobs=4 --runtime=30 --time_based \
        --rw=randrw --rwmixwrite=50 --group_reporting 2>&1 | grep -E 'IOPS|BW=' | head -2
    pass "Disk stress completed"
else
    dd if=/dev/zero of=/tmp/stress.tmp bs=1M count=1024 2>&1
    rm -f /tmp/stress.tmp
    pass "Disk stress (dd)"
fi

# 4. Context switching
echo "[4/6] Context switch stress (30s)"
if command -v stress-ng &>/dev/null; then
    stress-ng --switch 8 --fork 4 -t 30s --metrics 2>&1 | tail -1
    pass "Context switch test"
else
    skip "stress-ng not installed"
fi

# 5. Network throughput
echo "[5/6] Network stress (30s)"
if command -v iperf3 &>/dev/null; then
    iperf3 -s -D -1 2>/dev/null; sleep 1
    iperf3 -c 127.0.0.1 -t 15 2>&1 | tail -3
    pass "Network test"
else
    # Fallback: loopback flooding
    nc -l -p 9999 < /dev/zero &
    NC_PID=$!
    dd if=/dev/zero bs=1M count=100 2>/dev/null | nc 127.0.0.1 9999 2>/dev/null || true
    kill $NC_PID 2>/dev/null || true
    pass "Network test (nc)"
fi

# 6. Mixed load (all subsystems simultaneously)
echo "[6/6] Mixed load (${DURATION}s)"
if command -v stress-ng &>/dev/null; then
    stress-ng --cpu 4 --vm 1 --io 2 --hdd 1 --fork 2 \
        -t "${DURATION}s" --metrics 2>&1 | tail -1
    pass "Mixed load test"
else
    skip "stress-ng not installed"
fi

echo ""
echo "=== Stress Results: $PASS pass, $FAIL fail ==="
exit $FAIL
