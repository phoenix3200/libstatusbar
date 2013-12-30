
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "LSStatusBarClient.h"
#import "LSStatusBarServer.h"
#import "UIStatusBarCustomItem.h"

#import "LSStatusBarItem.h"

void UpdateStatusBar(CFNotificationCenterRef center, LSStatusBarClient* client)
{
//	NSLine();
	[client updateStatusBar];
}

void ResubmitContent(CFNotificationCenterRef center, LSStatusBarClient* client)
{
//	NSLine();
	[client resubmitContent];
	[client updateStatusBar];
}


extern "C" kern_return_t
bootstrap_look_up(mach_port_t bp, const char* service_name, mach_port_t *sp);

extern "C" mach_port_t bootstrap_port;

mach_port_t LSBServerPort()
{
	//mach_port_t bootstrap_port;
	
	//int err = task_get_bootstrap_port (mach_task_self (), &boot_port);
	const char* lookup_name = "com.apple.springboard.libstatusbar";
	
	mach_port_t lookup_port = NULL;
	kern_return_t err = bootstrap_look_up (bootstrap_port, lookup_name, &lookup_port);
	if(!err)
		return lookup_port;
	if(err)
	{
		NSLog(@"Could not fetch port: %x", err);
	}
	return 0;
}


@implementation LSStatusBarClient

+ (id) sharedInstance
{
	static LSStatusBarClient* client;
	
	if(!client)
	{
		if(!$SpringBoard)
		{
			if(sandbox_check(getpid(), "mach-lookup", (sandbox_filter_type) (SANDBOX_FILTER_LOCAL_NAME | SANDBOX_CHECK_NO_REPORT), "com.apple.springboard.libstatusbar"))
			{
				CommonLog_F("******SANDBOX FORBADE MACH LOOKUP.  LIBSTATUSBAR MAY CRASH IN THIS PROCESS********\n");
				TRACE_F();
				return nil;
			}
			if(sandbox_check(getpid(), "mach-lookup", (sandbox_filter_type) (SANDBOX_FILTER_LOCAL_NAME | SANDBOX_CHECK_NO_REPORT), "com.apple.springboard.services"))
			{
				CommonLog_F("******SANDBOX FORBADE MACH LOOKUP.  LIBSTATUSBAR MAY CRASH IN THIS PROCESS********\n");
				return nil;
			}
		}
		
		{
			// I feel so dirty.  But don't want to track where/how it's reentrant.
			client = [self alloc];
			[client init];
		}
	}
	return client;
}

- (id) init
{
	self = [super init];
	if(self)
	{
		_isLocal = $SpringBoard ? YES : NO;
		
		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, self, (CFNotificationCallback) UpdateStatusBar, (CFStringRef) @"libstatusbar_changed", NULL, NULL);

//		CFNotificationCenterAddObserver(darwin, self, (CFNotificationCallback) ResubmitContent, CFSTR("SBSpringBoardDidLaunchNotification"), NULL, NULL);
		CFNotificationCenterAddObserver(darwin, self, (CFNotificationCallback) ResubmitContent, CFSTR("LSBDidLaunchNotification"), NULL, NULL);
		
	//	[self performSelector: @selector(updateStatusBar) withObject: nil afterDelay: 0.001f];
	}
	return self;
}

- (NSDictionary*) currentMessage
{
	return _currentMessage;
}

- (void) retrieveCurrentMessage
{
	[_currentMessage release];
	if(_isLocal)
	{
		_currentMessage = [[[LSStatusBarServer sharedInstance] currentMessage] retain];
	}
	else if(LSBServerPort())
	{
		CPDistributedMessagingCenter* dmc = [CPDistributedMessagingCenter centerNamed: @"com.apple.springboard.libstatusbar"];
		_currentMessage = [[dmc sendMessageAndReceiveReplyName: @"currentMessage" userInfo: nil] retain];
	}
	else if(SBSSpringBoardServerPort())
	{
		CommonLog_F("****** UNABLE TO FETCH FROM LSB!");
	}
	else
	{
		_currentMessage = nil;
	}
//	NSDesc(_currentMessage);
}

- (NSString*) titleStringAtIndex: (int) idx
{
	if(idx < (int)[_titleStrings count])
	{
	//	NSLog(@"Fetching index %d of %d", idx, (int)[_titleStrings count]);
		return [_titleStrings objectAtIndex: idx];
	}
	return nil;
}

- (bool) processCurrentMessage
{
	bool ret = NO;
	
	if(!_currentMessage)
	{
		return NO;
	}
	
	//NSMutableDictionary *processedMessage = [_currentMessage mutableCopy];
	
	NSMutableArray* processedKeys = [[_currentMessage objectForKey: @"keys"] mutableCopy];
	
	
	[_titleStrings release];
	_titleStrings = [[_currentMessage objectForKey: @"titleStrings"] retain];
	
	
	/*
	if(_titleStrings)
	{
		[processedMessage removeObjectForKey: @"titleStrings"];
	}
	*/
	
	int keyidx = (cfvers >= CF_70) ? 32 : 24;
	
	//NSDesc(_currentMessage);
	
	
	
	
	
	
	
	extern NSMutableArray* customItems[3];
	
	for(int i=0; i<3; i++)
	{
		if(customItems[i])
		{
		//	NSDesc(customItems[i]);
			int cnt = [customItems[i] count]-1;
		/*
		extern NSMutableArray* allCustomItems;
		if(allCustomItems)
		{
			int cnt = [allCustomItems count]-1;
		*/	
			for(; cnt>= 0; cnt--)
//			for(UIStatusBarCustomItem* item in customItems[i])
			{
				UIStatusBarCustomItem* item = [customItems[i] objectAtIndex: cnt];
				//UIStatusBarCustomItem* item = [allCustomItems objectAtIndex: cnt];
			
				NSString* indicatorName = [item indicatorName];
				
				NSObject* properties = nil;
				if(_currentMessage)
				{
					properties = [_currentMessage objectForKey: indicatorName];
				}
				
				if(!properties)
				{
					ret = YES;
					
//					NSLog(@"removing item: %@", indicatorName);
					[item removeAllViews];
					//[allCustomItems removeObjectAtIndex: cnt];
					[customItems[i] removeObjectAtIndex: cnt];
//					[customItems[i] removeObject: item];
				}
				else
				{
//					NSLog(@"keeping item: %@", indicatorName);
					//[processedMessage removeObjectForKey: indicatorName];
					[processedKeys removeObject: indicatorName];
					
					int &type(MSHookIvar<int>(item, "_type"));
					if(type > keyidx)
						keyidx = type;
					
					item.properties = [properties isKindOfClass: [NSDictionary class]] ? (NSDictionary*) properties : nil;
				}
			}
		}
		else
		{
//			NSLog(@"creating array");
			customItems[i] = [[NSMutableArray alloc] init];
		}
	}
	
	keyidx++;
	
	if(processedKeys && [processedKeys count])
	{
		ret = YES;
		GETCLASS(UIStatusBarItem);
		for(NSString* key in processedKeys)//processedMessage)
		{
//			NSLog(@"adding item: %@", key);
			
			UIStatusBarCustomItem* item = ((cfvers >= CF_70) ? [$UIStatusBarItem itemWithType: keyidx++ idiom: 0] : [$UIStatusBarItem itemWithType: keyidx++]);
			
			[item setIndicatorName: key];
			
			NSObject* properties = [_currentMessage objectForKey: key];
			item.properties = [properties isKindOfClass: [NSDictionary class]] ? (NSDictionary*) properties : nil;
			
			
			if([item leftOrder])
			{
				if(!customItems[0])
				{
					customItems[0] = [[NSMutableArray alloc] init];
				}
				[customItems[0] addObject: item];
			}
			else if([item rightOrder])
			{
				if(!customItems[1])
				{
					customItems[1] = [[NSMutableArray alloc] init];
				}
				[customItems[1] addObject: item];
			}
			else if(item)
			{
				if(!customItems[2])
				{
					customItems[2] = [[NSMutableArray alloc] init];
				}
				[customItems[2] addObject: item];
			}
		}
	}
	
	
	//if(_titleStrings && [_titleStrings count])
	
	// too many cases; just refresh the damn thing.
	{
		ret = YES;
	}
	
	[processedKeys release];
	
//	NSLog(@"processCurrentMessage? %@", ret ? @"YES" : @"NO");
	return ret;
}

- (void) updateStatusBar
{
	if(!$UIApplication)
		return;
	
//	SelLog();
	
	[self retrieveCurrentMessage];
	
	// need a decent guard band because we do call before UIApp exists
	if([self processCurrentMessage])
	{
		if($UIApplication && [$UIApplication sharedApplication])
		{
			id sb = [[$UIApplication sharedApplication] statusBar];
			
			if(!sb)
				return;
			
			UIStatusBarForegroundView* _foregroundView = MSHookIvar<UIStatusBarForegroundView*>(sb, "_foregroundView");
			if(_foregroundView)
			{
				//NSLine();
				[sb forceUpdateData: NO];
				//NSLine();
				
				if(_isLocal)
				{
					
					GETCLASS(SBBulletinListController);
					//NSLine();
					if($SBBulletinListController)
					{
						//NSLine();
						id listview = [[$SBBulletinListController sharedInstance] listView];
						NSType(listview);
						if(listview)
						{
							id _statusBar = MSHookIvar<id>(listview, "_statusBar");
							[_statusBar forceUpdateData: NO];
						}
					}
					
					GETCLASS(SBNotificationCenterController);
					if($SBNotificationCenterController)
					{
						id vc = [[$SBNotificationCenterController sharedInstanceIfExists] viewController];
						if(vc)
						{
							//NSLine();
							id _statusBar = MSHookIvar<id>(vc, "_statusBar");
							
							if(_statusBar)
							{
								//NSDesc(_statusBar);
								
								// forceUpdateData: animated: doesn't work if statusbar._inProcessProvider = 1
								// bypass and directly do it.
								
								void* &_currentRawData(MSHookIvar<void*>(_statusBar, "_currentRawData"));
								[_statusBar forceUpdateToData: &_currentRawData animated: NO];
								
							}
						}
					}
				}
			}

			// ???
			
			
			//[LSStatusBarItem _updateItems];
		}
		

	}
	
//	
}

- (void) setProperties: (id) properties forItem: (NSString*) item
{
//	NSLine();
	//SelLog();
	if(item)
	{
		if(!_submittedMessages)
		{
			_submittedMessages = [[NSMutableDictionary alloc] init];
		}
		if(properties)
		{
			[_submittedMessages setObject: properties forKey: item];
		}
		else
		{
			[_submittedMessages removeObjectForKey: item];
		}
		
		
		
		NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
		if(_isLocal)
		{
			[[LSStatusBarServer sharedInstance] setProperties: properties forItem: item bundle: bundleId pid: [NSNumber numberWithInt: 0]];
		}
		else if(LSBServerPort())
		//else if(SBSSpringBoardServerPort())
		{
			NSNumber* pid = [NSNumber numberWithInt: getpid()];
			
			
			NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithCapacity: 4];
			if(item)
				[dict setObject: item forKey: @"item"];
			if(pid)
				[dict setObject: pid forKey: @"pid"];
			if(properties)
				[dict setObject: properties forKey: @"properties"];
			if(bundleId)
				[dict setObject: bundleId forKey: @"bundle"];
			/*
			NSDictionary* dict = [[NSDictionary alloc] initWithObjectsAndKeys:
									item, @"item",
									pid, @"pid",
									properties, @"properties",
									bundleId, @"bundle",
									nil];
			*/
			//NSLog(@"dict = %@", [dict description]);
			
			CPDistributedMessagingCenter* dmc = [CPDistributedMessagingCenter centerNamed: @"com.apple.springboard.libstatusbar"];
			[dmc sendMessageName: @"setProperties:userInfo:" userInfo: dict];
			//NSLine();
			[dict release];
		}
		else if(SBSSpringBoardServerPort())
		{
			CommonLog_F("****** UNABLE TO PUSH TO LSB!");
		}
	}
}

- (void) resubmitContent
{
//	NSLine();
	
	NSDictionary* messages = _submittedMessages;
	if(!messages)
		return;
	
	_submittedMessages = nil;
	
	for(NSString* key in messages)
	{
		[self setProperties: [messages objectForKey: key] forItem: key];
	}
	
	[messages release];
	
}

@end
