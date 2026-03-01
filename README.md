# Custom Firmware Development: Samsung Galaxy J7 (2016) (j7xelte)

## Project Overview

This repository contains the foundational device tree and configuration for building custom CoinOS 1.0 (Android 12) firmware for the Samsung Galaxy J7 (2016), model **SM-J710FN**, codenamed **j7xelte**.

The project aims to provide a stable, vanilla (GApps-free) Android experience optimized for the Exynos 7870 chipset, balancing performance with security and feature completeness.

**Note:** Android 12 runs on the legacy 3.18 kernel. A kernel upgrade is not feasible for this SoC, so compatibility is achieved through backports, shim libraries, and aggressive optimization.

## Hardware Specifications

*   **SoC:** Samsung Exynos 7870 (Octa-core 1.6 GHz Cortex-A53)
*   **GPU:** Mali-T830 MP1
*   **Architecture:** ARM64 (armv8-a)
*   **Bootloader:** universal7870
*   **Storage:** 16GB Internal (eMMC)
*   **RAM:** 2GB

## Features & Configuration

### Base System
*   **OS Base:** CoinOS 1.0 (Android 12)
*   **Build Variant:** `userdebug` (Root access via ADB for development)
*   **GApps:** None (Vanilla). Users can flash NikGApps or MindTheGapps separately.

### Kernel
*   **Version:** Linux 3.18.140 (Samsung OSS Base)
*   **Configuration:** `exynos7870_j7xelte_defconfig`
*   **Features:**
    *   SELinux Enforcing mode (required by Android 12)
    *   Binder IPC with binder, hwbinder, and vndbinder devices
    *   Ashmem support
    *   ION memory allocator (legacy)
    *   ZRAM compressed swap enabled
    *   DM-Verity support
    *   EXT4 encryption support

### Storage & Partitions
*   **Partition Scheme:** Treble-compatible (system/vendor split)
*   **File Systems:** EXT4 for System, Vendor, Userdata, Cache
*   **Encryption:** Full Disk Encryption (FDE) support enabled via footer
*   **VNDK:** Current version enforced

### Memory & Performance Optimization
*   **ZRAM:** 1GB compressed swap via LZ4
*   **LMKD:** Aggressively tuned for 2GB RAM
*   **Background apps:** Limited to 20
*   **CPU Governor:** schedutil
*   **Animation scales:** Reduced to 0.5x for snappier UI
*   **I/O Scheduler:** CFQ with 512KB read-ahead

### Security
*   **SELinux:** Enforcing mode (required by Android 12, no permissive fallback)
*   **Signing:** Test keys are used for development builds. Release builds will require private keys.

## Directory Structure

The project follows the standard Android build system hierarchy:

*   **`device/samsung/j7xelte/`**: The core device configuration.
    *   `BoardConfig.mk`: Defines hardware architecture, partition sizes, kernel flags, and VNDK configuration.
    *   `coinos_j7xelte.mk`: The product makefile that inherits CoinOS common configurations.
    *   `rootdir/etc/`: Contains init scripts (`init.j7xelte.rc`) and partition tables (`fstab.exynos7870`).
    *   `sepolicy/`: SELinux policy rules and file contexts for Android 12 enforcing mode.

*   **`vendor/samsung/j7xelte/`**: Proprietary blobs extracted from stock firmware (GPU drivers, RIL, Camera HALs) and shim libraries. *Note: You must populate this yourself.*

*   **`kernel/samsung/exynos7870/`**: The kernel source code. *Note: You must clone the Samsung kernel source here.*

## Build Instructions

### 1. Initialize the Build Environment
Set up your local build environment with the necessary dependencies (repo, git, build-essential, etc.).

### 2. Sync Source
```bash
repo init -u https://github.com/CoinOS/android.git -b coinos-1.0
# Add local manifests if necessary
repo sync
```

### 3. Populate Vendor and Kernel
Ensure the kernel source is placed in `kernel/samsung/exynos7870` and vendor blobs are extracted to `vendor/samsung/j7xelte`.

Shim libraries (`libshim_camera.so`, `libshim_ril.so`) must be built and placed in the vendor directory to resolve symbol mismatches between legacy blobs and Android 12 libraries.

### 4. Build
```bash
source build/envsetup.sh
lunch coinos_j7xelte-userdebug
mka bacon
```

## Android 12 Porting Notes

### Key Engineering Challenges
*   **Kernel 3.18 compatibility:** Requires backports for binder updates, ashmem, and memory management fixes.
*   **SELinux enforcing:** All vendor HAL domains must have complete policy rules. Expect hundreds of AVC denials during initial bring-up.
*   **Blob compatibility:** Samsung proprietary blobs require shim libraries for missing/renamed symbols in Android 12 libraries.
*   **Memory pressure:** Android 12 has higher baseline memory usage; aggressive LMKD and ZRAM tuning is critical.
*   **Graphics stack:** Mali-T830 blobs must be verified for EGL/GLES compatibility with Android 12 SurfaceFlinger.

### Known Limitations
*   VoLTE/IMS may be unstable due to RIL blob mismatches.
*   Performance ceiling constrained by hardware (Cortex-A53, 2GB RAM).
*   Long-term kernel maintainability limited due to 3.18 EOL status.

## Disclaimer
**Flash at your own risk.** This is custom firmware development. Incorrect configurations or flashing procedures can brick your device. Always backup your EFS/Modem partitions before flashing any custom ROM.
