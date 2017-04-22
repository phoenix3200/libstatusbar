
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "UIStatusBarCustomItem.h"
#import "UIStatusBarCustomItemView.h"
#import "LSStatusBarServer.h"
#import "LSStatusBarClient.h"


#import "LSStatusBarItem.h"


NSMutableArray* customItems[3];	 // left, right, center


#pragma mark UIStatusBar* Hooks

HOOKDEF(id, UIStatusBarItem, itemWithType$, int type)
{
	id ret = CALL_ORIG(UIStatusBarItem, itemWithType$, type);
	
	// construct our own custom item
	if(ret==nil)
	{
		ret = [[$UIStatusBarCustomItem alloc] initWithType: type];
	}
	return ret;
}

HOOKDEF(id, UIStatusBarItem, itemWithType$idiom$, int type, int idiom)
{
	id ret = CALL_ORIG(UIStatusBarItem, itemWithType$idiom$, type, idiom);
	
	// construct our own custom item
	if(ret==nil)
	{
		ret = [[$UIStatusBarCustomItem alloc] initWithType: type];
	}
	return ret;
}



@interface UIStatusBarItemView (extraSelector)
+ (UIStatusBarItemView*) createViewForItem: (UIStatusBarItem*) item withData: (void*) data actions: (int) actions foregroundStyle: (int) style;
@end

UIStatusBarItemView* InitializeView(UIStatusBarLayoutManager* self, id item)
{
	//NSLine();
	
	UIStatusBarItemView* _view = [item viewForManager: self];
	if(_view)
	{
		return _view;
	}
	
	//NSLine();
	
	
	GETVAR(UIStatusBarForegroundView*, _foregroundView);
	int foregroundStyle = [_foregroundView foregroundStyle];
	
	
	if([$UIStatusBarItemView respondsToSelector: @selector(createViewForItem:foregroundStyle:)])
	{
		_view = [$UIStatusBarItemView createViewForItem: item foregroundStyle: foregroundStyle];
	}
	else if([$UIStatusBarItemView respondsToSelector: @selector(createViewForItem:withData:actions:foregroundStyle:)])
	{
		_view = [$UIStatusBarItemView createViewForItem: item withData: nil actions: 0 foregroundStyle: foregroundStyle];
	}
	
	[_view setLayoutManager: self];

	GETVAR(int, _region);
	switch(_region)
	{
		case 0:
		{
			[_view setContentMode: UIViewContentModeLeft];
			[_view setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
			break;
		}
		case 1:
		{
			[_view setContentMode: UIViewContentModeRight];
			[_view setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin];
			break;
		}
		case 2:
		{
			[_view setContentMode: UIViewContentModeLeft];
			[_view setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin]; // 0x25
			break;
		}
	}
	
	[item setView: _view forManager: self];
	return _view;
}


HOOKDEF(void, UIStatusBarForegroundView, _computeVisibleItems$eitherSideItems$, NSMutableArray** visibleItems,  NSMutableArray* eitherSideItems) // 3 visible items
{
//	SelLog();
	
	// add our objects to the appropriate arrays
	for(int i=0; i<2; i++) // only left+right - center is "virtual"
	{
		for(UIStatusBarCustomItem* item in customItems[i])
		{
			NSNumber* visible = [[item properties] objectForKey: @"visible"];
			if(!visible || [visible boolValue])
			{
				[visibleItems[i] addObject: item];
			}
		}
	}
	
	CALL_ORIG(UIStatusBarForegroundView, _computeVisibleItems$eitherSideItems$, visibleItems,  eitherSideItems);
}

@interface UIStatusBarLayoutManager (missing)
- (CGFloat) sizeNeededForItems: (NSArray*) items;
- (CGFloat) sizeNeededForItem: (UIStatusBarItem*) item;
- (CGFloat) _positionAfterPlacingItemView: (UIStatusBarItemView*) view startPosition: (CGFloat) position firstView: (BOOL) isFirst;

- (CGRect) _frameForItemView:(id)itemView startPosition:(CGFloat)position firstView:(BOOL)view;
@end

HOOKDEF(id, UIStatusBarForegroundView, _computeVisibleItemsPreservingHistory$, bool preserve)
{
//	SelLog();

	id ret = CALL_ORIG(UIStatusBarForegroundView, _computeVisibleItemsPreservingHistory$, preserve);
	
	UIStatusBarLayoutManager * (&layoutManagers)[3](MSHookIvar<UIStatusBarLayoutManager*[3]>(self, "_layoutManagers"));
	
	float boundsWidth = [self bounds].size.width;
	CGFloat centerWidth;
	{
		
		NSMutableArray* center = [ret objectForKey: [NSNumber numberWithInt: 2]];
		
		//centerWidth = ((CGFloat(*)(...)) objc_msgSend)(layoutManagers[2], (cfvers > CF_70) ? @selector(sizeNeededForItems:) : @selector(widthNeededForItems:), center);
		
		//centerWidth = [layoutManagers[2] widthNeededForItems: center];
		centerWidth = (cfvers >= CF_71) ? [layoutManagers[2] sizeNeededForItems: center] : [layoutManagers[2] widthNeededForItems: center];
		
//		CommonLog("Center width = %f", centerWidth);
	}
	
	float edgeWidth = (boundsWidth - centerWidth) * 0.5f;
	
	
	for(int i=0; i<2; i++)
	{
		NSMutableArray* arr = [ret objectForKey: [NSNumber numberWithInt: i]];
		//NSDesc(arr);
		
		
		[layoutManagers[i] clearOverlapFromItems: arr];
		
		//float arrWidth = [layoutManagers[i] widthNeededForItems: arr];
		CGFloat arrWidth = (cfvers >= CF_71) ? [layoutManagers[i] sizeNeededForItems: arr] : [layoutManagers[i] widthNeededForItems: arr];
		
		
		for(UIStatusBarCustomItem* item in customItems[i])
		{
			NSNumber* visible = [[item properties] objectForKey: @"visible"];
			if(!visible || [visible boolValue])
			{
				float itemWidth = (cfvers >= CF_71) ? [layoutManagers[i] sizeNeededForItem: item] : [layoutManagers[i] widthNeededForItem: item];
				//float itemWidth = [layoutManagers[i] widthNeededForItem: item];
				if(arrWidth + itemWidth < edgeWidth + 4)
				{
					[arr addObject: item];
					arrWidth += itemWidth;
				}
			}
		}
		//NSDesc(arr);

		if(arrWidth > edgeWidth - 1)
		{
			[layoutManagers[i] distributeOverlap: arrWidth - edgeWidth + 1 amongItems: arr];
		}
	}
//	NSDesc(ret);
	
	return ret;
}



HOOKDEF(UIView*, UIStatusBarLayoutManager, _viewForItem$creatingIfNecessary$, id item, bool ifNecc)
{
	if([item isKindOfClass: $UIStatusBarCustomItem])
	{
	//	NSLine();
		
		UIStatusBarItemView* _view = InitializeView(self, item);
		return _view;
	}
	else
	{
		UIView* ret = CALL_ORIG(UIStatusBarLayoutManager, _viewForItem$creatingIfNecessary$, item, ifNecc);
		return ret;
	}
}

HOOKDEF(UIView*, UIStatusBarLayoutManager, _viewForItem$, id item)
{
	if([item isKindOfClass: $UIStatusBarCustomItem])
	{
	//	NSLine();
		
		UIStatusBarItemView* _view = InitializeView(self, item);
		return _view;
	}
	else
	{
		UIView* ret = CALL_ORIG(UIStatusBarLayoutManager, _viewForItem$, item);
		return ret;
	}
}



HOOKDEF(NSMutableArray*, UIStatusBarLayoutManager, _itemViews)
{
	NSMutableArray* _itemViews = CALL_ORIG(UIStatusBarLayoutManager, _itemViews);
	
	// add our array here
	if(_itemViews)
	{
		GETVAR(int, _region);
		if(_region < 3 && customItems[_region])
		{
			for(UIStatusBarCustomItem* item in customItems[_region])
			{
				UIStatusBarItemView* _view = InitializeView(self, item);
				if(_view)
				{
					[_itemViews addObject: _view];
				}
			}
		}
	}
//	NSDesc(_itemViews);
	
	return _itemViews;
}



void PrepareEnabledItemsCommon(UIStatusBarLayoutManager* self)
{
	GETVAR(UIStatusBarForegroundView*, _foregroundView);
	
	float startPosition = [self _startPosition];
	for(UIStatusBarItemView* view in [self _itemViewsSortedForLayout])
	{
		if([view superview] == nil)
		{
			[view setVisible: NO];
			if(cfvers >= CF_71)
			{
				[view setFrame: (CGRect) {{0.0f, 0.0f}, [self _frameForItemView: view startPosition: startPosition firstView: YES].size}];
			}
			else
			{
				[view setFrame: (CGRect) {{0.0f, 0.0f}, [self _frameForItemView: view startPosition: startPosition].size}];
			}
			
			[_foregroundView addSubview: view];
		}
		int type = [[view item] type];
		if(type)
		{
			if(cfvers >= CF_71)
			{
				startPosition = [self _positionAfterPlacingItemView: view startPosition: startPosition firstView: YES];
			}
			else
			{
				startPosition = [self _positionAfterPlacingItemView: view startPosition: startPosition];
			}
			
		}
	}
}

HOOKDEF(BOOL, UIStatusBarLayoutManager, prepareEnabledItems$, BOOL* items)
{
//	SelLog();
	BOOL ret = CALL_ORIG(UIStatusBarLayoutManager, prepareEnabledItems$, items);
	
	// the default function didn't refresh...let's refresh anyways
	if(ret==NO)
	{
		PrepareEnabledItemsCommon(self);
	}
	return YES;
}

HOOKDEF(BOOL, UIStatusBarLayoutManager, prepareEnabledItems$withData$actions$, BOOL* items, void* data, int actions)
{
	NSLine();
//	SelLog();
	BOOL ret = CALL_ORIG(UIStatusBarLayoutManager, prepareEnabledItems$withData$actions$, items, data, actions);
	
	// the default function didn't refresh...let's refresh anyways
	if(ret==NO)
	{
		NSLine();
		PrepareEnabledItemsCommon(self);
	}
	return YES;
	
}


HOOKDEF(CGRect, UIStatusBarLayoutManager, rectForItems$, NSMutableArray* items)
{
	int &region(MSHookIvar<int>(self, "_region"));
	
	
	if(region != 2)
	{
		CommonLog("Rect for region %d", region);
		
		for(UIStatusBarCustomItem* item in customItems[region])
		{
			NSNumber* visible = [[item properties] objectForKey: @"visible"];
			if(!visible || [visible boolValue])
			{
				[items addObject: item];
			}
		}
	}
	return CALL_ORIG(UIStatusBarLayoutManager, rectForItems$, items);
}


#pragma mark UIStatusBarTimeItemView modifications (for center text)

HOOKDEF(BOOL, UIStatusBarTimeItemView, updateForNewData$actions$, void* data, int actions)
{
//	SelLog();
	
	NSString* &_timeString(MSHookIvar<NSString*>(self, "_timeString"));
	NSString* oldString = [_timeString retain];
	
	// retrieve the current string index
	int idx;
	{
		uint64_t value;
		const char* notif = "libstatusbar_changed";
		static int token = 0;
		if(!token)
		{
			notify_register_check(notif, &token);
		}
		notify_get_state(token, &value);
		
		idx = value;
	//	NSLog(@"idx = %d", idx);
	}
	
	// Fetch the current string
	_timeString = [[[LSStatusBarClient sharedInstance] titleStringAtIndex: idx] retain];
	
	// I guess not.  Fetch the default string
	if(!_timeString)
	{
		CALL_ORIG(UIStatusBarTimeItemView, updateForNewData$actions$, data, actions);
	}
	
	// Did the string change?
	bool isSame = [oldString isEqualToString: _timeString];
	[oldString release];
	return !isSame;
}

/*
@interface UIStatusBar : NSObject
- (CGRect) currentFrame;
@end
*/




/*
- (CGRect)boundsRotatedWithStatusBar
{
    static BOOL isNotRotatedBySystem;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL OSIsBelowIOS8 = [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0;
        BOOL SDKIsBelowIOS8 = floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1;
        isNotRotatedBySystem = OSIsBelowIOS8 || SDKIsBelowIOS8;
    });

    BOOL needsToRotate = isNotRotatedBySystem && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if(needsToRotate)
    {
        CGRect screenBounds = [self bounds];
        CGRect bounds = screenBounds;
        bounds.size.width = screenBounds.size.height;
        bounds.size.height = screenBounds.size.width;
        return bounds;
    }
    else
    {
        return [self bounds];
    }
}


*/

HOOKDEF(UIImage*, UIStatusBarTimeItemView, contentsImage)
{
	NSLine();
	
	
	//	return;

	
	NSString* &_timeString(MSHookIvar<NSString*>(self, "_timeString"));

	NSMutableString* timeString = [_timeString mutableCopy];
	
	NSDesc([self textFont]);
	NSDesc(timeString);
	UIFont* font = [self textFont];
	if(!font || !timeString)
	{
		NSLine();
		return CALL_ORIG(UIStatusBarTimeItemView, contentsImage);
	}
	
	//CGSize size = [(UIStatusBar*)[[$UIApplication sharedApplication] statusBar] currentFrame].size;
	float maxlen;// = ((size.width > size.height) ? size.width : size.height)*0.6;//0.65;
	
	NSLine();
	{
		CGSize screenSz = [[$UIScreen mainScreen] bounds].size;
		if(cfvers < CF_80)
		{
			maxlen = screenSz.width * 0.6f;
		}
		else if (UIInterfaceOrientationIsPortrait([[$UIApplication sharedApplication] statusBarOrientation]))
		{
			maxlen = screenSz.width * 0.6f;
		}
		else
		{
			maxlen = screenSz.height * 0.6f;
		}
	}

	/*
	if(!maxlen)
	{
		maxlen = [[$UIScreen mainScreen] bounds].size.width * 0.6f;
	}
	*/
	
	NSLog(@"maxlen = %f", maxlen);
	
	
	NSLine();
	
	// ellipsize strings if they're too long
	if([timeString sizeWithFont: (UIFont*) [self textFont]].width > maxlen)
	{
		NSLine();

		[timeString replaceCharactersInRange: (NSRange){[timeString length]-1, 1} withString: @"…"];
		while([timeString length]>3 && [timeString sizeWithFont: (UIFont*) [self textFont]].width > maxlen)
		{
			[timeString replaceCharactersInRange: (NSRange){[timeString length]-2, 1} withString: @""];
		}
	}
	NSLine();

//	NSLog(@"Writing \"%@\" to statusbar %p", timeString, self);
	
	//svtrace(self);
	// string swap
	NSString* oldTimeString = _timeString;
	_timeString = [timeString retain]; // neccessary ?
	
	NSLine();

	UIImage* ret = CALL_ORIG(UIStatusBarTimeItemView, contentsImage);

	NSLine();
	
	// string swap
	_timeString = oldTimeString;
	[timeString release];

	NSLine();
	
	return ret;
}

HOOKDEF(UIImage*, UIStatusBarTimeItemView, contentsImageForStyle$, int style)
{
	//SelLog();
	
	NSString* &_timeString(MSHookIvar<NSString*>(self, "_timeString"));

	NSMutableString* timeString = [_timeString mutableCopy];
	
	CGSize size = [(UIStatusBar*)[[$UIApplication sharedApplication] statusBar] currentFrame].size;
	float maxlen = ((size.width > size.height) ? size.width : size.height)*0.6;//0.65;
	
	if(!maxlen)
	{
		maxlen = [[$UIScreen mainScreen] bounds].size.width * 0.6f;
	}
	
	// ellipsize strings if they're too long
	if([timeString sizeWithFont: (UIFont*) [self textFont]].width > maxlen)
	{
		[timeString replaceCharactersInRange: (NSRange){[timeString length]-1, 1} withString: @"…"];
		while([timeString length]>3 && [timeString sizeWithFont: (UIFont*) [self textFont]].width > maxlen)
		{
			[timeString replaceCharactersInRange: (NSRange){[timeString length]-2, 1} withString: @""];
		}
	}
//	NSLog(@"Writing \"%@\" to statusbar", timeString);
	
	// string swap
	NSString* oldTimeString = _timeString;
	_timeString = [timeString retain]; // neccessary ?
	
	UIImage* ret = CALL_ORIG(UIStatusBarTimeItemView, contentsImageForStyle$, style);
	
	// string swap
	_timeString = oldTimeString;
	[timeString release];
	
	return ret;
}


#pragma mark Client startup


//UIApplication* UIApp;

//_startWindowServerIfNecessary


HOOKDEF(void, UIApplication, _reportAppLaunchFinished)
{
	CALL_ORIG(UIApplication, _reportAppLaunchFinished);
	
	static BOOL hasAlreadyRan = NO;
	if(hasAlreadyRan)
	{
		CommonLog_F("Warning: UIApplication _startWindowServerIfNecessary called twice!");
		return;
	}
	else
	{
//		UIApp = [$UIApplication sharedApplication];
	}
	hasAlreadyRan = YES;
	
	// use this only for starting client
	// register as client - make sure SpringBoard is running
	// UIKit should still not exist.../yet/
	if($SpringBoard || SBSSpringBoardServerPort())
	{
//		[[LSStatusBarClient sharedInstance] performSelector: @selector(updateStatusBar) withObject: nil afterDelay: 0.001f];
	}
//	NSLine();
}


HOOKDEF(void, UIApplication, _startWindowServerIfNecessary)
{
//	SelLog();
	CALL_ORIG(UIApplication, _startWindowServerIfNecessary);
	
//	return;
	
	static BOOL hasAlreadyRan = NO;
	if(hasAlreadyRan)
	{
		CommonLog_F("Warning: UIApplication _startWindowServerIfNecessary called twice!");
		return;
	}
	else
	{
//		UIApp = [$UIApplication sharedApplication];
	}
	hasAlreadyRan = YES;
	
	// use this only for starting client
	// register as client - make sure SpringBoard is running
	// UIKit should still not exist.../yet/
	if($SpringBoard || SBSSpringBoardServerPort())
	{
		[[LSStatusBarClient sharedInstance] updateStatusBar];
		//[LSStatusBarClient sharedInstance];
	}
//	NSLine();
}





#pragma mark 3.x Compatibility Hooks

HOOKDEF(void, UIApplication, addStatusBarImageNamed$removeOnExit$, NSString* name, BOOL removeOnExit)
{
	[[LSStatusBarClient sharedInstance] setProperties: [NSNumber numberWithInt: 1] forItem: name];
}

HOOKDEF(void, UIApplication, addStatusBarImageNamed$, NSString* name)
{
	[[LSStatusBarClient sharedInstance] setProperties: [NSNumber numberWithInt: 1] forItem: name];
}

HOOKDEF(void, UIApplication, removeStatusBarImageNamed$, NSString* name)
{
	[[LSStatusBarClient sharedInstance] setProperties: nil forItem: name];
}





//@class UIStatusBarTimeItemView;


CFVers cfvers;

@class SBApplication;

HOOKDEF(void, SBApplication, exitedCommon)
{
	CALL_ORIG(SBApplication, exitedCommon);
	[[LSStatusBarServer sharedInstance] appDidExit: [self bundleIdentifier]];
}

CFVers QuantizeCFVers()
{
	CommonLog_F("CoreFoundation = %f", kCFCoreFoundationVersionNumber);
	
	if(kCFCoreFoundationVersionNumber == 478.47)
	{
		return CF_30;
	}
	else if(kCFCoreFoundationVersionNumber == 478.52)
	{
		return CF_31;
	}
	else if(kCFCoreFoundationVersionNumber == 478.61)
	{
		return CF_32;
	}
	else if(kCFCoreFoundationVersionNumber == 550.32)
	{
		return CF_40;
	}
	else if(kCFCoreFoundationVersionNumber == 550.38)
	{
		return CF_41;
	}
	else if(kCFCoreFoundationVersionNumber == 550.52)
	{
		return CF_42;
	}
	else if(kCFCoreFoundationVersionNumber == 550.58)
	{
		return CF_43;
	}
	else if(kCFCoreFoundationVersionNumber == 675.00) //661.00
	{
		return CF_50;
	}
	else if(kCFCoreFoundationVersionNumber == 690.10)
	{
		return CF_51;
	}
	else if(kCFCoreFoundationVersionNumber == 793.00)
	{
		return CF_60;
	}
	else if(kCFCoreFoundationVersionNumber == 847.20)// && kCFCoreFoundationVersionNumber < 848.0)
	{
		return CF_70;	
	}
	else if(kCFCoreFoundationVersionNumber == 847.21)
	{
		return CF_70;
	}
	else if(kCFCoreFoundationVersionNumber == 847.26)
	{
		return CF_71;
	}
	else if(kCFCoreFoundationVersionNumber == 847.27)
	{
		return CF_71;
	}
	else if(kCFCoreFoundationVersionNumber == 1140.10)
	{
		return CF_80;
	}
	else if(kCFCoreFoundationVersionNumber == 1141.14)
	{
		return CF_81;
	}
	else if(kCFCoreFoundationVersionNumber == 1141.16)
	{
		return CF_81;
	}
	else if(kCFCoreFoundationVersionNumber == 1142.16)
	{
		return CF_82;
	}
	else if(kCFCoreFoundationVersionNumber == 1144.17)
	{
		return CF_83;
	}
	else if(kCFCoreFoundationVersionNumber == 1145.15)
	{
		return CF_84;
	}
	else if(kCFCoreFoundationVersionNumber == 1240.10)
	{
		return CF_90;
	}
	
//	else if(kCFCoreFoundationVersionNumber == 847.23)
//	{
//		return CF_70;
//	}
	//else if(kCFCoreFoundationVersionNumber > 793.00)
	else
	{
		CommonLog_F("Could not match CoreFoundation = %f", kCFCoreFoundationVersionNumber);
	}
	
	return CF_NONE;
}




void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}


void mysighandler(int sig, siginfo_t *info, void *context) {
	void *backtraceFrames[128];
	int frameCount = backtrace(backtraceFrames, 128);

	NSLog(@"CRASH");
	//NSLog(@"%@",[NSThread callStackSymbols]);
	backtrace_symbols_fd(backtraceFrames, frameCount, 2);
	exit(1);
	// report the error
}





__attribute__((constructor)) void CrashWatcher()
{
	return;

    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    struct sigaction mySigAction;
    mySigAction.sa_sigaction = mysighandler;
    mySigAction.sa_flags = SA_SIGINFO;
    sigemptyset(&mySigAction.sa_mask);
    sigaction(SIGQUIT, &mySigAction, NULL);
    sigaction(SIGILL, &mySigAction, NULL);
    sigaction(SIGTRAP, &mySigAction, NULL);
    sigaction(SIGABRT, &mySigAction, NULL);
    sigaction(SIGEMT, &mySigAction, NULL);
    sigaction(SIGFPE, &mySigAction, NULL);
    sigaction(SIGBUS, &mySigAction, NULL);
    sigaction(SIGSEGV, &mySigAction, NULL);
    sigaction(SIGSYS, &mySigAction, NULL);
    sigaction(SIGPIPE, &mySigAction, NULL);
    sigaction(SIGALRM, &mySigAction, NULL);
    sigaction(SIGXCPU, &mySigAction, NULL);
    sigaction(SIGXFSZ, &mySigAction, NULL);
    
}

typedef struct {
	BOOL itemIsEnabled[25];
	BOOL timeString[64];
	int gsmSignalStrengthRaw;
	int gsmSignalStrengthBars;
	BOOL serviceString[100];
	BOOL serviceCrossfadeString[100];
	BOOL serviceImages[2][100];
	BOOL operatorDirectory[1024];
	unsigned serviceContentType;
	int wifiSignalStrengthRaw;
	int wifiSignalStrengthBars;
	unsigned dataNetworkType;
	int batteryCapacity;
	unsigned batteryState;
	BOOL batteryDetailString[150];
	int bluetoothBatteryCapacity;
	int thermalColor;
	unsigned thermalSunlightMode : 1;
	unsigned slowActivity : 1;
	unsigned syncActivity : 1;
	BOOL activityDisplayId[256];
	unsigned bluetoothConnected : 1;
	unsigned displayRawGSMSignal : 1;
	unsigned displayRawWifiSignal : 1;
	unsigned locationIconType : 1;
	unsigned quietModeInactive : 1;
	unsigned tetheringConnectionCount;
} StatusBarData;



__attribute__((constructor)) void start()
{
//	NSLine();
	
	cfvers = QuantizeCFVers();
	if(!cfvers)
		return;
	
	if(cfvers > CF_50 && cfvers < CF_70)
	{
		if(sandbox_check(getpid(), "mach-lookup", (sandbox_filter_type) (SANDBOX_FILTER_LOCAL_NAME | SANDBOX_CHECK_NO_REPORT), "com.apple.system.logger"))
		{
			return;
		}
		if(sandbox_check(getpid(), "mach-lookup", (sandbox_filter_type) (SANDBOX_FILTER_LOCAL_NAME | SANDBOX_CHECK_NO_REPORT), "com.apple.springboard.libstatusbar"))
		{
			CommonLog_F("******SANDBOX FORBADE MACH LOOKUP.  LIBSTATUSBAR MAY CRASH IN THIS PROCESS********\n");
			TRACE_F();
			return;
		}
		if(sandbox_check(getpid(), "mach-lookup", (sandbox_filter_type) (SANDBOX_FILTER_LOCAL_NAME | SANDBOX_CHECK_NO_REPORT), "com.apple.springboard.services"))
		{
			CommonLog_F("******SANDBOX FORBADE MACH LOOKUP.  LIBSTATUSBAR MAY CRASH IN THIS PROCESS********\n");
			TRACE_F();
			return;
		}
	}
	
	uint64_t load_time = 0;
	
	PROFILE(load_time)
	{
	
		// get classes
		Classes_Fetch();
		
		[[NSAutoreleasePool alloc] init];
		
		// we only hook UIKit apps - used as a guard band
		if($UIStatusBarItem)
		{
			ClassCreate_UIStatusBarCustomItemView();
			ClassCreate_UIStatusBarCustomItem();
			
			if(cfvers < CF_70)
			{
				HOOKCLASSMESSAGE(UIStatusBarItem, itemWithType:, itemWithType$);
			}
			else
			{
				HOOKCLASSMESSAGE(UIStatusBarItem, itemWithType:idiom:, itemWithType$idiom$);
			}
			
			if(cfvers < CF_60)
			{
				HOOKMESSAGE(UIStatusBarForegroundView, _computeVisibleItems:eitherSideItems:, _computeVisibleItems$eitherSideItems$);
			}
			else
			{
				HOOKMESSAGE(UIStatusBarForegroundView, _computeVisibleItemsPreservingHistory:, _computeVisibleItemsPreservingHistory$);	
			}
			{
				if([$UIStatusBarLayoutManager instancesRespondToSelector: @selector(_viewForItem:creatingIfNecessary:)])
					HOOKMESSAGE(UIStatusBarLayoutManager, _viewForItem:creatingIfNecessary:, _viewForItem$creatingIfNecessary$);
				if([$UIStatusBarLayoutManager instancesRespondToSelector: @selector(prepareEnabledItems:)])
					HOOKMESSAGE(UIStatusBarLayoutManager, prepareEnabledItems:, prepareEnabledItems$);
				
				if([$UIStatusBarLayoutManager instancesRespondToSelector: @selector(_viewForItem:)])
					HOOKMESSAGE(UIStatusBarLayoutManager, _viewForItem:, _viewForItem$);
				if([$UIStatusBarLayoutManager instancesRespondToSelector: @selector(prepareEnabledItems:withData:actions:)])
					HOOKMESSAGE(UIStatusBarLayoutManager, prepareEnabledItems:withData:actions:, prepareEnabledItems$withData$actions$);
				
				HOOKMESSAGE(UIStatusBarLayoutManager, _itemViews, _itemViews);
				/*
				if(cfvers >= CF_60)
				{
					HOOKMESSAGE(UIStatusBarLayoutManager, rectForItems:, rectForItems$);
				}
				*/
			
				HOOKMESSAGE(UIStatusBarTimeItemView, updateForNewData:actions:, updateForNewData$actions$);
				
				if(cfvers < CF_70)
				{
					HOOKMESSAGE(UIStatusBarTimeItemView, contentsImageForStyle:, contentsImageForStyle$);
				}
				else
				{
					HOOKMESSAGE(UIStatusBarTimeItemView, contentsImage, contentsImage);
				}
				
			
			}
			
			
			{
				HOOKMESSAGE(UIApplication, addStatusBarImageNamed:removeOnExit:, addStatusBarImageNamed$removeOnExit$);
				HOOKMESSAGE(UIApplication, addStatusBarImageNamed:, addStatusBarImageNamed$);
				HOOKMESSAGE(UIApplication, removeStatusBarImageNamed:, removeStatusBarImageNamed$);
				HOOKCLASSMESSAGE(UIApplication, _startWindowServerIfNecessary, _startWindowServerIfNecessary);
			//	HOOKCLASSMESSAGE(UIApplication, _reportAppLaunchFinished, _reportAppLaunchFinished);
				
				
			}
			
			if($SpringBoard)
			{
				[LSStatusBarServer sharedInstance];
				
				GETCLASS(SBApplication);
				HOOKMESSAGE(SBApplication, exitedCommon, exitedCommon);
			}
		//	CommonLog_F("*********** SpringBoard = %p", $SpringBoard);
			
			
			
		//	[[LSStatusBarClient sharedInstance] updateStatusBar];
			
		//	CommonLog_F("Done loading.");
		}
		else if(!$UIApplication)
		{
			CommonLog_F("Libstatusbar NOT loading on a UIKit process.");
		}
		else
		{
//			CommonLog_F("UIStatusBarItem is null??"); 
		}
	}
	CommonLog("Took %ld us to load libstatusbar\n", load_time);

}

