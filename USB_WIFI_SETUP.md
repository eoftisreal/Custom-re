# External USB WiFi Integration Guide

## Target Platform
- **Device:** Samsung Galaxy J7 2016 (Exynos 7870) — j7xelte
- **Kernel:** Linux 3.18.140
- **ROM Base:** LineageOS / Android 10+
- **Adapter:** TP-Link TL-WN823N (RTL8192EU)

## 1. Hardware Overview

**TP-Link TL-WN823N (v2/v3)**

| Property    | Value              |
|-------------|--------------------|
| Chipset     | Realtek RTL8192EU  |
| Interface   | USB 2.0            |
| Driver      | rtl8192eu (out-of-tree) |

Capabilities (driver dependent):
- Managed mode
- Monitor mode (patched driver only)
- Packet injection (patched driver only)

## 2. Architecture Overview

Data flow:

```
USB Adapter (TL-WN823N)
        ↓
USB Host Controller (Exynos USB OTG)
        ↓
Kernel USB Stack
        ↓
rtl8192eu.ko (kernel module)
        ↓
mac80211 / cfg80211
        ↓
Android WiFi HAL / userspace tools
```

> **Note:** Android framework does NOT natively manage external WiFi adapters.
> You will operate via: `iw`, `airmon-ng`, `tcpdump`, `aircrack-ng`.

## 3. Kernel Configuration Requirements

The following must be set in the kernel defconfig (`exynos7870_j7xelte_defconfig`):

### Core USB
```
CONFIG_USB_SUPPORT=y
CONFIG_USB=y
CONFIG_USB_OTG=y
CONFIG_USB_EHCI_HCD=y
CONFIG_USB_NET_DRIVERS=y
```

### Wireless Stack
```
CONFIG_CFG80211=y
CONFIG_MAC80211=y
CONFIG_NET_RADIO=y
CONFIG_PACKET=y
CONFIG_CFG80211_WEXT=y
```

### Module Support
```
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_MODVERSIONS=y
```

### Verification
```bash
modinfo 8192eu.ko    # check vermagic
uname -r             # must match module vermagic
```

## 4. Driver Selection

| Driver Type | Monitor Mode | Injection | Stability | 3.18 Compat |
|-------------|-------------|-----------|-----------|-------------|
| Official Realtek | No | No | High | Good |
| Aircrack-ng Fork | Yes | Yes | Medium | Requires patches |

**Recommended:** Use the aircrack-ng fork adapted for kernel 3.18 if monitor mode / injection is needed. Otherwise use the official Realtek driver for stability.

## 5. Building the Module

From the kernel source root:

```bash
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-

make M=drivers/net/wireless/rtl8192eu modules
```

Output: `8192eu.ko`

Verify:
```bash
modinfo 8192eu.ko
```

**Important:** Use the same compiler, vermagic, and LOCALVERSION for both the kernel and the module.

## 6. Integration Methods

### Method 1 — Manual Loading (Testing)

```bash
adb push 8192eu.ko /data/local/tmp/
adb shell
su
insmod /data/local/tmp/8192eu.ko
```

Verify:
```bash
dmesg | grep 8192
lsusb
ip link
```

### Method 2 — Permanent Integration

The device tree is already configured for permanent integration:

- `8192eu.ko` is listed in `proprietary-files.txt` at `vendor/lib/modules/8192eu.ko`
- `init.j7xelte.rc` loads the module at boot via `insmod /vendor/lib/modules/8192eu.ko`
- `device.mk` declares `android.hardware.usb.host` permission

Place the compiled `8192eu.ko` in the vendor blob directory so it is included in the vendor image during build.

## 7. Monitor Mode

After loading the module:

```bash
# Check interface
iw dev

# Enable monitor mode
ip link set wlan1 down
iw dev wlan1 set type monitor
ip link set wlan1 up

# Verify
iw dev
```

If the command fails, the driver variant does not support monitor mode.

## 8. Android Userspace Requirements

Required tools (root required):
- BusyBox
- `iw`
- `aircrack-ng`
- `tcpdump`

> Android does not expose the monitor interface in Settings UI.
> SELinux must be set to permissive during testing.

## 9. Known Issues on Kernel 3.18

- `cfg80211` API mismatch with newer driver code
- `net_device_ops` structure differences
- `skb` API changes
- Regulatory domain conflicts

Possible fixes:
- Backport missing kernel functions
- Modify driver source for 3.18 compatibility
- Disable unsupported features at compile time

## 10. Power Considerations

| Parameter | Value |
|-----------|-------|
| TL-WN823N draw | ~200–300mA |
| USB OTG supply | Limited |

**Risk:** Device reboot, USB disconnect, instability under load.

**Recommendation:** Use a powered OTG hub for stable operation.

## 11. Validation Checklist

After integration, verify each item:

- [ ] `lsusb` detects RTL8192EU
- [ ] `dmesg` shows driver attached
- [ ] `ip link` shows `wlan1`
- [ ] `iw dev` shows supported interface modes
- [ ] Monitor mode switches successfully (patched driver only)
- [ ] Packet capture works
- [ ] Injection test passes (`aireplay-ng --test`) (patched driver only)

> **Note:** USB power behavior, RF performance, monitor capture reliability, and injection stability cannot be tested virtually and must be verified on real hardware.
