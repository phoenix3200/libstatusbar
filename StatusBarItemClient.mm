
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "StatusBarItemClient.h"
#import "StatusBarItemServer.h"
#import "UIStatusBarCustomItem.h"

void UpdateStatusBar(CFNotificationCenterRef center, StatusBarItemClient* client)
{
	SelLog();
	[client updateStatusBar];
}

@implementation StatusBarItemClient

StatusBarItemClient* sharedItemClient;
+ (id) sharedInstance
{
	if(!sharedItemClient)
	{
		sharedItemClient = [[self alloc] init];
	}
	return sharedItemClient;
}

- (id) init
{
	self = [super init];
	if(self)
	{
		_isLocal = $SpringBoard ? YES : NO;
		
		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, self, (CFNotificationCallback) UpdateStatusBar, (CFStringRef) @"libstatusbar_changed", NULL, NULL);
		
		[self updateStatusBar];
		
	}
	return self;
}


- (void) retrieveCurrentMessage
{
	[_currentMessage release];
	if(_isLocal)
	{
		_currentMessage = [[[StatusBarItemServer sharedInstance] currentMessage] retain];
	}
	else
	{	CPDistributedMessagingCenter* dmc = [CPDistributedMessagingCenter centerNamed: @"com.apple.springboard.libstatusbar"];
	 
		_currentMessage = [[dmc sendMessageAndReceiveReplyName: @"currentMessage" userInfo: nil] retain];
	}
	NSDesc(_currentMessage);
}

- (bool) processCurrentMessage
{
	bool ret = NO;
	
	NSMutableDictionary *processedMessage = [_currentMessage mutableCopy];
	
	int keyidx = 22;
	
//	NSDesc(processedMessage);
	
	for(int i=0; i<3; i++)
	{
		extern NSMutableArray* customItems[3];
		if(customItems[i])
		{
			NSDesc(customItems[i]);
			int cnt = [customItems[i] count]-1;
			for(; cnt>= 0; cnt--)
//			for(UIStatusBarCustomItem* item in customItems[i])
			{
				UIStatusBarCustomItem* item = [customItems[i] objectAtIndex: cnt];
			
				NSString* indicatorName = [item indicatorName];
				if(processedMessage==nil || [processedMessage objectForKey: indicatorName] == nil)
				{
					ret = YES;
					
					NSLog(@"removing item: %@", indicatorName);
					[item removeAllViews];
					[customItems[i] removeObjectAtIndex: cnt];
//					[customItems[i] removeObject: item];
				}
				else
				{
					NSLog(@"keeping item: %@", indicatorName);
					[processedMessage removeObjectForKey: indicatorName];
					int &type(MSHookIvar<int>(item, "_type"));
					if(type > keyidx)
						keyidx = type;
					
				}
			}
		}
		else
		{
			NSLog(@"creating array");
			
			customItems[i] = [[NSMutableArray alloc] init];
		}
	}
	
	keyidx++;
	
	if(processedMessage && [processedMessage count])
	{
		ret = YES;
		GETCLASS(UIStatusBarItem);
		for(NSString* key in processedMessage)
		{
			NSLog(@"adding item: %@", key);
			[[$UIStatusBarItem itemWithType: keyidx++] setIndicatorName: key];
		}
	}
	NSLog(@"processCurrentMessage? %@", ret ? @"YES" : @"NO");
	return ret;
}

- (void) updateStatusBar
{
	SelLog();
	
	[self retrieveCurrentMessage];
	
	// need a decent guard band because we do call before UIApp exists
	if([self processCurrentMessage] && UIApp)
	{
		UIStatusBarForegroundView* _foregroundView = MSHookIvar<UIStatusBarForegroundView*>([UIApp statusBar], "_foregroundView");
		if(_foregroundView)
		{
			[_foregroundView setStatusBarData: (StatusBarData*) [$UIStatusBarServer getStatusBarData] actions: 0 animated: YES];
		}
	}
}

- (void) setProperties: (id) properties forItem: (NSString*) item
{
	SelLog();
	if(item)
	{
		if(_isLocal)
		{
			[[StatusBarItemServer sharedInstance] setProperties: properties forItem: item];
		}
		else
		{
			NSDictionary* dict = [[NSDictionary alloc] initWithObjectsAndKeys:
									item, @"item",
									properties, @"properties",
									nil];
		
			CPDistributedMessagingCenter* dmc = [CPDistributedMessagingCenter centerNamed: @"com.apple.springboard.libstatusbar"];
		
			[dmc sendMessageName: @"setProperties:userInfo:" userInfo: dict];
			[dict release];
		}
	}
}

@end
