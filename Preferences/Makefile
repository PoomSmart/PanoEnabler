GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7 arm64

BUNDLE_NAME = PanoPreferences
PanoPreferences_FILES = Preferences.mm
PanoPreferences_FRAMEWORKS = CoreGraphics Social UIKit
PanoPreferences_PRIVATE_FRAMEWORKS = Preferences
PanoPreferences_INSTALL_PATH = /Library/PreferenceBundles

include ../theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PanoPreferences.plist$(ECHO_END)
