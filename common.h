
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <syslog.h>


#import <mach/mach.h>



#include <sys/event.h>

#include <execinfo.h>

#include <sys/time.h>


//extern "C" UIApplication* UIApp;
//extern UIApplication* UIApp;


#import "UIApplication_libstatusbar.h"
@interface UIApplication (statusbar)
- (UIStatusBar*) statusBar;
@end
@interface UIImage (kitImageNamed)
+ (UIImage*) kitImageNamed: (NSString*) name;
+ (UIImage*) imageNamed: (NSString*) name inBundle: (NSBundle*) bundle;
@end

extern "C" int SBSSpringBoardServerPort();

#import <objc/message.h>
#import <substrate.h>

#import <notify.h>

#import <unistd.h>

#import "UIKIT/UIStatusBarLayoutManager.h"
#import "UIKIT/UIStatusBarItem.h"
#import "UIKIT/UIStatusBarItemView.h"
#import "UIKIT/UIStatusBarForegroundView.h"
#import "UIKIT/UIStatusBarServer.h"

#import "UIKIT/UIStatusBar.h"
#import "UIKIT/UIStatusBarTimeItemView.h"

#import "CPDistributedMessagingCenter.h"


enum sandbox_filter_type {
	SANDBOX_FILTER_NONE = 0,
	SANDBOX_FILTER_PATH = 1,
	SANDBOX_FILTER_GLOBAL_NAME  =2,
	SANDBOX_FILTER_LOCAL_NAME = 3,
	SANDBOX_CHECK_NO_REPORT = 0x40000000
};

extern "C" int sandbox_check(pid_t pid, const char *operation, enum sandbox_filter_type type, ...);



enum CFVers
{
	CF_NONE = 0,
	CF_30 = 1,
	CF_31 = 2,
	CF_32 = 4,
	CF_40 = 8,
	CF_41 = 16,
	CF_42 = 32,
	CF_43 = 64,
	CF_50 = 128,
	CF_51 = 256,
	CF_60 = 512,
	CF_70 = 1024,
	CF_71 = 2048,
	CF_80 = 4096,
	CF_81 = 8192
};

extern CFVers cfvers;

// structures listed here are NOT valid for iOS 4.2+ - at least two more "items" exist
/*
struct StatusBarData
{
	char itemIsEnabled[20];
	char timeString[64];				// TimeItem
	int gsmSignalStrengthRaw;			// SignalStrength
	int gsmSignalStrengthBars;			// SignalStrength
	char serviceString[100];			// Service
	char serviceImageBlack[100];		// Service
	char serviceImageSilver[100];		// Service
	char operatorDirectory[1024];		// Service
	unsigned int serviceContentType;	// Service
	int wifiSignalStrengthRaw;			// DataNetwork
	int wifiSignalStrengthBars;			// DataNetwork
	unsigned int dataNetworkType;		// DataNetwork
	int batteryCapacity;				// Battery, BatteryPercent
	unsigned int batteryState;			// Battery
	int bluetoothBatteryCapacity;		// BluetoothBattery
	int thermalColor;					// ThermalColor
	bool slowActivity;					// Activity
	char activityDisplayId[256];
	bool bluetoothConnected;			// Bluetooth
	bool displayRawGSMSignal;			// SignalStrength
	bool displayRawWifiSignal;			// DataNetwork
};
*/

/*	ClassNameComponent	indicatorName	priority	leftOrder	rightOrder	canBeEnabledForData
0	Time								15			0			0
1	Lock				Lock			15			0			0
2	AirplaneMode		Airplane		15			1			0
3	SignalStrength						15			2			0
4	Service								15			3			0
5	DataNetwork							12			4			0
6	Battery								15			0			1
7	BatteryPercent						1			0			2
8	BluetoothBattery					2			0			3
9	Bluetooth							10			0			4
10	Indicator			TTY				13			0			6
11	Indicator			Alarm			8			0			7
12	Indicator			Plus			5			0			8
13	Indicator			Play			6			0			9
14	Indicator			Location		7			0			11
15	Indicator			RotationLock	11			0			12
16	Indicator			VPN				3			7			10
17	Indicator			CallForward		4			6			13
18	Activity							9			0			14			_UIStatusBarActivityItemCanBeEnabled
19	ThermalColor						0			5			5
*/