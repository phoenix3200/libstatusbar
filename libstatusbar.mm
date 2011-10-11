
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


@interface UIStatusBarItemView (extraSelector)
+ (UIStatusBarItemView*) createViewForItem: (UIStatusBarItem*) item withData: (void*) data actions: (int) actions foregroundStyle: (int) style;
@end

UIStatusBarItemView* InitializeView(UIStatusBarLayoutManager* self, id item)
{
	UIStatusBarItemView* _view = [item viewForManager: self];
	if(_view)
	{
		return _view;
	}
	
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
	SelLog();
	
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


HOOKDEF(UIView*, UIStatusBarLayoutManager, _viewForItem$creatingIfNecessary$, id item, bool ifNecc)
{
	if([item isKindOfClass: $UIStatusBarCustomItem])
	{
		//NSLine();
		
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
		//NSLine();
		
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

HOOKDEF(BOOL, UIStatusBarLayoutManager, prepareEnabledItems$, BOOL* items)
{
	SelLog();
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
	SelLog();
	BOOL ret = CALL_ORIG(UIStatusBarLayoutManager, prepareEnabledItems$withData$actions$, items, data, actions);
	
	// the default function didn't refresh...let's refresh anyways
	if(ret==NO)
	{
		PrepareEnabledItemsCommon(self);
	}
	return YES;
	
}



#pragma mark UIStatusBarTimeItemView modifications (for center text)

HOOKDEF(BOOL, UIStatusBarTimeItemView, updateForNewData$actions$, void* data, int actions)
{
	SelLog();
	
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

HOOKDEF(UIImage*, UIStatusBarTimeItemView, contentsImageForStyle$, int style)
{
	SelLog();
	
	NSString* &_timeString(MSHookIvar<NSString*>(self, "_timeString"));

	NSMutableString* timeString = [_timeString mutableCopy];
	
	CGSize size = [(UIStatusBar*)[UIApp statusBar] currentFrame].size;
	float maxlen = (size.width > size.height ? size.width : size.height)*0.6;//0.65;
	
	// ellipsize strings if they're too long
	if([timeString sizeWithFont: (UIFont*) [self textFont]].width > maxlen)
	{
		[timeString replaceCharactersInRange: (NSRange){[timeString length]-1, 1} withString: @"…"];
		while([timeString length]>3 && [timeString sizeWithFont: (UIFont*) [self textFont]].width > maxlen)
		{
			[timeString replaceCharactersInRange: (NSRange){[timeString length]-2, 1} withString: @""];
		}
	}
	
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

HOOKDEF(void, UIApplication, _startWindowServerIfNecessary)
{
	SelLog();
	CALL_ORIG(UIApplication, _startWindowServerIfNecessary);
	
	static BOOL hasAlreadyRan = NO;
	if(hasAlreadyRan)
	{
		NSLog(@"Warning: _startWindowServerIfNecessary called twice!");
		return;
	}
	hasAlreadyRan = YES;
	
	// use this only for starting client
	// register as client - make sure SpringBoard is running
	// UIKit should still not exist.../yet/
	if($SpringBoard || SBSSpringBoardServerPort())
	{
		[LSStatusBarClient sharedInstance];
	}
	NSLine();
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



@class SBApplication;

HOOKDEF(void, SBApplication, exitedCommon)
{
	CALL_ORIG(SBApplication, exitedCommon);
	[[LSStatusBarServer sharedInstance] appDidExit: [self bundleIdentifier]];
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
		}
		
		{
			HOOKMESSAGE(UIStatusBarForegroundView, _computeVisibleItems:eitherSideItems:, _computeVisibleItems$eitherSideItems$);
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
		
			HOOKMESSAGE(UIStatusBarTimeItemView, updateForNewData:actions:, updateForNewData$actions$);
			HOOKMESSAGE(UIStatusBarTimeItemView, contentsImageForStyle:, contentsImageForStyle$);
		
		}
		
		
		{
			HOOKMESSAGE(UIApplication, addStatusBarImageNamed:removeOnExit:, addStatusBarImageNamed$removeOnExit$);
			HOOKMESSAGE(UIApplication, addStatusBarImageNamed:, addStatusBarImageNamed$);
			HOOKMESSAGE(UIApplication, removeStatusBarImageNamed:, removeStatusBarImageNamed$);
			HOOKCLASSMESSAGE(UIApplication, _startWindowServerIfNecessary, _startWindowServerIfNecessary);
		}
		
		if($SpringBoard)
		{
			[LSStatusBarServer sharedInstance];
			
			GETCLASS(SBApplication);
			HOOKMESSAGE(SBApplication, exitedCommon, exitedCommon);
		}
	}
}

