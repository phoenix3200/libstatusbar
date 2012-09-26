

#define TESTING

#import "common.h"
#import "defines.h"

#import "classes.h"

#import "LSStatusBarItem.h"


LSStatusBarItem* playItem;

void addPlay()
{
	SelLog();
	
	playItem =  [[LSStatusBarItem alloc] initWithIdentifier: @"libstatusbar.Play" alignment: StatusBarAlignmentLeft];
	playItem.imageName = @"Play";
}

void playToBT()
{
	SelLog();
	
	playItem.imageName = @"Siri";
}

LSStatusBarItem* centerItem;

LSStatusBarItem* centerItem2;


void addCenterText()
{
	SelLog();
	
	centerItem = [[LSStatusBarItem alloc] initWithIdentifier: @"libstatusbar.Center" alignment: StatusBarAlignmentCenter];
	centerItem.titleString = @"Test string";

	centerItem2 = [[LSStatusBarItem alloc] initWithIdentifier: @"libstatusbar.Center2" alignment: StatusBarAlignmentCenter];
	centerItem2.titleString = @"is a reallly long test string";
}

void modifyCenterText()
{
	//[playItem release];
	
	centerItem2.titleString = @"is an even longer test string to fill the screen";
}


void DelayedTesting()
{
	{
		{
			float delay = 4.0f;
			CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) addPlay;
		
			CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
		}
		{
			float delay = 16.0f;
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
			float delay = 30.0f;
			CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack) modifyCenterText;
		
			CFRunLoopTimerRef waitTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+delay, 0.0f, 0, 0, callback, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), waitTimer, kCFRunLoopCommonModes);
		}
	}
}

__attribute__((constructor)) void TestingStart()
{
	//GETCLASS(SpringBoard);
	GETCLASS(SpringBoard);
	if($SpringBoard)
	{
		DelayedTesting();
	}
}