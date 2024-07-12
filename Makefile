FINALPACKAGE=1
TARGET := iphone:clang:latest
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += modules/ActionButtonEnablerPreferences
SUBPROJECTS += modules/ActionButtonEnablerSpringBoard

include $(THEOS_MAKE_PATH)/aggregate.mk
