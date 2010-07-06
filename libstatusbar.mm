
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "UIStatusBarCustomItem.h"
#import "UIStatusBarCustomItemView.h"
#import "StatusBarItemServer.h"
#import "StatusBarItemClient.h"


NSMutableArray* customItems[3];	 // left, right, center


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

// May return NO if a callback function (designated separately) exists + refuses to show
// called by
//  (void) [UIStatusBarForegroundView setStatusBarData: (StatusBarData*) data actions: (int) actions animated: (BOOL) animated];
/*
HOOKDEF(BOOL, UIStatusBarItem, itemType$canBeEnabledForData$, int type, StatusBarData* data)
{
//	HookLog();
	BOOL ret = CALL_ORIG(UIStatusBarItem, itemType$canBeEnabledForData$, type, data);
	return ret;
}
*/

UIStatusBarItemView* InitializeView(UIStatusBarLayoutManager* self, id item)
{
	
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
//	HookLog();
	
	// add our objects to the appropriate arrays
	for(int i=0; i<3; i++)
	{
		for(UIStatusBarCustomItem* item in customItems[i])
		{
			[visibleItems[i] addObject: item];
		}
	}
	
	CALL_ORIG(UIStatusBarForegroundView, _computeVisibleItems$eitherSideItems$, visibleItems,  eitherSideItems);
}


HOOKDEF(UIView*, UIStatusBarLayoutManager, _viewForItem$creatingIfNecessary$, id item, bool ifNecc)
{
//	HookLog();
	
	if([item isKindOfClass: $UIStatusBarCustomItem])
	{
		UIStatusBarItemView* _view = InitializeView(self, item);
		return _view;
	}
	else
	{
		id ret = CALL_ORIG(UIStatusBarLayoutManager, _viewForItem$creatingIfNecessary$, item, ifNecc);
		return ret;
	}
}


HOOKDEF(NSMutableArray*, UIStatusBarLayoutManager, _itemViews)
{
//	HookLog();
	
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
					[_itemViews addObject: _view];
			}
		}
	}
	
	return _itemViews;
}



HOOKDEF(BOOL, UIStatusBarLayoutManager, prepareEnabledItems$, BOOL* items)
{
	SelLog();
	BOOL ret = CALL_ORIG(UIStatusBarLayoutManager, prepareEnabledItems$, items);
	
	// the default function didn't refresh...let's refresh anyways
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



HOOKDEF(void, UIApplication, addStatusBarImageNamed$removeOnExit$, NSString* name, BOOL removeOnExit)
{
//	HookLog();
	[[StatusBarItemClient sharedInstance] setProperties: [NSNumber numberWithInt: 1] forItem: name];
}

HOOKDEF(void, UIApplication, addStatusBarImageNamed$, NSString* name)
{
//	HookLog();
	[[StatusBarItemClient sharedInstance] setProperties: [NSNumber numberWithInt: 1] forItem: name];
}

HOOKDEF(void, UIApplication, removeStatusBarImageNamed$, NSString* name)
{
//	HookLog();
	[[StatusBarItemClient sharedInstance] setProperties: nil forItem: name];
}


// used for testing only
/*
void addPause()
{
	[UIApp addStatusBarImageNamed: @"Pause"];
}

void removePause()
{
	[UIApp removeStatusBarImageNamed: @"Pause"];
}

void addBT()
{
	[UIApp addStatusBarImageNamed: @"Bluetooth"];
}

void removeBT()
{
	[UIApp removeStatusBarImageNamed: @"Bluetooth"];
}
*/

HOOKDEF(void, UIApplication, _startWindowServerIfNecessary)
{
	HookLog();
	CALL_ORIG(UIApplication, _startWindowServerIfNecessary);
	
	// use this only for starting client
	// register as client - make sure SpringBoard is running
	// UIKit should still not exist.../yet/
	if($SpringBoard || SBSSpringBoardServerPort())
	{
		[StatusBarItemClient sharedInstance];
	}
	NSLine();
	
	// testing stuff...
	/*
	{
		float delay = 4.0f;
		CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) addBT;
		
		CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
		CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
	}
	{
		float delay = 8.0f;
		CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) addPause;
		
		
		CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
		CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
	}
	
	{
		float delay = 12.0f;
		CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) removeBT;
		
		
		CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
		CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
	}
	{
		float delay = 16.0f;
		CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) addBT;
		
		
		CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
		CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
	}
	*/
}


__attribute__((constructor)) void start()
{
	NSLine();
	
	// get classes
	Classes_Fetch();
	
	[[NSAutoreleasePool alloc] init];
	
	// we only hook UIKit apps - used as a guard band
	if($UIStatusBarItem)
	{
		ClassCreate_UIStatusBarCustomItemView();
		ClassCreate_UIStatusBarCustomItem();
		{
			HOOKCLASSMESSAGE(UIStatusBarItem, itemWithType:, itemWithType$);
//			HOOKCLASSMESSAGE(UIStatusBarItem, itemType:canBeEnabledForData:, itemType$canBeEnabledForData$);
		}
		
		{
			HOOKMESSAGE(UIStatusBarForegroundView, _computeVisibleItems:eitherSideItems:, _computeVisibleItems$eitherSideItems$);
		}
		{
			HOOKMESSAGE(UIStatusBarLayoutManager, _viewForItem:creatingIfNecessary:, _viewForItem$creatingIfNecessary$);
			HOOKMESSAGE(UIStatusBarLayoutManager, _itemViews, _itemViews);
			HOOKMESSAGE(UIStatusBarLayoutManager, prepareEnabledItems:, prepareEnabledItems$);
		}
		
		{
			HOOKMESSAGE(UIApplication, addStatusBarImageNamed:removeOnExit:, addStatusBarImageNamed$removeOnExit$);
			HOOKMESSAGE(UIApplication, addStatusBarImageNamed:, addStatusBarImageNamed$);
			HOOKMESSAGE(UIApplication, removeStatusBarImageNamed:, removeStatusBarImageNamed$);
			HOOKMESSAGE(UIApplication, _startWindowServerIfNecessary, _startWindowServerIfNecessary);
		}
		
		if($SpringBoard)
		{
			[StatusBarItemServer sharedInstance];
		}
		
		NSLine();
		
	}
}

