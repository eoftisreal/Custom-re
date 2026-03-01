# Kernel Integration Instructions

This device tree relies on an external kernel source repository.

## 1. Kernel Source
The kernel source should be placed in `kernel/samsung/exynos7870`.

You can use the `lineage.dependencies` file to automatically fetch it, or add it to your local manifest (`.repo/local_manifests/j7xelte.xml`):

```xml
<project path="kernel/samsung/exynos7870" name="android_kernel_samsung_exynos7870" remote="github" revision="lineage-19.1" />
```

*Note: Ensure you replace `android_kernel_samsung_exynos7870` with the actual repository name you are using.*

## 2. Android 12 Kernel Config Requirements

The following kernel config options are **required** for Android 12 compatibility on kernel 3.18:

### Binder IPC (critical)
```
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
CONFIG_ANDROID_BINDER_IPC_SELFTEST=n
```

### Memory Management
```
CONFIG_ASHMEM=y
CONFIG_ION=y
CONFIG_ION_EXYNOS=y
CONFIG_CGROUPS=y
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
CONFIG_ZRAM=y
CONFIG_CRYPTO_LZ4=y
CONFIG_FHANDLE=y
```

### Security
```
CONFIG_DM_VERITY=y
CONFIG_EXT4_FS_ENCRYPTION=y
CONFIG_SECURITY_SELINUX=y
CONFIG_CC_STACKPROTECTOR_STRONG=y
CONFIG_HARDENED_USERCOPY=y
CONFIG_FORTIFY_SOURCE=y
CONFIG_STRICT_KERNEL_RWX=y
CONFIG_SECCOMP=y
CONFIG_SECCOMP_FILTER=y
```

### Kernel Stability & Performance
```
CONFIG_HIGH_RES_TIMERS=y
CONFIG_PREEMPT=y
# Disable in production builds:
# CONFIG_DEBUG_KERNEL is not set
```

### Namespace / Container Support (chroot, proot, NetHunter)
```
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_BLK_DEV_LOOP=y
CONFIG_SQUASHFS=y
CONFIG_SQUASHFS_XZ=y
CONFIG_SQUASHFS_LZO=y
CONFIG_FUSE_FS=y
CONFIG_DEVPTS_MULTIPLE_INSTANCES=y
```

### Networking / Netfilter (Security Research)
```
CONFIG_NETFILTER=y
CONFIG_NETFILTER_ADVANCED=y
CONFIG_NF_CONNTRACK=y
CONFIG_NF_NAT=y
CONFIG_IP_NF_IPTABLES=y
CONFIG_IP_NF_FILTER=y
CONFIG_IP_NF_NAT=y
CONFIG_IP_NF_MANGLE=y
CONFIG_IP_NF_RAW=y
CONFIG_IP6_NF_IPTABLES=y
CONFIG_BRIDGE_NETFILTER=y
CONFIG_TUN=y
CONFIG_VETH=y
```

### NetHunter / USB Gadget Support
```
CONFIG_USB_GADGET=y
CONFIG_USB_CONFIGFS=y
CONFIG_USB_CONFIGFS_RNDIS=y
CONFIG_USB_CONFIGFS_ECM=y
CONFIG_USB_CONFIGFS_ACM=y
CONFIG_USB_CONFIGFS_MASS_STORAGE=y
CONFIG_USB_F_HID=y
CONFIG_USB_CONFIGFS_F_HID=y
CONFIG_HID=y
CONFIG_HIDRAW=y
CONFIG_USB_HIDDEV=y
```

### General
```
CONFIG_AUDIT=y
CONFIG_EPOLL=y
CONFIG_SIGNALFD=y
CONFIG_TIMERFD=y
CONFIG_EVENTFD=y
CONFIG_SHMEM=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
```

## 3. Boot Image Configuration
`BoardConfig.mk` is currently configured to use `exynos7870_j7xelte_defconfig`.

Once you have a working kernel build, you may need to update `BoardConfig.mk` with the correct `BOARD_MKBOOTIMG_ARGS`.
You can extract these arguments from a stock `boot.img` using `unpackbootimg`.

Example (Verify with your device!):
```makefile
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --dt_dir $(OUT)/obj/KERNEL_OBJ/arch/arm64/boot/dts
```

## 4. RTL8192EU USB WiFi Driver (TP-Link TL-WN823N)

This device tree includes support for loading the RTL8192EU out-of-tree kernel module (`8192eu.ko`) for external USB WiFi via TP-Link TL-WN823N (v2/v3).

### Kernel Defconfig Requirements

Ensure the following options are set in `exynos7870_j7xelte_defconfig`:

```
CONFIG_USB_SUPPORT=y
CONFIG_USB=y
CONFIG_USB_OTG=y
CONFIG_USB_EHCI_HCD=y
CONFIG_USB_NET_DRIVERS=y
CONFIG_CFG80211=y
CONFIG_MAC80211=y
CONFIG_NET_RADIO=y
CONFIG_PACKET=y
CONFIG_CFG80211_WEXT=y
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_MODVERSIONS=y
```

### Building the Driver Module

From the kernel source root (`kernel/samsung/exynos7870`):

```bash
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-

make M=drivers/net/wireless/rtl8192eu modules
```

This produces `8192eu.ko`. Verify with:

```bash
modinfo 8192eu.ko
```

Ensure `vermagic` matches `uname -r` on the target device. The module must be built with the **same compiler and LOCALVERSION** as the kernel.

### Installation

Place `8192eu.ko` in `vendor/lib/modules/` so it is included in the vendor image. The init script (`init.j7xelte.rc`) will load it automatically at boot.

For testing before permanent integration:

```bash
adb push 8192eu.ko /data/local/tmp/
adb shell su -c "insmod /data/local/tmp/8192eu.ko"
adb shell dmesg | grep 8192
```

### Monitor Mode (Patched Driver Only)

If using the aircrack-ng patched fork of rtl8192eu:

```bash
ip link set wlan1 down
iw dev wlan1 set type monitor
ip link set wlan1 up
iw dev
```

Monitor mode and packet injection require the patched driver variant. The stock Realtek driver does not support these features.

See `USB_WIFI_SETUP.md` for the full integration guide.
