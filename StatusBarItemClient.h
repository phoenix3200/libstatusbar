
@interface StatusBarItemClient : NSObject
{
	bool _isLocal;
	NSDictionary* _currentMessage;
}

+ (id) sharedInstance;

- (id) init;

- (void) retrieveCurrentMessage;
- (void) processCurrentMessage;
- (void) updateStatusBar;

- (void) setProperties: (id) properties forItem: (NSString*) item;

@end