#import "../PanoMod.h"
#import <substrate.h>
#include <sys/sysctl.h>

static NSString *getSysInfoByName(const char *typeSpecifier)
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char *answer = (char *)malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return results;
}

static NSString *Model()
{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	return modelName;
}

static NSString *ModelAP()
{
	return [getSysInfoByName("hw.model") stringByReplacingOccurrencesOfString:@"AP" withString:@""];
}

NSMutableDictionary *(*old__ACT_CopyDefaultConfigurationForPanorama)();
NSMutableDictionary *replaced__ACT_CopyDefaultConfigurationForPanorama()
{
	NSMutableDictionary *orig = old__ACT_CopyDefaultConfigurationForPanorama();
	NSString *preFirebreakPath = @"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist";
	NSString *firebreakPath = [NSString stringWithFormat:preFirebreakPath, isiOS7Up ? [NSString stringWithFormat:@"/%@/", ModelAP()] : @"/"];
	NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSMutableDictionary *firebreakDict = [[NSDictionary dictionary] mutableCopy];
	[firebreakDict addEntriesFromDictionary:orig != nil ? orig : [NSDictionary dictionaryWithContentsOfFile:firebreakPath]];
	NSString *model = Model();
	if (is8MPCamDevice) {
		BOOL is8MP = val(prefDict, @"Pano8MP", NO, BOOLEAN);
		setIntegerProperty(firebreakDict, @"ACTFrameWidth", is8MP ? 3264 : 2592)
		setIntegerProperty(firebreakDict, @"ACTFrameHeight", is8MP ? 2448 : 1936)
	}
	setIntegerProperty(firebreakDict, @"ACTPanoramaMaxWidth", val(prefDict, @"PanoramaMaxWidth", isNeedConfigDevice ? 4000 : 10800, INT))
	setIntegerProperty(firebreakDict, @"ACTPanoramaMaxFrameRate", val(prefDict, @"PanoramaMaxFrameRate", (isiPhone4S || isiPhone5Up || isiPadAir || isiPadAir2 || isiPadMini2G || isiPadMini3G) ? 20 : 15, INT))
	setIntegerProperty(firebreakDict, @"ACTPanoramaMinFrameRate", val(prefDict, @"PanoramaMinFrameRate", 15, INT))
	setIntegerProperty(firebreakDict, @"ACTPanoramaBufferRingSize", val(prefDict, @"PanoramaBufferRingSize", 6, INT)) 
	setIntegerProperty(firebreakDict, @"ACTPanoramaPowerBlurBias", val(prefDict, @"PanoramaPowerBlurBias", 30, INT))
	setIntegerProperty(firebreakDict, @"ACTPanoramaPowerBlurSlope", val(prefDict, @"PanoramaPowerBlurSlope", 16, INT))
	if (isiOS7Up) {
		setIntegerProperty(firebreakDict, @"ACTPanoramaBPNRMode", val(prefDict, @"BPNR", 1, INT))
	}
	return firebreakDict;
}

%ctor
{
	MSHookFunction((NSMutableDictionary *)MSFindSymbol(NULL, "_ACT_CopyDefaultConfigurationForPanorama"), (NSMutableDictionary *)replaced__ACT_CopyDefaultConfigurationForPanorama, (NSMutableDictionary **)&old__ACT_CopyDefaultConfigurationForPanorama);
}