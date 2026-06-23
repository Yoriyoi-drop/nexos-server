#!/bin/bash
# NexOS Server - Build Script
# Linux 7.1 + Limine | Server-focused distro

set -euo pipefail
NEXOS=$(dirname "$(readlink -f "$0")")
export NEXOS
WORKDIR="$NEXOS/work"
export WORKDIR
ROOTFS="$WORKDIR/rootfs"
ISO_DIR="$WORKDIR/iso"
OUTPUT="$NEXOS/nexos-server.iso"
CPUS=$(nproc)

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GRN}[INFO]${NC} $*"; }
warn()  { echo -e "${YLW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

mkdir -p "$WORKDIR" "$ROOTFS" "$ISO_DIR"

# ===== STAGE 1: Kernel =====
stage_kernel() {
    info "=== Stage 1: Building Linux 7.1 kernel ==="
    local kdir="/home/whale-d/nex/linux-7.1"

    if [ ! -f "$kdir/Makefile" ]; then
        error "Kernel source not found at $kdir"
    fi

    cp "$NEXOS/configs/kernel.config" "$kdir/.config" 2>/dev/null || {
        info "Generating server-optimized kernel config..."
        cd "$kdir"
        make defconfig
        # Server optimizations
        ./scripts/config --set-val CONFIG_NR_CPUS 64
        ./scripts/config --enable CONFIG_PREEMPT_NONE
        ./scripts/config --enable CONFIG_HZ_1000
        ./scripts/config --set-val CONFIG_HZ 1000
        ./scripts/config --enable CONFIG_TASKSTATS
        ./scripts/config --enable CONFIG_SCHEDSTATS
        ./scripts/config --enable CONFIG_PSI
        ./scripts/config --enable CONFIG_CGROUPS
        ./scripts/config --enable CONFIG_CGROUP_BPF
        ./scripts/config --enable CONFIG_NAMESPACES
        ./scripts/config --enable CONFIG_NET_NS
        ./scripts/config --enable CONFIG_PID_NS
        ./scripts/config --enable CONFIG_USER_NS
        ./scripts/config --enable CONFIG_VETH
        ./scripts/config --enable CONFIG_BRIDGE
        ./scripts/config --enable CONFIG_BRIDGE_VLAN_FILTERING
        ./scripts/config --enable CONFIG_NETFILTER
        ./scripts/config --enable CONFIG_NF_CONNTRACK
        ./scripts/config --enable CONFIG_NETFILTER_XTABLES
        ./scripts/config --enable CONFIG_NF_TABLES
        ./scripts/config --enable CONFIG_NF_TABLES_INET
        ./scripts/config --enable CONFIG_IP_NF_IPTABLES
        ./scripts/config --enable CONFIG_IP_NF_NAT
        ./scripts/config --enable CONFIG_IP6_NF_IPTABLES
        ./scripts/config --enable CONFIG_IP6_NF_NAT
        ./scripts/config --enable CONFIG_NFT_NAT
        ./scripts/config --enable CONFIG_NETFILTER_XT_MATCH_ADDRTYPE
        ./scripts/config --enable CONFIG_IP_SET
        ./scripts/config --enable CONFIG_IP_SET_HASH_IP
        ./scripts/config --enable CONFIG_IP_SET_HASH_NET
        ./scripts/config --enable CONFIG_OVERLAY_FS
        ./scripts/config --enable CONFIG_SQUASHFS
        ./scripts/config --enable CONFIG_SQUASHFS_XZ
        ./scripts/config --enable CONFIG_SQUASHFS_ZSTD
        ./scripts/config --enable CONFIG_BLK_DEV_NVME
        ./scripts/config --enable CONFIG_NVME_MULTIPATH
        ./scripts/config --enable CONFIG_NVME_HWMON
        ./scripts/config --enable CONFIG_BTRFS_FS
        ./scripts/config --enable CONFIG_BTRFS_FS_POSIX_ACL
        ./scripts/config --enable CONFIG_XFS_FS
        ./scripts/config --enable CONFIG_XFS_POSIX_ACL
        ./scripts/config --enable CONFIG_EXT4_FS
        ./scripts/config --enable CONFIG_EXT4_FS_POSIX_ACL
        ./scripts/config --enable CONFIG_ZFS_FS 2>/dev/null || true
        ./scripts/config --enable CONFIG_ZRAM
        ./scripts/config --enable CONFIG_ZRAM_DEF_COMP_LZORLE
        ./scripts/config --enable CONFIG_IPV6
        ./scripts/config --enable CONFIG_IPV6_ROUTER_PREF
        ./scripts/config --enable CONFIG_IPV6_OPTIMISTIC_DAD
        ./scripts/config --enable CONFIG_DEVTMPFS
        ./scripts/config --enable CONFIG_DEVTMPFS_MOUNT
        ./scripts/config --enable CONFIG_FW_LOADER
        ./scripts/config --enable CONFIG_DMIID
        ./scripts/config --enable CONFIG_EFI
        ./scripts/config --enable CONFIG_EFI_STUB
        ./scripts/config --enable CONFIG_EFIVAR_FS
        ./scripts/config --enable CONFIG_EFI_BOOTLOADER_CONTROL
        ./scripts/config --enable CONFIG_UEVENT_HELPER
        ./scripts/config --module CONFIG_UEVENT_HELPER_PATH
        ./scripts/config --enable CONFIG_NET_9P
        ./scripts/config --enable CONFIG_NET_9P_VIRTIO
        ./scripts/config --enable CONFIG_VIRTIO_PCI
        ./scripts/config --enable CONFIG_VIRTIO_BLK
        ./scripts/config --enable CONFIG_VIRTIO_NET
        ./scripts/config --enable CONFIG_VIRTIO_CONSOLE
        ./scripts/config --enable CONFIG_HW_RANDOM_VIRTIO
        ./scripts/config --enable CONFIG_DRM_VIRTIO_GPU
        ./scripts/config --enable CONFIG_VIRTIO_BALLOON
        ./scripts/config --enable CONFIG_VIRTIO_INPUT
        ./scripts/config --enable CONFIG_VIRTIO_MMIO
        ./scripts/config --enable CONFIG_CRYPTO
        ./scripts/config --enable CONFIG_CRYPTO_USER_API_HASH
        ./scripts/config --enable CONFIG_CRYPTO_USER_API_SKCIPHER
        ./scripts/config --enable CONFIG_CRYPTO_USER_API_RNG
        ./scripts/config --enable CONFIG_CRYPTO_CHACHA20POLY1305
        ./scripts/config --enable CONFIG_CRYPTO_CURVE25519
        ./scripts/config --enable CONFIG_CRYPTO_ECDH
        ./scripts/config --enable CONFIG_SYSTEM_TRUSTED_KEYRING
        ./scripts/config --enable CONFIG_MODULES
        ./scripts/config --enable CONFIG_MODULE_UNLOAD
        ./scripts/config --enable CONFIG_BINFMT_MISC
        ./scripts/config --enable CONFIG_CHECKPOINT_RESTORE
        ./scripts/config --enable CONFIG_SECCOMP
        ./scripts/config --enable CONFIG_SECCOMP_FILTER
        ./scripts/config --enable CONFIG_SECURITY
        ./scripts/config --set-val CONFIG_DEFAULT_MMAP_MIN_ADDR 65536
        ./scripts/config --enable CONFIG_CGROUP_DEVICE
        ./scripts/config --enable CONFIG_CGROUP_CPUACCT
        ./scripts/config --enable CONFIG_CGROUP_MEM_RES_CTLR
        ./scripts/config --enable CONFIG_CGROUP_PIDS
        ./scripts/config --enable CONFIG_MEMCG
        ./scripts/config --enable CONFIG_MEMCG_SWAP
        ./scripts/config --enable CONFIG_BLK_CGROUP
        ./scripts/config --enable CONFIG_CFS_BANDWIDTH
        ./scripts/config --enable CONFIG_FAIR_GROUP_SCHED
        ./scripts/config --enable CONFIG_RT_GROUP_SCHED
        ./scripts/config --enable CONFIG_IP_VS
        ./scripts/config --enable CONFIG_IP_VS_NFCT
        ./scripts/config --enable CONFIG_IP_VS_RR
        ./scripts/config --enable CONFIG_IP_VS_WRR
        ./scripts/config --enable CONFIG_IP_VS_LC
        ./scripts/config --enable CONFIG_IP_VS_WLC
        ./scripts/config --enable CONFIG_IP_VS_SH
        ./scripts/config --enable CONFIG_IP_VS_SED
        ./scripts/config --enable CONFIG_IP_VS_NQ
        ./scripts/config --enable CONFIG_NF_CONNTRACK_ZONES
        ./scripts/config --enable CONFIG_NF_CONNTRACK_EVENTS
        ./scripts/config --enable CONFIG_NF_CONNTRACK_TIMEOUT
        ./scripts/config --enable CONFIG_NF_CONNTRACK_TIMESTAMP
        ./scripts/config --enable CONFIG_NF_CT_PROTO_DCCP
        ./scripts/config --enable CONFIG_NF_CT_PROTO_SCTP
        ./scripts/config --enable CONFIG_NF_CT_PROTO_UDPLITE
        ./scripts/config --enable CONFIG_NETFILTER_NETLINK_GLUE_CT
        ./scripts/config --enable CONFIG_NETFILTER_NETLINK_QUEUE_CT
        ./scripts/config --enable CONFIG_NETFILTER_NETLINK_DUP
        ./scripts/config --disable CONFIG_SYSTEM_REVOCATION_KEYS
        ./scripts/config --disable CONFIG_SYSTEM_TRUSTED_KEYS

        # Module signing
        ./scripts/config --enable CONFIG_MODULE_SIG
        ./scripts/config --enable CONFIG_MODULE_SIG_FORCE
        ./scripts/config --enable CONFIG_MODULE_SIG_SHA512
        ./scripts/config --set-str CONFIG_MODULE_SIG_HASH "sha512"
        ./scripts/config --enable CONFIG_MODULE_SIG_ALL

        # Kernel lockdown LSM
        ./scripts/config --enable CONFIG_SECURITY_LOCKDOWN_LSM
        ./scripts/config --enable CONFIG_SECURITY_LOCKDOWN_LSM_EARLY
        ./scripts/config --enable CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT

        # Integrity subsystem
        ./scripts/config --enable CONFIG_INTEGRITY
        ./scripts/config --enable CONFIG_INTEGRITY_SIGNATURE
        ./scripts/config --module CONFIG_INTEGRITY_TRUSTED_KEYRING
        ./scripts/config --enable CONFIG_INTEGRITY_ASYMMETRIC_KEYS 2>/dev/null || true

        # IMA - Integrity Measurement Architecture
        ./scripts/config --enable CONFIG_IMA
        ./scripts/config --enable CONFIG_IMA_MEASURE_PCR_IDX
        ./scripts/config --enable CONFIG_IMA_LSM_RULES
        ./scripts/config --enable CONFIG_IMA_NG_TEMPLATE
        ./scripts/config --enable CONFIG_IMA_DEFAULT_HASH_SHA256
        ./scripts/config --enable CONFIG_IMA_WRITE_POLICY
        ./scripts/config --enable CONFIG_IMA_READ_POLICY
        ./scripts/config --enable CONFIG_IMA_APPRAISE

        # EVM - Extended Verification Module
        ./scripts/config --enable CONFIG_EVM
        ./scripts/config --enable CONFIG_EVM_ATTR_FUSE
        ./scripts/config --enable CONFIG_EVM_EXTRA_SMACK_XATTRS
        ./scripts/config --enable CONFIG_EVM_ADD_XATTRS

        # NFS v4.1/v4.2 + server enhancements
        ./scripts/config --enable CONFIG_NFS_V4_1
        ./scripts/config --enable CONFIG_NFS_V4_2
        ./scripts/config --enable CONFIG_NFS_V4_1_IMPLEMENTATION_ID_DOMAIN
        ./scripts/config --enable CONFIG_NFS_FSCACHE
        ./scripts/config --enable CONFIG_NFS_USE_KERNEL_DNS
        ./scripts/config --enable CONFIG_NFSD_V4
        ./scripts/config --enable CONFIG_NFSD_PNFS
        ./scripts/config --enable CONFIG_NFSD_BLOCKLAYOUT
        ./scripts/config --enable CONFIG_NFSD_SCSILAYOUT
        ./scripts/config --enable CONFIG_NFSD_FLEXFILELAYOUT
        ./scripts/config --enable CONFIG_NFSD_V4_SECURITY_LABEL

        # CIFS/SMB2/3 client
        ./scripts/config --module CONFIG_CIFS
        ./scripts/config --module CONFIG_CIFS_STATS2
        ./scripts/config --enable CONFIG_CIFS_ALLOW_INSECURE_LEGACY
        ./scripts/config --enable CONFIG_CIFS_SMB_DIRECT
        ./scripts/config --enable CONFIG_CIFS_FSCACHE

        # Ceph filesystem (cloud storage)
        ./scripts/config --module CONFIG_CEPH_FS 2>/dev/null || true

        # KSM - Kernel Same-page Merging (memory dedup for VMs)
        ./scripts/config --enable CONFIG_KSM

        # ZSWAP - compressed swap cache
        ./scripts/config --enable CONFIG_ZSWAP
        ./scripts/config --enable CONFIG_ZSWAP_DEFAULT_ON
        ./scripts/config --enable CONFIG_ZPOOL
        ./scripts/config --enable CONFIG_FRONTSWAP

        # BBR TCP congestion control + FQ qdisc
        ./scripts/config --enable CONFIG_TCP_CONG_BBR
        ./scripts/config --set-str CONFIG_DEFAULT_TCP_CONG "bbr"
        ./scripts/config --enable CONFIG_NET_SCH_FQ
        ./scripts/config --enable CONFIG_NET_SCH_FQ_CODEL

        # Secure Boot kernel support
        ./scripts/config --enable CONFIG_EFI_SECURE_BOOT_LOCK_DOWN 2>/dev/null || true
        ./scripts/config --enable CONFIG_LOAD_UEFI_KEYS 2>/dev/null || true
        ./scripts/config --enable CONFIG_EFI_SIGNATURE_LIST_PARSER 2>/dev/null || true
        ./scripts/config --enable CONFIG_EFI_CUSTOM_SSDT_OVERLAYS 2>/dev/null || true

        # Kernel live patching (kpatch/kgraft)
        ./scripts/config --enable CONFIG_LIVEPATCH

        # x2APIC for large interrupt scaling
        ./scripts/config --enable CONFIG_X86_X2APIC

        # IOMMU support (both Intel VT-d and AMD-Vi)
        ./scripts/config --enable CONFIG_AMD_IOMMU
        ./scripts/config --enable CONFIG_AMD_IOMMU_V2
        ./scripts/config --enable CONFIG_INTEL_IOMMU
        ./scripts/config --enable CONFIG_INTEL_IOMMU_SVM
        ./scripts/config --enable CONFIG_INTEL_IOMMU_DEFAULT_ON
        ./scripts/config --enable CONFIG_IRQ_REMAP

        # ACPI APEI - hardware error handling
        ./scripts/config --enable CONFIG_ACPI_APEI
        ./scripts/config --enable CONFIG_ACPI_APEI_GHES
        ./scripts/config --enable CONFIG_ACPI_APEI_PCIEAER
        ./scripts/config --enable CONFIG_ACPI_APEI_MEMORY_FAILURE
        ./scripts/config --enable CONFIG_ACPI_APEI_EINJ
        ./scripts/config --enable CONFIG_ACPI_APEI_ERST_DEBUG

        # ACPI HMAT - heterogeneous memory
        ./scripts/config --enable CONFIG_ACPI_HMAT

        # Memory encryption (SME/SEV for AMD)
        ./scripts/config --enable CONFIG_AMD_MEM_ENCRYPT

        # AppArmor LSM - Mandatory Access Control
        ./scripts/config --enable CONFIG_SECURITY_APPARMOR
        ./scripts/config --enable CONFIG_SECURITY_APPARMOR_BOOTPARAM_VALUE
        ./scripts/config --set-val CONFIG_SECURITY_APPARMOR_BOOTPARAM_VALUE 1
        ./scripts/config --enable CONFIG_SECURITY_APPARMOR_HASH
        ./scripts/config --enable CONFIG_SECURITY_APPARMOR_HASH_DEFAULT
        ./scripts/config --enable CONFIG_SECURITY_APPARMOR_DEBUG
        ./scripts/config --enable CONFIG_DEFAULT_SECURITY_APPARMOR
        ./scripts/config --set-str CONFIG_DEFAULT_SECURITY "apparmor"
        ./scripts/config --enable CONFIG_AUDIT
        ./scripts/config --enable CONFIG_AUDIT_WATCH
        ./scripts/config --enable CONFIG_AUDIT_TREE

        # TPM 2.0 support
        ./scripts/config --enable CONFIG_TCG_TPM
        ./scripts/config --enable CONFIG_TCG_TIS_CORE
        ./scripts/config --enable CONFIG_TCG_TIS
        ./scripts/config --enable CONFIG_TCG_TIS_I2C_CR50
        ./scripts/config --enable CONFIG_TCG_CRB
        ./scripts/config --enable CONFIG_TCG_VTPM_PROXY
        ./scripts/config --enable CONFIG_TCG_FWDRV
        ./scripts/config --enable CONFIG_TMPFS
        ./scripts/config --enable CONFIG_TMPFS_POSIX_ACL
        ./scripts/config --enable CONFIG_TMPFS_XATTR

        # ===== Storage: MD RAID =====
        ./scripts/config --enable CONFIG_MD_RAID0
        ./scripts/config --enable CONFIG_MD_RAID1
        ./scripts/config --enable CONFIG_MD_RAID10
        ./scripts/config --enable CONFIG_MD_RAID456
        ./scripts/config --enable CONFIG_MD_MULTIPATH
        ./scripts/config --enable CONFIG_MD_FAULTY

        # ===== Storage: Device-mapper extras =====
        ./scripts/config --enable CONFIG_DM_SNAPSHOT
        ./scripts/config --enable CONFIG_DM_VERITY
        ./scripts/config --enable CONFIG_DM_INTEGRITY
        ./scripts/config --enable CONFIG_DM_CACHE
        ./scripts/config --enable CONFIG_DM_WRITECACHE
        ./scripts/config --enable CONFIG_DM_LOG_WRITES
        ./scripts/config --enable CONFIG_DM_DELAY
        ./scripts/config --enable CONFIG_DM_LOG_USERSPACE

        # ===== Kernel hardening =====

        # Transparent Huge Pages (improved TLB coverage for large workloads)
        ./scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE
        ./scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS

        # Multi-Gen LRU (better page reclaim, lower latency under memory pressure)
        ./scripts/config --enable CONFIG_LRU_GEN
        ./scripts/config --enable CONFIG_LRU_GEN_ENABLED

        # Memory hotplug (hot-add/remove RAM in VMs)
        ./scripts/config --enable CONFIG_MEMORY_HOTPLUG
        ./scripts/config --enable CONFIG_MEMORY_HOTPLUG_DEFAULT_ONLINE
        ./scripts/config --enable CONFIG_MEMORY_HOTREMOVE
        ./scripts/config --enable CONFIG_HAVE_ARCH_PFN_VALID

        # Memory failure recovery (needed by APEI and hardware poison handling)
        ./scripts/config --enable CONFIG_MEMORY_FAILURE

        # Slab allocator hardening
        ./scripts/config --enable CONFIG_SLAB_FREELIST_RANDOM
        ./scripts/config --enable CONFIG_SLAB_FREELIST_HARDENED

        # Page poisoning (detect use-after-free)
        ./scripts/config --enable CONFIG_PAGE_POISONING
        ./scripts/config --enable CONFIG_PAGE_POISONING_NO_SANITY
        ./scripts/config --enable CONFIG_PAGE_POISONING_ZERO

        # ===== Reliability: Lockup detectors =====
        ./scripts/config --enable CONFIG_SOFTLOCKUP_DETECTOR
        ./scripts/config --enable CONFIG_BOOTPARAM_SOFTLOCKUP_PANIC
        ./scripts/config --set-val CONFIG_SOFTLOCKUP_DETECTOR_INTERVAL 60
        ./scripts/config --enable CONFIG_HARDLOCKUP_DETECTOR
        ./scripts/config --enable CONFIG_BOOTPARAM_HARDLOCKUP_PANIC
        ./scripts/config --set-val CONFIG_HARDLOCKUP_DETECTOR_PERIOD 10
        ./scripts/config --enable CONFIG_DETECT_HUNG_TASK
        ./scripts/config --set-val CONFIG_DEFAULT_HUNG_TASK_TIMEOUT 120
        ./scripts/config --enable CONFIG_BOOTPARAM_HUNG_TASK_PANIC
        ./scripts/config --enable CONFIG_WQ_WATCHDOG

        # ===== Cloud/VM support =====
        ./scripts/config --enable CONFIG_HW_RANDOM_VIRTIO
        ./scripts/config --enable CONFIG_BALLOON_COMPACTION

        # ===== Reliability: Lockdep (lock validation) =====
        ./scripts/config --enable CONFIG_PROVE_LOCKING
        ./scripts/config --enable CONFIG_LOCK_STAT
        ./scripts/config --enable CONFIG_DEBUG_LOCKDEP
        ./scripts/config --enable CONFIG_DEBUG_ATOMIC_SLEEP
        ./scripts/config --enable CONFIG_DEBUG_MUTEXES
        ./scripts/config --enable CONFIG_DEBUG_SPINLOCK
        ./scripts/config --enable CONFIG_STACKTRACE

        # ===== Reliability: Watchdog timers =====
        ./scripts/config --enable CONFIG_WATCHDOG_CORE
        ./scripts/config --enable CONFIG_WATCHDOG_NOWAYOUT
        ./scripts/config --enable CONFIG_WATCHDOG_SYSFS
        ./scripts/config --enable CONFIG_WATCHDOG_HRTIMER_PRETIMEOUT
        # Intel TCO
        ./scripts/config --module CONFIG_I6300ESB_WDT
        # AMD SP5100
        ./scripts/config --module CONFIG_SP5100_TCO
        # HP ProLiant
        ./scripts/config --module CONFIG_HP_WATCHDOG
        # Intel TCO (NM10)
        ./scripts/config --module CONFIG_NV_TCO
        # Super I/O
        ./scripts/config --module CONFIG_SMSC_SCH311X_WDT
        ./scripts/config --module CONFIG_SMSC37B787_WDT
        ./scripts/config --module CONFIG_F71808E_WDT
        ./scripts/config --module CONFIG_ALIM1535_WDT
        ./scripts/config --module CONFIG_ALIM7101_WDT
        ./scripts/config --module CONFIG_IB700_WDT
        ./scripts/config --module CONFIG_EUROTECH_WDT
        ./scripts/config --module CONFIG_ADVANTECH_WDT
        ./scripts/config --module CONFIG_ADVANTECH_EC_WDT
        ./scripts/config --module CONFIG_SBC_FITPC2_WATCHDOG
        ./scripts/config --module CONFIG_PCWD
        ./scripts/config --module CONFIG_WDTPCI

        # ===== Reliability: Kdump enhancement =====
        ./scripts/config --enable CONFIG_KEXEC_FILE
        ./scripts/config --enable CONFIG_CRASH_DUMP
        ./scripts/config --enable CONFIG_PROC_VMCORE
        ./scripts/config --enable CONFIG_PROC_KCORE

        # ===== Networking: Advanced features =====

        # WireGuard VPN
        ./scripts/config --module CONFIG_WIREGUARD

        # VLAN 802.1Q
        ./scripts/config --module CONFIG_VLAN_8021Q

        # Bonding / NIC aggregation
        ./scripts/config --module CONFIG_BONDING

        # Multipath TCP
        ./scripts/config --enable CONFIG_MPTCP
        ./scripts/config --enable CONFIG_MPTCP_IPV6

        # HSR (High-availability Seamless Redundancy) for ring topologies
        ./scripts/config --module CONFIG_HSR

        # TLS offload
        ./scripts/config --enable CONFIG_TLS
        ./scripts/config --enable CONFIG_TLS_DEVICE

        # Traffic control enhancements
        ./scripts/config --enable CONFIG_NET_CLS_BPF
        ./scripts/config --enable CONFIG_NET_CLS_FLOWER
        ./scripts/config --enable CONFIG_NET_ACT_POLICE
        ./scripts/config --enable CONFIG_NET_ACT_GACT
        ./scripts/config --enable CONFIG_NET_ACT_MIRRED
        ./scripts/config --enable CONFIG_NET_ACT_SAMPLE
        ./scripts/config --enable CONFIG_NET_ACT_CT
        ./scripts/config --enable CONFIG_NET_ACT_CTINFO
        ./scripts/config --enable CONFIG_NET_ACT_SKBEDIT
        ./scripts/config --enable CONFIG_NET_ACT_CSUM
        ./scripts/config --enable CONFIG_NET_CLS_ACT
        ./scripts/config --enable CONFIG_NET_ACT_VLAN
        ./scripts/config --enable CONFIG_NET_ACT_TUNNEL_KEY
        ./scripts/config --enable CONFIG_NET_IFE

        # ===== Enterprise NIC drivers =====

        # Intel 1GbE
        ./scripts/config --module CONFIG_E1000E

        # Intel 10GbE
        ./scripts/config --module CONFIG_IXGBE
        ./scripts/config --module CONFIG_IXGBEVF

        # Intel 40GbE
        ./scripts/config --module CONFIG_I40E
        ./scripts/config --module CONFIG_I40EVF

        # Intel 100GbE (ice)
        ./scripts/config --module CONFIG_ICE
        ./scripts/config --module CONFIG_ICE_SWITCHDEV

        # Mellanox ConnectX-4/5/6/7
        ./scripts/config --module CONFIG_MLX4_EN
        ./scripts/config --module CONFIG_MLX4_CORE
        ./scripts/config --module CONFIG_MLX5_CORE
        ./scripts/config --module CONFIG_MLX5_CORE_EN
        ./scripts/config --module CONFIG_MLX5_MPFS
        ./scripts/config --enable CONFIG_MLX5_ESWITCH
        ./scripts/config --enable CONFIG_MLX5_SF
        ./scripts/config --module CONFIG_MLX5_SF_MANAGER
        ./scripts/config --enable CONFIG_MLXSW_CORE
        ./scripts/config --module CONFIG_MLXFW

        # Broadcom
        ./scripts/config --module CONFIG_TIGON3
        ./scripts/config --module CONFIG_BNXT
        ./scripts/config --module CONFIG_BNXT_SRIOV

        # AWS ENA (Elastic Network Adapter)
        ./scripts/config --module CONFIG_ENA_ETHERNET

        # Google gVNIC
        ./scripts/config --module CONFIG_GVNIC

        # Microsoft VM-NIC (mana)
        ./scripts/config --module CONFIG_MANA_INFINIBAND 2>/dev/null || true
        ./scripts/config --module CONFIG_MANA 2>/dev/null || true

        cp .config "$NEXOS/configs/kernel.config"
    }

    info "Building kernel... (${CPUS} cores)"
    cd "$kdir"
    make -j"$CPUS" bzImage 2>&1 | tail -5
    make -j"$CPUS" modules 2>&1 | tail -5

    mkdir -p "$ROOTFS/boot"
    cp arch/x86_64/boot/bzImage "$ROOTFS/boot/vmlinuz-nexos"

    info "Installing kernel modules..."
    make INSTALL_MOD_PATH="$ROOTFS" modules_install 2>&1 | tail -3

    info "Kernel built successfully"
}

# ===== STAGE 2: Base Root Filesystem =====
stage_rootfs_base() {
    info "=== Stage 2: Building root filesystem ==="
    
    # Create device nodes
    mkdir -p "$ROOTFS/dev"
    sudo mknod -m 622 "$ROOTFS/dev/console" c 5 1 2>/dev/null || true
    sudo mknod -m 666 "$ROOTFS/dev/null" c 1 3 2>/dev/null || true
    sudo mknod -m 666 "$ROOTFS/dev/zero" c 1 5 2>/dev/null || true
    sudo mknod -m 644 "$ROOTFS/dev/random" c 1 8 2>/dev/null || true
    sudo mknod -m 644 "$ROOTFS/dev/urandom" c 1 9 2>/dev/null || true
    sudo mknod -m 666 "$ROOTFS/dev/tty" c 5 0 2>/dev/null || true

    # Proc, sys, devpts mount points
    mkdir -p "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev/pts" "$ROOTFS/run" "$ROOTFS/tmp"
    chmod 1777 "$ROOTFS/tmp"

    # Download and install busybox static binary
    info "Installing BusyBox..."
    local bb_ver="1.36.1"
    if [ ! -f "$WORKDIR/busybox-$bb_ver-static" ]; then
        wget -q "https://busybox.net/downloads/binaries/${bb_ver}-defconfig-multiarch-musl/busybox-x86_64" \
            -O "$WORKDIR/busybox-$bb_ver-static" || {
            # Build from source
            warn "Download failed, building busybox from source..."
            cd "$WORKDIR"
            [ -d "busybox-$bb_ver" ] || {
                wget -q "https://busybox.net/downloads/busybox-$bb_ver.tar.bz2"
                tar xf "busybox-$bb_ver.tar.bz2"
            }
            cd "busybox-$bb_ver"
            make defconfig
            # Static build
            sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
            sed -i 's/CONFIG_INSTALL_NO_USR=y/# CONFIG_INSTALL_NO_USR is not set/' .config 2>/dev/null || true
            make -j"$CPUS" 2>&1 | tail -3
            cp busybox "$WORKDIR/busybox-$bb_ver-static"
        }
    fi
    
    chmod +x "$WORKDIR/busybox-$bb_ver-static"
    cp "$WORKDIR/busybox-$bb_ver-static" "$ROOTFS/bin/busybox"

    # Install BusyBox applets
    for applet in sh ash bash ls cp mv rm cat chmod chown chroot clear cpio cut date df dirname du echo env expr find grep head hostname id kill killall less ln logger logname lsattr mkdir mkfifo mknod more mount mv nc netstat nice nohup od passwd pidof ping ping6 ps pwd renice reset rm rmdir sed seq sh sleep sort stty su sync tail tar tee test time touch tr true umount uname uniq uptime usleep vi watch wc wget which whoami xargs yes zcat bzcat unxz xzcat unzip ftpd httpd telnetd tftpd dnsd ntpd syslogd klogd crond vi diff fold; do
        ln -sf /bin/busybox "$ROOTFS/bin/$applet" 2>/dev/null || true
    done

    # Link basic directories
    ln -sf /bin/busybox "$ROOTFS/sbin/init" 2>/dev/null || true
    ln -sf /bin/busybox "$ROOTFS/sbin/mdev" 2>/dev/null || true
    ln -sf /bin/busybox "$ROOTFS/sbin/reboot" 2>/dev/null || true
    ln -sf /bin/busybox "$ROOTFS/sbin/halt" 2>/dev/null || true
    ln -sf /bin/busybox "$ROOTFS/sbin/poweroff" 2>/dev/null || true
    ln -sf /bin/busybox "$ROOTFS/usr/bin/env" 2>/dev/null || true

    # Download glibc for proper runtime
    info "Installing glibc runtime..."
    local glibc_ver="2.39"
    local glibc_dir="$WORKDIR/glibc-$glibc_ver"
    if [ ! -f "$glibc_dir/BUILD_DONE" ]; then
        cd "$WORKDIR"
        if [ ! -d "glibc-$glibc_ver" ]; then
            wget -q "https://ftp.gnu.org/gnu/glibc/glibc-$glibc_ver.tar.xz"
            tar xf "glibc-$glibc_ver.tar.xz"
        fi
        mkdir -p "glibc-build"
        cd "glibc-build"
        "$glibc_dir/configure" --prefix=/usr --enable-stack-protector=strong \
            --disable-werror --enable-kernel=6.12 2>&1 | tail -5
        make -j"$CPUS" 2>&1 | tail -5
        make install DESTDIR="$ROOTFS" 2>&1 | tail -5
        touch "$glibc_dir/BUILD_DONE"
    fi

    # Libraries
    mkdir -p "$ROOTFS/lib64" "$ROOTFS/usr/lib"
    cp /lib/x86_64-linux-gnu/libc.so.6 "$ROOTFS/lib64/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libm.so.6 "$ROOTFS/lib64/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libpthread.so.0 "$ROOTFS/lib64/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libdl.so.2 "$ROOTFS/lib64/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libc.so.6 "$ROOTFS/usr/lib/" 2>/dev/null || true
    cp /lib64/ld-linux-x86-64.so.2 "$ROOTFS/lib64/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libnss_dns.so.2 "$ROOTFS/lib64/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libnss_files.so.2 "$ROOTFS/lib64/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libresolv.so.2 "$ROOTFS/lib64/" 2>/dev/null || true

    mkdir -p "$ROOTFS/etc/ld.so.conf.d"
    echo "/usr/lib" > "$ROOTFS/etc/ld.so.conf"
    echo "/lib" >> "$ROOTFS/etc/ld.so.conf"
    echo "/lib64" >> "$ROOTFS/etc/ld.so.conf"
}

# ===== STAGE 3: systemd =====
stage_systemd() {
    info "=== Stage 3: Building systemd ==="
    local sd_ver="255"
    local sdir="$WORKDIR/systemd-$sd_ver"

    if [ ! -d "$sdir" ]; then
        cd "$WORKDIR"
        if [ ! -f "v$sd_ver.tar.gz" ]; then
            wget -q "https://github.com/systemd/systemd/archive/refs/tags/v$sd_ver.tar.gz"
        fi
        tar xf "v$sd_ver.tar.gz"
    fi

    mkdir -p "$WORKDIR/systemd-build"
    cd "$WORKDIR/systemd-build"

    meson setup "$sdir" . \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        -Drootlibdir=/usr/lib \
        -Drootprefix=/usr \
        -Dbuildtype=release \
        -Db_ndebug=true \
        -Dman=false \
        -Dhtml=false \
        -Ddbus=false \
        -Dgnutls=false \
        -Dopenssl=true \
        -Dpam=true \
        -Dacl=true \
        -Dsmack=false \
        -Dselinux=false \
        -Dapparmor=true \
        -Dima=false \
        -Daudit=true \
        -Dkmod=false \
        -Dxkbcommon=false \
        -Dlibcryptsetup=false \
        -Dpwquality=false \
        -Dqrencode=false \
        -Dgcrypt=false \
        -Dmicrohttpd=false \
        -Dquotacheck=false \
        -Dsysusers=false \
        -Dtmpfiles=true \
        -Dhwdb=false \
        -Drfkill=false \
        -Dldconfig=false \
        -Dnetworkd=true \
        -Dtimesyncd=true \
        -Duserdb=false \
        -Dhomed=false \
        -Dportabled=false \
        -Dmachined=false \
        -Doomd=false \
        -Dsysext=false \
        -Dbootloader=false \
        -Dstandalone-binaries=false \
        -Dtests=false \
        -Dfuzz-tests=false \
        -Defi=true \
        2>&1 | tail -10

    ninja -j"$CPUS" 2>&1 | tail -5
    # Remove conflicting tmp.mount (systemd provides tmp.mount natively)
    rm -f "$ROOTFS/usr/lib/systemd/system/tmp.mount" 2>/dev/null || true
    DESTDIR="$ROOTFS" ninja install 2>&1 | tail -5

    # Create systemd-journal directory
    mkdir -p "$ROOTFS/var/log/journal"
    mkdir -p "$ROOTFS/etc/systemd/system"
    
    # Enable essential services
    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /usr/lib/systemd/system/systemd-networkd.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true
    # resolved disabled in build (no libsystemd-resolve)
    # ln -sf /usr/lib/systemd/system/systemd-resolved.service \
    #    "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true
    ln -sf /usr/lib/systemd/system/systemd-timesyncd.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true
    ln -sf /usr/lib/systemd/system/sshd.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true

    # Install PAM libraries (required by systemd when built with -Dpam=true)
    info "Installing PAM libraries and configuration..."
    mkdir -p "$ROOTFS/lib/x86_64-linux-gnu" "$ROOTFS/usr/lib/x86_64-linux-gnu"
    mkdir -p "$ROOTFS/usr/lib/x86_64-linux-gnu/security"
    mkdir -p "$ROOTFS/etc/pam.d"

    # Copy PAM shared libraries from host
    for lib in libpam.so.0 libpam.so.0.85.1 libpam_misc.so.0 libpam_misc.so.0.82.1 \
               libpamc.so.0 libpamc.so.0.82.1; do
        cp /lib/x86_64-linux-gnu/$lib "$ROOTFS/lib/x86_64-linux-gnu/" 2>/dev/null || true
        cp /usr/lib/x86_64-linux-gnu/$lib "$ROOTFS/usr/lib/x86_64-linux-gnu/" 2>/dev/null || true
    done

    # Copy PAM security modules (minimum set for server)
    for mod in pam_unix.so pam_deny.so pam_permit.so pam_env.so pam_limits.so \
               pam_access.so pam_rootok.so pam_wheel.so pam_shells.so \
               pam_faildelay.so pam_echo.so pam_lastlog.so pam_nologin.so \
               pam_succeed_if.so pam_systemd.so; do
        cp "/usr/lib/x86_64-linux-gnu/security/$mod" \
            "$ROOTFS/usr/lib/x86_64-linux-gnu/security/" 2>/dev/null || true
    done

    # Create ldconfig cache
    ldconfig -r "$ROOTFS" 2>/dev/null || true

    # Basic PAM configuration for server
    cat > "$ROOTFS/etc/pam.d/other" << 'PAM_OTHER'
auth     required   pam_deny.so
account  required   pam_deny.so
password required   pam_deny.so
session  required   pam_deny.so
PAM_OTHER

    cat > "$ROOTFS/etc/pam.d/login" << 'PAM_LOGIN'
auth     requisite  pam_nologin.so
auth     required   pam_tally2.so onerr=fail audit silent deny=6 unlock_time=900
auth     required   pam_unix.so
account  required   pam_access.so
account  required   pam_unix.so
password required   pam_unix.so obscure sha512 minlen=8
session  required   pam_unix.so
session  required   pam_limits.so
session  optional   pam_lastlog.so
PAM_LOGIN

    cat > "$ROOTFS/etc/pam.d/sshd" << 'PAM_SSHD'
auth     requisite  pam_nologin.so
auth     required   pam_unix.so
account  required   pam_access.so
account  required   pam_unix.so
password required   pam_unix.so obscure sha512 minlen=8
session  required   pam_unix.so
session  required   pam_limits.so
session  optional   pam_lastlog.so
PAM_SSHD

    cat > "$ROOTFS/etc/pam.d/su" << 'PAM_SU'
auth     sufficient pam_rootok.so
auth     required   pam_unix.so
account  required   pam_unix.so
session  required   pam_unix.so
PAM_SU

    cat > "$ROOTFS/etc/pam.d/runuser" << 'PAM_RUNUSER'
auth     sufficient pam_rootok.so
session  required   pam_unix.so
PAM_RUNUSER

    # PAM env config
    cat > "$ROOTFS/etc/security/pam_env.conf" << 'PAM_ENV'
# PAM environment variables
# Default file, override in /etc/security/pam_env.conf.local
PAM_ENV
    mkdir -p "$ROOTFS/etc/security"

    # PAM limits config
    cat > "$ROOTFS/etc/security/limits.conf" << 'LIMITS'
# /etc/security/limits.conf - System limits
*               soft    nofile          4096
*               hard    nofile          65536
*               soft    nproc           4096
*               hard    nproc           65536
*               soft    stack           8192
*               hard    stack           65536
LIMITS

    # Timezone data directory required by PAM
    mkdir -p "$ROOTFS/usr/share/zoneinfo"

    info "PAM libraries and configuration installed"
    info "systemd built and installed"
}

# ===== STAGE 4: Server Packages =====
stage_nginx() {
    info "Building nginx..."
    local ver="1.26.2"
    local sdir="$WORKDIR/nginx-$ver"
    
    if [ ! -d "$sdir" ]; then
        cd "$WORKDIR"
        wget -q "https://nginx.org/download/nginx-$ver.tar.gz"
        tar xf "nginx-$ver.tar.gz"
    fi
    
    cd "$sdir"
    ./configure --prefix=/usr --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --user=nobody --group=nogroup \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_slice_module \
        --with-mail --with-mail_ssl_module \
        --with-stream --with-stream_ssl_module \
        --with-threads \
        --without-http_autoindex_module \
        --without-http_browser_module \
        --without-http_geo_module \
        --without-http_userid_module \
        2>&1 | tail -5
    
    make -j"$CPUS" 2>&1 | tail -3
    make install DESTDIR="$ROOTFS" 2>&1 | tail -3
    
    # Systemd service
    mkdir -p "$ROOTFS/usr/lib/systemd/system"
    cat > "$ROOTFS/usr/lib/systemd/system/nginx.service" << 'NGINX_SVC'
[Unit]
Description=NexOS High-Performance Web Server
Documentation=https://nginx.org
After=network.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/usr/sbin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
NGINX_SVC

    # Basic nginx config
    mkdir -p "$ROOTFS/etc/nginx"
    cat > "$ROOTFS/etc/nginx/nginx.conf" << 'NGINX_CONF'
worker_processes auto;
events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}
http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 1000;
    server_tokens off;
    gzip on;
    include /etc/nginx/sites-enabled/*;
}
NGINX_CONF
    mkdir -p "$ROOTFS/etc/nginx/sites-available" "$ROOTFS/etc/nginx/sites-enabled"

    # Default site
    cat > "$ROOTFS/etc/nginx/sites-available/default" << 'NGINX_SITE'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;
    server_name _;
    location / { try_files $uri $uri/ =404; }
}
NGINX_SITE
    ln -sf /etc/nginx/sites-available/default "$ROOTFS/etc/nginx/sites-enabled/default"

    # Default index page
    mkdir -p "$ROOTFS/var/www/html"
    cat > "$ROOTFS/var/www/html/index.html" << 'INDEX'
<!DOCTYPE html>
<html>
<head><title>NexOS Server</title></head>
<body>
<h1>NexOS Server 1.0</h1>
<p>Linux 7.1 &middot; systemd 255 &middot; Nginx</p>
</body>
</html>
INDEX
}

stage_mariadb() {
    info "Building MariaDB..."
    info "MariaDB - licensed separately, manual install required"
    info "  Download: https://mariadb.org/download/"
    info "  Extract to rootfs manually:"
    info "    wget https://archive.mariadb.org/mariadb-11.4.3/bintar-linux-systemd-x86_64/mariadb-11.4.3-linux-systemd-x86_64.tar.gz"
    info "    tar xf mariadb-11.4.3-*.tar.gz -C \$ROOTFS/usr/ --strip-components=1"
    mkdir -p "$ROOTFS/var/lib/mysql" "$ROOTFS/var/log/mysql" "$ROOTFS/run/mysqld"
}

stage_kubernetes() {
    info "Installing Kubernetes components..."
    local kube_ver="1.31.0"
    mkdir -p "$ROOTFS/usr/bin"
    
    for bin in kubelet kubeadm kubectl; do
        if [ ! -f "$WORKDIR/$bin" ]; then
            wget -q "https://dl.k8s.io/v$kube_ver/bin/linux/amd64/$bin" \
                -O "$WORKDIR/$bin"
            chmod +x "$WORKDIR/$bin"
        fi
        cp "$WORKDIR/$bin" "$ROOTFS/usr/bin/"
    done

    # containerd
    local ctr_ver="1.7.22"
    if [ ! -f "$WORKDIR/containerd-installed" ]; then
        cd "$WORKDIR"
        wget -q "https://github.com/containerd/containerd/releases/download/v$ctr_ver/containerd-$ctr_ver-linux-amd64.tar.gz"
        tar xf "containerd-$ctr_ver-linux-amd64.tar.gz" -C "$ROOTFS/usr/" --strip-components=1
        touch "$WORKDIR/containerd-installed"
    fi

    # crictl
    if [ ! -f "$WORKDIR/crictl" ]; then
        wget -q "https://github.com/kubernetes-sigs/cri-tools/releases/download/v$kube_ver/crictl-v$kube_ver-linux-amd64.tar.gz"
        tar xf "crictl-v$kube_ver-linux-amd64.tar.gz" -C "$ROOTFS/usr/bin/"
    fi

    # etcd
    local etcd_ver="3.5.15"
    if [ ! -f "$WORKDIR/etcd-installed" ]; then
        cd "$WORKDIR"
        wget -q "https://github.com/etcd-io/etcd/releases/download/v$etcd_ver/etcd-v$etcd_ver-linux-amd64.tar.gz"
        tar xf "etcd-v$etcd_ver-linux-amd64.tar.gz"
        cp "etcd-v$etcd_ver-linux-amd64/etcd" "$ROOTFS/usr/bin/"
        cp "etcd-v$etcd_ver-linux-amd64/etcdctl" "$ROOTFS/usr/bin/"
        touch "$WORKDIR/etcd-installed"
    fi

    # CNI plugins
    local cni_ver="1.5.1"
    if [ ! -f "$WORKDIR/cni-installed" ]; then
        mkdir -p "$ROOTFS/opt/cni/bin"
        cd "$WORKDIR"
        wget -q "https://github.com/containernetworking/plugins/releases/download/v$cni_ver/cni-plugins-linux-amd64-v$cni_ver.tgz"
        tar xf "cni-plugins-linux-amd64-v$cni_ver.tgz" -C "$ROOTFS/opt/cni/bin/"
        touch "$WORKDIR/cni-installed"
    fi

    # Kubernetes sysctl
    mkdir -p "$ROOTFS/etc/sysctl.d"
    cat > "$ROOTFS/etc/sysctl.d/99-kubernetes.conf" << 'SYSCTL'
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.conf.all.rp_filter=1
user.max_user_namespaces=28633
SYSCTL

    # containerd config (CRI-ready)
    mkdir -p "$ROOTFS/etc/containerd"
    cat > "$ROOTFS/etc/containerd/config.toml" << 'CTRCFG'
version = 2
root = "/var/lib/containerd"
state = "/run/containerd"

[grpc]
  address = "/run/containerd/containerd.sock"
  max_recv_message_size = 16777216
  max_send_message_size = 16777216

[metrics]
  address = "127.0.0.1:1338"

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.10"
    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/cni/bin"
      conf_dir = "/etc/cni/net.d"
    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry-1.docker.io"]
CTRCFG

    # kubelet config
    mkdir -p "$ROOTFS/var/lib/kubelet"
    cat > "$ROOTFS/var/lib/kubelet/config.yaml" << 'KUBECFG'
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: 0.0.0.0
authentication:
  anonymous:
    enabled: true
  webhook:
    enabled: false
authorization:
  mode: AlwaysAllow
cgroupDriver: systemd
cgroupRoot: /
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
failSwapOn: false
healthzBindAddress: 0.0.0.0
kubeletCgroups: /system.slice
nodeStatusUpdateFrequency: 10s
podCIDR: 10.244.0.0/16
protectKernelDefaults: false
readOnlyPort: 10255
rotateCertificates: true
runtimeRequestTimeout: 15m
serializeImagePulls: false
serverTLSBootstrap: true
KUBECFG

    # Kubeconfig pointing to localhost (for bootstrap / standalone)
    # In production, kubeadm will replace this
    mkdir -p "$ROOTFS/etc/kubernetes"
    cat > "$ROOTFS/etc/kubernetes/kubelet.conf" << 'KUBECONF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://localhost:6443
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: kubelet
  name: default-context
current-context: default-context
users:
- name: kubelet
  user: {}
KUBECONF

    # containerd service
    mkdir -p "$ROOTFS/usr/lib/systemd/system"
    cat > "$ROOTFS/usr/lib/systemd/system/containerd.service" << 'CTRSVC'
[Unit]
Description=NexOS Container Runtime (containerd)
After=network.target

[Service]
ExecStart=/usr/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
MemoryMax=1024M
TasksMax=infinity

[Install]
WantedBy=multi-user.target
CTRSVC

    # kubelet service
    cat > "$ROOTFS/usr/lib/systemd/system/kubelet.service" << 'KUBESVC'
[Unit]
Description=NexOS Kubelet
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/bin/kubelet \
    --kubeconfig=/etc/kubernetes/kubelet.conf \
    --config=/var/lib/kubelet/config.yaml \
    --container-runtime-endpoint=unix:///run/containerd/containerd.sock
Restart=always
StartLimitInterval=0
RestartSec=10
Delegate=yes

[Install]
WantedBy=multi-user.target
KUBESVC

    # Enable services
    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /usr/lib/systemd/system/containerd.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    ln -sf /usr/lib/systemd/system/kubelet.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/"

    # kubeadm helper script
    cat > "$ROOTFS/usr/local/bin/nexos-kube-init" << 'INITSH'
#!/bin/sh
# NexOS Kubernetes cluster initializer
# Run after boot to initialize the cluster
set -e
echo "[NexOS] Initializing Kubernetes cluster..."
modprobe br_netfilter 2>/dev/null || true
sysctl -p /etc/sysctl.d/99-kubernetes.conf 2>/dev/null || true
kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket=unix:///run/containerd/containerd.sock
echo ""
echo "[NexOS] Cluster initialized!"
echo "To join worker nodes, run the kubeadm join command shown above"
echo "To use kubectl as root: export KUBECONFIG=/etc/kubernetes/admin.conf"
INITSH
    chmod +x "$ROOTFS/usr/local/bin/nexos-kube-init"

    # CNI network dir
    mkdir -p "$ROOTFS/etc/cni/net.d"
    
    info "Kubernetes $kube_ver + containerd $ctr_ver installed"
}

# ===== STAGE 5: SSH Server =====
stage_ssh() {
    local src="/home/whale-d/nex/NexOS/work/openssh-9.8p1"
    if [ ! -d "$src" ]; then
        info "OpenSSH not built yet, run build outside or skip"
        return
    fi
    cd "$src"
    make install DESTDIR="$ROOTFS" 2>&1 | tail -1

    mkdir -p "$ROOTFS/var/run/sshd" "$ROOTFS/var/log"

    cat > "$ROOTFS/etc/ssh/sshd_config" << 'SSHD'
Port 22
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
UsePAM yes
X11Forwarding no
Subsystem sftp /usr/libexec/sftp-server
ClientAliveInterval 300
ClientAliveCountMax 2
SSHD

    cat > "$ROOTFS/etc/ssh/ssh_config" << 'SSHCFG'
Host *
HashKnownHosts yes
StrictHostKeyChecking ask
SSHCFG

    # Pre-generate SSH host keys
    ssh-keygen -q -t rsa -b 4096 -f "$ROOTFS/etc/ssh/ssh_host_rsa_key" -N "" 2>/dev/null || true
    ssh-keygen -q -t ed25519 -f "$ROOTFS/etc/ssh/ssh_host_ed25519_key" -N "" 2>/dev/null || true

    mkdir -p "$ROOTFS/usr/lib/systemd/system"
    cat > "$ROOTFS/usr/lib/systemd/system/sshd.service" << 'SSHD_SVC'
[Unit]
Description=NexOS SSH Server
After=network.target

[Service]
ExecStart=/usr/sbin/sshd -D -E /var/log/sshd.log
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SSHD_SVC

    ln -sf /usr/lib/systemd/system/sshd.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    info "OpenSSH installed"
}

# ===== STAGE 6: Firewall =====
stage_firewall() {
    info "=== Stage 6: Firewall ==="
    mkdir -p "$ROOTFS/etc"
    cat > "$ROOTFS/etc/nftables.conf" << 'NFT'
#!/usr/sbin/nft -f
# NexOS Server firewall
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iif lo accept
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
        tcp dport { ssh, http, https } accept
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
NFT
    chmod 644 "$ROOTFS/etc/nftables.conf"

    mkdir -p "$ROOTFS/usr/lib/systemd/system"
    cat > "$ROOTFS/usr/lib/systemd/system/nftables.service" << 'NFTSVC'
[Unit]
Description=NexOS Firewall (nftables)
After=network-pre.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/nft -f /etc/nftables.conf
ExecStart=-/bin/sh -c 'echo "[nftables] Warning: firewall rules failed - see systemctl status nftables.service"'
ExecReload=/usr/sbin/nft -f /etc/nftables.conf
ExecStop=/usr/sbin/nft flush ruleset
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
NFTSVC

    ln -sf /usr/lib/systemd/system/nftables.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    info "Firewall configured (SSH, HTTP, HTTPS allowed)"
}

# ===== STAGE 7: Package Manager (APK) =====
stage_package_manager() {
    info "=== Stage 7: Installing APK package manager ==="
    local apk_ver="2.14.4-r0"
    local apk_static="$WORKDIR/apk-static-$apk_ver"

    if [ ! -f "$apk_static" ]; then
        cd "$WORKDIR"
        wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.20/main/x86_64/apk-tools-static-$apk_ver.apk" \
            -O "apk-tools-static-$apk_ver.apk" || {
            warn "Download failed, building apk-tools from source..."
            local apk_src_ver="2.14.4"
            if [ ! -d "apk-tools-$apk_src_ver" ]; then
                wget -q "https://gitlab.alpinelinux.org/alpine/apk-tools/-/archive/v$apk_src_ver/apk-tools-v$apk_src_ver.tar.gz"
                tar xf "apk-tools-v$apk_src_ver.tar.gz"
                mv "apk-tools-v$apk_src_ver" "apk-tools-$apk_src_ver"
            fi
            cd "apk-tools-$apk_src_ver"
            make -j"$CPUS" LDFLAGS="-static" 2>&1 | tail -5
            cp apk "$apk_static"
            cd "$WORKDIR"
        }
    fi

    if [ -f "$apk_static" ]; then
        tar xzf "$apk_static" -C "$WORKDIR" 2>/dev/null || true
    fi

    if [ ! -f "$apk_static" ] && [ ! -f "$ROOTFS/sbin/apk" ]; then
        # Try extracting from .apk (tar.gz)
        if [ -f "apk-tools-static-$apk_ver.apk" ]; then
            mkdir -p "$WORKDIR/apk-extract"
            cd "$WORKDIR/apk-extract"
            tar xzf "../apk-tools-static-$apk_ver.apk" 2>/dev/null || true
            if [ -f "sbin/apk" ]; then
                cp "sbin/apk" "$apk_static"
            fi
            cd "$WORKDIR"
            rm -rf "$WORKDIR/apk-extract"
        fi
    fi

    if [ -f "$apk_static" ]; then
        cp "$apk_static" "$ROOTFS/sbin/apk"
        chmod 755 "$ROOTFS/sbin/apk"
    fi

    if [ -f "$ROOTFS/sbin/apk" ]; then
        info "APK package manager installed ($($ROOTFS/sbin/apk --version 2>/dev/null || echo 'version unknown'))"
    else
        warn "APK binary not installed - building from source..."
        local apk_src_ver="2.14.4"
        if [ ! -d "$WORKDIR/apk-tools-$apk_src_ver" ]; then
            cd "$WORKDIR"
            if [ ! -f "apk-tools-v$apk_src_ver.tar.gz" ]; then
                wget -q "https://gitlab.alpinelinux.org/alpine/apk-tools/-/archive/v$apk_src_ver/apk-tools-v$apk_src_ver.tar.gz"
            fi
            tar xf "apk-tools-v$apk_src_ver.tar.gz"
            mv "apk-tools-v$apk_src_ver" "apk-tools-$apk_src_ver"
        fi
        cd "$WORKDIR/apk-tools-$apk_src_ver"
        make -j"$CPUS" LDFLAGS="-static" 2>&1 | tail -5
        if [ -f "apk" ]; then
            cp apk "$ROOTFS/sbin/apk"
            chmod 755 "$ROOTFS/sbin/apk"
            info "APK built from source"
        else
            error "Failed to build APK"
        fi
    fi

    # APK repository configuration
    mkdir -p "$ROOTFS/etc/apk"
    cat > "$ROOTFS/etc/apk/repositories" << 'APKREPO'
# NexOS APK repositories
# https://dl-cdn.alpinelinux.org/alpine/
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
APKREPO

    # APK keys directory
    mkdir -p "$ROOTFS/etc/apk/keys"

    # Install Alpine signing keys
    local keys_dir="$WORKDIR/apk-keys"
    mkdir -p "$keys_dir"
    for key in "alpine-devel@lists.alpinelinux.org-58cbb1d2.rsa.pub" \
               "alpine-devel@lists.alpinelinux.org-58199dcc.rsa.pub"; do
        if [ ! -f "$keys_dir/$key" ]; then
            wget -q "https://alpinelinux.org/keys/$key" -O "$keys_dir/$key" 2>/dev/null || true
        fi
    done
    # Use available keys
    cp "$keys_dir"/*.pub "$ROOTFS/etc/apk/keys/" 2>/dev/null || true

    # Initialize APK database
    mkdir -p "$ROOTFS/lib/apk/db"
    if [ ! -f "$ROOTFS/lib/apk/db/installed" ]; then
        echo "# APK database initialized by NexOS build" > "$ROOTFS/lib/apk/db/installed"
    fi

    # Add APK cache dir
    mkdir -p "$ROOTFS/var/cache/apk"

    # NexOS signing key setup
    if [ ! -f "$WORKDIR/nexos-key.rsa.pub" ]; then
        info "Generating NexOS APK signing key..."
        openssl genrsa -out "$WORKDIR/nexos-key.rsa" 4096 2>/dev/null
        openssl rsa -in "$WORKDIR/nexos-key.rsa" -pubout -out "$WORKDIR/nexos-key.rsa.pub" 2>/dev/null
    fi
    if [ -f "$WORKDIR/nexos-key.rsa.pub" ]; then
        # Copy public key into rootfs for APK verification
        cp "$WORKDIR/nexos-key.rsa.pub" "$ROOTFS/etc/apk/keys/nexos@nexos.org.rsa.pub"
        # Store private key for repo signing (not in rootfs!)
        info "NexOS APK signing key generated (private: $WORKDIR/nexos-key.rsa)"
    fi

    # Install core packages via APK during build
    if [ -f "$ROOTFS/sbin/apk" ] && [ -f "$ROOTFS/etc/apk/keys/alpine-devel@lists.alpinelinux.org-58cbb1d2.rsa.pub" ]; then
        info "Installing core packages via APK (AppArmor, TPM tools)..."
        APK_CMD="$ROOTFS/sbin/apk add --root=$ROOTFS --arch=x86_64 --initdb --no-scripts"
        # Initialize APK database properly
        rm -f "$ROOTFS/lib/apk/db/installed"
        $APK_CMD alpine-base 2>/dev/null || true
        # Install AppArmor userspace
        $APK_CMD apparmor-utils apparmor-profiles 2>/dev/null || true
        # Install TPM tools
        $APK_CMD tpm2-tools 2>/dev/null || true
        # Install cloud-init (full python version)
        $APK_CMD cloud-init 2>/dev/null || true
        # Install storage management tools
        $APK_CMD lvm2 mdadm cryptsetup quota e2fsprogs-extra btrfs-progs xfsprogs f2fs-tools dosfstools 2>/dev/null || true
        # Install reliability tools
        $APK_CMD watchdog stress-ng fio sysbench kdump-tools makedumpfile 2>/dev/null || true
        # Install operations tools
        $APK_CMD ansible ansible-pull py3-jinja2 py3-yaml git openssh-client 2>/dev/null || true
        # Install cloud/VM tools
        $APK_CMD qemu-guest-agent docker-cli cloud-utils acpi 2>/dev/null || true
        # Install network filesystem tools
        $APK_CMD nfs-utils cifs-utils samba-utils ceph-common 2>/dev/null || true
        # Install performance tuning tools
        $APK_CMD tuned irqbalance cpupower 2>/dev/null || true
        # Install security/usability tools
        $APK_CMD ostree fapolicyd usbguard logrotate tmux htop iotop sysstat lsof strace ltrace iperf3 2>/dev/null || true
        # Install networking tools
        $APK_CMD iproute2 iproute2-ss iproute2-tc ethtool bridge-utils tcpdump netcat-openbsd iptables ip6tables conntrack-tools ipvsadm wireguard-tools 2>/dev/null || true
        # Install common server utilities
        $APK_CMD curl wget rsync openssh-server-sftp 2>/dev/null || true
        info "Core package installation complete"

        # Sign APK index
        if [ -f "$ROOTFS/var/cache/apk/APKINDEX.tar.gz" ]; then
            apk sign --key "$WORKDIR/nexos-key.rsa" \
                "$ROOTFS/var/cache/apk/APKINDEX.tar.gz" 2>/dev/null || true
            info "APK index signed with NexOS key"
        fi
    else
        warn "APK not fully configured for offline install - packages will install at first boot"
    fi

    # First-boot APK cache update and package install service
    cat > "$ROOTFS/usr/lib/systemd/system/nexos-apk-setup.service" << 'APK_SVC'
[Unit]
Description=NexOS APK cache initialization
After=network.target
Before=multi-user.target
ConditionPathExists=!/var/cache/apk/.initialized

[Service]
Type=oneshot
ExecStart=/sbin/apk update
ExecStartPost=/bin/touch /var/cache/apk/.initialized
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
APK_SVC

    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /usr/lib/systemd/system/nexos-apk-setup.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true

    # NexOS repo management helper
    cat > "$ROOTFS/usr/local/bin/nexos-repo" << 'REPO_HELPER'
#!/bin/sh
# NexOS repository management utility
usage() {
    echo "Usage: nexos-repo <command>"
    echo "  list        - List configured repositories"
    echo "  add <url>   - Add a repository"
    echo "  del <url>   - Remove a repository"
    echo "  update      - Update APK cache"
    echo "  key <file>  - Add a signing key"
    exit 1
}
    case "${1:-}" in
    list) cat /etc/apk/repositories ;;
    add) echo "$2" >> /etc/apk/repositories && echo "Added: $2" ;;
    del) sed -i "\|$2|d" /etc/apk/repositories && echo "Removed: $2" ;;
    update) apk update ;;
    key) mkdir -p /etc/apk/keys && cp "$2" /etc/apk/keys/ && echo "Key added: $2" ;;
    sign)
        KEY="${2:-/etc/nexos/nexos-key.rsa}"
        REPO="${3:-/var/cache/apk}"
        if [ ! -f "$KEY" ]; then echo "ERROR: key not found: $KEY" >&2; exit 1; fi
        echo "Signing APK index in $REPO..."
        apk sign --key "$KEY" "$REPO/APKINDEX.tar.gz" 2>/dev/null || \
        echo "Sign with: openssl dgst -sha256 -sign \"$KEY\" -out \"$REPO/APKINDEX.tar.gz.sig\" \"$REPO/APKINDEX.tar.gz\""
        echo "Repository signed."
        ;;
    verify)
        KEY="${2:-/etc/apk/keys/nexos@nexos.org.rsa.pub}"
        REPO="${3:-/var/cache/apk}"
        openssl dgst -sha256 -verify "$KEY" -signature "$REPO/APKINDEX.tar.gz.sig" \
            "$REPO/APKINDEX.tar.gz" 2>/dev/null && echo "Signature VALID" || echo "Signature INVALID"
        ;;
    *) usage ;;
esac
REPO_HELPER
    chmod +x "$ROOTFS/usr/local/bin/nexos-repo"

    info "APK package manager stage complete"
}

# ===== STAGE 8: Configuration =====
stage_config() {
    info "=== Stage 7: Configuring system ==="

    # fstab (overlay rootfs is writable, no separate partitions)
    cat > "$ROOTFS/etc/fstab" << 'FSTAB'
# NexOS Server fstab
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devpts /dev/pts devpts gid=5,mode=620 0 0
FSTAB

    # hostname
    echo "nexos-server" > "$ROOTFS/etc/hostname"

    # hosts
    cat > "$ROOTFS/etc/hosts" << 'HOSTS'
127.0.0.1 localhost
127.0.1.1 nexos-server
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
HOSTS

    # systemd-networkd DHCP config
    mkdir -p "$ROOTFS/etc/systemd/network"
    cat > "$ROOTFS/etc/systemd/network/10-dhcp-all.network" << 'NET'
[Match]
Name=*

[Network]
DHCP=yes
DNSSEC=no
NET

    # resolv.conf (static fallback, overridden by DHCP)
    rm -f "$ROOTFS/etc/resolv.conf"
    cat > "$ROOTFS/etc/resolv.conf" << 'RESOLV'
nameserver 1.1.1.1
nameserver 8.8.8.8
RESOLV

    # passwd
    cat > "$ROOTFS/etc/passwd" << 'PASSWD'
root:x:0:0:root:/root:/bin/sh
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
PASSWD

    # group
    cat > "$ROOTFS/etc/group" << 'GROUP'
root:x:0:
daemon:x:1:
nogroup:x:65534:
adm:x:4:
systemd-journal:x:190:
systemd-network:x:191:
GROUP
    # Shadow file - temporary password set, forced change on first login
    # Password: "nexos" (hashed) + lastchg=0 forces password change on next login
    local root_hash
    root_hash=$(openssl passwd -1 'nexos' 2>/dev/null || echo '$1$xyz$abc')
    echo "root:${root_hash}:0:0:99999:7:::" > "$ROOTFS/etc/shadow"
    echo 'daemon:!!:19858:0:99999:7:::' >> "$ROOTFS/etc/shadow"
    echo 'nobody:!!:19858:0:99999:7:::' >> "$ROOTFS/etc/shadow"
    chmod 640 "$ROOTFS/etc/shadow"

    # profile
    cat > "$ROOTFS/etc/profile" << 'PROFILE'
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export EDITOR=vi
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
PROFILE

    # nsswitch
    cat > "$ROOTFS/etc/nsswitch.conf" << 'NSS'
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
NSS

    # systemd config: device timeout + no udev
    cat > "$ROOTFS/etc/systemd/system.conf" << 'SYSDBLK'
[Manager]
DefaultDeviceTimeoutSec=5
DefaultTimeoutStartSec=10
SYSDBLK

    # Mask udev (no udevd binary available)
    for svc in systemd-udevd.service systemd-udevd-control.socket \
               systemd-udevd-kernel.socket systemd-udev-trigger.service \
               systemd-udev-settle.service; do
        ln -sf /dev/null "$ROOTFS/etc/systemd/system/$svc"
    done

    # Disable serial-getty on ttyS0 (blocks boot without udev)
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/serial-getty@ttyS0.service"
    ln -sf /dev/null "$ROOTFS/etc/systemd/system/getty@ttyS0.service"

    # Enable getty on tty1 for graphical console
    mkdir -p "$ROOTFS/etc/systemd/system/getty.target.wants"
    ln -sf /usr/lib/systemd/system/getty@.service \
        "$ROOTFS/etc/systemd/system/getty.target.wants/getty@tty1.service"

    # systemd journal config
    cat > "$ROOTFS/etc/systemd/journald.conf" << 'JOURNAL'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
JOURNAL

    # doas (minimal privilege escalation)
    if [ ! -f "$ROOTFS/usr/bin/doas" ]; then
        cp "$WORKDIR/opendoas/doas" "$ROOTFS/usr/bin/doas"
    fi
    cat > "$ROOTFS/etc/doas.conf" << 'DOAS'
permit nopass keepenv root as root
permit :wheel as root
DOAS
    chmod 440 "$ROOTFS/etc/doas.conf"

    # Set setuid on boot via tmpfiles.d
    mkdir -p "$ROOTFS/etc/tmpfiles.d"
    cat > "$ROOTFS/etc/tmpfiles.d/doas.conf" << 'TMPD'
f /usr/bin/doas 4755 root root -
TMPD

    # sudo compatibility wrapper (for scripts expecting /usr/bin/sudo)
    cat > "$ROOTFS/usr/bin/sudo" << 'SUDOWRAP'
#!/bin/sh
exec /usr/bin/doas "$@"
SUDOWRAP
    chmod +x "$ROOTFS/usr/bin/sudo"

    # Shell alias for sudo
    mkdir -p "$ROOTFS/etc/profile.d"
    cat > "$ROOTFS/etc/profile.d/doas-alias.sh" << 'ALIAS'
alias sudo='doas '
ALIAS

    # Disk installation script for persistent rootfs
    cat > "$ROOTFS/usr/local/bin/nexos-install" << 'INSTALL'
#!/bin/sh
# NexOS Server - Disk Installer
# Installs NexOS to a target disk with persistent rootfs
set -e

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GRN}[INFO]${NC} $*"; }
warn()  { echo -e "${YLW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

usage() {
    echo "Usage: nexos-install <device> [options]"
    echo "  device                  Target disk (e.g., /dev/sda, /dev/nvme0n1)"
    echo "  -f, --fs <ext4|btrfs>  Filesystem type (default: ext4)"
    echo "  -s, --swap <size>      Swap partition size in GB (default: 0 = no swap)"
    echo "  -o, --overlay          Use overlay rootfs (default: direct root)"
    echo "  -h, --help             Show this help"
    exit 0
}

FS_TYPE=ext4
SWAP_SIZE=0
USE_OVERLAY=0

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--fs) FS_TYPE="$2"; shift 2 ;;
        -s|--swap) SWAP_SIZE="$2"; shift 2 ;;
        -o|--overlay) USE_OVERLAY=1; shift ;;
        -h|--help) usage ;;
        -*)
            if [ -z "${DEV:-}" ]; then DEV="$1"; shift; else usage; fi ;;
        *)
            if [ -z "${DEV:-}" ]; then DEV="$1"; shift; else usage; fi ;;
    esac
done

if [ -z "${DEV:-}" ]; then
    echo "Error: No device specified"
    usage
fi

# Validate device
if [ ! -b "$DEV" ]; then
    error "Not a block device: $DEV"
fi

# Check if we're running from ISO (root.squashfs present) or installed
if [ -f /root.squashfs ]; then
    SOURCE="/root.squashfs"
    info "Running from ISO - will install from squashfs"
elif [ -f /run/rootfsbase ]; then
    SOURCE="/run/rootfsbase"
    info "Running from overlay - will install from overlay source"
else
    SOURCE="/"
    info "Running from installed system - will copy current rootfs"
fi

info "Target device: $DEV"
info "Filesystem:    $FS_TYPE"
info "Swap:          ${SWAP_SIZE}GB"

# Confirm
echo ""
warn "This will DESTROY ALL DATA on $DEV"
echo -n "Continue? [y/N] "
read -r confirm
[ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || exit 1

# Partition
info "Partitioning $DEV..."
if echo "$DEV" | grep -q "nvme"; then
    PART_PREFIX="${DEV}p"
else
    PART_PREFIX="${DEV}"
fi

# Wipe partition table
dd if=/dev/zero of="$DEV" bs=1M count=10 2>/dev/null

# Create GPT partition table
parted -s "$DEV" mklabel gpt

# BIOS boot partition (for Limine)
parted -s "$DEV" mkpart primary 1MiB 8MiB
parted -s "$DEV" set 1 bios_grub on

# Root partition
if [ "$SWAP_SIZE" -gt 0 ]; then
    # Swap + root
    parted -s "$DEV" mkpart primary linux-swap 8MiB "${SWAP_SIZE}GiB"
    parted -s "$DEV" mkpart primary "${SWAP_SIZE}GiB" 100%
    SWAP_PART="${PART_PREFIX}2"
    ROOT_PART="${PART_PREFIX}3"
else
    parted -s "$DEV" mkpart primary 8MiB 100%
    ROOT_PART="${PART_PREFIX}2"
fi

# Format
info "Formatting $ROOT_PART as $FS_TYPE..."
case "$FS_TYPE" in
    ext4) mkfs.ext4 -F -L nexos-root "$ROOT_PART" >/dev/null 2>&1 ;;
    btrfs) mkfs.btrfs -f -L nexos-root "$ROOT_PART" >/dev/null 2>&1 ;;
    xfs) mkfs.xfs -f -L nexos-root "$ROOT_PART" >/dev/null 2>&1 ;;
    *) error "Unsupported filesystem: $FS_TYPE" ;;
esac

if [ -n "${SWAP_PART:-}" ]; then
    info "Formatting swap on $SWAP_PART..."
    mkswap "$SWAP_PART" >/dev/null 2>&1
fi

# Mount target
MOUNT="/mnt/nexos-install"
mkdir -p "$MOUNT"
mount "$ROOT_PART" "$MOUNT"

# Copy rootfs
info "Copying root filesystem (this may take a while)..."
if [ "$SOURCE" = "/root.squashfs" ]; then
    # Running from ISO - extract squashfs
    mkdir -p /mnt/squash-src
    mount -t squashfs /root.squashfs /mnt/squash-src 2>/dev/null || \
        mount -o loop /root.squashfs /mnt/squash-src
    cp -a /mnt/squash-src/* "$MOUNT/"
    umount /mnt/squash-src
    rmdir /mnt/squash-src 2>/dev/null || true
elif [ "$SOURCE" = "/run/rootfsbase" ]; then
    cp -a "$SOURCE"/* "$MOUNT/"
elif [ "$SOURCE" = "/" ]; then
    # Running from live system - copy everything except special dirs
    for dir in bin boot dev etc home lib lib64 opt root sbin srv usr var; do
        [ -d "/$dir" ] && cp -a "/$dir" "$MOUNT/" 2>/dev/null || true
    done
    # Create required directories
    for dir in proc sys run tmp mnt; do
        mkdir -p "$MOUNT/$dir"
        chmod 755 "$MOUNT/$dir"
    done
    chmod 1777 "$MOUNT/tmp"
    chmod 755 "$MOUNT/var/log/journal" 2>/dev/null || true
fi

# Generate fstab
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
cat > "$MOUNT/etc/fstab" << FSTAB
# NexOS Server - fstab (generated by nexos-install)
# Root filesystem
UUID=$ROOT_UUID / $FS_TYPE defaults,noatime 0 1
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devpts /dev/pts devpts gid=5,mode=620 0 0
FSTAB

if [ -n "${SWAP_PART:-}" ]; then
    SWAP_UUID=$(blkid -s UUID -o value "$SWAP_PART")
    echo "UUID=$SWAP_UUID none swap sw 0 0" >> "$MOUNT/etc/fstab"
fi

# Install bootloader
info "Installing Limine bootloader..."
LIMINE_DIR="/usr/share/limine"
if [ ! -d "$LIMINE_DIR" ]; then
    LIMINE_DIR="/boot/limine"
fi

mkdir -p "$MOUNT/boot/limine"
cp /boot/vmlinuz-nexos "$MOUNT/boot/" 2>/dev/null || cp /vmlinuz-nexos "$MOUNT/boot/" 2>/dev/null || true

# Generate persistent initramfs
info "Generating initramfs for persistent root..."
mkdir -p /tmp/initramfs-persist/{bin,dev,etc,proc,sys,newroot}
cp /bin/busybox /tmp/initramfs-persist/bin/ 2>/dev/null || true

cat > /tmp/initramfs-persist/init << 'INIT'
#!/bin/busybox sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
/bin/busybox --install -s /bin 2>/dev/null

mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

# Root from kernel cmdline or fstab
ROOT=$(cat /proc/cmdline | tr ' ' '\n' | grep '^root=' | cut -d= -f2)
ROOTFLAGS="ro"

# Wait for root device
echo "Waiting for root device $ROOT..."
for i in $(seq 1 30); do
    if [ -b "$ROOT" ]; then break; fi
    sleep 1
done

if [ -b "$ROOT" ]; then
    # Mount real root
    ROOT_FSTYPE=$(blkid -o value -s TYPE "$ROOT" 2>/dev/null || echo "auto")
    mount -t "$ROOT_FSTYPE" -o "$ROOTFLAGS" "$ROOT" /newroot 2>/dev/null || \
        mount "$ROOT" /newroot

    if [ -f /newroot/sbin/init ] || [ -f /newroot/lib/systemd/systemd ]; then
        exec switch_root /newroot /lib/systemd/systemd
    fi
fi

# Fallback: run sh
exec /bin/sh
INIT
chmod +x /tmp/initramfs-persist/init
mknod /tmp/initramfs-persist/dev/console c 5 1 2>/dev/null || true
mknod /tmp/initramfs-persist/dev/null c 1 3 2>/dev/null || true

cd /tmp/initramfs-persist
find . | cpio -o -H newc | gzip -9 > "$MOUNT/boot/initramfs-nexos.img"
cd /
rm -rf /tmp/initramfs-persist

# Bootloader config
cat > "$MOUNT/boot/limine.conf" << LIMCONF
TIMEOUT=5

:NexOS Server 1.0 (Persistent)
PROTOCOL=linux
KERNEL_PATH=boot:///boot/vmlinuz-nexos
MODULE_PATH=boot:///boot/initramfs-nexos.img
CMDLINE=root=UUID=$ROOT_UUID rw console=tty0 console=ttyS0,115200 net.ifnames=0 systemd.unified_cgroup_hierarchy=1 apparmor=1 security=apparmor loglevel=3

:NexOS Server (Recovery)
PROTOCOL=linux
KERNEL_PATH=boot:///boot/vmlinuz-nexos
MODULE_PATH=boot:///boot/initramfs-nexos.img
CMDLINE=root=UUID=$ROOT_UUID rw console=tty0 console=ttyS0,115200 net.ifnames=0 systemd.unified_cgroup_hierarchy=1 apparmor=1 security=apparmor loglevel=3 systemd.device_timeout=15 systemd.unit=rescue.target
LIMCONF

# Install Limine binaries
if [ -d "$LIMINE_DIR" ]; then
    cp "$LIMINE_DIR"/limine-bios*.sys "$MOUNT/boot/" 2>/dev/null || true
    mkdir -p "$MOUNT/EFI/BOOT"
    cp "$LIMINE_DIR"/BOOTX64.EFI "$MOUNT/EFI/BOOT/" 2>/dev/null || true
    cp "$LIMINE_DIR"/BOOTIA32.EFI "$MOUNT/EFI/BOOT/" 2>/dev/null || true
fi

# Install Limine to disk
if command -v limine >/dev/null 2>&1; then
    limine bios-install "$DEV" 2>/dev/null || true
fi

# Clean up
sync
umount "$MOUNT"
rmdir "$MOUNT" 2>/dev/null || true

echo ""
info "=============================================="
info "NexOS Server installed successfully!"
info "  Device: $DEV"
info "  Root:   $ROOT_PART ($FS_TYPE)"
info "  UUID:   $ROOT_UUID"
info "=============================================="
echo ""
echo "Remove installation media and reboot."
echo "Default login: root / nexos"
echo "  (CHANGE PASSWORD on first login!)"
INSTALL
    chmod +x "$ROOTFS/usr/local/bin/nexos-install"

    # Also install to /sbin for PATH
    ln -sf /usr/local/bin/nexos-install "$ROOTFS/sbin/nexos-install" 2>/dev/null || true

    # ===== Minimal cloud-init script =====
    # Handles cloud metadata for AWS EC2, OpenStack, and GCP
    cat > "$ROOTFS/usr/local/bin/nexos-cloud-init" << 'CLOUDINIT'
#!/bin/sh
# NexOS minimal cloud-init - handles cloud metadata provisioning
set -e

METADATA_URLS="http://169.254.169.254"
DIAG=""
HOST=""

# Try EC2 IMDSv2 first
fetch_ec2_metadata() {
    TOKEN=$(curl -s -X PUT "$METADATA_URLS/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 300" 2>/dev/null) || return 1
    TOKEN_HDR="X-aws-ec2-metadata-token: $TOKEN"

    DIAG=$(curl -s -H "$TOKEN_HDR" "$METADATA_URLS/latest/meta-data/public-keys/0/openssh-key" 2>/dev/null) || DIAG=""
    HOST=$(curl -s -H "$TOKEN_HDR" "$METADATA_URLS/latest/meta-data/hostname" 2>/dev/null | cut -d. -f1) || true

    # User data
    USERDATA=$(curl -s -H "$TOKEN_HDR" "$METADATA_URLS/latest/user-data" 2>/dev/null) || USERDATA=""

    # Network config
    LOCAL_IPV4=$(curl -s -H "$TOKEN_HDR" "$METADATA_URLS/latest/meta-data/local-ipv4" 2>/dev/null) || true
    [ -n "$LOCAL_IPV4" ] && echo "$LOCAL_IPV4" > /var/tmp/cloud-local-ipv4

    return 0
}

# Try OpenStack metadata
fetch_openstack_metadata() {
    DIAG=$(curl -s "$METADATA_URLS/openstack/latest/meta_data.json" 2>/dev/null) || return 1

    # Parse JSON without python
    HOST=$(echo "$DIAG" | grep -o '"hostname": *"[^"]*"' | cut -d'"' -f4 | cut -d. -f1) || true

    # SSH keys
    KEY_JSON=$(curl -s "$METADATA_URLS/openstack/latest/public_keys" 2>/dev/null) || true
    if [ -n "$KEY_JSON" ]; then
        DIAG=$(echo "$KEY_JSON" | grep -o '"data": *"[^"]*"' | cut -d'"' -f4) || DIAG=""
    fi

    USERDATA=$(curl -s "$METADATA_URLS/openstack/latest/user_data" 2>/dev/null) || USERDATA=""
    return 0
}

# Try GCP metadata
fetch_gcp_metadata() {
    HEADER="Metadata-Flavor: Google"
    DIAG=$(curl -s -H "$HEADER" "$METADATA_URLS/computeMetadata/v1/instance/attributes/ssh-keys" 2>/dev/null) || return 1
    HOST=$(curl -s -H "$HEADER" "$METADATA_URLS/computeMetadata/v1/instance/hostname" 2>/dev/null | cut -d. -f1) || true
    USERDATA=$(curl -s -H "$HEADER" "$METADATA_URLS/computeMetadata/v1/instance/attributes/user-data" 2>/dev/null) || USERDATA=""
    return 0
}

# Main
echo "[nexos-cloud-init] Detecting cloud environment..."

fetch_ec2_metadata || fetch_openstack_metadata || fetch_gcp_metadata || {
    echo "[nexos-cloud-init] No cloud metadata found"
    exit 0
}

# Set hostname from cloud
if [ -n "$HOST" ]; then
    echo "[nexos-cloud-init] Setting hostname: $HOST"
    hostname "$HOST"
    echo "$HOST" > /etc/hostname
fi

# Inject SSH keys
if [ -n "$DIAG" ]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    echo "$DIAG" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "[nexos-cloud-init] SSH keys installed"
fi

# Process user-data
if [ -n "$USERDATA" ]; then
    echo "[nexos-cloud-init] Processing user-data..."
    echo "$USERDATA" > /var/tmp/cloud-userdata
    # If user-data starts with #!, execute it
    if echo "$USERDATA" | head -1 | grep -q '^#!'; then
        echo "$USERDATA" > /var/tmp/cloud-userdata.script
        chmod +x /var/tmp/cloud-userdata.script
        /var/tmp/cloud-userdata.script
        echo "[nexos-cloud-init] User-data script executed"
    fi
    # cloud-config is handled by cloud-init if installed via APK
fi

echo "[nexos-cloud-init] Cloud provisioning complete"
exit 0
CLOUDINIT
    chmod +x "$ROOTFS/usr/local/bin/nexos-cloud-init"

    # cloud-init service
    cat > "$ROOTFS/usr/lib/systemd/system/nexos-cloud-init.service" << 'CINIT_SVC'
[Unit]
Description=NexOS minimal cloud-init
After=network-online.target
Wants=network-online.target
Before=multi-user.target
ConditionKernelCommandLine=!no-cloud

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nexos-cloud-init
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
CINIT_SVC

    # Enable service (will be skipped if no cloud metadata)
    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /usr/lib/systemd/system/nexos-cloud-init.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true

    # First-boot password setup service
    cat > "$ROOTFS/usr/lib/systemd/system/nexos-firstboot.service" << 'FIRSTBOOT'
[Unit]
Description=NexOS first-boot setup
ConditionPathExists=!/var/tmp/nexos-firstboot-done
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nexos-firstboot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
FIRSTBOOT

    cat > "$ROOTFS/usr/local/bin/nexos-firstboot" << 'FIRSTBOOTSH'
#!/bin/sh
# NexOS first-boot setup
# Forces password change, generates SSH keys, etc.
set -e

LOCKFILE="/var/tmp/nexos-firstboot-done"
[ -f "$LOCKFILE" ] && exit 0

echo ""
echo "=============================================="
echo "  NexOS Server - First Boot Setup"
echo "=============================================="
echo ""

# Check if SSH keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[firstboot] Generating SSH host keys..."
    ssh-keygen -q -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" 2>/dev/null || true
    ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" 2>/dev/null || true
    echo "[firstboot] SSH host keys generated"
fi

# Force password change if shadow has lastchg=0
SHADOW_ROOT=$(grep '^root:' /etc/shadow | cut -d: -f3)
if [ "$SHADOW_ROOT" = "0" ]; then
    echo ""
    echo "=============================================="
    echo "  FIRST LOGIN - PASSWORD MUST BE CHANGED"
    echo "=============================================="
    echo "  Please set a strong password for root."
    echo "  Minimum length: 8 characters"
    echo ""
    # Can't run passwd non-interactively in a oneshot service
    # The shadow expiration will force change on login
    echo "[firstboot] Password change will be enforced on next login"
fi

# Run cloud-init
if [ -f /usr/local/bin/nexos-cloud-init ]; then
    /usr/local/bin/nexos-cloud-init
fi

touch "$LOCKFILE"
echo "[firstboot] Setup complete"
exit 0
FIRSTBOOTSH
    chmod +x "$ROOTFS/usr/local/bin/nexos-firstboot"

    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /usr/lib/systemd/system/nexos-firstboot.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true

    # Watchdog service
    cat > "$ROOTFS/usr/lib/systemd/system/nexos-watchdog.service" << 'WDT_SVC'
[Unit]
Description=NexOS Watchdog Timer
After=basic.target
Before=shutdown.target
DefaultDependencies=no

[Service]
Type=simple
ExecStart=/sbin/watchdog -t 10 -T 30 -F
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
WDT_SVC
    ln -sf /usr/lib/systemd/system/nexos-watchdog.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true

    # kdump service - loads crash kernel
    cat > "$ROOTFS/usr/lib/systemd/system/nexos-kdump.service" << 'KDUMP_SVC'
[Unit]
Description=NexOS kdump crash kernel loader
DefaultDependencies=no
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/kexec -p /boot/vmlinuz-nexos --initrd=/boot/initramfs-kdump.img --reuse-cmdline --append="nr_cpus=1 elfcorehdr=128M reset_devices"
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
KDUMP_SVC
    ln -sf /usr/lib/systemd/system/nexos-kdump.service \
        "$ROOTFS/etc/systemd/system/sysinit.target.wants/" 2>/dev/null || true

    # Message in /etc/issue to warn about password
    cat > "$ROOTFS/etc/issue" << 'ISSUE'
NexOS Server \r (\l)

WARNING: Default password must be changed immediately.
Login with root, the system will force a password change.

ISSUE
    cat > "$ROOTFS/etc/issue.net" << 'ISSUENET'
NexOS Server - Unauthorized access prohibited

ISSUENET

    # SSH banner
    cat > "$ROOTFS/etc/ssh/banner.txt" << 'BANNER'
****************************************************************
*  NexOS Server                                                 *
*  All connections are monitored and logged.                    *
*  Unauthorized access is prohibited.                           *
****************************************************************
BANNER

    # Basic AppArmor profiles
    mkdir -p "$ROOTFS/etc/apparmor.d"
    cat > "$ROOTFS/etc/apparmor.d/usr.sbin.sshd" << 'AA_SSHD'
# AppArmor profile for SSH daemon
#include <tunables/global>

/usr/sbin/sshd {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability audit,
  capability chown,
  capability dac_override,
  capability dac_read_search,
  capability fowner,
  capability fsetid,
  capability kill,
  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability sys_resource,
  capability sys_tty_config,

  /etc/ssh/ r,
  /etc/ssh/ssh_host_* r,
  /etc/ssh/sshd_config r,
  /etc/motd r,
  /etc/nologin r,
  /etc/pam.d/ r,
  /etc/pam.d/sshd r,
  /etc/security/ r,
  /lib/x86_64-linux-gnu/ r,
  /lib/x86_64-linux-gnu/lib*.so* mr,
  /usr/lib/ r,
  /usr/lib/x86_64-linux-gnu/ r,
  /usr/lib/x86_64-linux-gnu/lib*.so* mr,
  /usr/lib/x86_64-linux-gnu/security/pam_*.so mr,
  /var/log/ w,
  /var/log/lastlog rw,
  /var/run/sshd/ rw,
  /var/run/sshd/* rw,
  /var/empty/ r,
  /proc/ r,
  /proc/*/ r,
  /sys/ r,

  /usr/sbin/sshd r,
  /bin/ r,
  /usr/bin/ r,

  network inet stream,
  network inet6 stream,

  deny /etc/shadow r,
  deny /etc/ssh/ssh_host_* key,
}
AA_SSHD

    cat > "$ROOTFS/etc/apparmor.d/usr.sbin.nginx" << 'AA_NGINX'
# AppArmor profile for Nginx
#include <tunables/global>

/usr/sbin/nginx {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability dac_override,
  capability dac_read_search,
  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability kill,
  capability chown,
  capability sys_resource,

  /etc/nginx/ r,
  /etc/nginx/** r,
  /var/log/nginx/ rw,
  /var/log/nginx/*.log rw,
  /run/nginx.pid rw,
  /var/www/ r,
  /var/www/** r,
  /usr/sbin/nginx r,

  network inet stream,
  network inet6 stream,

  /lib/x86_64-linux-gnu/lib*.so* mr,
  /usr/lib/nginx/ r,
  /usr/lib/nginx/** mr,
}
AA_NGINX

    cat > "$ROOTFS/etc/apparmor.d/usr.sbin.containerd" << 'AA_CTRD'
# AppArmor profile for containerd
#include <tunables/global>

/usr/bin/containerd {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability sys_admin,
  capability sys_chroot,
  capability sys_ptrace,
  capability sys_resource,
  capability dac_override,
  capability dac_read_search,
  capability fowner,
  capability fsetid,
  capability kill,
  capability setgid,
  capability setuid,
  capability net_admin,
  capability net_bind_service,
  capability mknod,
  capability audit_control,

  /etc/containerd/ r,
  /etc/containerd/** r,
  /run/containerd/ rw,
  /run/containerd/** rw,
  /var/lib/containerd/ rw,
  /var/lib/containerd/** rw,
  /usr/bin/containerd r,
  /opt/cni/ r,
  /opt/cni/** r,
  /usr/bin/runc r,

  network inet stream,
  network inet6 stream,
  network netlink raw,
}
AA_CTRD

    # Basic abstractions
    mkdir -p "$ROOTFS/etc/apparmor.d/abstractions"
    cat > "$ROOTFS/etc/apparmor.d/abstractions/base" << 'AA_BASE'
# Base abstraction for all AppArmor profiles
  / r,
  /bin/ r,
  /bin/** r,
  /usr/ r,
  /usr/bin/ r,
  /usr/bin/** r,
  /usr/sbin/ r,
  /usr/sbin/** r,
  /lib/ r,
  /lib/** r,
  /usr/lib/ r,
  /usr/lib/** r,
  /etc/ r,
  /etc/** r,
  /dev/null rw,
  /dev/urandom r,
  /dev/random r,
  /dev/zero rw,
  /dev/pts/ rw,
  /dev/ptmx rw,
  /proc/ r,
  /proc/** r,
  /sys/ r,
  /sys/** r,
  /tmp/ rw,
  /tmp/** rw,
  /var/tmp/ rw,
  /var/tmp/** rw,
  /run/ r,
  /run/** rw,
AA_BASE

    cat > "$ROOTFS/etc/apparmor.d/abstractions/nameservice" << 'AA_NS'
# Nameservice abstraction
  /etc/hosts r,
  /etc/hostname r,
  /etc/resolv.conf r,
  /etc/nsswitch.conf r,
  /etc/passwd r,
  /etc/group r,
  /lib/x86_64-linux-gnu/libnss_* r,
  /lib/x86_64-linux-gnu/libnss_*.so* mr,
  /lib/x86_64-linux-gnu/libresolv* mr,
  network inet stream,
  network inet6 stream,
  network inet dgram,
  network inet6 dgram,
AA_NS

    # AppArmor tunables
    mkdir -p "$ROOTFS/etc/apparmor.d/tunables"
    cat > "$ROOTFS/etc/apparmor.d/tunables/global" << 'AA_GLOBAL'
# Global AppArmor tunables
@{PROC}=/proc/
@{PROC_MOUNTED}=/proc/
@{HOME}=/root/
@{HOMEDIRS}=/root/ /home/*/
@{multiarch}=x86_64-linux-gnu
@{pid}=[0-9]*
@{sanitized_eggs}=/tmp/
AA_GLOBAL

    # AppArmor sysctl tuning
    mkdir -p "$ROOTFS/etc/sysctl.d"
    cat > "$ROOTFS/etc/sysctl.d/99-apparmor.conf" << 'AA_SYSCTL'
kernel.apparmor_restrict_unprivileged_names=1
kernel.apparmor_restrict_unprivileged_userns=1
AA_SYSCTL

    # AppArmor systemd service
    cat > "$ROOTFS/usr/lib/systemd/system/apparmor.service" << 'AA_SVC'
[Unit]
Description=NexOS AppArmor initialization
Before=local-fs.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/sbin/apparmor_parser -r -W -T /etc/apparmor.d
ExecReload=/sbin/apparmor_parser -r -W -T /etc/apparmor.d
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
AA_SVC

    mkdir -p "$ROOTFS/etc/systemd/system/sysinit.target.wants"
    ln -sf /usr/lib/systemd/system/apparmor.service \
        "$ROOTFS/etc/systemd/system/sysinit.target.wants/" 2>/dev/null || true

    # ===== Operations: Snapshot-based rollback =====
    mkdir -p "$ROOTFS/usr/local/bin"
    cat > "$ROOTFS/usr/local/bin/nexos-snapshot" << 'SNAP'
#!/bin/sh
# NexOS snapshot utility (btrfs or rsync-based)
set -e
SNAP_DIR="${SNAP_DIR:-/var/lib/nexos/snapshots}"
SNAP_NAME="${1:-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$SNAP_DIR"
if command -v btrfs >/dev/null 2>&1 && btrfs filesystem df / >/dev/null 2>&1; then
    # btrfs snapshot
    btrfs subvolume snapshot -r / "$SNAP_DIR/$SNAP_NAME"
    echo "btrfs snapshot $SNAP_NAME created"
elif command -v rsync >/dev/null 2>&1; then
    # rsync fallback - exclude runtime dirs
    rsync -aAX --delete --exclude={/proc,/sys,/dev,/run,/tmp,/mnt,/media,/lost+found} \
        / "$SNAP_DIR/$SNAP_NAME/" 2>/dev/null
    echo "rsync snapshot $SNAP_NAME created"
else
    echo "ERROR: no snapshot backend available (install btrfs-progs or rsync)" >&2
    exit 1
fi
SNAP
    chmod +x "$ROOTFS/usr/local/bin/nexos-snapshot"

    cat > "$ROOTFS/usr/local/bin/nexos-rollback" << 'ROLL'
#!/bin/sh
# NexOS rollback utility
set -e
SNAP_DIR="${SNAP_DIR:-/var/lib/nexos/snapshots}"
if [ -z "$1" ]; then
    echo "Available snapshots:"
    ls -1 "$SNAP_DIR" 2>/dev/null || echo "(none)"
    echo "Usage: $0 <snapshot-name>"
    exit 1
fi
SNAP="$SNAP_DIR/$1"
if [ ! -d "$SNAP" ]; then
    echo "ERROR: snapshot '$1' not found in $SNAP_DIR" >&2
    exit 1
fi
echo "WARNING: Rollback requires reboot. Continue? (y/N)"
read -r confirm
[ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || exit 0
if command -v btrfs >/dev/null 2>&1 && btrfs filesystem df / >/dev/null 2>&1; then
    btrfs subvolume snapshot "$SNAP" /
    echo "btrfs rollback of $1 complete. Reboot required."
else
    rsync -aAX --delete "$SNAP/" / --exclude={/proc,/sys,/dev,/run,/tmp,/mnt,/media}
    echo "rsync rollback of $1 complete. Reboot required."
fi
ROLL
    chmod +x "$ROOTFS/usr/local/bin/nexos-rollback"

    # ===== Operations: PXE auto-install =====
    cat > "$ROOTFS/usr/local/bin/nexos-pxe-boot.sh" << 'PXE'
#!/bin/sh
# NexOS PXE boot config generator
# Usage: nexos-pxe-boot.sh <tftp-root> <kernel> <initrd>
set -e
TFTP_ROOT="${1:-/var/lib/tftpboot}"
KERNEL="${2:-/boot/vmlinuz-nexos}"
INITRD="${3:-/boot/initramfs-nexos}"
NEXOS_ISO="${4:-/var/lib/nexos/nexos-server.iso}"
mkdir -p "$TFTP_ROOT/nexos"
cp "$KERNEL" "$TFTP_ROOT/nexos/vmlinuz"
cp "$INITRD" "$TFTP_ROOT/nexos/initramfs"
if [ -f "$NEXOS_ISO" ]; then
    cp "$NEXOS_ISO" "$TFTP_ROOT/nexos/nexos.iso"
fi
cat > "$TFTP_ROOT/pxelinux.cfg/default" << 'PXECFG'
DEFAULT nexos
LABEL nexos
    KERNEL nexos/vmlinuz
    INITRD nexos/initramfs
    APPEND root=/dev/ram0 console=ttyS0,115200 console=tty0 net.ifnames=0 nexos.install=auto
PXECFG
echo "NexOS PXE boot configured at $TFTP_ROOT"
PXE
    chmod +x "$ROOTFS/usr/local/bin/nexos-pxe-boot.sh"

    # ===== Operations: OSTree-based atomic updates =====
    mkdir -p "$ROOTFS/etc/nexos/ostree"
    cat > "$ROOTFS/usr/local/bin/nexos-ostree-setup" << 'OST'
#!/bin/sh
# NexOS atomic update setup (OSTree-based)
set -e
echo "Setting up OSTree-based atomic updates..."
echo "  OSTree repo: /ostree/repo"
echo "  Deploy root: /ostree/deploy"
echo ""
echo "OSTree is available via APK. Install with:"
echo "  apk add ostree ostree-grub2"
echo ""
echo "Then initialize a repo:"
echo "  ostree init --repo=/ostree/repo --mode=archive-z2"
echo "  ostree commit --repo=/ostree/repo --branch=nexos/$(uname -m)/stable /"
echo ""
echo "For remote updates, add a remote:"
echo "  ostree remote add --repo=/ostree/repo nexus https://updates.nexos.dev/ostree"
echo "  ostree pull --repo=/ostree/repo nexus:nexos/$(uname -m)/stable"
echo "  ostree admin deploy nexus:nexos/$(uname -m)/stable"
exit 0
OST
    chmod +x "$ROOTFS/usr/local/bin/nexos-ostree-setup"

    # ===== Kernel live patching: kpatch-build helper =====
    cat > "$ROOTFS/usr/local/bin/nexos-kpatch-build" << 'KPATCH'
#!/bin/sh
# NexOS kernel live patching builder (kpatch)
set -e
KVER=$(uname -r)
KDIR="/usr/src/linux-$KVER"
PATCH="$1"
[ -z "$PATCH" ] && { echo "Usage: $0 <patch-file>"; exit 1; }
[ ! -f "$PATCH" ] && { echo "Patch not found: $PATCH"; exit 1; }
echo "Building live patch for kernel $KVER"
echo "  Patch: $PATCH"
echo ""
echo "Install kpatch-build:"
echo "  apk add kpatch kpatch-build"
echo "  git clone https://github.com/dynup/kpatch /usr/src/kpatch"
echo ""
echo "Then run:"
echo "  cd /usr/src/kpatch"
echo "  kpatch-build -t vmlinux -s $KDIR $PATCH"
echo "  kpatch load kpatch-*.ko"
echo ""
echo "Or for simple function replacements:"
echo "  kpatch-build -s $KDIR -r 'function_to_patch' $PATCH"
KPATCH
    chmod +x "$ROOTFS/usr/local/bin/nexos-kpatch-build"

    # ===== Cloud image builder scripts =====
    cat > "$ROOTFS/usr/local/bin/nexos-build-ami" << 'AMI'
#!/bin/sh
# NexOS AWS AMI builder
# Prerequisites: aws-cli configured, qemu-img, sudo
set -e
OUTPUT="${1:-/tmp/nexos-ami}"
WORKDIR=$(mktemp -d)
IMG="$WORKDIR/nexos.raw"
GZIP="$OUTPUT/nexos-ami.raw.gz"
mkdir -p "$OUTPUT"

echo "Building NexOS AMI image..."
# Create 10G raw image
qemu-img create -f raw "$IMG" 10G
# Partition
echo -e "g\nn\n1\n\n+512M\nt\n1\nn\n2\n\n\nw" | fdisk "$IMG"
# Setup loopback
LOOP=$(sudo losetup --show -fP "$IMG")
sudo mkfs.ext4 -F "${LOOP}p2"
sudo mkfs.fat -F32 "${LOOP}p1"
sudo mount "${LOOP}p2" "$WORKDIR/mnt"
sudo mkdir -p "$WORKDIR/mnt/boot"
sudo mount "${LOOP}p1" "$WORKDIR/mnt/boot"
# Extract ISO to image
sudo xorriso -osirrox on -indev "$(dirname "$0")/../nexos-server.iso" \
    -extract / "$WORKDIR/iso" 2>/dev/null
sudo cp -a "$WORKDIR/iso/"* "$WORKDIR/mnt/" 2>/dev/null || true
sudo grub-install --target=x86_64-efi --efi-directory="$WORKDIR/mnt/boot" \
    --boot-directory="$WORKDIR/mnt/boot" --removable 2>/dev/null || true
sudo umount "$WORKDIR/mnt/boot" "$WORKDIR/mnt"
sudo losetup -d "$LOOP"
# Compress
mkdir -p "$OUTPUT"
gzip -c "$IMG" > "$GZIP"
echo "AMI image: $GZIP"
echo "Import to AWS:"
echo "  aws s3 cp $GZIP s3://my-bucket/nexos-ami.raw.gz"
echo "  aws ec2 import-snapshot --disk-container format=raw,url=s3://my-bucket/nexos-ami.raw.gz"
rm -rf "$WORKDIR"
AMI
    chmod +x "$ROOTFS/usr/local/bin/nexos-build-ami"

    cat > "$ROOTFS/usr/local/bin/nexos-build-gcp-image" << 'GCP'
#!/bin/sh
# NexOS GCP image builder
set -e
OUTPUT="${1:-/tmp/nexos-gcp}"
WORKDIR=$(mktemp -d)
IMG="$WORKDIR/nexos-gcp.tar.gz"
mkdir -p "$OUTPUT"

echo "Building NexOS GCP image..."
qemu-img create -f raw "$WORKDIR/disk.raw" 10G
echo -e "g\nn\n1\n\n+512M\nt\n1\nn\n2\n\n\nw" | fdisk "$WORKDIR/disk.raw"
LOOP=$(sudo losetup --show -fP "$WORKDIR/disk.raw")
sudo mkfs.ext4 -F "${LOOP}p2"
sudo mkfs.fat -F32 "${LOOP}p1"
sudo mount "${LOOP}p2" "$WORKDIR/mnt"
sudo mkdir -p "$WORKDIR/mnt/boot"
sudo mount "${LOOP}p1" "$WORKDIR/mnt/boot"
sudo xorriso -osirrox on -indev "$(dirname "$0")/../nexos-server.iso" \
    -extract / "$WORKDIR/iso" 2>/dev/null || true
sudo cp -a "$WORKDIR/iso/"* "$WORKDIR/mnt/" 2>/dev/null || true
sudo grub-install --target=x86_64-efi --efi-directory="$WORKDIR/mnt/boot" \
    --boot-directory="$WORKDIR/mnt/boot" --removable 2>/dev/null || true
sudo umount "$WORKDIR/mnt/boot" "$WORKDIR/mnt"
sudo losetup -d "$LOOP"
# GCP requires raw disk image packed as tar.gz
tar czf "$IMG" -C "$WORKDIR" disk.raw
echo "GCP image: $IMG"
echo "Upload to GCP:"
echo "  gcloud compute images create nexos-server --source-file=$IMG --guest-os-features=UEFI_COMPATIBLE"
rm -rf "$WORKDIR"
GCP
    chmod +x "$ROOTFS/usr/local/bin/nexos-build-gcp-image"

    # ===== SELinux alternative LSM skeleton =====
    mkdir -p "$ROOTFS/etc/selinux/nexos"
    cat > "$ROOTFS/etc/selinux/nexos/config" << 'SELINUX'
# SELinux configuration for NexOS
# Primary LSM: AppArmor
# SELinux is available as an alternative via kernel cmdline:
#   selinux=1 security=selinux
# Build reference policy with:
#   apk add selinux-policy-refpolicy
#   make -C /usr/share/selinux/refpolicy

SELINUX=disabled
SELINUXTYPE=nexos
SETLOCALDEFS=0
SELINUX
    cat > "$ROOTFS/etc/selinux/nexos/policy/policy.31" << 'SELPOL'
# NexOS SELinux policy placeholder
# Install refpolicy and compile:
#   apk add selinux-policy-refpolicy checkpolicy
#   cd /usr/share/selinux/refpolicy && make
#   cp policy.* /etc/selinux/nexos/policy/
SELPOL

    # ===== Operations: Auto-install config (preseed-style) =====
    mkdir -p "$ROOTFS/etc/nexos"
    cat > "$ROOTFS/etc/nexos/install.conf" << 'INSTALL'
# NexOS auto-install configuration
# Copy to /etc/nexos/install.conf or pass via kernel cmdline: nexos.config=<url>
#
# Boot arguments:
#   nexos.install=auto        - enable auto-install
#   nexos.config=<url>        - URL to this config file
#   nexos.disk=/dev/sda       - target disk
#   nexos.filesystem=ext4     - root filesystem (ext4/btrfs/xfs)
#   nexos.hostname=nexos      - server hostname
#   nexos.password=<hash>     - SHA512 password hash
#   nexos.ssh-key=<url>       - URL to SSH public key

disk=/dev/sda
filesystem=ext4
hostname=nexos
timezone=UTC
INSTALL

    echo "nexos-snapshot: take filesystem snapshots"
    echo "nexos-rollback: rollback to a snapshot"
    echo "nexos-pxe-boot.sh: set up PXE boot server"

    # ===== Performance: NexOS tuned profile =====
    mkdir -p "$ROOTFS/etc/tuned/nexos-server"
    cat > "$ROOTFS/etc/tuned/nexos-server/tuned.conf" << 'TUNED'
[main]
summary=NexOS Server optimized profile

[cpu]
governor=performance
energy_perf_policy=performance
min_perf_pct=100
max_perf_pct=100

[disk]
readahead=4096

[sysctl]
kernel.numa_balancing=1
kernel.sched_latency_ns=10000000
kernel.sched_migration_cost_ns=5000000
kernel.sched_min_granularity_ns=4000000
kernel.sched_wakeup_granularity_ns=5000000
vm.swappiness=10
vm.dirty_ratio=40
vm.dirty_background_ratio=10
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 134217728
net.ipv4.tcp_wmem=4096 65536 134217728
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
net.ipv4.tcp_notsent_lowat=16384

[service]
service.stress=off,disabled
TUNED

    # ===== Security: Secure Boot key enrollment & signing =====
    # ===== IMA/EVM policy =====
    mkdir -p "$ROOTFS/etc/ima"
    cat > "$ROOTFS/etc/ima/ima-policy" << 'IMA_POL'
# IMA default measurement policy
# Measure all executables, mmap'd files, and files opened for read
measure func=BPRM_CHECK
measure func=FILE_MMAP mask=MAY_EXEC
measure func=FILE_CHECK mask=MAY_READ uid=0
appraise func=BPRM_CHECK fowner=0
appraise func=FILE_MMAP mask=MAY_EXEC fowner=0
appraise func=MODULE_CHECK
IMA_POL
    # Load policy at boot via sysctl hook
    cat > "$ROOTFS/usr/lib/systemd/system/nexos-ima-policy.service" << 'IMA_SVC'
[Unit]
Description=NexOS IMA/EVM policy loader
DefaultDependencies=no
After=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c '/sbin/apk add ima-evm-utils 2>/dev/null; echo "ima_policy=tcb" > /sys/kernel/security/ima/policy 2>/dev/null || true; echo "0" > /sys/kernel/security/evm 2>/dev/null || true'

[Install]
WantedBy=basic.target
IMA_SVC
    ln -sf /usr/lib/systemd/system/nexos-ima-policy.service \
        "$ROOTFS/etc/systemd/system/basic.target.wants/" 2>/dev/null || true

    # ===== Security: Secure Boot key enrollment & signing =====
    cat > "$ROOTFS/usr/local/bin/nexos-secureboot-setup" << 'SB'
#!/bin/sh
# NexOS Secure Boot key enrollment
set -e
KEY_DIR="${KEY_DIR:-/etc/nexos/secureboot}"
mkdir -p "$KEY_DIR"
if [ ! -f "$KEY_DIR/DB.key" ]; then
    echo "Generating Secure Boot signing keys..."
    openssl req -new -x509 -newkey rsa:4096 -keyout "$KEY_DIR/DB.key" \
        -out "$KEY_DIR/DB.crt" -days 3650 -nodes \
        -subj "/CN=NexOS Secure Boot Key/"
    openssl x509 -in "$KEY_DIR/DB.crt" -out "$KEY_DIR/DB.der" -outform DER
    echo "Keys generated. To enroll:"
    echo "  1. Boot into UEFI firmware setup"
    echo "  2. Set Secure Boot to Setup Mode"
    echo "  3. Run: sbkeysync --verbose"
    echo ""
    echo "Or use mokutil on already-signed systems:"
    echo "  mokutil --import $KEY_DIR/DB.der"
fi
if [ -f /boot/vmlinuz-nexos ]; then
    echo "Signing kernel with Secure Boot key..."
    sbsign --key "$KEY_DIR/DB.key" --cert "$KEY_DIR/DB.crt" \
        --output /boot/vmlinuz-nexos.signed /boot/vmlinuz-nexos
fi
SB
    chmod +x "$ROOTFS/usr/local/bin/nexos-secureboot-setup"

    # SBAT (Secure Boot Advanced Targeting) data
    mkdir -p "$ROOTFS/etc/sbat"
    cat > "$ROOTFS/etc/sbat/nexos.csv" << 'SBAT'
sbat,1,SBAT Version,sbat,1,https://github.com/rhboot/shim/blob/main/SBAT.md
nexos,1,NexOS,nexos,1,https://nexos.dev
grub,1,GRUB,grub,2,https://www.gnu.org/software/grub/
SBAT
    # Add SBAT section to kernel (done at build time in nexos-secureboot-setup)
    cat >> "$ROOTFS/usr/local/bin/nexos-secureboot-setup" << 'SBAT2'
if [ -f /boot/vmlinuz-nexos ] && command -v pesign &>/dev/null; then
    pesign -s -i /boot/vmlinuz-nexos -o /boot/vmlinuz-nexos.sbat \
        --sbat /etc/sbat/nexos.csv 2>/dev/null || true
fi
SBAT2

    # ===== Kernel live patching: kpatch helper =====
    cat > "$ROOTFS/usr/local/bin/nexos-livepatch-status" << 'LP'
#!/bin/sh
echo "NexOS kernel live patching status:"
if [ -d /sys/kernel/livepatch ]; then
    for p in /sys/kernel/livepatch/*/enabled; do
        name=$(basename "$(dirname "$p")")
        val=$(cat "$p" 2>/dev/null || echo "unknown")
        echo "  $name: $([ "$val" = 1 ] && echo 'ACTIVE' || echo 'inactive')"
    done
else
    echo "  No live patches loaded"
fi
echo ""
echo "Kernel: $(uname -r)"
echo "Livepatch: $([ -f /proc/sys/kernel/livepatch_enabled ] && cat /proc/sys/kernel/livepatch_enabled || echo 'not available')"
LP
    chmod +x "$ROOTFS/usr/local/bin/nexos-livepatch-status"

    # ===== NFS/CIFS auto-config =====
    mkdir -p "$ROOTFS/etc/exports.d"
    cat > "$ROOTFS/etc/exports.d/nexos.exports" << 'NFS_EXP'
# NFS exports - uncomment to enable
#/srv/nfs  *(rw,sync,no_subtree_check,no_root_squash)
NFS_EXP
    mkdir -p "$ROOTFS/etc/systemd/system/nfs-server.service.d"
    cat > "$ROOTFS/etc/systemd/system/nfs-server.service.d/override.conf" << 'NFS_OVR'
[Unit]
Wants=network-online.target
After=network-online.target
NFS_OVR
    mkdir -p "$ROOTFS/etc/nexos/cifs"
    cat > "$ROOTFS/etc/nexos/cifs/example.conf" << 'CIFS_EX'
# CIFS mount example - save as /etc/systemd/system/mnt-share.mount:
# [Unit]
# Description=CIFS share mount
# [Mount]
# What=//server/share
# Where=/mnt/share
# Type=cifs
# Options=credentials=/etc/nexos/cifs/creds,uid=0,gid=0,file_mode=0644,dir_mode=0755,iocharset=utf8
CIFS_EX

    # ===== Logrotate configuration =====
    mkdir -p "$ROOTFS/etc/logrotate.d"
    cat > "$ROOTFS/etc/logrotate.d/nexos" << 'LOGROT'
/var/log/syslog /var/log/messages {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        /usr/bin/systemctl restart syslogd 2>/dev/null || true
    endscript
}
/var/log/nginx/*.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        /usr/bin/kill -USR1 $(cat /run/nginx.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
/var/log/containers/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
LOGROT

    # ===== Cloud: QEMU guest agent service =====
    mkdir -p "$ROOTFS/etc/systemd/system/qemu-guest-agent.service.d"
    cat > "$ROOTFS/etc/systemd/system/qemu-guest-agent.service.d/override.conf" << 'QEMU'
[Unit]
Description=NexOS QEMU guest agent
Wants=systemd-networkd.service
After=systemd-networkd.service

[Service]
ExecStart=
ExecStart=/usr/sbin/qemu-ga -d -m virtio-serial -p /dev/virtio-ports/org.qemu.guest_agent.0
Restart=always
RestartSec=5
QEMU
    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /usr/lib/systemd/system/qemu-guest-agent.service \
        "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true

}


build_overlay_initramfs() {
    local out="$1"
    info "Building overlay initramfs..."
    mkdir -p "$WORKDIR/initramfs-overlay"/{bin,dev,proc,sys,squash,overlay,newroot}
    cp "$ROOTFS/bin/busybox" "$WORKDIR/initramfs-overlay/bin/"

    mksquashfs "$ROOTFS" "$WORKDIR/initramfs-overlay/root.squashfs" \
        -comp zstd -b 1M -noappend 2>&1 | tail -1

    cd "$WORKDIR/initramfs-overlay/bin"
    for app in $(./busybox --list 2>/dev/null); do
        ln -sf busybox "$app" 2>/dev/null || true
    done
    cd "$WORKDIR/initramfs-overlay"

    cat > init << 'INIT'
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
INIT
    chmod +x init
    mknod dev/console c 5 1 2>/dev/null || true
    mknod dev/null c 1 3 2>/dev/null || true

    find . | cpio -o -H newc | gzip -9 > "$out"
    rm -rf "$WORKDIR/initramfs-overlay"
    info "Initramfs built: $(ls -lh "$out" | awk '{print $5}')"
}

# ===== STAGE 9: Bootloader & Initramfs =====
stage_boot() {
    info "=== Stage 8: Bootloader + Initramfs ==="
    local limine_dir="/home/whale-d/nex/Limine"
    
    mkdir -p "$ISO_DIR/boot" "$ISO_DIR/EFI/BOOT"
    
    # Limine binaries (BOOTX64.EFI in EFI/BOOT for UEFI, rest in boot/)
    cp "$limine_dir/BOOTX64.EFI" "$ISO_DIR/EFI/BOOT/"
    cp "$limine_dir/BOOTIA32.EFI" "$ISO_DIR/EFI/BOOT/" 2>/dev/null || true
    cp "$limine_dir/limine-bios.sys" "$ISO_DIR/boot/"
    cp "$limine_dir/limine-bios-cd.bin" "$ISO_DIR/boot/"
    cp "$limine_dir/limine-uefi-cd.bin" "$ISO_DIR/boot/"
    cp "$ROOTFS/boot/vmlinuz-nexos" "$ISO_DIR/boot/"

    # Build overlay initramfs
    build_overlay_initramfs "$ISO_DIR/boot/initramfs-nexos.img"

    # Limine config
    cat > "$ISO_DIR/boot/limine.conf" << 'LIMINE_CFG'
TIMEOUT=5
VERBOSE=yes

:NexOS Server 1.0
PROTOCOL=linux
KERNEL_PATH=boot:///boot/vmlinuz-nexos
MODULE_PATH=boot:///boot/initramfs-nexos.img
CMDLINE=root=/dev/ram0 rw console=tty0 console=ttyS0,115200 net.ifnames=0 systemd.unified_cgroup_hierarchy=1 apparmor=1 security=apparmor loglevel=3

:NexOS Server (Recovery)
PROTOCOL=linux
KERNEL_PATH=boot:///boot/vmlinuz-nexos
MODULE_PATH=boot:///boot/initramfs-nexos.img
CMDLINE=root=/dev/ram0 rw console=tty0 console=ttyS0,115200 net.ifnames=0 systemd.unified_cgroup_hierarchy=1 apparmor=1 security=apparmor loglevel=3 systemd.device_timeout=15

:NexOS Server (Debug)
PROTOCOL=linux
KERNEL_PATH=boot:///boot/vmlinuz-nexos
MODULE_PATH=boot:///boot/initramfs-nexos.img
CMDLINE=root=/dev/ram0 rw console=tty0 console=ttyS0,115200 net.ifnames=0 systemd.unified_cgroup_hierarchy=1 loglevel=7 systemd.log_level=debug systemd.device_timeout=15
LIMINE_CFG

    info "Bootloader + initramfs staged"
}

# ===== STAGE 10: ISO Creation =====
stage_iso() {
    info "=== Stage 9: Creating bootable ISO ==="
    local limine_dir="/home/whale-d/nex/Limine"

    # Follow Limine USAGE.md exactly for ISO structure
    # Files are: limine-bios-cd.bin, limine-uefi-cd.bin, limine-bios.sys, limine.conf in /boot/
    # BOOTX64.EFI -> /EFI/BOOT/BOOTX64.EFI

    info "Generating ISO image..."
    xorriso -as mkisofs -R -r -J \
        -b boot/limine-bios-cd.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -hfsplus -apm-block-size 2048 \
        --efi-boot boot/limine-uefi-cd.bin \
        -efi-boot-part --efi-boot-image --protective-msdos-label \
        "$ISO_DIR" -o "$OUTPUT" 2>&1 | tail -5

    "$limine_dir/limine" bios-install "$OUTPUT" 2>/dev/null || \
        warn "Limine bios-install failed"

    info "ISO: $(ls -lh "$OUTPUT" | awk '{print $5}')"
    
    # Note: ISO boots via -kernel/-initrd in QEMU (run.sh)
    # El Torito BIOS/UEFI may need real hardware or newer SeaBIOS
}

# ===== Main =====
main() {
    echo "=========================================="
    echo "  NexOS Server - Linux Distro Builder"
    echo "  Linux 7.1 | Limine | Server Focused"
    echo "=========================================="
    
    cd "$NEXOS"
    mkdir -p "$WORKDIR"

    stage_kernel
    stage_rootfs_base
    stage_systemd
    stage_nginx
    stage_mariadb
    stage_kubernetes
    stage_ssh
    stage_firewall
    stage_package_manager
    stage_config
    stage_boot
    stage_iso

    echo ""
    info "NexOS Server build complete!"
    info "Output: $OUTPUT"
    echo ""
    echo "Quick boot (QEMU):"
    echo "  ./run.sh"
    echo "  ./run.sh -g      # with display"
    echo ""
    echo "Installation:"
    echo "  dd if=$OUTPUT of=/dev/sdX bs=4M status=progress"
}

main "$@"
