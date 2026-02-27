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
BOARD_KERNEL_CMDLINE := console=ttySAC2,115200 androidboot.hardware=exynos7870 androidboot.selinux=permissive
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

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 41943040

# TODO: Replace with actual PIT values from heimdall print-pit
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
BOARD_USERDATAIMAGE_PARTITION_SIZE := 12884901888
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# System as root
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false # Android 11 legacy handling for non-AB devices, verify if true is needed for your specific setup. Often false for older devices on R.

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
