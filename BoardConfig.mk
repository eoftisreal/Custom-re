# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := universal7870
TARGET_NO_BOOTLOADER := true

# Platform
BOARD_VENDOR := samsung
TARGET_SOC := exynos7870

# Kernel
BOARD_KERNEL_CMDLINE := console=ttySAC2,115200 androidboot.hardware=exynos7870
# TODO: Replace with verified values from stock SM-J710FN boot.img
BOARD_KERNEL_BASE := 0x10000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_TAGS_OFFSET := 0x00000100
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_VERSION := 0
TARGET_KERNEL_SOURCE := kernel/samsung/exynos7870
TARGET_KERNEL_CONFIG := exynos7870_j7xelte_defconfig

# Android 12 kernel config requirements (in addition to USB WiFi below):
#   CONFIG_ANDROID_BINDER_IPC=y
#   CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
#   CONFIG_ANDROID_BINDER_IPC_SELFTEST=n
#   CONFIG_ION=y
#   CONFIG_ION_EXYNOS=y
#   CONFIG_DM_VERITY=y
#   CONFIG_EXT4_FS_ENCRYPTION=y
#   CONFIG_ASHMEM=y
#   CONFIG_FHANDLE=y
#   CONFIG_CGROUPS=y
#   CONFIG_MEMCG=y
#   CONFIG_MEMCG_SWAP=y
#   CONFIG_ZRAM=y
#   CONFIG_CRYPTO_LZ4=y

# External USB WiFi (RTL8192EU) - Kernel config requirements
# These flags must be set in the kernel defconfig (exynos7870_j7xelte_defconfig):
#   CONFIG_USB_SUPPORT=y
#   CONFIG_USB=y
#   CONFIG_USB_OTG=y
#   CONFIG_USB_EHCI_HCD=y
#   CONFIG_USB_NET_DRIVERS=y
#   CONFIG_CFG80211=y
#   CONFIG_MAC80211=y
#   CONFIG_NET_RADIO=y
#   CONFIG_PACKET=y
#   CONFIG_CFG80211_WEXT=y
#   CONFIG_MODULES=y
#   CONFIG_MODULE_UNLOAD=y
#   CONFIG_MODVERSIONS=y

# Security hardening - Kernel config requirements:
#   CONFIG_CC_STACKPROTECTOR_STRONG=y  (stack canaries)
#   CONFIG_HARDENED_USERCOPY=y         (hardened usercopy)
#   CONFIG_FORTIFY_SOURCE=y            (buffer overflow detection)
#   CONFIG_STRICT_KERNEL_RWX=y         (read-only kernel text/rodata)
#   CONFIG_SECURITY_PERF_EVENTS_RESTRICT=y
#   CONFIG_PAGE_TABLE_ISOLATION=y      (Spectre v2 mitigation, if available)
#   CONFIG_SECCOMP=y                   (syscall filtering)
#   CONFIG_SECCOMP_FILTER=y

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 41943040

# TODO: Replace with actual PIT values from heimdall print-pit
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
BOARD_VENDORIMAGE_PARTITION_SIZE := 524288000
BOARD_USERDATAIMAGE_PARTITION_SIZE := 12884901888
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4

# Vendor partition
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor

# System as root
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false

# VNDK
BOARD_VNDK_VERSION := current

# Recovery
TARGET_RECOVERY_FSTAB := device/samsung/j7xelte/recovery.fstab

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += \
    device/samsung/j7xelte/sepolicy/vendor

# HIDL
DEVICE_MANIFEST_FILE := device/samsung/j7xelte/manifest.xml
DEVICE_MATRIX_FILE := device/samsung/j7xelte/compatibility_matrix.xml

# Inherit from the proprietary version
-include vendor/samsung/j7xelte/BoardConfigVendor.mk
