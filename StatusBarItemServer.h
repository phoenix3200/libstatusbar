
@interface StatusBarItemServer : NSObject
{
	CPDistributedMessagingCenter *_dmc;
	NSMutableDictionary* _currentMessage;
}

+ (id) sharedInstance;

- (id) init;

- (void) setProperties: (NSString*) message userInfo: (NSDictionary*) userInfo;
- (void) setProperties: (id) properties forItem: (NSString*) item;

- (NSMutableDictionary*) currentMessage;

@end