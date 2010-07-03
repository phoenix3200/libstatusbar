

// not implemented yet - will end up allowing you to create custom items From SpringBoard
/*
@protocol StatusBarCustomItemDelegate
@required
- (int) leftOrder;
- (int) rightOrder;
- (Class) viewClass;
- (NSString*) indicatorName;
- (int) priority;
//- (NSString*) description;
@end
*/

@interface UIStatusBarCustomItemView : UIStatusBarItemView
{
}
- (UIImage*)contentsImageForStyle: (int) style;
@end

void ClassCreate_UIStatusBarCustomItemView();