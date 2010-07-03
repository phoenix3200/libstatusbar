
#import "common.h"
#import "defines.h"

#import "classes.h"
//#import "StatusBarItemClient.h"
#import "StatusBarItemServer.h"
//#import "UIStatusBarCustomItem.h"

@implementation StatusBarItemServer

StatusBarItemServer* sharedItemServer;
+ (id) sharedInstance
{
	if(!sharedItemServer)
	{
		sharedItemServer = [[self alloc] init];
	}
	return sharedItemServer;
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
		
		
	}
	return self;
}

- (NSMutableDictionary*) currentMessage
{
	return _currentMessage;
}

- (void) setProperties: (id) properties forItem: (NSString*) item
{
	SelLog();
	if(item)
	{
		// use setValue instead of setObject
		[_currentMessage setValue: properties forKey: item];
	}
	NSDesc(_currentMessage);
	notify_post("libstatusbar_changed");
	
}

- (void) setProperties: (NSString*) message userInfo: (NSDictionary*) userInfo
{
	NSString* item = [userInfo objectForKey: @"item"];
	NSDictionary* properties = [userInfo objectForKey: @"properties"];
	
	[self setProperties: properties forItem: item];
	
	
}

@end