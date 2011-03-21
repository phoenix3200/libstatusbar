
@interface LSStatusBarClient : NSObject
{
	bool _isLocal;
	NSDictionary* _currentMessage;
	NSArray* _titleStrings;
}

+ (id) sharedInstance;

- (id) init;

- (NSDictionary*) currentMessage;
- (void) retrieveCurrentMessage;
- (bool) processCurrentMessage;
- (void) updateStatusBar;

- (void) setProperties: (id) properties forItem: (NSString*) item;

- (NSString*) titleStringAtIndex: (int) idx;

@end