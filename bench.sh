#!/bin/bash
# NexOS Performance Benchmark Suite
set -euo pipefail
DATE=$(date +%Y%m%d-%H%M)
OUTDIR="/tmp/nexos-bench-$DATE"
mkdir -p "$OUTDIR"

# Compare against previous baseline
PREV_DIR="/var/lib/nexos/benchmarks"
[ -d "$PREV_DIR" ] && PREV=$(ls -t "$PREV_DIR" 2>/dev/null | head -1) || PREV=""

echo "NexOS Performance Benchmark - $DATE"
echo "Output: $OUTDIR"
echo ""

# System info
echo "=== System Info ===" | tee "$OUTDIR/system.info"
uname -a | tee -a "$OUTDIR/system.info"
head -1 /proc/cpuinfo | tee -a "$OUTDIR/system.info"
grep -c processor /proc/cpuinfo | xargs echo "CPUs:" | tee -a "$OUTDIR/system.info"
free -h | tee -a "$OUTDIR/system.info"
cat /proc/sys/net/ipv4/tcp_congestion_control | xargs echo "TCP CC:" | tee -a "$OUTDIR/system.info"
echo ""

# 1. CPU: sysbench
echo "=== CPU Benchmark (sysbench) ===" | tee "$OUTDIR/cpu.txt"
if command -v sysbench &>/dev/null; then
  sysbench cpu --cpu-max-prime=20000 run | tee -a "$OUTDIR/cpu.txt"
else
  echo "sysbench not installed" | tee -a "$OUTDIR/cpu.txt"
fi

# 2. Memory: sysbench
echo "=== Memory Benchmark (sysbench) ===" | tee "$OUTDIR/memory.txt"
if command -v sysbench &>/dev/null; then
  sysbench memory --memory-block-size=1M --memory-total-size=10G run | tee -a "$OUTDIR/memory.txt"
fi

# 3. Disk: fio sequential
echo "=== Disk Benchmark (fio - sequential) ===" | tee "$OUTDIR/disk-seq.txt"
if command -v fio &>/dev/null; then
  fio --name=seq-read --ioengine=libaio --direct=1 --bs=1M \
    --size=1G --numjobs=1 --runtime=30 --group_reporting \
    --rw=read --output="$OUTDIR/disk-seq.json" --output-format=json
  fio --name=seq-write --ioengine=libaio --direct=1 --bs=1M \
    --size=1G --numjobs=1 --runtime=30 --group_reporting \
    --rw=write --output="$OUTDIR/disk-seq-write.json" --output-format=json
fi

# 4. Disk: fio random
echo "=== Disk Benchmark (fio - random) ===" | tee "$OUTDIR/disk-rand.txt"
if command -v fio &>/dev/null; then
  fio --name=rand-read --ioengine=libaio --direct=1 --bs=4k \
    --size=1G --numjobs=4 --runtime=30 --group_reporting \
    --rw=randread --output="$OUTDIR/disk-rand.json" --output-format=json
  fio --name=rand-write --ioengine=libaio --direct=1 --bs=4k \
    --size=1G --numjobs=4 --runtime=30 --group_reporting \
    --rw=randwrite --output="$OUTDIR/disk-rand-write.json" --output-format=json
fi

# 5. Network: localhost TCP
echo "=== Network Benchmark (localhost TCP) ===" | tee "$OUTDIR/network.txt"
if command -v iperf3 &>/dev/null; then
  iperf3 -s -D -1 2>/dev/null || true
  sleep 1
  iperf3 -c 127.0.0.1 -t 30 -P 4 2>&1 | tee -a "$OUTDIR/network.txt"
else
  # Fallback: dd over nc
  echo "iperf3 not installed, using dd/netcat fallback" | tee -a "$OUTDIR/network.txt"
fi

# 6. Context switching
echo "=== Context Switch (stress-ng) ===" | tee "$OUTDIR/context.txt"
if command -v stress-ng &>/dev/null; then
  stress-ng --switch 4 --fork 2 --timeout 10s --metrics 2>&1 | tee -a "$OUTDIR/context.txt"
fi

# Summary
echo ""
echo "=== Summary ===" | tee "$OUTDIR/summary.txt"
if command -v sysbench &>/dev/null; then
  grep "total time:" "$OUTDIR/cpu.txt" 2>/dev/null | tee -a "$OUTDIR/summary.txt"
  grep "transferred" "$OUTDIR/memory.txt" 2>/dev/null | tee -a "$OUTDIR/summary.txt"
fi
if command -v fio &>/dev/null; then
  python3 -c "
import json
for f in ['disk-seq.json', 'disk-seq-write.json', 'disk-rand.json', 'disk-rand-write.json']:
    try:
        with open('$OUTDIR/' + f) as fp:
            d = json.load(fp)
        r = d['jobs'][0]
        print(f'{f}: {r[\"read\"][\"bw_mean\"]/1024:.0f} MB/s read, IOPS={r[\"read\"][\"iops_mean\"]:.0f}')
    except: pass" 2>/dev/null | tee -a "$OUTDIR/summary.txt" || true
fi
echo "" | tee -a "$OUTDIR/summary.txt"
echo "Benchmark complete. Results in: $OUTDIR"

# Save baseline for trend tracking
if [ -d "$PREV_DIR" ]; then
    cp -r "$OUTDIR" "$PREV_DIR/$DATE"
    echo "Baseline saved to $PREV_DIR/$DATE"
else
    echo "Skipping baseline save ($PREV_DIR not found)"
fi

# Trend comparison
if [ -n "$PREV" ] && [ -f "$PREV_DIR/$PREV/summary.txt" ]; then
    echo ""
    echo "=== Trend vs $PREV ==="
    diff -u "$PREV_DIR/$PREV/summary.txt" "$OUTDIR/summary.txt" 2>/dev/null || true
fi
