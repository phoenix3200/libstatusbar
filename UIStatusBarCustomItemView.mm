
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "UIStatusBarCustomItemView.h"

NSMutableDictionary* cachedImages[5];

UIImage* UIStatusBarCustomItemView$contentsImageForStyle$(UIStatusBarCustomItemView* self, SEL sel, int style)
{
	//SelLog();
	
	NSString* itemName = [[self item] indicatorName];
	
	if(style > 3)
	{
		return [[self class] imageNamed: itemName forForegroundStyle: style];
	}
	
	
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
		ret = [$UIImage kitImageNamed: imageName];
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
		ret = [$UIImage kitImageNamed: imageName];
	}
	
	// try SB folder naming convention
	if(!ret)
	{
		NSString* styleStr = isBlack ? @"FSO" : @"Default";
		
		NSString *imageName = [NSString stringWithFormat: @"%@_%@.png", styleStr, itemName];
		NSBundle* bundle = [NSBundle bundleWithPath: @"/System/Library/CoreServices/SpringBoard.app"];
		ret = [$UIImage imageNamed: imageName inBundle: bundle];
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

@interface UIStatusBarForegroundStyle : NSObject
- (UIColor*) tintColor;
- (NSString*) expandedNameForImageName: (NSString*) imageName;
- (UIImage*) shadowImageForImage: (UIImage*) img withIdentifier: (NSString*) id forStyle: (int) style withStrength: (float) strength cachesImage: (bool) cache;
@end

@interface UIColor (ss)
- (NSString*) styleString;
@end

@interface UIImage (fiwc)
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end

@interface UIStatusBarItemView (lss)
- (int) legibilityStyle;
- (float) legibilityStrength;
@end

@interface _UILegibilityImageSet : NSObject
+ (_UILegibilityImageSet*) imageFromImage: (UIImage*) image withShadowImage: (UIImage*) imag_sh;
@end

@interface UIStatusBarCustomItemView (fgs)
- (UIStatusBarForegroundStyle*) foregroundStyle;
@end


_UILegibilityImageSet* UIStatusBarCustomItemView$contentsImage(UIStatusBarCustomItemView* self, SEL sel)
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	NSString* itemName = [[self item] indicatorName];
	
	UIColor* tintColor = [fs tintColor];
	
	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	NSString* expandedName_cache = [NSString stringWithFormat: @"%@_%@.png", expandedName_default, [tintColor styleString]]; 

	if(!cachedImages[4])
	{
		cachedImages[4] = [[NSMutableDictionary alloc] init];
	}
	if(cachedImages[4])
	{
		id ret = [cachedImages[4] objectForKey: expandedName_cache];
		if(ret)
			return ret;
	}
	
	bool isBlack = [tintColor isEqual: [$UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass: objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [$UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	UIImage* image_base = image_color ? 0 : [$UIImage kitImageNamed: expandedName_default];
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}
	/*
	if(!image)
	{
		// fall back to try the old routines.
		image = UIStatusBarCustomItemView$contentsImageForStyle$(self, @selector(contentsImageForStyle:), isBlack ? 2 : 1);
	}
	
	// create a shadowed icon?  for who?
	if(image)
	{
		image_sh = [fs shadowImageForImage: image withIdentifier: nil forStyle: [self legibilityStyle] withStrength: [self legibilityStrength] cachesImage: NO];	
	}*/

	_UILegibilityImageSet* ret = [$_UILegibilityImageSet imageFromImage: image withShadowImage: nil];//image_sh];
	
	if(ret && cachedImages[4])
	{
		[cachedImages[4] setObject: ret forKey: expandedName_cache];
	}

	return ret;


	
	
	// UIStatusBarLegacyStyleAttributes: wobe
	// UIStatusBarLegacyBlackTransparentShadowedStyleAttributes: wobs
	//
	
	
	// default: nil
	// new: 'Black_<Name>'
	// external: new + '-card'
	// lockscreen: 'Lockscreen_<Name>'
	// wobe: 'WhiteOnBlackEtch_<name>'
	// wobs: 'WhiteOnBlackShadow_<name>'
	
	
	// externaltranslucent
	// externalincall
	// externalnavigation
	/*
	UIStatusBarForegroundStyleAttributes.h:@interface UIStatusBarForegroundStyleAttributes : NSObject {
	UIStatusBarWhiteOnBlackEtchForegroundStyleAttributes.h:@interface UIStatusBarWhiteOnBlackEtchForegroundStyleAttributes : UIStatusBarForegroundStyleAttributes {
	UIStatusBarNewUIForegroundStyleAttributes.h:@interface UIStatusBarNewUIForegroundStyleAttributes : UIStatusBarForegroundStyleAttributes {
	UIStatusBarExternalForegroundStyleAttributes.h:@interface UIStatusBarExternalForegroundStyleAttributes : UIStatusBarNewUIForegroundStyleAttributes {
	UIStatusBarLockScreenForegroundStyleAttributes.h:@interface UIStatusBarLockScreenForegroundStyleAttributes : UIStatusBarNewUIForegroundStyleAttributes {
	*/
	
	
//	NSLog(@"expandedName: %@", expandedName_default);
	
	//UIImage* image = [$UIImage kitImageNamed: expandedName_default];
	//bool isBlack = [tintColor isEqual: [$UIColor blackColor]];
	
	
	
	
//	TRACE();
	//UIImage* UIStatusBarCustomItemView$contentsImageForStyle$(id self, SEL sel, int style)
	
	
	//NSLog(@"styleString = %@", styleString);
	
	// Lockscreen
	// Black
	
	//_%@
	//NSString* imageName = [NSString stringWithFormat: @"LockScreen_%@.png", itemName, styleStr];
	
	//Black_
	//LockScreen_
	//WhiteOnBlackShadow_
	//WhiteOnBlackEtch_
	
	
	//NSLog(@"image name = %@", imageName);
	
	//UIImage* image = [$UIImage kitImageNamed: imageName];
	
	//image = [image _flatImageWithColor: [[self foregroundStyle] tintColor]];
	
	//UIImage* image2 = [[self foregroundStyle] shadowImageForImage: image withIdentifier: nil forStyle: [self legibilityStyle] withStrength: [self legibilityStrength] cachesImage: NO];

//	shadowImageForImage_withIdentifier_forStyle_withStrength_cachesImage
	
	// untintedImageNamed: ...
	// _flatImageWithColor: ...]
	
	//UIImage* image = UIStatusBarCustomItemView$contentsImageForStyle$(self, @selector(contentsImageForStyle:), 2);
	
	//id ret = [$_UILegibilityImageSet imageFromImage: image withShadowImage: image_sh];
	
	//[self setBackgroundColor: [objc_getClass("UIColor") redColor]];
	//[self setFrame: (CGRect){{0,0},{20,20}}];
	
//	if(ret && cachedImages[4])
//	{
//		[cachedImages[style] setObject: ret forKey: itemName];

//		[cachedImages[4] setObject: ret forKey: expandedName_cache];
//	}

//	return ret;
		
	/*
	[self imageWithShadowNamed: name]
		fgs = [self foregroundStyle];
		(int) [self legibilityStyle];
		(int) [self legibilityStrength];
		[fgs imageNamed: withLegibilityStyle: legibilityStrength: ]
		
			[[fgs tintColor] styleString]
	*/
}


void ClassCreate_UIStatusBarCustomItemView()
{
	GETCLASS(UIStatusBarItemView);
	$UIStatusBarCustomItemView = objc_allocateClassPair($UIStatusBarItemView, "UIStatusBarCustomItemView", 0);
	if(cfvers >= CF_70)
	{
		class_addMethod($UIStatusBarCustomItemView, @selector(contentsImage), (IMP) UIStatusBarCustomItemView$contentsImage, "@@:");	
	}
	else
	{
		class_addMethod($UIStatusBarCustomItemView, @selector(contentsImageForStyle:), (IMP) UIStatusBarCustomItemView$contentsImageForStyle$, "@@:i");
	}
	
	
//	class_addIvar($UIStatusBarCustomItemView, "_itemName", sizeof(NSString*), 0x4, "@");
	objc_registerClassPair($UIStatusBarCustomItemView);
}