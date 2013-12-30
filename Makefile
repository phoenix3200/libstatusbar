TWEAK_NAME = libstatusbar
libstatusbar_FILES = libstatusbar.mm Classes.mm \
 							LSStatusBarClient.mm LSStatusBarServer.mm \
							UIStatusBarCustomItem.mm UIStatusBarCustomItemView.mm \
							LSStatusBarItem.mm # Testing.mm
# libstatusbar_FRAMEWORKS = UIKit

libstatusbar_PRIVATE_FRAMEWORKS = AppSupport SpringboardServices

libstatusbar_LDFLAGS += -lsubstrate

GO_EASY_ON_ME =1

# IPHONE_ARCHS = armv6 
IPHONE_ARCHS = armv6 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 4.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
SDKVERSION_armv6 = 4.0

# THEOS_PLATFORM_SDK_ROOT_armv6 = /Developer
THEOS_PLATFORM_SDK_ROOT_armv6 = /Applications/Xcode_440.app/Contents/Developer

#SDKVERSION = 3.0

# ADDITIONAL_OBJCCFLAGS = -fvisibility=hidden

include framework2/makefiles/common.mk
include framework2/makefiles/tweak.mk