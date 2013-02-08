
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "LSStatusBarServer.h"

#import "LSStatusBarItem.h"


void updateLockStatus(CFNotificationCenterRef center, LSStatusBarServer* server)
{
//	NSLine();
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

- (void) postChanged
{
	SelLog();
//	NSLine();
	notify_post("libstatusbar_changed");
}

- (void) enqueuePostChanged
{
	SelLog();
//	NSLine();
	NSRunLoop* loop = [NSRunLoop mainRunLoop];
	
	[loop cancelPerformSelector: @selector(postChanged) target: self argument: nil];
	[loop performSelector: @selector(postChanged) target: self argument: nil order: 0 modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	
	//[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(postChanged) object: nil];
	//[self performSelector: @selector(postChanged) withObject: nil afterDelay: 0.0001f];	
}

- (void) processMessageCommonWithFocus: (NSString*) item
{
	NSLog(@"processing %@", item);
	
	timeHidden = NO;
	
	NSMutableArray* titleStrings = [NSMutableArray array];
	for(NSString* key in _currentKeys)
	{
		NSDictionary* dict = [_currentMessage objectForKey: key];
		
		if(!dict || ![dict isKindOfClass: [NSDictionary class]])
			continue;
		
		NSNumber* alignment = [dict objectForKey: @"alignment"];
		if(alignment && ((StatusBarAlignment) [alignment intValue]) == StatusBarAlignmentCenter)
		{
			NSNumber* visible = [dict objectForKey: @"visible"];
			if(!visible || [visible boolValue])
			{
				NSString* titleString = [dict objectForKey: @"titleString"];
				if(titleString && [titleString length])
				{
					if(item && [item isEqualToString: key])
					{
						[self setState: [titleStrings count]];
						[self resyncTimer];
					}
					[titleStrings addObject: titleString];
					
					if([[dict objectForKey: @"hidesTime"] boolValue])
					{
						timeHidden = YES;
					}
				}
			}
		}
	}
	
	[_currentMessage setValue: _currentKeys forKey: @"keys"];
//	NSDesc(_currentKeys);
	
	
	
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
//	NSDesc(_currentMessage);
	
	[self enqueuePostChanged];
	//[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(postChanged) object: nil];
	//[self performSelector: @selector(postChanged) withObject: nil afterDelay: 0.0f];
}




static void NoteExitKQueueCallback(
    CFFileDescriptorRef f, 
    CFOptionFlags       callBackTypes, 
    NSNumber *              pidinfo
)
{
//    struct kevent   event;
//    (void) kevent( CFFileDescriptorGetNativeDescriptor(f), NULL, 0, &event, 1, NULL);
//    NSLog(@"terminated %d", (int) (pid_t) event.ident);

    [[LSStatusBarServer sharedInstance] pidDidExit: [pidinfo autorelease]];
}


void MonitorPID(NSNumber* pid)
{
    FILE *                  f;
    int                     kq;
    struct kevent           changes;
    CFFileDescriptorContext context = { 0, [pid retain], NULL, NULL, NULL };
    CFRunLoopSourceRef      rls;


    kq = kqueue();

    EV_SET(&changes, [pid intValue], EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT, 0, NULL);
    (void) kevent(kq, &changes, 1, &changes, 1, NULL);

    CFFileDescriptorRef noteExitKQueueRef = CFFileDescriptorCreate(NULL, kq, true, (CFFileDescriptorCallBack) NoteExitKQueueCallback, &context);
    rls = CFFileDescriptorCreateRunLoopSource(NULL, noteExitKQueueRef, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease(rls);

    CFFileDescriptorEnableCallBacks(noteExitKQueueRef, kCFFileDescriptorReadCallBack);

}


- (void) registerPid: (NSNumber*) thepid
{
	int pid = [thepid intValue];
	if(!pid)
		return;
	
	if(!clientPids)
	{
		clientPids = [[NSMutableArray alloc] init];
	}
	if(![clientPids containsObject: thepid])
	{
		[clientPids addObject: thepid];
		
		MonitorPID(thepid);
			
	}
}

- (void) setProperties: (id) properties forItem: (NSString*) item bundle: (NSString*) bundle pid: (NSNumber*) pid
{
//	SelLog();
	if(!item || !pid)
	{
		NSLog(@"missing info. returning... %@ %@", [item description], [pid description]);
		return;
	}
	
	[self registerPid: pid];
	
	// get the current item usage by bundles
	
	
	NSMutableArray* pids = [_currentKeyUsage objectForKey: item];
	if(!pids)
	{
		pids = [NSMutableArray array];
		[_currentKeyUsage setObject: pids forKey: item];
	}
	
	int itemIdx = [_currentKeys indexOfObject: item];
	
	
	if(properties)
	{
		[_currentMessage setValue: properties forKey: item];
		
		if(![pids containsObject: pid])
		{
			[pids addObject: pid];
		}
		
		if(itemIdx == NSNotFound)
		{
			[_currentKeys addObject: item];
		}
	}
	else
	{
		[pids removeObject: pid];
		NSLog(@"removing object");
		
		if([pids count]==0)
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
	
	[self processMessageCommonWithFocus: item];
}

- (void) pidDidExit: (NSNumber*) pid
{
	NSLine();
	
	int nKeys = [_currentKeys count];
	for(int i=nKeys - 1; i>=0; i--)
	{
		NSString* item = [_currentKeys objectAtIndex: i];
		
		NSMutableArray* pids = [_currentKeyUsage objectForKey: item];
		if(!pids)
		{
			continue;
		}

		if([pids containsObject: pid])
		{
			[pids removeObject: pid];
			NSLog(@"removing object");

			if([pids count]==0)
			{
				// object is truly dead
				[_currentMessage setValue: nil forKey: item];

				int itemIdx = [_currentKeys indexOfObject: item];
				if(itemIdx!=NSNotFound)
					[_currentKeys removeObjectAtIndex: itemIdx];
			}
		}
	}
	
	[self processMessageCommonWithFocus: nil];
	
}


- (void) appDidExit: (NSString*) bundle
{
	
	
	int nKeys = [_currentKeys count];
	for(int i=nKeys - 1; i>=0; i--)
	{
		NSString* item = [_currentKeys objectAtIndex: i];
		
		NSMutableArray* pids = [_currentKeyUsage objectForKey: item];
		if(!pids)
		{
			continue;
		}

		if([pids containsObject: bundle])
		{
			[pids removeObject: bundle];
			NSLog(@"removing object");

			if([pids count]==0)
			{
				// object is truly dead
				[_currentMessage setValue: nil forKey: item];

				int itemIdx = [_currentKeys indexOfObject: item];
				if(itemIdx!=NSNotFound)
					[_currentKeys removeObjectAtIndex: itemIdx];
			}
		}
	}
	
	[self processMessageCommonWithFocus: nil];
}




- (void) setProperties: (NSString*) message userInfo: (NSDictionary*) userInfo
{
	NSString* item = [userInfo objectForKey: @"item"];
	NSDictionary* properties = [userInfo objectForKey: @"properties"];
	NSString* bundleId = [userInfo objectForKey: @"bundle"];
	NSNumber* pid = [userInfo objectForKey: @"pid"];
	
	[self setProperties: properties forItem: item bundle: bundleId pid: pid];
}


- (void) setState: (int) newState
{
	uint64_t value = newState;
	static int token = 0;
	if(!token)
	{
		const char* notif = "libstatusbar_changed";
		notify_register_check(notif, &token);
	}
	notify_set_state(token, value);
	[self enqueuePostChanged];
	
}

- (void) resyncTimer
{
	if(timer)
	{
		CFRunLoopTimerInvalidate(timer);
		CFRelease(timer);
		
		timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+3.5f, 3.5f, 0, 0, (CFRunLoopTimerCallBack) incrementTimer, NULL);
		CFRunLoopAddTimer(CFRunLoopGetMain(), timer, kCFRunLoopCommonModes);
	}
	
	
}


- (void) startTimer
{
//	NSLine();
	
	// is timer already running?
	if(timer)
	{
		NSLog(@"timer is already active.  Leaving it alone");
		return;
	}
	
	// check lock status
	uint64_t locked;
	{
		static int token = 0;
		if(!token)
		{
			notify_register_check("com.apple.springboard.lockstate", &token);
		}
		notify_get_state(token, &locked);
	}
	
//	NSLine();
	
	// reset timer state
	[self stopTimer];
//	NSLine();
	
	if(!locked)
	{
		NSLine();
		
		NSArray* titleStrings = [_currentMessage objectForKey: @"titleStrings"];
		if(titleStrings && [titleStrings count])
		{
			NSLine();
		
			timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+3.5f, 3.5f, 0, 0, (CFRunLoopTimerCallBack) incrementTimer, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), timer, kCFRunLoopCommonModes);
			
			{
				/*
				const char* notif = "libstatusbar_changed";
				uint64_t value = 0;
				int token = 0;
				notify_register_check(notif, &token);
				notify_set_state(token, value);
				*/
				[self setState: 0];
				
				[self enqueuePostChanged];
				//notify_post(notif);
			}
			
		}
	}
//	NSLine();
	
}

- (void) stopTimer
{
//	NSLine();
	
	// reset the statusbar state
	{
		/*
		const char* notif = "libstatusbar_changed";
		
		uint64_t value = NSNotFound;
		int token = 0;
		notify_register_check(notif, &token);
		notify_set_state(token, value);
		*/
		
		if(timer) // only post a notification if the timer was running
			[self enqueuePostChanged];
			//notify_post(notif);
	}
	
	[self setState: NSNotFound];
	// kill timer
	if(timer)
	{
		CFRunLoopTimerInvalidate(timer);
		CFRelease(timer);
		timer = nil;
		[self enqueuePostChanged];
	}
//	NSLine();
}


- (void) incrementTimer
{
//	NSLine();
	
	NSArray* titleStrings = [_currentMessage objectForKey: @"titleStrings"];
	
	const char* notif = "libstatusbar_changed";
	
	if(titleStrings && [titleStrings count])
	{
		uint64_t value;
		static int token = 0;
		if(!token)
		{
			notify_register_check(notif, &token);
		}
		notify_get_state(token, &value);
		
		value++;
		if(timeHidden ? (value >= [titleStrings count]) : (value > [titleStrings count]) )
		{
			value = 0;
		}
		
//		NSLog(@"idx = %ld", value);
		
		notify_set_state(token, value);
		
		[self enqueuePostChanged];
		//notify_post(notif);
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