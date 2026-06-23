# NexOS Server Makefile
# Linux 7.1 + Limine bootloader

.PHONY: all kernel rootfs systemd packages config bootloader iso clean distclean

all: iso

kernel:
	./build.sh --kernel-only

rootfs: kernel
	./build.sh --rootfs-only

systemd: rootfs
	./build.sh --systemd-only

packages: systemd
	./build.sh --packages-only

config: packages
	./build.sh --config-only

bootloader: config
	./build.sh --bootloader-only

iso: bootloader
	./build.sh --iso-only

clean:
	rm -rf work/*
	find work -mindepth 1 -delete 2>/dev/null || true

distclean: clean
	rm -f nexos-server.iso
	rm -rf work
	rm -rf rootfs
