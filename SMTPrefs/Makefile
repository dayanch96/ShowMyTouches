TARGET := iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SMTPrefs
$(BUNDLE_NAME)_FILES = $(wildcard *.m Models/*/*.m Categories/*/*.m)
$(BUNDLE_NAME)_FRAMEWORKS = UIKit PhotosUI
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc -I../include -IModels -ICategories -DPACKAGE_VERSION='"$(PACKAGE_VERSION)"'

include $(THEOS_MAKE_PATH)/bundle.mk
