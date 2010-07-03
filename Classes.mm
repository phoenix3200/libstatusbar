
#import "common.h"
#import "defines.h"

#define CLCLASS(cls) \
	Class $ ## cls
#include "classlist.h"
#undef CLCLASS

void Classes_Fetch()
{
	#define CLCLASS(cls) \
		$ ## cls = objc_getClass(#cls)
	#include "classlist.h"
	#undef CLCLASS
}