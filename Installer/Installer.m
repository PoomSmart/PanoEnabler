#import "../PanoMod.h"
#include <sys/sysctl.h>

@interface PanoInstaller : NSObject
@end

@implementation PanoInstaller

- (NSString *)getSysInfoByName:(char *)typeSpecifier
{
	size_t size;
	sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
	char *answer = (char *)malloc(size);
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	return results;
}

- (NSString *)modelAP
{
	return [self getSysInfoByName:"hw.model"];
}

- (NSString *)model
{
	return [self getSysInfoByName:"hw.machine"];
}

- (NSString *)modelFile
{
	return [[self modelAP] stringByReplacingOccurrencesOfString:@"AP" withString:@""];
}

- (BOOL)addPanoProperties
{
	NSString *model = [self model];
	NSString *modelFile = [self modelFile];
	
	#define setObject(value, key) \
		[cameraProperties setObject:@(value) forKey:key];

	#define setObjectFloat(value, key) \
		[cameraProperties setObject:@(value) forKey:key];

	if (isNeedConfigDevice || isNeedConfigDevice7) {
		NSString *platformPathWithFile = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/CameraSetup.plist", modelFile];
		NSMutableDictionary *root = [[NSDictionary dictionaryWithContentsOfFile:platformPathWithFile] mutableCopy];
		if (root == nil) return NO;
		NSMutableDictionary *tuningParameters = [root[@"TuningParameters"] mutableCopy];
		if (tuningParameters == nil) return NO;
		NSMutableDictionary *portTypeBack = [tuningParameters[@"PortTypeBack"] mutableCopy];
		if (portTypeBack == nil) return NO;

		for (NSString *key in [portTypeBack allKeys]) {
			NSMutableDictionary *cameraProperties = [portTypeBack[key] mutableCopy];
		
			setObject(isiPad ? 17 : 10, @"panoramaMaxIntegrationTime")
			setObject(4096, @"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition")
			setObject(1000, @"panoramaAEIntegrationTimeForUnityGainToMinGainTransition")
			setObject(1024, @"panoramaAEMinGain")
			setObject(4096, @"panoramaAEMaxGain")

			if (isiOS78) {
				setObject(65, @"panoramaAELowerExposureDelta")
				setObject(256, @"panoramaAEUpperExposureDelta")
				setObject(12, @"panoramaAEMaxPerFrameExposureDelta")
				setObjectFloat(0.34999999999999998, @"PanoramaFaceAEHighKeyCorrection")
				setObjectFloat(0.29999999999999999, @"PanoramaFaceAELowKeyCorrection")
			}
			[portTypeBack setObject:cameraProperties forKey:key];
		}

		[tuningParameters setObject:portTypeBack forKey:@"PortTypeBack"];
		[root setObject:tuningParameters forKey:@"TuningParameters"];
		[root writeToFile:platformPathWithFile atomically:YES];
    
    	NSString *firebreakFile = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist", isiOS7Up ? [NSString stringWithFormat:@"/%@/", modelFile] : @"/"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:firebreakFile]) {
			NSLog(@"Adding firebreak-Configuration.plist to system.");
			NSMutableDictionary *insideDict = [[NSMutableDictionary alloc] init];
			setIntegerProperty(insideDict, @"ACTFrameHeight", isNeedConfigDevice ? 720 : 1936)
			setIntegerProperty(insideDict, @"ACTFrameWidth", isNeedConfigDevice ? 960 : 2592)
			setIntegerProperty(insideDict, @"ACTPanoramaMaxWidth", isNeedConfigDevice ? 4000 : 10800)
			setIntegerProperty(insideDict, @"ACTPanoramaDefaultDirection", 1)
			setIntegerProperty(insideDict, @"ACTPanoramaMaxFrameRate", 15)
			setIntegerProperty(insideDict, @"ACTPanoramaMinFrameRate", 15)
			setIntegerProperty(insideDict, @"ACTPanoramaBufferRingSize", 4) 
			setIntegerProperty(insideDict, @"ACTPanoramaPowerBlurBias", 30)
			setIntegerProperty(insideDict, @"ACTPanoramaPowerBlurSlope", 16)
			setIntegerProperty(insideDict, @"ACTPanoramaSliceWidth", 240)
			if (isiOS7Up) {
				setIntegerProperty(insideDict, @"ACTPanoramaBPNRMode", 1)
				NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
        		[[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework/%@", modelFile] withIntermediateDirectories:YES attributes:attr error:nil];
        	}
			[insideDict writeToFile:firebreakFile atomically:YES];
			[insideDict release];
		}
	}

    NSString *avSession = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/AVCaptureSession.plist", modelFile];
    NSMutableDictionary *avRoot = [[NSMutableDictionary dictionaryWithContentsOfFile:avSession] mutableCopy];
    if (avRoot == nil) return NO;
    NSMutableArray *avCap = [avRoot[@"AVCaptureDevices"] mutableCopy];
	if (avCap == nil) return NO;
	NSMutableDictionary *index0 = [avCap[0] mutableCopy];
	if (index0 == nil) return NO;
   	
	if (isNeedConfigDevice) {
		NSDictionary *presetPhoto = index0[@"AVCaptureSessionPresetPhoto"];
		if (presetPhoto == nil) return NO;
		NSMutableDictionary *presetPhotoToAdd = [presetPhoto mutableCopy];
		NSMutableDictionary *liveSourceOptions = [presetPhotoToAdd[@"LiveSourceOptions"] mutableCopy];
		NSDictionary *res = [NSDictionary dictionaryWithObjectsAndKeys:
    									@960, @"Width",
    									@"420f", @"PixelFormatType",
    									@720, @"Height", nil];
		[liveSourceOptions setObject:res forKey:@"Sensor"];
		[liveSourceOptions setObject:res forKey:@"Capture"];
		[liveSourceOptions setObject:res forKey:@"Preview"];
		[presetPhotoToAdd setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
		[index0 setObject:presetPhotoToAdd forKey:@"AVCaptureSessionPresetPhoto2592x1936"];
		[avCap replaceObjectAtIndex:0 withObject:index0];
		[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
		[avRoot writeToFile:avSession atomically:YES];
	}
	
	[self removeFiles];
	
	return YES;
}

- (void)removeFiles
{
	NSFileManager *manager = [NSFileManager defaultManager];
	if (!isiOS7) {
		[manager removeItemAtPath:@"/Library/MobileSubstrate/DynamicLibraries/BackBoardEnv7.dylib" error:nil];
		[manager removeItemAtPath:@"/Library/MobileSubstrate/DynamicLibraries/BackBoardEnv7.plist" error:nil];
	}
	if (isiOS8Up) {
		[manager removeItemAtPath:@"/Library/MobileSubstrate/DynamicLibraries/actFix.dylib" error:nil];
		[manager removeItemAtPath:@"/Library/MobileSubstrate/DynamicLibraries/actFix.plist" error:nil];
	}
}

- (BOOL)install
{
	BOOL success = YES;
	NSLog(@"Adding Panorama Properties.");
	success = [self addPanoProperties];
	if (!success) {
		NSLog(@"Failed adding Panorama Properties.");
		return success;
	}
	NSLog(@"Done!");
	return success;
}

@end

int main(int argc, char **argv, char **envp)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	PanoInstaller *installer = [[PanoInstaller alloc] init];
	BOOL success = [installer install];
	[installer release];
	[pool release];
	return (success ? 0 : 1);
}