
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
extern "C" UIApplication* UIApp;
#import "UIApplication_libstatusbar.h"
@interface UIApplication (statusbar)
- (UIStatusBar*) statusBar;
@end
@interface UIImage (kitImageNamed)
+ (UIImage*) kitImageNamed: (NSString*) name;
@end


#import <objc/message.h>
#import <substrate.h>

#import <notify.h>

#import "UIStatusBarLayoutManager.h"
#import "UIStatusBarItem.h"
#import "UIStatusBarItemView.h"
#import "UIStatusBarForegroundView.h"
#import "UIStatusBarServer.h"

#import "CPDistributedMessagingCenter.h"

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

