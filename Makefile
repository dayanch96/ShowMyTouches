DEBUG = 0
FINALPACKAGE = 1
TARGET := iphone:clang:16.5:14.0
export PACKAGE_VERSION = 2.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ShowMyTouches
$(TWEAK_NAME)_FILES = Tweak.x Utils/SMTManager.m Views/SMTTouchView.m SMTPrefs/Models/SMTUserDefaults/SMTUserDefaults.m SMTPrefs/Models/SMTTouchSettings/SMTTouchSettings.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude -ISMTPrefs/Models
$(TWEAK_NAME)_LOGOS_DEFAULT_GENERATOR = internal

ifeq ($(SIDELOADING),1)
$(TWEAK_NAME)_FILES += Utils/SMTSettingsTrigger.m SMTPrefs/DVNRootListController.m $(wildcard SMTPrefs/Categories/*/*.m)
$(TWEAK_NAME)_CFLAGS += -DSIDELOADING=1 -ISMTPrefs -ISMTPrefs/Categories -DPACKAGE_VERSION='"$(PACKAGE_VERSION)"'
$(TWEAK_NAME)_FRAMEWORKS = UIKit PhotosUI
endif

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SIDELOADING),1)
internal-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/Library/Application Support"$(ECHO_END)
	$(ECHO_NOTHING)rsync -a "SMTPrefs/layout/Library/Application Support/SMTPrefs.bundle" "$(THEOS_STAGING_DIR)/Library/Application Support/" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE)$(ECHO_END)

before-package:: $(THEOS_STAGING_DIR)/DEBIAN/control
	$(ECHO_NOTHING)sed '/^Depends: mobilesubstrate/d' "$<" > "$<.tmp" && mv "$<.tmp" "$<"$(ECHO_END)
else
SUBPROJECTS += SMTPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk
endif

