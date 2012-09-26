
//#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"
#import "UIStatusBarCustomItem.h"

#import "LSStatusBarItem.h"


//Class $UIStatusBarCustomItem;

int UIStatusBarCustomItem$type(UIStatusBarCustomItem* self, SEL sel)
{
	return 0;
}

int UIStatusBarCustomItem$leftOrder(UIStatusBarCustomItem* self, SEL sel)
{
	if(NSDictionary* properties = [self properties])
	{
		NSNumber* nsalign = [properties objectForKey: @"alignment"];
		StatusBarAlignment alignment = nsalign ? (StatusBarAlignment) [nsalign intValue] : StatusBarAlignmentRight;
		if(alignment & StatusBarAlignmentLeft)
		{
			return 15;
		}
	}
	return 0;
}

Class UIStatusBarCustomItem$viewClass(UIStatusBarCustomItem* self, SEL sel)
{
	return $UIStatusBarCustomItemView;
//	return objc_getClass("UIStatusBarCustomItemView");
//	return objc_getClass("UIStatusBarIndicatorItemView");
}

int UIStatusBarCustomItem$rightOrder(UIStatusBarCustomItem* self, SEL sel)
{
	if(NSDictionary* properties = [self properties])
	{
		NSNumber* nsalign = [properties objectForKey: @"alignment"];
		StatusBarAlignment alignment = nsalign ? (StatusBarAlignment) [nsalign intValue] : StatusBarAlignmentRight;
		if(alignment & StatusBarAlignmentRight)
		{
			return 15;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return 15;
	}
}

int UIStatusBarCustomItem$priority(UIStatusBarCustomItem* self, SEL sel)
{
	return 0;
}

NSString* UIStatusBarCustomItem$description(UIStatusBarCustomItem* self, SEL sel)
{
	return @"UIStatusBarCustomItem <No desc yet>";
}

NSString* UIStatusBarCustomItem$indicatorName(UIStatusBarCustomItem* self, SEL sel)
{
	
	if(NSDictionary* properties = [self properties])
	{
		NSString* name = [properties objectForKey: @"imageName"];
		if(name)
			return name;
	}
	
	NSString* &_indicatorName(MSHookIvar<NSString*>(self, "_indicatorName"));
	return _indicatorName;
}

void UIStatusBarCustomItem$setIndicatorName$(UIStatusBarCustomItem* self, SEL sel, NSString* name)
{
	NSString* &_indicatorName(MSHookIvar<NSString*>(self, "_indicatorName"));
	[_indicatorName release];
	_indicatorName = [name retain];

}


NSDictionary* UIStatusBarCustomItem$properties(UIStatusBarCustomItem* self, SEL sel)
{
	NSDictionary* &_properties(MSHookIvar<NSDictionary*>(self, "_properties"));
	return _properties;
}

void UIStatusBarCustomItem$setProperties$(UIStatusBarCustomItem* self, SEL sel, NSDictionary* properties)
{
	NSDictionary* &_properties(MSHookIvar<NSDictionary*>(self, "_properties"));
	[_properties release];
	_properties = [properties retain];
}


UIStatusBarItemView* UIStatusBarCustomItem$viewForManager$(id self, SEL sel, id manager)
{
	CFMutableDictionaryRef &_views(MSHookIvar<CFMutableDictionaryRef>(self, "_views"));
	if(_views)
	{
		return (UIStatusBarItemView*) CFDictionaryGetValue(_views, (void*) manager);
	}
	else
	{
		return nil;
	}
}

void UIStatusBarCustomItem$setView$forManager$(id self, SEL sel, id view, id manager)
{
	CFMutableDictionaryRef &_views(MSHookIvar<CFMutableDictionaryRef>(self, "_views"));
	if(!_views)
	{
		_views = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	}
	CFDictionarySetValue(_views, (void*) manager, view);
}

void UIStatusBarCustomItem$removeFromSuperview(id key, UIView* view)
{
	if(view)
		[view removeFromSuperview];
}

void UIStatusBarCustomItem$removeAllViews(id self, SEL sel)
{
	CFMutableDictionaryRef &_views(MSHookIvar<CFMutableDictionaryRef>(self, "_views"));
	
	if(_views)
	{
		CFDictionaryApplyFunction(_views, (CFDictionaryApplierFunction) UIStatusBarCustomItem$removeFromSuperview, NULL);
	}
}

void ClassCreate_UIStatusBarCustomItem()
{
	GETCLASS(UIStatusBarItem);
	$UIStatusBarCustomItem = objc_allocateClassPair($UIStatusBarItem, "UIStatusBarCustomItem", 0);
	
	class_addMethod($UIStatusBarCustomItem, @selector(type), (IMP) UIStatusBarCustomItem$type, "i@:");
	class_addMethod($UIStatusBarCustomItem, @selector(leftOrder), (IMP)  UIStatusBarCustomItem$leftOrder, "i@:");
	class_addMethod($UIStatusBarCustomItem, @selector(viewClass), (IMP)  UIStatusBarCustomItem$viewClass, "#@:");
	class_addMethod($UIStatusBarCustomItem, @selector(rightOrder), (IMP)  UIStatusBarCustomItem$rightOrder, "i@:");
	class_addMethod($UIStatusBarCustomItem, @selector(priority), (IMP)  UIStatusBarCustomItem$priority, "i@:");
	class_addMethod($UIStatusBarCustomItem, @selector(description), (IMP)  UIStatusBarCustomItem$description, "@@:");
	
	class_addIvar($UIStatusBarCustomItem, "_views", sizeof(id), 0x4, "@");
	class_addMethod($UIStatusBarCustomItem, @selector(viewForManager:), (IMP) UIStatusBarCustomItem$viewForManager$, "@@:@");
	class_addMethod($UIStatusBarCustomItem, @selector(setView:forManager:), (IMP) UIStatusBarCustomItem$setView$forManager$, "v@:@@");
	
	class_addMethod($UIStatusBarCustomItem, @selector(removeAllViews), (IMP) UIStatusBarCustomItem$removeAllViews, "v@:");
	
	
	class_addIvar($UIStatusBarCustomItem, "_properties", sizeof(id), 0x4, "@");
	
	class_addIvar($UIStatusBarCustomItem, "_indicatorName", sizeof(id), 0x4, "@");
	class_addMethod($UIStatusBarCustomItem, @selector(indicatorName), (IMP)  UIStatusBarCustomItem$indicatorName, "@@:");
	class_addMethod($UIStatusBarCustomItem, @selector(setIndicatorName:), (IMP) UIStatusBarCustomItem$setIndicatorName$, "v@:@");
	
	class_addMethod($UIStatusBarCustomItem, @selector(properties), (IMP)  UIStatusBarCustomItem$properties, "@@:");
	class_addMethod($UIStatusBarCustomItem, @selector(setProperties:), (IMP) UIStatusBarCustomItem$setProperties$, "v@:@");	
	
	objc_registerClassPair($UIStatusBarCustomItem);
	
	CommonLog("Class created")
}
