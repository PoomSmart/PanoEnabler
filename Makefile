include theos/makefiles/common.mk

AGGREGATE_NAME = PanoEnabler
SUBPROJECTS = Preferences Installer PanoMod PanoModiOS6 PanoModiOS7 PanoModiOS8 PanoModiOS9 actFix actHook PanoHook RootHelper

include $(THEOS_MAKE_PATH)/aggregate.mk
