# Custom Firmware Development: Samsung Galaxy J7 (2016) (j7xelte)

## Project Overview

This repository contains the foundational device tree and configuration for building custom LineageOS 18.1 (Android 11) firmware for the Samsung Galaxy J7 (2016), model **SM-J710FN**, codenamed **j7xelte**.

The project aims to provide a stable, vanilla (GApps-free) Android experience optimized for the Exynos 7870 chipset, balancing performance with security and feature completeness.

## Hardware Specifications

*   **SoC:** Samsung Exynos 7870 (Octa-core 1.6 GHz Cortex-A53)
*   **GPU:** Mali-T830 MP1
*   **Architecture:** ARM64 (armv8-a)
*   **Bootloader:** universal7870
*   **Storage:** 16GB Internal (eMMC)
*   **RAM:** 2GB

## Features & Configuration

### Base System
*   **OS Base:** LineageOS 18.1 (Android 11)
*   **Build Variant:** `userdebug` (Root access via ADB for development)
*   **GApps:** None (Vanilla). Users can flash NikGApps or MindTheGapps separately.

### Kernel
*   **Version:** Linux 3.18.x (Samsung OSS Base)
*   **Configuration:** `exynos7870_j7xelte_defconfig`
*   **Features:**
    *   SELinux Enforcing capable (Permissive during initial bringup)
    *   Binder IPC 64-bit support
    *   Ashmem support

### Storage & Partitions
*   **Partition Scheme:** Non-Treble (Legacy)
*   **File Systems:** EXT4 for System, Userdata, Cache
*   **Encryption:** Full Disk Encryption (FDE) support enabled via footer

### Security
*   **SELinux:** Targeted for Enforcing mode in release builds.
*   **Signing:** Test keys are used for development builds. Release builds will require private keys.

## Directory Structure

The project follows the standard Android build system hierarchy:

*   **`device/samsung/j7xelte/`**: The core device configuration.
    *   `BoardConfig.mk`: Defines hardware architecture, partition sizes, and kernel flags.
    *   `lineage_j7xelte.mk`: The product makefile that inherits LineageOS common configurations.
    *   `rootdir/etc/`: Contains init scripts (`init.j7xelte.rc`) and partition tables (`fstab.exynos7870`).
    *   `sepolicy/`: SELinux policy rules and file contexts.

*   **`vendor/samsung/j7xelte/`**: Proprietary blobs extracted from stock firmware (GPU drivers, RIL, Camera HALs). *Note: You must populate this yourself.*

*   **`kernel/samsung/exynos7870/`**: The kernel source code. *Note: You must clone the Samsung kernel source here.*

## Build Instructions

### 1. Initialize the Build Environment
Set up your local build environment with the necessary dependencies (repo, git, build-essential, etc.).

### 2. Sync Source
```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-18.1
# Add local manifests if necessary
repo sync
```

### 3. Populate Vendor and Kernel
Ensure the kernel source is placed in `kernel/samsung/exynos7870` and vendor blobs are extracted to `vendor/samsung/j7xelte`.

### 4. Build
```bash
source build/envsetup.sh
lunch lineage_j7xelte-userdebug
mka bacon
```

## Disclaimer
**Flash at your own risk.** This is custom firmware development. Incorrect configurations or flashing procedures can brick your device. Always backup your EFS/Modem partitions before flashing any custom ROM.
