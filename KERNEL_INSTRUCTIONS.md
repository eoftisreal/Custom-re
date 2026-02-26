# Kernel Integration Instructions

This device tree relies on an external kernel source repository.

## 1. Kernel Source
The kernel source should be placed in `kernel/samsung/exynos7870`.

You can use the `lineage.dependencies` file to automatically fetch it, or add it to your local manifest (`.repo/local_manifests/j7xelte.xml`):

```xml
<project path="kernel/samsung/exynos7870" name="android_kernel_samsung_exynos7870" remote="github" revision="lineage-18.1" />
```

*Note: Ensure you replace `android_kernel_samsung_exynos7870` with the actual repository name you are using.*

## 2. Boot Image Configuration
`BoardConfig.mk` is currently configured to use `exynos7870_j7xelte_defconfig`.

Once you have a working kernel build, you may need to update `BoardConfig.mk` with the correct `BOARD_MKBOOTIMG_ARGS`.
You can extract these arguments from a stock `boot.img` using `unpackbootimg`.

Example (Verify with your device!):
```makefile
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --dt_dir $(OUT)/obj/KERNEL_OBJ/arch/arm64/boot/dts
```
