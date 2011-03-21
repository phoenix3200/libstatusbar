
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "LSStatusBarServer.h"

#import "LSStatusBarItem.h"


void updateLockStatus(CFNotificationCenterRef center, LSStatusBarServer* server)
{
	NSLine();
	[server updateLockStatus];
}

void incrementTimer()//CFRunLoopTimerRef timer, LSStatusBarServer* self)
{
	[[LSStatusBarServer sharedInstance] incrementTimer];
}


@implementation LSStatusBarServer


+ (id) sharedInstance
{
	static LSStatusBarServer* server;
	
	if(!server)
	{
		server = [[self alloc] init];
	}
	return server;
}


- (id) init
{
	self = [super init];
	if(self)
	{
		_dmc = [CPDistributedMessagingCenter centerNamed: @"com.apple.springboard.libstatusbar"];
		[_dmc runServerOnCurrentThread];
		[_dmc registerForMessageName: @"currentMessage" target: self selector: @selector(currentMessage)];
		[_dmc registerForMessageName: @"setProperties:userInfo:" target: self selector: @selector(setProperties:userInfo:)];
		
		_currentMessage = [[NSMutableDictionary alloc] init];
		_currentKeys = [[NSMutableArray alloc] init];
		_currentKeyUsage = [[NSMutableDictionary alloc] init];
		
		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, self, (CFNotificationCallback) updateLockStatus, (CFStringRef) @"com.apple.springboard.lockstate", self, NULL);
		
	}
	return self;
}




- (NSMutableDictionary*) currentMessage
{
	return _currentMessage;
}


- (void) processMessageCommon
{
	NSMutableArray* titleStrings = [NSMutableArray array];
	for(NSString* key in _currentKeys)
	{
		NSDictionary* dict = [_currentMessage objectForKey: key];
		
		if(!dict || ![dict isKindOfClass: [NSDictionary class]])
			continue;
		
		NSNumber* alignment = [dict objectForKey: @"alignment"];
		if(alignment && ((StatusBarAlignment) [alignment intValue]) == StatusBarAlignmentCenter)
		{
			NSLine();
			NSNumber* visible = [dict objectForKey: @"visible"];
			if(!visible || [visible boolValue])
			{
				NSLine();
				if(NSString* titleString = [dict objectForKey: @"titleString"])
				{
					NSLine();
					[titleStrings addObject: titleString];
				}
			}
		}
	}
	
	[_currentMessage setValue: _currentKeys forKey: @"keys"];
	NSDesc(_currentKeys);
	
	
	
	if([titleStrings count])
	{
		[_currentMessage setValue: titleStrings forKey: @"titleStrings"];
		
		[self startTimer];
	}
	else
	{
		[_currentMessage setValue: nil forKey: @"titleStrings"];
		
		//if(!timer)
		//	notify_post("libstatusbar_changed");
		[self stopTimer];
	}
	NSDesc(_currentMessage);
	
	notify_post("libstatusbar_changed");
}

- (void) setProperties: (id) properties forItem: (NSString*) item bundle: (NSString*) bundle
{
	SelLog();
	if(!item || !bundle)
	{
		NSLog(@"missing info. returning...");
		return;
	}
	
	// get the current item usage by bundles
	NSMutableArray* bundles = [_currentKeyUsage objectForKey: item];
	if(!bundles)
	{
		bundles = [NSMutableArray array];
		[_currentKeyUsage setObject: bundles forKey: item];
	}
	
	int itemIdx = [_currentKeys indexOfObject: item];
	
	if(properties)
	{
		[_currentMessage setValue: properties forKey: item];
		
		if(![bundles containsObject: bundle])
		{
			[bundles addObject: bundle];
		}
		
		if(itemIdx == NSNotFound)
		{
			[_currentKeys addObject: item];
		}
	}
	else
	{
		[bundles removeObject: bundle];
		NSLog(@"removing object");
		
		if([bundles count]==0)
		{
			// object is truly dead
			[_currentMessage setValue: nil forKey: item];
		
			if(itemIdx!=NSNotFound)
				[_currentKeys removeObjectAtIndex: itemIdx];
		}
	}
	
	/*
	int itemIdx = [_currentKeys indexOfObject: item];
	if(!properties && itemIdx != NSNotFound)
	{
		[_currentKeys removeObjectAtIndex: itemIdx];
	}
	else if(properties && itemIdx == NSNotFound)
	{
		[_currentKeys addObject: item];
	}
	*/
	
	
	// find all title strings
	
	[self processMessageCommon];
}


- (void) appDidExit: (NSString*) bundle
{
	
	
	int nKeys = [_currentKeys count];
	for(int i=nKeys - 1; i>=0; i--)
	{
		NSString* item = [_currentKeys objectAtIndex: i];
		
		NSMutableArray* bundles = [_currentKeyUsage objectForKey: item];
		if(!bundles)
		{
			continue;
		}

		if([bundles containsObject: bundle])
		{
			[bundles removeObject: bundle];
			NSLog(@"removing object");

			if([bundles count]==0)
			{
				// object is truly dead
				[_currentMessage setValue: nil forKey: item];

				int itemIdx = [_currentKeys indexOfObject: item];
				if(itemIdx!=NSNotFound)
					[_currentKeys removeObjectAtIndex: itemIdx];
			}
		}
	}
	
	[self processMessageCommon];
}




- (void) setProperties: (NSString*) message userInfo: (NSDictionary*) userInfo
{
	NSString* item = [userInfo objectForKey: @"item"];
	NSDictionary* properties = [userInfo objectForKey: @"properties"];
	NSString* bundleId = [userInfo objectForKey: @"bundle"];
	
	[self setProperties: properties forItem: item bundle: bundleId];
}

- (void) startTimer
{
	NSLine();
	
	// is timer already running?
	if(timer)
	{
		NSLog(@"timer is already active.  Leaving it alone");
		return;
	}
	
	// check lock status
	uint64_t locked;
	{
		int token = 0;
		notify_register_check("com.apple.springboard.lockstate", &token);
		notify_get_state(token, &locked);
	}
	
	NSLine();
	
	// reset timer state
	[self stopTimer];
	NSLine();
	
	if(!locked)
	{
		NSLine();
		
		NSArray* titleStrings = [_currentMessage objectForKey: @"titleStrings"];
		if(titleStrings && [titleStrings count])
		{
			NSLine();
		
			timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+3.5f, 3.5f, 0, 0, (CFRunLoopTimerCallBack) incrementTimer, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), timer, kCFRunLoopCommonModes);
		}
	}
	NSLine();
	
}

- (void) stopTimer
{
	NSLine();
	
	// reset the statusbar state
	{
		const char* notif = "libstatusbar_changed";
		
		uint64_t value = NSNotFound;
		int token = 0;
		notify_register_check(notif, &token);
		
		notify_set_state(token, value);
		
		if(timer) // only post a notification if the timer was running
			notify_post(notif);
	}
	
	// kill timer
	if(timer)
	{
		CFRunLoopTimerInvalidate(timer);
		CFRelease(timer);
		timer = nil;
	}
	NSLine();
}


- (void) incrementTimer
{
	NSLine();
	
	NSArray* titleStrings = [_currentMessage objectForKey: @"titleStrings"];
	
	const char* notif = "libstatusbar_changed";
	
	if(titleStrings && [titleStrings count])
	{
		uint64_t value;
		int token = 0;
		notify_register_check(notif, &token);
		notify_get_state(token, &value);
		
		value++;
		if(value > [titleStrings count])
		{
			value = 0;
		}
		
		NSLog(@"idx = %ld", value);
		
		notify_set_state(token, value);
		notify_post(notif);
	}
	else
	{
		[self stopTimer];
		/*
		NSLog(@"idx = %ld", value);
		
		CFRunLoopTimerInvalidate(timer);
		CFRelease(timer);
		timer = nil;
		
		notify_post(notif);
		*/
	}	
}


- (void) updateLockStatus
{
	[self stopTimer];
	[self startTimer];
}



@end