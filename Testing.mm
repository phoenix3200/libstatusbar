

#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"

#import "LSStatusBarItem.h"


LSStatusBarItem* playItem;

void addPlay()
{
	NSLine();
	
	playItem =  [[LSStatusBarItem alloc] initWithIdentifier: @"libstatusbar.Play" alignment: StatusBarAlignmentLeft];
	playItem.imageName = @"3_WifiBars";//Play";
	
	
	[[$UIApplication sharedApplication] addStatusBarImageNamed: @"Siri"];//Siri"];
	[[$UIApplication sharedApplication] addStatusBarImageNamed: @"Lightning"];//Siri"];
	
}

void playToBT()
{
	NSLine();
	
	playItem.imageName = @"Bluetooth";//Siri";
	
//	[[$UIApplication sharedApplication] removeStatusBarImageNamed: @"Pause"];//Siri"];
//	[[$UIApplication sharedApplication] addStatusBarImageNamed: @"Pause"];//Siri"];

}

LSStatusBarItem* centerItem;

LSStatusBarItem* centerItem2;


void addCenterText()
{
	NSLine();
	
	centerItem = [[LSStatusBarItem alloc] initWithIdentifier: @"libstatusbar.Center" alignment: StatusBarAlignmentCenter];
	//[centerItem setHidesTime: YES];
	centerItem.titleString = @"Test string";

//	centerItem2 = [[LSStatusBarItem alloc] initWithIdentifier: @"libstatusbar.Center2" alignment: StatusBarAlignmentCenter];
//	centerItem2.titleString = @"is a reallly long test string";
	
	NSLine();
}

void modifyCenterText()
{
	//[playItem release];
	centerItem2 = [[LSStatusBarItem alloc] initWithIdentifier: @"libstatusbar.Center2" alignment: StatusBarAlignmentCenter];

	centerItem2.titleString = @"is an even longer test string to fill the screen";
}


void DelayedTesting()
{
	{
		{
			float delay = 8.0f;
			CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) addPlay;
		
			CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
		}
		{
			float delay = 12.0f;
			CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) playToBT;
		
			CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
		}
		{
			float delay = 2.0f;
			CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) addCenterText;
		
			CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
		}
		
		{
			float delay = 16.0f;
			CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) modifyCenterText;
		
			CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
		}
	}
}

__attribute__((constructor)) void TestingStart()
{
	NSLine();
	
	//GETCLASS(SpringBoard);
	GETCLASS(SpringBoard);
	if($SpringBoard)
	{
		DelayedTesting();
	}
}