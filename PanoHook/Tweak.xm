#import <substrate.h>
#import "../PanoMod.h"

CFPropertyListRef (*my_copyRealAnswer)(CFStringRef);
CFPropertyListRef (*orig_copyRealAnswer)(CFStringRef);
CFPropertyListRef hax_copyRealAnswer(CFStringRef key)
{
	if (CFEqual(key, CFSTR("PanoramaCameraCapability")))
		return kCFBooleanTrue;
    return orig_copyRealAnswer(key);
}

CFPropertyListRef (*my_MGCopyAnswer)(CFStringRef);
CFPropertyListRef (*orig_MGCopyAnswer)(CFStringRef);
CFPropertyListRef hax_MGCopyAnswer(CFStringRef key)
{
	if (CFEqual(key, CFSTR("PanoramaCameraCapability")))
		return kCFBooleanTrue;
    return orig_MGCopyAnswer(key);
}

%ctor
{
	if (val([NSDictionary dictionaryWithContentsOfFile:PREF_PATH], @"PanoEnabled", YES, BOOLEAN)) {
		const char *gest = "/usr/lib/libMobileGestalt.dylib";
		if (dlopen(gest, RTLD_LAZY) != NULL) {
			MSImageRef ref = MSGetImageByName(gest);
			if (isiOS6) {
				my_copyRealAnswer = (CFPropertyListRef (*)(CFStringRef))MSFindSymbol(ref, "_copyRealAnswer");
				MSHookFunction(my_copyRealAnswer, hax_copyRealAnswer, &orig_copyRealAnswer);
			} else {
				my_MGCopyAnswer = (CFPropertyListRef (*)(CFStringRef))MSFindSymbol(ref, "_MGCopyAnswer");
				MSHookFunction(my_MGCopyAnswer, hax_MGCopyAnswer, &orig_MGCopyAnswer);
			}
		}
	}
}