#!/bin/bash
# NexOS Integration Test Suite
# These tests require a running NexOS instance (bare-metal, VM, or container)
set -euo pipefail
PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); echo -e "  \033[0;32mPASS\033[0m $1"; }
fail() { FAIL=$((FAIL+1)); echo -e "  \033[0;31mFAIL\033[0m $1"; }
skip() { echo -e "  \033[1;33mSKIP\033[0m $1"; }

echo "=== NexOS Integration Tests ==="
echo ""

# 1. Kernel version
echo "[1/15] Kernel check"
KVER=$(uname -r 2>/dev/null || echo "")
[ -n "$KVER" ] && pass "Kernel: $KVER" || fail "No kernel"

# 2. systemd running
echo "[2/15] systemd"
PID1=$(cat /proc/1/comm 2>/dev/null || echo "")
[ "$PID1" = "systemd" ] && pass "systemd is PID 1" || fail "PID 1: $PID1"

# 3. APK available
echo "[3/15] Package manager"
command -v apk &>/dev/null && pass "APK installed" || fail "APK missing"
apk --version 2>/dev/null | head -1

# 4. Kernel modules loadable
echo "[4/15] Kernel modules"
lsmod 2>/dev/null | head -1 && pass "lsmod works" || fail "lsmod failed"
modinfo ext4 2>/dev/null >/dev/null && pass "ext4 module" || fail "ext4 module missing"

# 5. Network
echo "[5/15] Network stack"
ip link 2>/dev/null | grep -q LOOPBACK && pass "loopback up" || fail "No loopback"
ping -c 1 127.0.0.1 2>/dev/null >/dev/null && pass "IPv4 loopback" || warn "IPv4 ping failed"
ip addr 2>/dev/null | grep -q inet6 && pass "IPv6 enabled" || skip "IPv6 not configured"

# 6. Security - AppArmor
echo "[6/15] AppArmor"
if command -v aa-status &>/dev/null; then
    aa-status 2>/dev/null | head -3
    pass "AppArmor running"
elif [ -d /sys/kernel/security/apparmor ]; then
    pass "AppArmor kernel module present"
else
    fail "AppArmor not available"
fi

# 7. PAM
echo "[7/15] PAM"
[ -f /etc/pam.d/sshd ] && pass "PAM sshd config" || fail "PAM sshd missing"
[ -f /etc/pam.d/login ] && pass "PAM login config" || fail "PAM login missing"
grep -q "pam_unix.so.*sha512" /etc/pam.d/sshd 2>/dev/null && pass "SHA512 password" || warn "SHA512 not in PAM"

# 8. systemd services
echo "[8/15] systemd services"
for svc in systemd-networkd systemd-journald systemd-logind sshd apparmor; do
    systemctl is-enabled "$svc" &>/dev/null && pass "$svc enabled" || warn "$svc not enabled"
done

# 9. SSH
echo "[9/15] SSH"
[ -f /etc/ssh/sshd_config ] && pass "SSH config exists" || fail "SSH config missing"
grep -q "PermitRootLogin" /etc/ssh/sshd_config && pass "SSH root login configured" || warn "SSH root login not set"

# 10. Cloud-init
echo "[10/15] Cloud-init"
[ -f /usr/lib/systemd/system/nexos-cloud-init.service ] && pass "cloud-init service installed" || fail "cloud-init service missing"

# 11. Filesystem support
echo "[11/15] Filesystems"
for fs in ext4 btrfs xfs squashfs overlay; do
    grep -q "$fs" /proc/filesystems 2>/dev/null && pass "FS: $fs" || fail "FS: $fs missing"
done

# 12. Network protocols
echo "[12/15] Network protocols"
grep -q wireguard /proc/modules 2>/dev/null && pass "WireGuard module loaded" || skip "WireGuard not loaded"
grep -q "vlan" /proc/net/vlan/config 2>/dev/null && pass "VLAN support" || skip "No VLAN config"
ls /sys/class/net/bonding_masters 2>/dev/null && pass "Bonding available" || skip "No bonding"

# 13. TPM
echo "[13/15] TPM"
[ -d /sys/class/tpm ] && pass "TPM device present" || skip "No TPM hardware"

# 14. Watchdog
echo "[14/15] Watchdog"
[ -d /sys/class/watchdog ] && pass "Watchdog device present" || skip "No watchdog hardware"

# 15. Kernel config live-check
echo "[15/15] Kernel features"
zgrep -q "CONFIG_SECURITY_APPARMOR=y" /proc/config.gz 2>/dev/null && pass "AppArmor in kernel" || {
    modprobe configs 2>/dev/null || true
    zcat /proc/config.gz 2>/dev/null | grep -q "CONFIG_SECURITY_APPARMOR=y" && pass "AppArmor in kernel" || warn "Cannot verify kernel config"
}

echo ""
echo "=== Results: $PASS pass, $FAIL fail ==="
exit $FAIL
