TARGET := iphone:clang:latest:14.0
ARCHS = arm64
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = AxiomRobloxModMenu
AxiomRobloxModMenu_FILES = Robloxui.m
AxiomRobloxModMenu_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
include $(THEOS_MAKE_PATH)/tweak.mk
