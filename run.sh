#!/bin/bash
# NexOS Server - QEMU Runner
# Boots the distro without ISO (kernel+initramfs direct)
set -euo pipefail

NEXOS=$(dirname "$(readlink -f "$0")")
KERNEL="$NEXOS/work/iso-boot/vmlinuz-nexos"
INITRD="$NEXOS/work/iso-boot/initramfs-nexos.img"
MEM=${MEM:-2048}
CPUS=${CPUS:-2}
DEBUG=${DEBUG:-0}
DISPLAY=${DISPLAY:-0}

usage() {
    echo "Usage: $0 [options]"
    echo "  -m <MB>   Memory in MB (default: 2048)"
    echo "  -c <n>    CPU cores (default: 2)"
    echo "  -g        Graphical mode (VGA window + serial console)"
    echo "  -d        Debug mode (loglevel=7, stdio)"
    echo "  -k        Rebuild initramfs, then boot"
    echo "  -h        Show this help"
    exit 0
}

while getopts "m:c:gdkh" opt; do
    case $opt in
        m) MEM=$OPTARG ;;
        c) CPUS=$OPTARG ;;
        g) DISPLAY=1 ;;
        d) DEBUG=1 ;;
        k) REBUILD=1 ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Rebuild initramfs if requested or missing
if [ "${REBUILD:-0}" = "1" ] || [ ! -f "$INITRD" ]; then
    echo "==> Rebuilding initramfs..."
    cd "$NEXOS/work"
    rm -rf initramfs-run
    mkdir -p initramfs-run/{bin,sbin,dev,proc,sys,squash,overlay,newroot}
    cp "$NEXOS/work/rootfs/bin/busybox" initramfs-run/bin/
    mksquashfs "$NEXOS/work/rootfs" initramfs-run/root.squashfs \
        -comp zstd -b 1M -noappend 2>&1 | tail -1

    cd initramfs-run/bin
    for app in $(./busybox --list 2>/dev/null); do
        ln -sf busybox "$app" 2>/dev/null || true
    done
    cd "$NEXOS/work"

    cat > initramfs-run/init << 'EOF'
#!/bin/busybox sh
export PATH=/bin:/sbin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t squashfs /root.squashfs /squash
mount -t tmpfs tmpfs /overlay
mkdir -p /overlay/upper /overlay/work
mount -t overlay overlay -o lowerdir=/squash,upperdir=/overlay/upper,workdir=/overlay/work /newroot
mkdir -p /newroot/run /newroot/dev /newroot/proc /newroot/sys
exec /bin/switch_root /newroot /usr/lib/systemd/systemd
exec /bin/sh
EOF
    chmod +x initramfs-run/init
    mknod initramfs-run/dev/console c 5 1 2>/dev/null || true
    mknod initramfs-run/dev/null c 1 3 2>/dev/null || true

    cd initramfs-run
    find . | cpio -o -H newc | gzip -9 > "$INITRD"
    cd "$NEXOS"
    rm -rf "$NEXOS/work/initramfs-run"
    echo "==> Initramfs rebuilt"
fi

if [ ! -f "$KERNEL" ]; then
    echo "ERROR: Kernel not found at $KERNEL"
    echo "Run ./build.sh first"
    exit 1
fi

CMDLINE="root=/dev/ram0 rw console=ttyS0 net.ifnames=0"
CMDLINE="$CMDLINE systemd.unified_cgroup_hierarchy=1 systemd.device_timeout=15 loglevel=3"

QEMU_OPTS=(
    -m "$MEM" -smp "$CPUS"
    -kernel "$KERNEL"
    -initrd "$INITRD"
    -append "$CMDLINE"
    -nic user,model=virtio,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443
    -no-reboot
)

if [ "$DEBUG" = "1" ]; then
    QEMU_OPTS+=(
        -append "root=/dev/ram0 rw console=ttyS0 net.ifnames=0 systemd.unified_cgroup_hierarchy=1 systemd.device_timeout=15 loglevel=7 systemd.log_level=debug"
        -serial stdio
    )
    echo "==> Booting NexOS Server (debug)..."
    qemu-system-x86_64 "${QEMU_OPTS[@]}"
elif [ "$DISPLAY" = "1" ]; then
    QEMU_OPTS+=(
        -vga std
        -display gtk
        -serial mon:stdio
        -append "root=/dev/ram0 rw console=tty0 console=ttyS0 net.ifnames=0 systemd.unified_cgroup_hierarchy=1 systemd.device_timeout=15 loglevel=3"
    )
    echo "==> Booting NexOS Server (${MEM}MB, ${CPUS} cores, graphical)..."
    qemu-system-x86_64 "${QEMU_OPTS[@]}"
else
    QEMU_OPTS+=(-nographic)
    echo "==> Booting NexOS Server (${MEM}MB, ${CPUS} cores)..."
    echo "    Press Ctrl-A X to exit QEMU"
    qemu-system-x86_64 "${QEMU_OPTS[@]}"
fi
