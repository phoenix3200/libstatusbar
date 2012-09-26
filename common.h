
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <syslog.h>

extern "C" UIApplication* UIApp;
#import "UIApplication_libstatusbar.h"
@interface UIApplication (statusbar)
- (UIStatusBar*) statusBar;
@end
@interface UIImage (kitImageNamed)
+ (UIImage*) kitImageNamed: (NSString*) name;
@end

extern "C" int SBSSpringBoardServerPort();

#import <objc/message.h>
#import <substrate.h>

#import <notify.h>

#import "UIStatusBarLayoutManager.h"
#import "UIStatusBarItem.h"
#import "UIStatusBarItemView.h"
#import "UIStatusBarForegroundView.h"
#import "UIStatusBarServer.h"

#import "UIStatusBar.h"
#import "UIStatusBarTimeItemView.h"

#import "CPDistributedMessagingCenter.h"

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