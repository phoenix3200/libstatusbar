

@interface UIStatusBarCustomItem : UIStatusBarItem
{
//	NSString* _indicatorName;
//	CFMutableDictionaryRef _views;
}

- (UIStatusBarItemView*) viewForManager: (id) manager;
- (void) setView:  (UIStatusBarItemView*) view forManager: (id) manager;
- (void) removeAllViews;

- (void) setIndicatorName: (NSString*) name;

//@property (nonatomic, retain) NSString* indicatorName;
@property (nonatomic, retain) NSDictionary* properties;


@end

void ClassCreate_UIStatusBarCustomItem();