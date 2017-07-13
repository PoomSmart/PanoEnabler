#import "../PanoMod.h"
#include <sys/sysctl.h>

@interface PanoRemover : NSObject
@end

@implementation PanoRemover

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

- (BOOL)removePanoProperties
{
	NSString *model = [self model];
	NSString *modelFile = [self modelFile];
	
	if (isNeedConfigDevice) {
		NSString *platformPathWithFile = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/CameraSetup.plist", modelFile];

		NSMutableDictionary *root = [[NSDictionary dictionaryWithContentsOfFile:platformPathWithFile] mutableCopy];
		if (root == nil) return NO;
		NSMutableDictionary *tuningParameters = [root[@"TuningParameters"] mutableCopy];
		if (tuningParameters == nil) return NO;
		NSMutableDictionary *portTypeBack = [tuningParameters[@"PortTypeBack"] mutableCopy];
		if (portTypeBack == nil) return NO;
    
		for (NSString *key in [portTypeBack allKeys]) {
			NSMutableDictionary *cameraProperties = [portTypeBack[key] mutableCopy];

			#define removeObject(key) \
				[cameraProperties removeObjectForKey:key];

			if (!isiPad)
				removeObject(@"panoramaMaxIntegrationTime")
			removeObject(@"panoramaAEGainThresholdForFlickerZoneIntegrationTimeTransition")
			removeObject(@"panoramaAEIntegrationTimeForUnityGainToMinGainTransition")
			removeObject(@"panoramaAEMinGain")
			removeObject(@"panoramaAEMaxGain")
			if (isiOS7Up) {
				removeObject(@"panoramaAELowerExposureDelta")
				removeObject(@"panoramaAEUpperExposureDelta")
				removeObject(@"panoramaAEMaxPerFrameExposureDelta")
				removeObject(@"PanoramaFaceAEHighKeyCorrection")
				removeObject(@"PanoramaFaceAELowKeyCorrection")
			}
			[portTypeBack setObject:cameraProperties forKey:key];
		}
	
		if (isiOS7Up)
			[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework/%@", modelFile] error:nil];
		else
			[[NSFileManager defaultManager] removeItemAtPath:@"/System/Library/PrivateFrameworks/ACTFramework.framework/firebreak-Configuration.plist" error:nil];
	
		[tuningParameters setObject:portTypeBack forKey:@"PortTypeBack"];
		[root setObject:tuningParameters forKey:@"TuningParameters"];
		[root writeToFile:platformPathWithFile atomically:YES];
	}
    
	NSString *avSession = [NSString stringWithFormat:@"/System/Library/Frameworks/MediaToolbox.framework/%@/AVCaptureSession.plist", modelFile];
	NSMutableDictionary *avRoot = [[NSMutableDictionary dictionaryWithContentsOfFile:avSession] mutableCopy];
   	if (avRoot == nil) return NO;
	NSMutableArray *avCap = [avRoot[@"AVCaptureDevices"] mutableCopy];
   	if (avCap == nil) return NO;
   	NSMutableDictionary *index0 = [avCap[0] mutableCopy];
   	if (index0 == nil) return NO;
   	NSMutableDictionary *preset = [index0[@"AVCaptureSessionPresetPhoto2592x1936"] mutableCopy];
   	if (preset == nil) return isNeedConfigDevice;

	if (isNeedConfigDevice)
		[index0 removeObjectForKey:@"AVCaptureSessionPresetPhoto2592x1936"];
	else {
		NSMutableDictionary *liveSourceOptions = [preset[@"LiveSourceOptions"] mutableCopy];
		[liveSourceOptions setObject:(isiPhone4S || isiPhone5Up || isiPad3or4 || isiPadAir || isiPadMini2G) ? @(20) : @(15) forKey:@"MaxFrameRate"];
		[liveSourceOptions setObject:@15 forKey:@"MinFrameRate"];
		if (is8MPCamDevice) {
			NSDictionary *res = [NSDictionary dictionaryWithObjectsAndKeys:
    									@(2592), @"Width",
    									@"420f", @"PixelFormatType",
    									@(1936), @"Height", nil];
			[liveSourceOptions setObject:res forKey:@"Sensor"];
			[liveSourceOptions setObject:res forKey:@"Capture"];
		}
		[preset setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
		[index0 setObject:preset forKey:@"AVCaptureSessionPresetPhoto2592x1936"];
	}
	[avCap replaceObjectAtIndex:0 withObject:index0];
	[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
	[avRoot writeToFile:avSession atomically:YES];
	
	if (!isNeedConfigDevice) {
		NSString *firebreakFile = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/ACTFramework.framework%@firebreak-Configuration.plist", isiOS7Up ? [NSString stringWithFormat:@"/%@/", modelFile] : @"/"];
		NSMutableDictionary *firebreakDict = [[NSDictionary dictionaryWithContentsOfFile:firebreakFile] mutableCopy];
	
		setIntegerProperty(firebreakDict, @"ACTFrameWidth", 2592)
		setIntegerProperty(firebreakDict, @"ACTFrameHeight", 1936)
		setIntegerProperty(firebreakDict, @"ACTPanoramaMaxWidth", 10800)
		setIntegerProperty(firebreakDict, @"ACTPanoramaMaxFrameRate", (isiPhone4S || isiPhone5Up || isiPad3or4 || isiPadAir || isiPadAir2 || isiPadMini2G) ? 20 : 15)
		setIntegerProperty(firebreakDict, @"ACTPanoramaMinFrameRate", 15)
		setIntegerProperty(firebreakDict, @"ACTPanoramaBufferRingSize", (isiPhone5Up || isiPad3or4) ? 5 : 7) 
		setIntegerProperty(firebreakDict, @"ACTPanoramaPowerBlurBias", 30)
		setIntegerProperty(firebreakDict, @"ACTPanoramaPowerBlurSlope", 16)
		if (isiOS7Up) {
			setIntegerProperty(firebreakDict, @"ACTPanoramaBPNRMode", (int)(isiPhone5s || isiPhone6 || isiPadAir2))
       	}
		[firebreakDict writeToFile:firebreakFile atomically:YES];
	}
	
	return YES;
}

- (BOOL)remove
{
	BOOL success = YES;
	NSLog(@"Removing Panorama Properties.");
	success = [self removePanoProperties];
	if (!success) {
		NSLog(@"Failed removing Panorama Properties.");
		return success;
	}
	NSLog(@"Done!");
	return success;
}

@end

int main(int argc, char **argv, char **envp)
{
	if (isiOS9Up)
		return 0;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	PanoRemover *remover = [[PanoRemover alloc] init];
	BOOL success = [remover remove];
	[remover release];
	[pool release];
	return (success ? 0 : 1);
}