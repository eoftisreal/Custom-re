# Inherit from common samsung/exynos makefiles if available
# $(call inherit-product, hardware/samsung_slsi/exynos/exynos7870/exynos7870.mk)
# $(call inherit-product, hardware/samsung_slsi/exynos/exynos.mk)

# Overlay
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml

# Rootdir
PRODUCT_PACKAGES += \
    init.j7xelte.rc

# Copy fstab to ramdisk (for first stage init) and vendor (for second stage mount_all)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.exynos7870:$(TARGET_COPY_OUT_RAMDISK)/fstab.exynos7870 \
    $(LOCAL_PATH)/rootdir/etc/fstab.exynos7870:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.exynos7870

# Init scripts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.j7xelte.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.j7xelte.rc

# Inherit from vendor
$(call inherit-product-if-exists, vendor/samsung/j7xelte/j7xelte-vendor.mk)
