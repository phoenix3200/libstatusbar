
#import "common.h"
#import "defines.h"

#import "classes.h"
#import "UIStatusBarCustomItemView.h"

NSMutableDictionary* cachedImages[2];

UIImage* UIStatusBarCustomItemView$contentsImageForStyle$(id self, SEL sel, int style)
{
	NSString* itemName = [[self item] indicatorName];
	
	int isBlack = (style==2) ? 1 : 0;
	
	UIImage* ret = nil;
	
	// try the cache
	if(cachedImages[isBlack])
	{
		ret = [cachedImages[isBlack] objectForKey: itemName];
	}
	
	// try kit images first
	if(!ret)
	{
		NSString* styleStr = isBlack ? @"Black" : @"Silver";
		NSString *imageName = [NSString stringWithFormat: @"%@_%@.png", styleStr, itemName];
		ret = [UIImage kitImageNamed: imageName];
	}
	
	// try non-kit images
	if(!ret)
	{
		NSString* styleStr = isBlack ? @"FSO" : @"Default";
		NSString *imageName = [NSString stringWithFormat: @"/System/Library/CoreServices/SpringBoard.app/%@_%@.png", styleStr, itemName];
		ret = [UIImage imageWithContentsOfFile: imageName];
	}
	
	// make sure we have a way to cache
	if(!cachedImages[isBlack])
	{
		cachedImages[isBlack] = [[NSMutableDictionary alloc] init];
	}
	// cache the image
	if(ret)
		[cachedImages[isBlack] setObject: ret forKey: itemName];
	
	return ret;
}

void ClassCreate_UIStatusBarCustomItemView()
{
	GETCLASS(UIStatusBarItemView);
	$UIStatusBarCustomItemView = objc_allocateClassPair($UIStatusBarItemView, "UIStatusBarCustomItemView", 0);
	class_addMethod($UIStatusBarCustomItemView, @selector(contentsImageForStyle:), (IMP) UIStatusBarCustomItemView$contentsImageForStyle$, "@@:i");
	
//	class_addIvar($UIStatusBarCustomItemView, "_itemName", sizeof(NSString*), 0x4, "@");
	objc_registerClassPair($UIStatusBarCustomItemView);
}