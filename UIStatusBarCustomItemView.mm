
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "UIStatusBarCustomItemView.h"

NSMutableDictionary* cachedImages[4];

UIImage* UIStatusBarCustomItemView$contentsImageForStyle$(id self, SEL sel, int style)
{
	//SelLog();
	
	NSString* itemName = [[self item] indicatorName];
	
	int isBlack = (style==2 || style==3) ? 1 : 0;
	
	UIImage* ret = nil;
	
	// try the cache
	
	if(cachedImages[style])
	{
		ret = [cachedImages[style] objectForKey: itemName];
	}
	
	/*
	if(cachedImages[isBlack])
	{
		ret = [cachedImages[isBlack] objectForKey: itemName];
	}
	*/
	
//	NSBundle* kitbundle = [NSBundle bundleWithPath: @"/System/Library/Frameworks/UIKit.framework"];
	

	//NSBundle* bundle
	
	if(!ret) // try iOS 4 naming convention
	{
		NSString* styleStr = isBlack ? @"Black" : @"Silver";
		NSString *imageName = [NSString stringWithFormat: @"%@_%@.png", styleStr, itemName];
	//	ret = [UIImage imageNamed: imageName inBundle: kitbundle];
		ret = [UIImage kitImageNamed: imageName];
	}
	
	if(!ret) // try iOS 5 naming convention
	{
		NSString* styleStr = nil;
		switch(style)
		{
		case 1:
			styleStr =  @"ColorOnGrayShadow";
			break;
		case 2:
			styleStr = @"WhiteOnBlackEtch";
			break;
		case 3:
			styleStr = @"WhiteOnBlackShadow";
			break;
		default:
			NSLog(@"Unknown style %d", style);
			break;
		}
		
		//NSString* styleStr = ((style==2) ? @"WhiteOnBlackEtch" : ((style==3) ? @"WhiteOnBlackShadow") :
		//isBlack ? @"WhiteOnBlackEtch" : @"ColorOnGrayShadow";
		NSString *imageName = [NSString stringWithFormat: @"%@_%@.png", styleStr, itemName];
		NSLog(@"searching for image named %@", imageName);
//		ret = [UIImage imageNamed: imageName inBundle: kitbundle];
		ret = [UIImage kitImageNamed: imageName];
	}
	
	// try SB folder naming convention
	if(!ret)
	{
		NSString* styleStr = isBlack ? @"FSO" : @"Default";
		
		NSString *imageName = [NSString stringWithFormat: @"%@_%@.png", styleStr, itemName];
		NSBundle* bundle = [NSBundle bundleWithPath: @"/System/Library/CoreServices/SpringBoard.app"];
		ret = [UIImage imageNamed: imageName inBundle: bundle];
	}

	if(!ret)
		NSLog(@"image %@ not found", itemName);
	
	// make sure we have a way to cache
	if(!cachedImages[style])
	{
		cachedImages[style] = [[NSMutableDictionary alloc] init];
	}
	// cache the image
	if(ret)
		[cachedImages[style] setObject: ret forKey: itemName];
	
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