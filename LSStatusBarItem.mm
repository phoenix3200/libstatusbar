

//#define TESTING

#import "common.h"
#import "defines.h"

#import "LSStatusBarItem.h"
#import "LSStatusBarClient.h"


#import "classes.h"


NSMutableDictionary* sbitems = nil;

@implementation LSStatusBarItem


+ (void) _updateProperties: (NSMutableDictionary*) dict forIdentifier: (NSString*) identifier
{
	
	if(!sbitems)
	{
		sbitems = [NSMutableDictionary new];
	}
	
	
	NSArray* idArray = [sbitems objectForKey: identifier];
	for(LSStatusBarItem* item in idArray)
	{
		[item _setProperties: dict];
	}
	
}


- (id) initWithIdentifier: (NSString*) identifier alignment: (StatusBarAlignment) alignment
{
	if(!identifier)
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: No identifer specified"];
	}
	
	if(!alignment)
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Alignment not specified"];
	}
	
	/*
	if($UIApplication && ![$UIApplication sharedApplication])
	{
		TRACE_F();
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Wait for UIApp to load!"];
	}*/
	
	if((self = [super init]))
	{
		
		if(!sbitems)
		{
			sbitems = [NSMutableDictionary new];
		}
		
		
		NSMutableArray* idArray = [sbitems objectForKey: identifier];
		LSStatusBarItem* item = idArray ? [idArray count] ? [idArray objectAtIndex: 0] : nil : nil;
		NSMutableDictionary* properties = item ? [item properties] : nil;
		if(!properties)
			properties = [NSMutableDictionary new];
		
		
		// save all the settings
		{
			_identifier = [identifier retain];
			
			[self _setProperties: properties];
			
			NSNumber* align = [_properties objectForKey: @"alignment"];
			if(!align)
			{
				[_properties setObject: [NSNumber numberWithInt: alignment] forKey: @"alignment"];
			}
			else if([align intValue] != alignment)
			{
				[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: You cannot specify a new alignment!"];	
			}
		}
		
		// keep track of StatusBarItem(s)
		{
			
			NSMutableArray* idArray = [sbitems objectForKey: identifier];
			if(!idArray)
			{
				// this creates a retain/release-less NSMutableArray
				idArray = (NSMutableArray*) CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
				[sbitems setObject: idArray forKey: identifier];
				CFRelease(idArray);
			}
		
			if(idArray)
			{
				[idArray addObject: self];
			}
		}
		return self;
	}
	
	return nil;
}


- (void) dealloc
{
	if(sbitems)
	{
		NSMutableArray* idArray = [sbitems objectForKey: _identifier]; 
		
		// kill the current item count
		if(idArray)
		{
			[idArray removeObject: self];
			
			if([idArray count] == 0)
			{
				// item is no longer in use by this process, let the server no
				[[LSStatusBarClient sharedInstance] setProperties: nil forItem: _identifier];
			}
		}
		
		[_identifier release];
		[_properties release];
	}
	
	[super dealloc];
}

- (NSDictionary*) properties
{
	return _properties;
}


- (void) _setProperties: (NSDictionary*) dict
{
	if(dict == _properties)
		return;
	[_properties release];
	if(!dict)
	{
		_properties = [NSMutableDictionary new];
	}
	else
	{
		_properties = [dict mutableCopy];
	}
}


- (StatusBarAlignment) alignment
{
	NSNumber* alignment = [_properties objectForKey: @"alignment"];
	return alignment ? (StatusBarAlignment) [alignment intValue] : StatusBarAlignmentLeft;
}

- (void) setVisible: (BOOL) visible
{
	[_properties setObject: [NSNumber numberWithBool: visible] forKey: @"visible"];
	
	if(!_manualUpdate)
		[self update];
}

- (BOOL) isVisible
{
	NSNumber* visible = [_properties objectForKey: @"visible"];
	return visible ? [visible boolValue] : YES;
}

- (void) setHidesTime: (BOOL) hidesTime
{
	NSNumber* oldTime = [_properties objectForKey: @"imageName"];
	if([oldTime boolValue] != hidesTime)
	{
		[_properties setObject: [NSNumber numberWithBool: hidesTime] forKey: @"hidesTime"];
		
		if(!_manualUpdate)
			[self update];
	}
}

- (BOOL) hidesTime
{
	NSNumber* hidesTime = [_properties objectForKey: @"hidesTime"];
	return hidesTime ? [hidesTime boolValue] : NO;
}


- (void) setImageName: (NSString*) imageName
{
	if(self.alignment & StatusBarAlignmentCenter)
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Cannot use images with a center alignment"];
	}
	
	NSString* oldImageName = [_properties objectForKey: @"imageName"];
	
	if(!oldImageName || ![oldImageName isEqualToString: imageName])
	{
		[_properties setValue: imageName forKey: @"imageName"];	

		if(!_manualUpdate)
			[self update];
	}
}

- (NSString*) imageName
{
	return [_properties objectForKey: @"imageName"];	
}

- (void) setTitleString: (NSString*) string
{
	if(self.alignment & (StatusBarAlignmentLeft | StatusBarAlignmentRight))
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Cannot use a title string with a side alignment"];
	}
	
	NSString* oldTitle = [_properties objectForKey: @"titleString"];
	
	if((!oldTitle && string) || (oldTitle && ![oldTitle isEqualToString: string]))
	{
		NSLog(@"oldTitle = %@, newTitle = %@", oldTitle, string);
		
		[_properties setValue: string forKey: @"titleString"];	

		if(!_manualUpdate)
			[self update];
	}
}

- (void) setCustomViewClass: (NSString*) customViewClass
{
	NSString* oldClass = [_properties objectForKey: @"customViewClass"];
	
	if(oldClass)
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Item already has a custom view class!"];	
	
	[_properties setValue: customViewClass forKey: @"customViewClass"];	
	
	if(!_manualUpdate)
		[self update];
}

- (NSString*) customViewClass
{
	return [_properties objectForKey: @"customViewClass"];
}

- (NSString*) titleString
{
	return [_properties objectForKey: @"titleString"];
}


- (void) setManualUpdate: (BOOL) manualUpdate
{
	_manualUpdate = manualUpdate;
}

- (BOOL) isManualUpdate
{
	return _manualUpdate;
}

- (void) update
{
	SelLog();	
	[[LSStatusBarClient sharedInstance] setProperties: _properties forItem: _identifier];
	
	[LSStatusBarItem _updateProperties: _properties forIdentifier: _identifier];

}


// future API

- (void) setExclusiveToApp: (NSString*) bundleId
{
	[_properties setObject: bundleId forKey: @"exclusiveToApp"];
}

- (NSString*) exclusiveToApp
{
	return [_properties objectForKey: @"exclusiveToApp"];
}

- (void) addTouchDelegate: (id) delegate
{
}

- (void) removeTouchDelegate: (id) delegate
{
}


@end