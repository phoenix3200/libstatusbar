TWEAK_NAME = libstatusbar
libstatusbar_OBJCC_FILES = libstatusbar.mm Classes.mm \
 							LSStatusBarClient.mm LSStatusBarServer.mm \
							UIStatusBarCustomItem.mm UIStatusBarCustomItemView.mm \
							LSStatusBarItem.mm # Testing.mm
libstatusbar_FRAMEWORKS = UIKit
libstatusbar_PRIVATE_FRAMEWORKS = AppSupport SpringboardServices


#SYSROOT = /Wildcat7B367.dyld_cache
GO_EASY_ON_ME =1
SDKVERSION = 4.0

ADDITIONAL_OBJCCFLAGS = -fvisibility=hidden
ADDITIONAL_OBJCCFLAGS += -IUIKit_40/Headers/


include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

