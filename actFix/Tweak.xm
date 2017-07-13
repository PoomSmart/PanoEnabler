#import "../PanoMod.h"
#import <substrate.h>
#import <sys/utsname.h>

static BOOL shouldHook = NO;
static BOOL PanoEnabled;

static void hook(PLIOSurfaceData *jpegData)
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	readBoolOption(@"PanoEnabled", PanoEnabled);
	shouldHook = NO;
	if (PanoEnabled) {
		UIImage *image = [[UIImage alloc] initWithData:jpegData];
		UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
		[image release];
	}
}

%group iOS6

id (*orig_PLCreateThumbnailsFromJPEGData)(PLIOSurfaceData *, id, id, BOOL);
id replaced_PLCreateThumbnailsFromJPEGData(PLIOSurfaceData *jpegData, id r2, id r3, BOOL r4)
{
	if (shouldHook)
		hook(jpegData);
	return orig_PLCreateThumbnailsFromJPEGData(jpegData, r2, r3, r4);
}

%end

%group iOS7

%hook PLImageUtilities

+ (BOOL)generateThumbnailsFromJPEGData:(PLIOSurfaceData *)jpegData
		inputSize:(CGSize)size
		preCropLargeThumbnailSize:(CGSize)size3
		postCropLargeThumbnailSize:(CGSize)size4
		preCropSmallThumbnailSize:(CGSize)size5
		postCropSmallThumbnailSize:(CGSize)size6
		outSmallThumbnailImageRef:(CGImageRef *)ref
		outLargeThumbnailImageRef:(CGImageRef *)ref8
		outLargeThumbnailJPEGData:(id *)data
		generateFiltersBlock:(id)block
{
	if (shouldHook)
		hook(jpegData);
	return %orig;
}

%end

%end

%group Common

%hook PLCameraController

- (void)_panoramaDidStop
{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	shouldHook = isSlow;
	%orig;
}

%end

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init(Common);
	if (isiOS6) {
		%init(iOS6);
		MSHookFunction((void *)MSFindSymbol(NULL, "_PLCreateThumbnailsFromJPEGData"), (void *)replaced_PLCreateThumbnailsFromJPEGData, (void **)&orig_PLCreateThumbnailsFromJPEGData);
	}
	else if (isiOS7) {
		%init(iOS7);
	}
	[pool drain];
}
