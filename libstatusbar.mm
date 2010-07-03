
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "UIStatusBarCustomItem.h"
#import "UIStatusBarCustomItemView.h"
#import "StatusBarItemServer.h"
#import "StatusBarItemClient.h"



HOOKDEF(NSArray*, UIStatusBarLayoutManager, _itemViewsSortedForLayout)
{
//	HookLog();
	id ret = CALL_ORIG(UIStatusBarLayoutManager, _itemViewsSortedForLayout);
//	NSType(ret);
//	NSDesc(ret);
	return ret;
}

NSMutableArray* customItems[3];	 // left, right, center

UIStatusBarItemView* InitializeView(UIStatusBarLayoutManager* self, id item)
{
	//UIStatusBarItemView* &_view(MSHookIvar<UIStatusBarItemView*>(item, "_view"));
	
	UIStatusBarItemView* _view = [item viewForManager: self];
	if(_view)
	{
		return _view;
	}
	
	GETCLASS(UIStatusBarItemView);
	
	GETVAR(UIStatusBarForegroundView*, _foregroundView);
	int foregroundStyle = [_foregroundView foregroundStyle];
	
	NSLog(@"foregroundStyle = %d", foregroundStyle);
	
	_view = [$UIStatusBarItemView createViewForItem: item foregroundStyle: foregroundStyle];
	[_view setLayoutManager: self];

	GETVAR(int, _region);
	switch(_region)
	{
	case 0:
	{
		[_view setContentMode: UIViewContentModeLeft]; // 7
		[_view setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin]; // 0x24
		break;
	}
	case 1:
	{
		[_view setContentMode: UIViewContentModeRight]; // 8
		[_view setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin]; // 0x21
		break;
	}
	case 2:
	{
		[_view setContentMode: UIViewContentModeLeft]; // 7
		[_view setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin]; // 0x25
		break;
	}
	}
	
	[item setView: _view forManager: self];
	return _view;
}


HOOKDEF(NSMutableArray*, UIStatusBarLayoutManager, _itemViews)
{
//	HookLog();
	NSMutableArray* _itemViews = CALL_ORIG(UIStatusBarLayoutManager, _itemViews);
	//
	// add our array here
	if(_itemViews)// && FALSE)
	{
		GETVAR(int, _region);
		if(_region < 3 && customItems[_region])
		{
			for(UIStatusBarCustomItem* item in customItems[_region])
			{
				//UIStatusBarItemView* &_view(MSHookIvar<UIStatusBarItemView*>(item, "_view"));
				
				UIStatusBarItemView* _view = InitializeView(self, item);
				
				if(_view)
					[_itemViews addObject: _view];
			}
		}
			/*
			GETVAR(UIStatusBarForegroundView*, _foregroundView);
			
			UIStatusBarItemView* view = [$UIStatusBarItemView, createViewForItem: () item foregroundStype
			
			[[$UIStatusBarCustomItemView alloc] initWithItem: nil style: [_foregroundView foregroundStyle]];
			[view setContentMode: (UIViewContentMode) 7];
			[view setAutoresizingMask: 0x24];
			[view setLayoutManager: self];
			
			[ret addObject: [view autorelease]];
			NSDesc(ret);
			*/
	}
	GETVAR(int, _region);
//	if(_region==1)
//	{
//		NSDesc(_itemViews);
//	}
	
	
	return _itemViews;
}


HOOKDEF(UIView*, UIStatusBarLayoutManager, _viewForItem$creatingIfNecessary$, id item, bool ifNecc)
{
//	HookLog();
//	NSType(item);
	if([item isKindOfClass: $UIStatusBarCustomItem])
	{
	//	NSLine();
		UIStatusBarItemView* _view = InitializeView(self, item);
				
		return _view;
	}
	else
	{
		id ret = CALL_ORIG(UIStatusBarLayoutManager, _viewForItem$creatingIfNecessary$, item, ifNecc);
//		NSType(ret);
		return ret;
	}
}



//@class UIStatusBarItem;

// called by
//  (void) [UIStatusBarLayoutManager* prepareEnabledItems: (BOOL[20]) itemIsEnabled];
//  (void) [UIStatusBarForegroundView* _reflowItemViewsWithDuration: (double) dur suppressCenterAnimation: (BOOL) suppress];
HOOKDEF(id, UIStatusBarItem, itemWithType$, int type)
{
//	HookLog();
	id ret = CALL_ORIG(UIStatusBarItem, itemWithType$, type);
	if(ret==nil)
	{
		NSLog(@"type = %d", type);
		ret = [[$UIStatusBarCustomItem alloc] initWithType: type];
		if([ret leftOrder])
		{
			if(!customItems[0])
			{
				customItems[0] = [[NSMutableArray alloc] init];
			}
			[customItems[0] addObject: ret];
		}
		else if([ret rightOrder])
		{
			if(!customItems[1])
			{
				customItems[1] = [[NSMutableArray alloc] init];
			}
			[customItems[1] addObject: ret];
		}
		else
		{
			if(!customItems[2])
			{
				customItems[2] = [[NSMutableArray alloc] init];
			}
			[customItems[2] addObject: ret];
		}
		NSType(ret);
		
		// now let's get to work
	}
	return ret;
}

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



// May return NO if a callback function (designated separately) exists + refuses to show
// called by
//  (void) [UIStatusBarForegroundView setStatusBarData: (StatusBarData*) data actions: (int) actions animated: (BOOL) animated];
HOOKDEF(BOOL, UIStatusBarItem, itemType$canBeEnabledForData$, int type, StatusBarData* data)
{
//	HookLog();
//	NSLog(@"type = %d", type);
	BOOL ret = CALL_ORIG(UIStatusBarItem, itemType$canBeEnabledForData$, type, data);
	return ret;
}

/*
// sees if the value is <20 - doesn't do an absolute value compare afaik
// used only with itemWithType:
HOOKDEF(BOOL, UIStatusBarItem, typeIsValid$, int type)
{
	HookLog();
	NSLog(@"type = %d", type);
	BOOL ret = CALL_ORIG(UIStatusBarItem, typeIsValid$, type);
	return ret;	
}
*/

/*
HOOKDEF(int, UIStatusBarItem, type)
{
	HookLog();
	int type = CALL_ORIG(UIStatusBarItem, type);
	if(type <19)
		return type;
	else
		return 0;
}

HOOKDEF(int, UIStatusBarItem, priority)
{
	HookLog();
	int type = CALL_ORIG(UIStatusBarItem, type);
	if(type <19)
		return CALL_ORIG(UIStatusBarItem, priority);
	else
		return 0;
}

HOOKDEF(NSString*, UIStatusBarItem, description);
*/


HOOKDEF(void, UIStatusBarForegroundView, _computeVisibleItems$eitherSideItems$, NSMutableArray** visibleItems,  NSMutableArray* eitherSideItems) // 3 visible items
{
	NSLine();
	// add our objects to the appropriate arrays
	for(int i=0; i<3; i++)
	{
		for(UIStatusBarCustomItem* item in customItems[i])
		{
//			UIStatusBarItemView* view = [item view];
//			if(view)
			[visibleItems[i] addObject: item];
				//InitializeView(visibleItems[i], item);
		}
	}
	
	
	CALL_ORIG(UIStatusBarForegroundView, _computeVisibleItems$eitherSideItems$, visibleItems,  eitherSideItems);
}










HOOKDEF(void, UIApplication, addStatusBarImageNamed$removeOnExit$, NSString* name, BOOL removeOnExit)
{
	HookLog();
	[[StatusBarItemClient sharedInstance] setProperties: [NSNumber numberWithInt: 1] forItem: name];
}

HOOKDEF(void, UIApplication, addStatusBarImageNamed$, NSString* name)
{
	HookLog();
	[[StatusBarItemClient sharedInstance] setProperties: [NSNumber numberWithInt: 1] forItem: name];
}

HOOKDEF(void, UIApplication, removeStatusBarImageNamed$, NSString* name)
{
	HookLog();
	[[StatusBarItemClient sharedInstance] setProperties: nil forItem: name];
}

void addSBItem()
{
	[UIApp addStatusBarImageNamed: @"Pause"];
}

void removeSBItem()
{
	[UIApp removeStatusBarImageNamed: @"Pause"];
}

HOOKDEF(BOOL, UIStatusBarLayoutManager, prepareEnabledItems$, BOOL* items)
{
	SelLog();
	BOOL ret = CALL_ORIG(UIStatusBarLayoutManager, prepareEnabledItems$, items);
	if(ret==NO)
	{
		
		GETVAR(UIStatusBarForegroundView*, _foregroundView);
		
		float startPosition = [self _startPosition];
		for(UIStatusBarItemView* view in [self _itemViewsSortedForLayout])
		{
			if([view superview] == nil)
			{
				[view setVisible: NO];
				[view setFrame: (CGRect) {{0.0f, 0.0f}, [self _frameForItemView: view startPosition: startPosition].size}];
				[_foregroundView addSubview: view];
			}
			int type = [[view item] type];
			if(type)
			{
				startPosition = [self _positionAfterPlacingItemView: view startPosition: startPosition];
			}
		}
	}
	return YES;
}

__attribute__((constructor)) void start()
{
	NSLine();
	
	[[NSAutoreleasePool alloc] init];
	
	// get classes
	Classes_Fetch();
	
//	GETCLASS(UIStatusBarItem);
	if($UIStatusBarItem)
	{
		ClassCreate_UIStatusBarCustomItemView();
		ClassCreate_UIStatusBarCustomItem();
		{
//			$$UIStatusBarItem = object_getClass($UIStatusBarItem);
//			HOOKMESSAGE($UIStatusBarItem, itemWithType:, itemWithType$);
//			HOOKMESSAGE($UIStatusBarItem, itemType:canBeEnabledForData:, itemType$canBeEnabledForData$);
			HOOKCLASSMESSAGE(UIStatusBarItem, itemWithType:, itemWithType$);
			HOOKCLASSMESSAGE(UIStatusBarItem, itemType:canBeEnabledForData:, itemType$canBeEnabledForData$);
		}
		
		{
//			GETCLASS(UIStatusBarForegroundView);
			HOOKMESSAGE(UIStatusBarForegroundView, _computeVisibleItems:eitherSideItems:, _computeVisibleItems$eitherSideItems$);
		}
		{
//			GETCLASS(UIStatusBarLayoutManager);
			HOOKMESSAGE(UIStatusBarLayoutManager, _viewForItem:creatingIfNecessary:, _viewForItem$creatingIfNecessary$);
			HOOKMESSAGE(UIStatusBarLayoutManager, _itemViewsSortedForLayout, _itemViewsSortedForLayout);
			HOOKMESSAGE(UIStatusBarLayoutManager, _itemViews, _itemViews);
			
			HOOKMESSAGE(UIStatusBarLayoutManager, prepareEnabledItems:, prepareEnabledItems$);
			
		}
		
		{
//			GETCLASS(UIApplication);
			HOOKMESSAGE(UIApplication, addStatusBarImageNamed:removeOnExit:, addStatusBarImageNamed$removeOnExit$);
			HOOKMESSAGE(UIApplication, addStatusBarImageNamed:, addStatusBarImageNamed$);
			HOOKMESSAGE(UIApplication, removeStatusBarImageNamed:, removeStatusBarImageNamed$);
		}
		
//		GETCLASS(SpringBoard);
		if($SpringBoard)
		{
			//StatusBarItemServer* server = 
			[StatusBarItemServer sharedInstance];
			//[server setProperties: [NSNumber numberWithInt: 1] forItem: @"Pause"];
		}
		// register as client
		[StatusBarItemClient sharedInstance];
		
		CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+4.0f, 0.0f, 0, 0, (CFRunLoopTimerCallBack) addSBItem, NULL);
		CFRunLoopTimerRef waitTimer2 = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+20.0f, 0.0f, 0, 0, (CFRunLoopTimerCallBack) removeSBItem, NULL);
		
		CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
		CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer2, kCFRunLoopCommonModes);
		
		
		NSLine();
	}
}

