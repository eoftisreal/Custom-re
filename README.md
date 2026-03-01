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
*   **File Systems:** EXT4 for System, Vendor, Userdata, Cache; F2FS also supported
*   **Encryption:** Full Disk Encryption (FDE) support enabled via footer
*   **VNDK:** Current version enforced
*   **SQLite:** WAL journal mode for improved concurrent I/O

### Memory & Performance Optimization
*   **ZRAM:** 1.5GB compressed swap via LZ4 (75% of RAM for research workloads)
*   **KSM:** Kernel Same-page Merging enabled for memory deduplication
*   **LMKD:** Aggressively tuned for 2GB RAM with vmpressure-based monitoring
*   **Background apps:** Limited to 24
*   **CPU Governor:** schedutil with tuned rate limits (1ms up / 20ms down at boot, 10ms down post-boot for faster thermal response)
*   **Animation scales:** Reduced to 0.5x for snappier UI
*   **I/O Scheduler:** CFQ at boot → deadline post-boot, 2048KB→512KB readahead transition
*   **VM tuning:** dirty_ratio=15, dirty_background_ratio=5, swappiness=60, page-cluster=0
*   **ART:** Profile-guided JIT, speed-compiled system_server, dex2oat memory-bounded
*   **Kernel scheduler:** Tuned sched_latency, min_granularity, wakeup_granularity, migration_cost
*   **Post-boot:** Cache drop on boot_completed, scheduler switch, readahead reduction
*   **TCP:** cubic congestion, fastopen=3, tuned keepalive/fin timeouts
*   **Entropy:** Optimized read/write wakeup thresholds for faster boot
*   **EXT4:** journal_async_commit, commit=20 for reduced journal overhead

### Security Research & NetHunter Support
*   **Chroot/proot containers:** Full namespace support (PID, NET, UTS, IPC, USER, MNT)
*   **USB OTG:** Autosuspend disabled, stable host stack for research hardware
*   **USB gadgets:** HID, RNDIS, ECM, ACM, mass storage for NetHunter attacks
*   **USB configfs:** Full SELinux access for dynamic gadget configuration
*   **Network stack:** 8MB rmem/wmem buffers, 65K conntrack, 5000 backlog, tuned keepalive
*   **SELinux:** Dedicated `research_tool` domain with raw sockets, configfs, proc/sys access
*   **Wireless:** Full WEXT support, monitor mode, rfkill, NL80211 testmode
*   **Crypto:** ARM64 CE acceleration (AES, SHA2) for research tool performance
*   **Thermal management:** Logging reduced, governor tuned for sustained workloads
*   **NetHunter chroot:** Directories pre-created at /data/local/nhsystem

### External USB WiFi (RTL8192EU)
*   **Adapter:** TP-Link TL-WN823N (v2/v3) via USB OTG
*   **Driver:** rtl8192eu out-of-tree kernel module (`8192eu.ko`), loaded at boot via init script
*   **Monitor mode / Packet injection:** Supported with aircrack-ng patched driver fork
*   **Integration:** Module placed in `vendor/lib/modules/`, auto-loaded by `init.j7xelte.rc`
*   See [`USB_WIFI_SETUP.md`](USB_WIFI_SETUP.md) for the full integration guide

### HIDL HAL Interfaces
Declared in `manifest.xml`:
*   Audio 6.0, Audio Effect 6.0
*   Bluetooth 1.0
*   Camera Provider 2.4 (HAL3 enabled via `persist.camera.HAL3.enabled=1`)
*   DRM 1.3 (CryptoFactory, DrmFactory)
*   GNSS 1.0
*   Graphics: Allocator 2.0, Composer 2.1, Mapper 2.0
*   Keymaster 4.0, Gatekeeper 1.0
*   Sensors 1.0
*   WiFi 1.0, Supplicant 1.0, Hostapd 1.0
*   Health 2.1

### Graphics & Rendering
*   **GPU Composition:** Prefer GPU over HWC for stability on Mali-T830
*   **Renderer:** SkiaGL threaded backend with render-ahead=2
*   **HWUI cache:** Tuned for 2GB RAM (texture=24MB, layer=16MB, path=4MB)
*   **SurfaceFlinger:** Color management enabled, max 3 acquired frame buffers

### Telephony & IMS
*   **RIL:** Samsung Exynos 7870 RIL with power collapse support
*   **VoLTE/VT/WFC:** Enabled via IMS properties and overlay config
*   **IMS daemon:** Starts after RIL connection for VoLTE/VT registration

### Security
*   **SELinux:** Enforcing mode (required by Android 12, no permissive fallback)
*   **ASLR:** Full randomization (`randomize_va_space=2`)
*   **Kernel hardening:** Stack protector (strong), hardened usercopy, FORTIFY_SOURCE, SECCOMP filter
*   **Signing:** Test keys are used for development builds. Release builds will require private keys.

### Overlay Customizations
*   Gesture navigation enabled by default
*   WiFi MAC address randomization enabled
*   Animation scales reduced to 0.5x for snappier UI on low-end hardware
*   Quick Settings: 2 columns, max 4 notification icons

## Additional Documentation

*   [`KERNEL_INSTRUCTIONS.md`](KERNEL_INSTRUCTIONS.md) — Kernel config requirements, boot image configuration, and RTL8192EU driver build instructions
*   [`USB_WIFI_SETUP.md`](USB_WIFI_SETUP.md) — Full external USB WiFi integration guide (hardware, driver selection, monitor mode, known issues)

## Directory Structure

The project follows the standard Android build system hierarchy:

*   **`device/samsung/j7xelte/`**: The core device configuration.
    *   `AndroidProducts.mk`: Declares the product makefile for the build system.
    *   `BoardConfig.mk`: Defines hardware architecture, partition sizes, kernel flags, and VNDK configuration.
    *   `coin_j7xelte.mk`: The product makefile that inherits CoinOS common configurations.
    *   `device.mk`: Hardware permissions, memory optimization properties, overlay, and init script packaging.
    *   `system.prop`: System properties for RIL, IMS, graphics, Dalvik/ART, LMKD, and TCP tuning.
    *   `manifest.xml`: HIDL HAL interface declarations for the device.
    *   `compatibility_matrix.xml`: Required HIDL interfaces (binder manager, memory allocator).
    *   `recovery.fstab`: Partition table for recovery mode (includes external SD card).
    *   `coin.dependencies`: JSON file listing external repos (kernel, vendor) for automatic dependency resolution.
    *   `local_manifests_example.xml`: Example local manifest for repo sync.
    *   `extract-files.sh`: Script to extract proprietary blobs from a device or backup.
    *   `setup-makefiles.sh`: Generates vendor makefiles after blob extraction.
    *   `proprietary-files.txt`: List of proprietary blobs (audio, Bluetooth, camera, graphics, RIL, IMS, sensors, WiFi, shim libraries).
    *   `rootdir/etc/`: Contains init scripts (`init.j7xelte.rc`) and partition tables (`fstab.exynos7870`).
    *   `sepolicy/vendor/`: SELinux policy rules (`device.te`) and file contexts for Android 12 enforcing mode, including a dedicated `research_tool` domain for security research tools (raw sockets, configfs, USB gadgets).
    *   `overlay/`: Framework resource overlays for SystemUI, SettingsProvider, and CoreServices.

*   **`vendor/samsung/j7xelte/`**: Proprietary blobs extracted from stock firmware (GPU drivers, RIL, Camera HALs) and shim libraries. *Note: You must populate this yourself.*

*   **`kernel/samsung/exynos7870/`**: The kernel source code. *Note: You must clone the Samsung kernel source here.*

## Build Instructions

### 1. Initialize the Build Environment
Set up your local build environment with the necessary dependencies (repo, git, build-essential, etc.).

### 2. Sync Source
```bash
repo init -u https://github.com/eoftisreal/android.git -b coin-1.0
# Add local manifests for device dependencies (see local_manifests_example.xml):
# cp local_manifests_example.xml .repo/local_manifests/j7xelte.xml
repo sync
```

*Note: The `coin.dependencies` file can also be used by dependency resolvers to automatically fetch the kernel and vendor repos.*

### 3. Populate Vendor and Kernel
Ensure the kernel source is placed in `kernel/samsung/exynos7870` and vendor blobs are extracted to `vendor/samsung/j7xelte`.

See [`KERNEL_INSTRUCTIONS.md`](KERNEL_INSTRUCTIONS.md) for detailed kernel configuration requirements and boot image setup.

Shim libraries (`libshim_camera.so`, `libshim_ril.so`) must be built and placed in the vendor directory to resolve symbol mismatches between legacy blobs and Android 12 libraries.

### 4. Build
```bash
source build/envsetup.sh
lunch coin_j7xelte-userdebug
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

## Changelog

### 2026-03-01
*   **system.prop:** Added animation scale properties (0.5x) for snappier UI on 2GB RAM. Added thermal management logging properties to reduce overhead during sustained workloads.
*   **init.j7xelte.rc:** Added vendor module directory creation at `post-fs-data` to ensure out-of-tree drivers (e.g., RTL8192EU) load reliably. Added thermal governor enable and scheduler boost reset at boot for balanced thermal behavior.
*   **SELinux:** Added `thermal_hal` domain for SoC thermal monitoring and `health_hal` domain for battery/charger reporting. Refined `file_contexts` with thermal zone sysfs labels and HAL executable labels for Thermal 2.0 and Health 2.1 services.
*   **BoardConfig.mk:** Added `androidboot.selinux=enforcing` to kernel cmdline to enforce SELinux from first-stage init. Enabled `MALLOC_SVELTE` for reduced memory allocator overhead on 2GB RAM devices.
*   **fstab.exynos7870:** Changed `barrier=0` on cache and userdata partitions where `journal_async_commit` is used, since the async journal commit already provides ordering guarantees and the explicit barrier adds unnecessary write overhead on eMMC.

## Rationale for Kernel and SELinux Changes

### Kernel Configuration Rationale
The kernel 3.18 configuration is driven by three constraints: Android 12 compatibility, 2GB RAM optimization, and NetHunter security research support.

*   **`CONFIG_PREEMPT=y`** and **`CONFIG_HIGH_RES_TIMERS=y`**: Required for responsive UI on a single-cluster Cortex-A53 SoC. Without preemption, long-running kernel paths (e.g., filesystem commits) cause visible UI jank.
*   **`CONFIG_DEBUG_KERNEL=n`** and **`CONFIG_DEBUG_INFO=n`**: Debug infrastructure adds measurable overhead (lock debugging, assertion checks) and inflates the kernel image. Disabled for production builds to reclaim both CPU cycles and flash space.
*   **`CONFIG_MEMCG=y`** and **`CONFIG_MEMCG_SWAP=y`**: Android 12's LMKD relies on cgroup memory accounting for per-process memory tracking. Without these, the vmpressure-based LMKD cannot accurately identify memory hogs.
*   **`CONFIG_ZRAM=y`** and **`CONFIG_CRYPTO_LZ4=y`**: ZRAM provides 1.5GB of compressed swap using LZ4 (chosen over LZO for its lower CPU cost on Cortex-A53), effectively extending usable memory to ~3GB for research workloads.
*   **`CONFIG_KSM=y`**: Kernel Same-page Merging deduplicates identical memory pages across processes. On a 2GB device running multiple research containers, KSM can reclaim 50-100MB.
*   **`CONFIG_NAMESPACES`** (PID, NET, UTS, IPC, USER, MNT): Full namespace support is required for chroot/proot containers used by NetHunter. Without mount namespaces, container isolation is incomplete and processes can escape.
*   **`CONFIG_SECCOMP_FILTER=y`**: Android 12 requires seccomp for Zygote process sandboxing. Apps that fail the seccomp check are killed at launch.
*   **`androidboot.selinux=enforcing`** in kernel cmdline: Ensures SELinux is enforcing from the earliest init stage, before any vendor processes start. This prevents a window where processes could run unconfined.

### SELinux Policy Rationale
The SELinux policy follows Android 12's principle of least privilege while accommodating vendor HAL requirements and research tool access.

*   **`thermal_hal` domain**: Isolated domain for the Thermal HAL 2.0 service. Grants read-only access to thermal zone sysfs nodes (`/sys/class/thermal/`) for temperature monitoring. Write access is deliberately excluded — the HAL reports temperatures but does not directly control cooling.
*   **`health_hal` domain**: Isolated domain for the Health HAL 2.1 service. Grants read-only sysfs access for battery voltage, current, and charger status reporting. Separated from other HAL domains to limit blast radius if the health service is compromised.
*   **`research_tool` domain**: Confined domain for NetHunter and security research tools. Grants `net_raw`, `net_admin`, `sys_chroot`, and USB configfs access without requiring global permissive mode. This is a deliberate trade-off: research tools need elevated capabilities, but confining them to a labeled domain ensures that only binaries in `/data/local/nhsystem/` receive these privileges.
*   **`imsd` domain**: The IMS daemon requires binder access to both `hwservicemanager` and `servicemanager`, plus Unix socket connectivity to `rild` for VoLTE registration. Each permission was added in response to specific `avc: denied` audit logs during IMS bring-up.
*   **File context refinements**: Thermal zone sysfs (`/sys/class/thermal/`, `/sys/devices/virtual/thermal/`) and HAL executable paths are explicitly labeled to prevent `unlabeled` type denials that would block HAL startup in enforcing mode.
