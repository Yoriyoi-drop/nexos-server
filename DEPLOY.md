# NexOS Deployment Guide

## Table of Contents
1. [Build from Source](#build-from-source)
2. [Quick Start (QEMU)](#quick-start-qemu)
3. [Bare Metal Install](#bare-metal-install)
4. [Cloud Deployment](#cloud-deployment)
5. [Post-Install Configuration](#post-install-configuration)
6. [Network Configuration](#network-configuration)
7. [Security Hardening](#security-hardening)
8. [Monitoring](#monitoring)

## Build from Source

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get install -y build-essential flex bison libelf-dev libssl-dev \
  libncurses-dev bc cpio xorriso mtools zstd wget python3 python3-pip \
  git meson ninja-build pkg-config libpam0g-dev libapparmor-dev \
  libaudit-dev libcap-ng-dev libmount-dev libblkid-dev

# Build (downloads kernel + builds everything)
cd NexOS
./build.sh          # Full build
bash test.sh        # Verify
```

### Output

- `NexOS/nexos-server.iso` — bootable hybrid ISO (BIOS + UEFI)

## Quick Start (QEMU)

```bash
./run.sh                    # Default (serial console, 2G RAM)
./run.sh -g                 # With graphical display
./run.sh -m 4096            # 4G RAM
./run.sh -k /path/to/vmlinuz # Custom kernel

# Inside the VM:
# Login: root (no password - change immediately)
# The system will force a password change on first login.
```

## Bare Metal Install

### Write ISO to USB

```bash
dd if=nexos-server.iso of=/dev/sdX bs=4M status=progress
# WHERE /dev/sdX IS YOUR USB DRIVE - BE CAREFUL
```

### Install to Disk

Boot the ISO, then:

```bash
# List disks
lsblk

# Install to SSD/NVMe
nexos-install /dev/nvme0n1

# Install with specific filesystem
nexos-install /dev/sda
# Default: ext4
# Alternatives: btrfs, xfs

# Reboot after install
reboot
```

### Partition Layout (auto-created)

```
/dev/sda1   EFI System (512M)     FAT32   /boot
/dev/sda2   Linux Swap (4G)       swap    [swap]
/dev/sda3   Linux Root (rest)     ext4    /
```

## Cloud Deployment

### AWS EC2

1. Convert ISO to raw image:
```bash
qemu-img convert -O raw nexos-server.iso nexos-server.raw
```

2. Upload to S3 and register as AMI via VM Import/Export.

3. Or run in EC2 via QEMU nested virtualization.

4. Cloud-init handles SSH key injection automatically
   (IMDSv2 metadata endpoint).

### OpenStack / Proxmox

```bash
# Upload ISO to OpenStack
openstack image create --disk-format iso \
  --container-format bare \
  --file nexos-server.iso \
  nexos-server
```

### GCP

```bash
gcloud compute images create nexos-server --source-file=nexos-server.iso
```

## Post-Install Configuration

### First Boot

1. Login as root (password change forced)
2. Set hostname: `hostnamectl set-hostname server01`
3. Check network: `ip addr`
4. DHCP is enabled by default on all interfaces

### Package Management

```bash
# Update package cache
apk update

# Search packages
apk search <package>

# Install
apk add nginx postgresql

# Remove
apk del <package>

# List installed
apk list --installed
```

## Network Configuration

### Static IP

```bash
cat > /etc/systemd/network/10-static.network << EOF
[Match]
Name=en*

[Network]
Address=10.0.0.10/24
Gateway=10.0.0.1
DNS=1.1.1.1
DNS=8.8.8.8
EOF
systemctl restart systemd-networkd
```

### VLAN

```bash
cat > /etc/systemd/network/10-vlan.netdev << EOF
[NetDev]
Name=vlan10
Kind=vlan

[VLAN]
Id=10
EOF
```

### WireGuard

```bash
cat > /etc/systemd/network/10-wg0.netdev << EOF
[NetDev]
Name=wg0
Kind=wireguard

[WireGuard]
PrivateKey=<base64-private-key>
ListenPort=51820

[WireGuardPeer]
PublicKey=<base64-public-key>
AllowedIPs=10.0.1.0/24
Endpoint=peer.example.com:51820
EOF
```

### Bonding

```bash
cat > /etc/systemd/network/10-bond.netdev << EOF
[NetDev]
Name=bond0
Kind=bond

[Bond]
Mode=802.3ad
MIIMonitorSec=100ms
LACPTransmitRate=fast
EOF
```

## Security Hardening

### Password Policy

Already configured: SHA512, minlen=8, deny=6 after failed attempts.
PAM config at `/etc/pam.d/system-auth`.

### AppArmor

```bash
# Status
aa-status

# Enforce a profile
aa-enforce /etc/apparmor.d/usr.sbin.sshd

# Set to complain mode
aa-complain /etc/apparmor.d/usr.sbin.sshd

# Reload profiles
systemctl reload apparmor
```

### Firewall (nftables)

```bash
# Default rules are permissive (allow SSH + ICMP)
nft list ruleset

# Add custom rule
nft add rule inet filter input tcp dport 443 accept
```

### Secure Boot

```bash
# Generate signing keys
nexos-secureboot-setup

# Enroll key
mokutil --import /etc/nexos/secureboot/DB.der
# Reboot and follow MOK enrollment in UEFI menu
```

### IMA/EVM (File Integrity)

IMA and EVM are compiled into the kernel. To enable at boot:

```bash
# Add to kernel cmdline (in /etc/default/limine or bootloader config):
# ima_tcb ima_appraise=fix evm=fix

# After boot, setup policy:
echo "ima_policy=tcb" > /sys/kernel/security/ima/policy
```

## Monitoring

```bash
# System resources
htop
iotop

# Disk I/O
iostat -x 5

# Network
nethogs
iftop

# Logs
journalctl -xe
journalctl -u nginx.service -f

# Process tracking
pidstat 5

# Watchdog status
systemctl status nexos-watchdog

# kdump test
echo c > /proc/sysrq-trigger   # Triggers crash dump (caution)
```

## Backup and Recovery

```bash
# Snapshot root filesystem (btrfs)
nexos-snapshot pre-update-$(date +%Y%m%d)

# Rollback
nexos-rollback pre-update-20260623

# List snapshots
ls -la /var/lib/nexos/snapshots/
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| No network | `ip link`, `systemctl status systemd-networkd` |
| Services fail | `journalctl -xe`, `journalctl -p err -b` |
| Can't login | Check PAM: `tail -20 /var/log/auth.log` |
| AppArmor denies | `aa-status`, `dmesg \| grep -i apparmor` |
| Kernel panic | Check kdump: `ls /var/crash/` |
| Watchdog reboot | `journalctl -u nexos-watchdog`, `dmesg` |
