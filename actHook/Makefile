ARCHS = armv7 arm64
SDKVERSION = 7.0

include ../theos/makefiles/common.mk

TWEAK_NAME = actHook
actHook_FILES = Tweak.xm
actHook_LIBRARIES = substrate
actHook_PRIVATE_FRAMEWORKS = ACTFramework

include $(THEOS_MAKE_PATH)/tweak.mk
