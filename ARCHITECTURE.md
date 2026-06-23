# NexOS Architecture

## Overview

NexOS is a **Linux distribution builder** — a Bash-based build system that
assembles Linux 7.1 (XanMod), glibc, BusyBox, and systemd 255 into a
bootable server ISO. It is not a single binary or Rust application; it is
a infrastructure-as-code distribution toolkit.

```
┌─────────────────────────────────────────────────────────┐
│                   build.sh (orchestrator)                │
├─────────┬──────────┬──────────┬───────────┬─────────────┤
│ Stage 1 │ Stage 2  │ Stage 3  │ Stage 4-6 │ Stage 7-10  │
│ Kernel  │ Rootfs   │ systemd  │ Packages  │ APK + Conf  │
│ 7.1     │ BusyBox  │ 255      │ nginx     │ + Boot +    │
│         │ glibc    │          │ MariaDB   │ ISO         │
│         │          │          │ K8s       │             │
└─────────┴──────────┴──────────┴───────────┴─────────────┘
```

## Build Stages

| Stage | Function | What it does |
|-------|----------|-------------|
| 1 | `stage_kernel` | Patches + builds Linux 7.1 with server-optimized config |
| 2 | `stage_rootfs_base` | Installs BusyBox applets, glibc, device nodes |
| 3 | `stage_systemd` | Builds systemd 255 with PAM + AppArmor + audit + networkd |
| 4 | `stage_nginx` | Builds nginx for reverse proxy / load balancing |
| 5 | `stage_mariadb` | Builds MariaDB (enabled via flag, not default) |
| 6 | `stage_kubernetes` | Builds containerd, runc, cni-plugins, kubectl, kubelet |
| 7 | `stage_ssh` | Configures OpenSSH server with PAM + AppArmor |
| 8 | `stage_firewall` | Configures iptables/nftables rules |
| 9 | `stage_package_manager` | Installs APK (Alpine Package Keeper) + signing keys |
| 10 | `stage_config` | All configuration: PAM, AppArmor, cloud-init, network, watchdog, tuned |
| 11 | `stage_boot` | Creates overlay initramfs + Limine bootloader |
| 12 | `stage_iso` | Generates final bootable ISO |

## Kernel Configuration

The kernel config lives in `configs/kernel.config` (~5000 options).
On fresh builds, `stage_kernel` regenerates it via `make defconfig` then
applies ~150 server-optimized settings through `./scripts/config`.

Key subsystems enabled:
- **Scheduling**: PREEMPT_NONE (server), HZ_1000, NUMA balancing
- **Security**: AppArmor, IMA/EVM, lockdown LSM, module signing, TPM
- **Storage**: ext4, btrfs, XFS, MD RAID, dm-crypt, dm-verity, LVM2
- **Networking**: WireGuard, VLAN, Bonding, MPTCP, BBR, enterprise NICs
- **Reliability**: IOMMU, x2APIC, APEI, MEMORY_HOTPLUG, MEMORY_FAILURE
- **Debug**: lockdep, lockup detectors, kdump, watchdog

## Boot Process

```
Limine (EFI) → bzImage → initramfs (busybox) → switch_root → systemd
                                                     ↓
                                              overlay rootfs
                                              (squashfs + tmpfs overlay)
```

Two boot modes:
1. **Live ISO**: Overlay initramfs — squashfs root + tmpfs overlay (default)
2. **Installed**: Persistent initramfs — disk-based rootfs (via nexos-install)

## Deployment

### Build Requirements

- x86_64 Linux host
- gcc, make, bison, flex, libelf-dev, libssl-dev
- meson, ninja, pkg-config, libpam-dev, libapparmor-dev, libaudit-dev
- 16GB RAM, 20GB disk, 8+ cores recommended

### Build

```bash
git clone https://github.com/nexos/nexos
cd nexos
./build.sh
# Output: NexOS/nexos-server.iso
```

### Test in QEMU

```bash
./run.sh           # Serial console
./run.sh -g        # With display
./run.sh -h        # Help
```

### Install to Disk

Boot the ISO, then:
```bash
nexos-install /dev/sda
# Supports: /dev/sda, /dev/nvme0n1, /dev/vda
# Filesystems: ext4, btrfs, xfs
# Enables: swap, persistent initramfs, Limine bootloader
```

## Cloud Images

NexOS includes cloud-init support for AWS EC2, OpenStack, and GCP.
The `nexos-cloud-init` service runs at first boot, injects SSH keys
from metadata endpoints, sets hostname, and executes user-data scripts.

## Configuration Management

- **Ansible**: Installed by default (apk add ansible)
- **tuned**: Pre-configured `nexos-server` profile
- **systemd-networkd**: DHCP on all interfaces by default
- **AppArmor**: Profiles for sshd, nginx, containerd included

## Production Readiness

| Category | Status |
|----------|--------|
| Kernel architecture | PRODUCTION |
| Security | PRODUCTION |
| Storage | PRODUCTION |
| Networking | PRODUCTION |
| Reliability | PRODUCTION |
| Operations | BETA |
| Cloud readiness | BETA |
| Developer ecosystem | NOT IMPLEMENTED |
| Performance baselines | NOT MEASURED |

## Known Limitations

- No automated test suite execution in CI
- No rollback mechanism beyond manual btrfs snapshots
- IMA/EVM requires policy deployment at boot
- Secure Boot requires manual key enrollment
- No official cloud marketplace images
