

@interface UIApplication (libstatusbar)
- (void) addStatusBarImageNamed: (NSString*) name removeOnExit: (BOOL) remove;
- (void) addStatusBarImageNamed: (NSString*) name;
- (void) removeStatusBarImageNamed: (NSString*) name;


@end