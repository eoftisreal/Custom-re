# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile
$(call inherit-product, device/samsung/j7xelte/device.mk)

# Inherit some common CoinOS stuff.
$(call inherit-product, vendor/coin/config/common_full_phone.mk)

PRODUCT_NAME := coin_j7xelte
PRODUCT_DEVICE := j7xelte
PRODUCT_MANUFACTURER := Samsung
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-J710FN

PRODUCT_GMS_CLIENTID_BASE := android-samsung
