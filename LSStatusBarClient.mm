
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
	[client updateStatusBar];
}

@implementation LSStatusBarClient

+ (id) sharedInstance
{
	static LSStatusBarClient* client;
	
	if(!client)
	{
		client = [[self alloc] init];
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
		
		[self updateStatusBar];
		
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
	else
	{	CPDistributedMessagingCenter* dmc = [CPDistributedMessagingCenter centerNamed: @"com.apple.springboard.libstatusbar"];
	 
		_currentMessage = [[dmc sendMessageAndReceiveReplyName: @"currentMessage" userInfo: nil] retain];
	}
//	NSDesc(_currentMessage);
}

- (NSString*) titleStringAtIndex: (int) idx
{
	if(idx < (int)[_titleStrings count])
	{
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
	
	int keyidx = 24;
	
//	NSDesc(_currentMessage);
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
			
			UIStatusBarCustomItem* item = [$UIStatusBarItem itemWithType: keyidx++];
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
			else
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
	SelLog();
	
	[self retrieveCurrentMessage];
	
	// need a decent guard band because we do call before UIApp exists
	if([self processCurrentMessage] && UIApp)
	{
		UIStatusBarForegroundView* _foregroundView = MSHookIvar<UIStatusBarForegroundView*>([UIApp statusBar], "_foregroundView");
		if(_foregroundView)
		{
			[[UIApp statusBar] forceUpdateData: NO];
			
			NSLine();
			GETCLASS(SBBulletinListController);
			NSLine();
			if($SBBulletinListController)
			{
				NSLine();
				id listview = [[$SBBulletinListController sharedInstance] listView];
				NSType(listview);
				if(listview)
				{
					id _statusBar = MSHookIvar<id>(listview, "_statusBar");
					[_statusBar forceUpdateData: NO];
				}
			}
			
			
			/*
			//[_foregroundView _reflowItemViewsWithDuration: 0.0f suppressCenterAnimation: YES];
			
			[_foregroundView startIgnoringData];
			[_foregroundView stopIgnoringData: YES];
			
			
			
			
			StatusBarData* data = (StatusBarData*) [$UIStatusBarServer getStatusBarData];
			
			if(data)
			//	[_foregroundView setStatusBarData: data actions: 1 animated: YES];
				[_foregroundView setStatusBarData: data actions: 0 animated: NO];
				*/
		}
		
		[LSStatusBarItem _updateItems];
	}
	
//	
}

- (void) setProperties: (id) properties forItem: (NSString*) item
{
//	SelLog();
	if(item)
	{
		NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
		
		if(_isLocal)
		{
			[[LSStatusBarServer sharedInstance] setProperties: properties forItem: item bundle: bundleId];
		}
		else
		{
			
			
			NSDictionary* dict = [[NSDictionary alloc] initWithObjectsAndKeys:
									item, @"item",
									properties, @"properties",
									bundleId, @"bundle",
									nil];
		
			CPDistributedMessagingCenter* dmc = [CPDistributedMessagingCenter centerNamed: @"com.apple.springboard.libstatusbar"];
		
			[dmc sendMessageName: @"setProperties:userInfo:" userInfo: dict];
			[dict release];
		}
	}
}

@end
