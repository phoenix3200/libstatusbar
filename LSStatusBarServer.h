
@interface LSStatusBarServer : NSObject
{
	CPDistributedMessagingCenter *_dmc;
	NSMutableDictionary* _currentMessage;
	NSMutableArray* _currentKeys;
	NSMutableDictionary* _currentKeyUsage;
	
	CFRunLoopTimerRef timer;
	bool timeHidden;
}

+ (id) sharedInstance;

- (id) init;

- (void) appDidExit: (NSString*) bundle;

- (void) setProperties: (NSString*) message userInfo: (NSDictionary*) userInfo;
- (void) setProperties: (id) properties forItem: (NSString*) item bundle: (NSString*) bundle;

- (NSMutableDictionary*) currentMessage;

- (void) incrementTimer;
- (void) updateLockStatus;

- (void) startTimer;
- (void) stopTimer;

@end