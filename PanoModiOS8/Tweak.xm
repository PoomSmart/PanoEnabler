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

#define isPanorama (self.cameraMode == 3)

%hook CAMCameraView

- (void)_createOrDestroyPanoramaViewIfNecessary
{
	%orig;
	CAMPanoramaView *panoramaView = MSHookIvar<CAMPanoramaView *>(self, "_panoramaView");
	if (panoramaView != nil) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			int direction = MSHookIvar<int>(panoramaView, "_direction");
			int trueDirection = direction - 1;
			if (defaultDirection != trueDirection) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[panoramaView _arrowWasTapped:nil];
				});
			}
		});
	}
}

- (BOOL)_zoomIsAllowed
{
	return panoZoom && isPanorama ? YES : %orig;
}

- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	return (isPanorama && (PanoGridOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) ? 1 : %orig;
}

- (BOOL)_shouldHideGridView
{
	if (isPanorama && PanoGridOn) {
		MSHookIvar<int>([%c(CAMCaptureController) sharedInstance], "_cameraMode") = 0;
		BOOL r = %orig;
		MSHookIvar<int>([%c(CAMCaptureController) sharedInstance], "_cameraMode") = 3;
		return r;
	}
	return %orig;
}

%end

%hook CAMPadApplicationSpec

- (BOOL)shouldCreatePanoramaView
{
	return YES;
}

%end

%hook CAMCaptureController

- (CGSize)panoramaPreviewSize
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
