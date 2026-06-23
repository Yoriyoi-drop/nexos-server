# NexOS Reference Benchmarks

Run `bench.sh` on the target hardware and commit results here.

## How to Bench

```bash
# On the running NexOS instance:
./bench.sh

# Results saved to:
#   /var/lib/nexos/benchmarks/YYYYMMDD-HHMMSS/
#   /tmp/nexos-bench-YYYYMMDD-HHMMSS/

# Trend comparison (auto):
# bench.sh compares against previous run automatically
```

## Expected Results (Reference: 8 vCPU / 16GB / NVMe)

| Test | Metric | Expected Range | Unit |
|------|--------|---------------|------|
| CPU (sysbench) | total time | < 20 | seconds |
| Memory throughput | transferred | > 5000 | MiB/sec |
| Disk seq read (fio) | bandwidth | > 1000 | MB/s |
| Disk seq write (fio) | bandwidth | > 500 | MB/s |
| Disk rand read (fio) | IOPS | > 50000 | IOPS |
| Disk rand write (fio) | IOPS | > 20000 | IOPS |
| Network loopback | throughput | > 20000 | Mbps |
| Context switch | rate | > 50000 | /sec |

## Comparison with Other Distros

| Distro | CPU (s) | Disk Seq R (MB/s) | Disk Rand R (IOPS) | Network (Mbps) |
|--------|---------|-------------------|--------------------|-----------------|
| NexOS | TBD | TBD | TBD | TBD |
| Ubuntu 24.04 | TBD | TBD | TBD | TBD |
| Alpine 3.20 | TBD | TBD | TBD | TBD |

## Notes

- BBR TCP congestion control is default (lower latency under load)
- kernel.sched_latency_ns=10000000 (desktop-like latency)
- tuned profile: nexos-server (performance governor)
- All benchmarks should be run 3x, median reported
- Test with `taskset -c 0-3` to pin to dedicated cores if on shared hardware
