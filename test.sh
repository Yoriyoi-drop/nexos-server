#!/bin/bash
# NexOS - Test Suite
set -euo pipefail
NEXOS=$(dirname "$(readlink -f "$0")")
WORKDIR="$NEXOS/work"
ROOTFS="$WORKDIR/rootfs"
PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); echo -e "  \033[0;32mPASS\033[0m $1"; }
fail() { FAIL=$((FAIL+1)); echo -e "  \033[0;31mFAIL\033[0m $1"; }

echo "=== NexOS Test Suite ==="

# 1. Build script syntax
echo "[1/8] build.sh syntax check"
bash -n "$NEXOS/build.sh" 2>/dev/null && pass "build.sh syntax OK" || fail "build.sh syntax error"

# 2. Stage functions defined
echo "[2/8] All stages defined"
for stage in stage_kernel stage_rootfs_base stage_systemd stage_nginx stage_mariadb \
  stage_kubernetes stage_ssh stage_firewall stage_package_manager stage_config \
  stage_boot stage_iso; do
  grep -q "^${stage}()" "$NEXOS/build.sh" && pass "  $stage" || fail "  $stage"
done

# 3. Kernel config exists
echo "[3/8] Kernel config validation"
if [ -f "$NEXOS/configs/kernel.config" ]; then
  pass "kernel.config exists"
  for opt in CONFIG_SMP CONFIG_EFI CONFIG_NET CONFIG_IPV6 CONFIG_BLK_DEV_NVME \
    CONFIG_EXT4_FS CONFIG_BTRFS_FS CONFIG_XFS_FS CONFIG_OVERLAY_FS \
    CONFIG_SQUASHFS CONFIG_MODULES CONFIG_SECURITY_APPARMOR \
    CONFIG_WIREGUARD CONFIG_IMA CONFIG_EVM; do
    grep -q "^${opt}=y" "$NEXOS/configs/kernel.config" && pass "  $opt=y" || {
      grep -q "^${opt}=m" "$NEXOS/configs/kernel.config" && pass "  $opt=m" || fail "  $opt missing"
    }
  done
else
  fail "kernel.config not found"
fi

# 4. Initramfs structure
echo "[4/8] Initramfs scripts"
grep -q "switch_root" "$NEXOS/build.sh" && pass "initramfs switch_root" || fail "initramfs missing switch_root"
grep -q "overlay" "$NEXOS/build.sh" && pass "overlay filesystem" || fail "overlay not configured"

# 5. APK package manager
echo "[5/8] APK integration"
grep -q "apk add" "$NEXOS/build.sh" && pass "APK package installs" || fail "APK not used"

# 6. Systemd services
echo "[6/8] Systemd services"
for svc in nexos-cloud-init nexos-firstboot nexos-apk-setup nexos-watchdog; do
  grep -q "$svc.service" "$NEXOS/build.sh" && pass "service $svc" || fail "service $svc missing"
done

# 7. Security hardening
echo "[7/8] Security checks"
grep -q "CONFIG_SECURITY_APPARMOR=y" "$NEXOS/configs/kernel.config" && pass "AppArmor kernel" || fail "AppArmor kernel missing"
grep -q "lastchg.*0" "$NEXOS/build.sh" && pass "password force change" || fail "password policy missing"
grep -q "DEFAULT_SECURITY.*apparmor" "$NEXOS/build.sh" && pass "default AppArmor" || fail "AppArmor not default"

# 8. Kernel config count
echo "[8/8] Kernel config size"
COUNT=$(grep -c '=y\|=m' "$NEXOS/configs/kernel.config" 2>/dev/null || echo 0)
[ "$COUNT" -gt 3000 ] && pass "config options: $COUNT" || fail "too few options: $COUNT"

echo ""
echo "=== Results: $PASS pass, $FAIL fail ==="
exit $FAIL
