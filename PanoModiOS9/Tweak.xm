#import "../PanoMod.h"
#import <notify.h>

static BOOL customText, hideArrow, hideLabel, hideLevelBar, panoZoom, PanoGridOn, noArrowTail;
static NSString *myText;
static int defaultDirection;
static int PreviewWidth;
static int PreviewHeight;

static void PanoModLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	readBoolOption(@"customText", customText);
	readBoolOption(@"hideArrow", hideArrow);
	readBoolOption(@"hideLabel", hideLabel);
	readBoolOption(@"hideLevelBar", hideLevelBar);
	readBoolOption(@"panoZoom", panoZoom);
	readBoolOption(@"panoGrid", PanoGridOn);
	readBoolOption(@"noArrowTail", noArrowTail);
	readIntOption(@"defaultDirection", defaultDirection, 0);
	readIntOption(@"PreviewWidth", PreviewWidth, 306);
	readIntOption(@"PreviewHeight", PreviewHeight, 86);
	myText = dict[@"myText"];
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	PanoModLoader();
}

#define isPanorama (self._currentMode == 3)

%hook CAMCaptureCapabilities

- (float)maximumVideoZoomFactorForMode:(int)mode device:(int)device
{
	return panoZoom && mode == 3 ? %orig(0, device) : %orig;
}

%end

%hook CAMViewfinderViewController

- (void)_createPanoramaViewControllerIfNecessary
{
	%orig;
	CAMPanoramaViewController *panoramaViewController = MSHookIvar<CAMPanoramaViewController *>(self, "__panoramaViewController");
	CAMPanoramaView *panoramaView = (CAMPanoramaView *)(panoramaViewController.view);
	if (panoramaView != nil) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			int direction = MSHookIvar<int>(panoramaView, "_direction");
			int trueDirection = direction - 1;
			if (defaultDirection != trueDirection) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[panoramaViewController _handleDirectionChange:nil];
				});
			}
		});
	}
}

- (BOOL)_shouldCreateGridViewForMode:(int)mode
{
	return mode == 3 ? PanoGridOn : %orig;
}

%end

%hook CAMPanoramaUtilities

+ (CGSize)previewSize
{
	return CGSizeMake(PreviewWidth, PreviewHeight);
}

%end

%hook CAMPanoramaArrowView

- (id)initWithFrame:(CGRect)frame
{
	self = %orig;
	if (self)
		self.hidden = hideArrow;
	return self;
}

- (CGPathRef)_newTailPiecesPathOfWidth:(float *)width
{
	return noArrowTail ? nil : %orig;
}

%end

%hook CAMPanoramaLabel

- (id)initWithFrame:(CGRect)frame
{
	self = %orig;
	if (self)
		self.hidden = hideLabel;
	return self;
}

- (void)setText:(NSString *)text
{
	%orig((customText && myText != nil) ? myText : text);
}

%end

%hook CAMPanoramaLevelView

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		self.hidden = hideLevelBar;
	return self;
}

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	PanoModLoader();
	%init;
	[pool drain];
}