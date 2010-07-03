
#define CLCLASS(cls) \
	extern Class $ ## cls

#include "classList.h"
#undef CLCLASS


void Classes_Fetch();