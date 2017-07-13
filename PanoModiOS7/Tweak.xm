#import "../PanoMod.h"
#import <notify.h>

static BOOL customText, hideArrow, hideLabel, hideLevelBar, panoZoom, PanoGridOn, hideLabelBG, hideGhostImg, noArrowTail;
static NSString *myText;
static int defaultDirection;
static int PreviewWidth;
static int PreviewHeight;

static NSString *Model()
{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	return modelName;
}

static void PanoModLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	readBoolOption(@"customText", customText);
	readBoolOption(@"hideArrow", hideArrow);
	readBoolOption(@"hideLabel", hideLabel);
	readBoolOption(@"hideLevelBar", hideLevelBar);
	readBoolOption(@"panoZoom", panoZoom);
	readBoolOption(@"panoGrid", PanoGridOn);
	readBoolOption(@"hideLabelBG", hideLabelBG);
	readBoolOption(@"hideGhostImg", hideGhostImg);
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

%group iPad

static BOOL padTextHook = NO;

%hook UIDevice

- (NSString *)model
{
	return padTextHook ? @"iPhone" : %orig;
}

%end

%hook PLCameraPanoramaView

- (void)_updateInstructionalText:(NSString *)text
{
	%orig(padTextHook ? [text stringByReplacingOccurrencesOfString:@"iPhone" withString:@"iPad"] : text);
}

%end

%hook PLCameraView

- (void)_createOrDestroyPanoramaViewIfNecessary
{
	padTextHook = YES;
	%orig;
	padTextHook = NO;
}

%end

%end

%hook PLCameraView

- (void)_createOrDestroyPanoramaViewIfNecessary
{
	%orig;
	PLCameraPanoramaView *panoramaView = MSHookIvar<PLCameraPanoramaView *>(self, "_panoramaView");
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

- (BOOL)_gridLinesShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

- (BOOL)_shouldHideGridView
{
	if (isPanorama && PanoGridOn) {
		MSHookIvar<int>([%c(PLCameraController) sharedInstance], "_cameraMode") = 0;
		BOOL r = %orig;
		MSHookIvar<int>([%c(PLCameraController) sharedInstance], "_cameraMode") = 3;
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

%hook PLCameraController

- (CGSize)panoramaPreviewSize
{
	return CGSizeMake(PreviewWidth, PreviewHeight);
}

%end

%hook PLCameraPanoramaBrokenArrowView

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

%hook PLCameraPanoramaView

- (void)updateUI
{
	%orig;
	UIView *labelBG = MSHookIvar<UIView *>(self, "_instructionalTextBackground");
	UIImageView *ghostImg = MSHookIvar<UIImageView *>(self, "_previewGhostImageView");
	labelBG.hidden = hideLabelBG;
	ghostImg.hidden = hideGhostImg;
}

%end

%hook PLCameraPanoramaTextLabel

- (id)initWithFrame:(struct CGRect)frame
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

%hook PLCameraLevelView

- (id)initWithFrame:(struct CGRect)frame
{
	self = %orig;
	if (self)
		self.hidden = hideLevelBar;
	return self;
}

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	PanoModLoader();
	NSString *model = Model();
	if (isiPad) {
		%init(iPad);
	}
	%init;
	[pool drain];
}
