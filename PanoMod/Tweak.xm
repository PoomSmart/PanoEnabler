#import "../PanoMod.h"
#import <dlfcn.h>

BOOL Pano8MP;
BOOL PanoDarkFix;

%group Pano8MP

%hook AVCaptureSession

+ (NSDictionary *)avCaptureSessionPlist
{
	NSMutableDictionary *avRoot = [%orig mutableCopy];
	NSMutableArray *avCap = [avRoot[@"AVCaptureDevices"] mutableCopy];
	NSMutableDictionary *index0 = [avCap[0] mutableCopy];
	NSMutableDictionary *presetPhoto = [index0[@"AVCaptureSessionPresetPhoto2592x1936"] mutableCopy];
	if (presetPhoto == nil)
		return %orig;
	NSMutableDictionary *liveSourceOptions = [presetPhoto[@"LiveSourceOptions"] mutableCopy];
	NSDictionary *res = [NSDictionary dictionaryWithObjectsAndKeys:
    									Pano8MP ? @(3264) : @(2592), @"Width",
    									@"420f", @"PixelFormatType",
    									Pano8MP ? @(2448) : @(1936), @"Height", nil];
	[liveSourceOptions setObject:res forKey:@"Sensor"];
	[liveSourceOptions setObject:res forKey:@"Capture"];
	[presetPhoto setObject:liveSourceOptions forKey:@"LiveSourceOptions"];
	[index0 setObject:presetPhoto forKey:@"AVCaptureSessionPresetPhoto2592x1936"];
	[avCap replaceObjectAtIndex:0 withObject:index0];
	[avRoot setObject:avCap forKey:@"AVCaptureDevices"];
	return avRoot;
}

%end

%end

%group PanoDarkFix

%hook AVCaptureFigVideoDevice

- (void)setImageControlMode:(int)mode
{
	%orig((PanoDarkFix && mode == 4) ? 1 : mode);
}

%end

%end

static void PanoModLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	readBoolOption(@"PanoDarkFix", PanoDarkFix);
	readBoolOption(@"Pano8MP", Pano8MP);
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	PanoModLoader();
}

static NSString *Model()
{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	return modelName;
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	PanoModLoader();
	NSString *model = Model();
	if (is8MPCamDevice && !isiOS9Up) {
		%init(Pano8MP);
	}
	%init(PanoDarkFix);
	if (isiOS9Up)
		dlopen("/Library/Application Support/PanoMod/actHackiOS9.dylib", RTLD_LAZY);
	else if (isiOS8)
		dlopen("/Library/Application Support/PanoMod/actHackiOS8.dylib", RTLD_LAZY);
	else if (isiOS7)
		dlopen("/Library/Application Support/PanoMod/actHackiOS7.dylib", RTLD_LAZY);
	else if (isiOS6)
		dlopen("/Library/Application Support/PanoMod/actHackiOS6.dylib", RTLD_LAZY);
	[pool drain];
}