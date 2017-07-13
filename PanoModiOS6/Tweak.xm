#import "../PanoMod.h"
#import <notify.h>

static BOOL bluePanoBtn, customText, hideArrow, hideLabel, hideLevelBar, panoZoom, PanoGridOn, hideLabelBG, hideGhostImg, noArrowTail;
static NSString *myText;
static int defaultDirection;
static int PreviewWidth;
static int PreviewHeight;

static void PanoModLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	readBoolOption(@"bluePanoBtn", bluePanoBtn);
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

#define isPanorama (self.cameraMode == 2)

%hook PLCameraView

- (void)_showSettings:(BOOL)settings sender:(id)sender
{
	%orig;
	if (PanoGridOn) {
		if (settings) {
			PLCameraSettingsView *settingsView = MSHookIvar<PLCameraSettingsView *>(self, "_settingsView");
			MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_panoramaGroup").hidden = isPanorama;
			((UISwitch *)MSHookIvar<PLCameraSettingsGroupView *>(settingsView, "_hdrGroup").accessorySwitch).enabled = !isPanorama;
		}
	}
}

- (BOOL)_optionsButtonShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

- (BOOL)_zoomIsAllowed
{
	return panoZoom && isPanorama ? YES : %orig;
}

- (NSInteger)_glyphOrientationForCameraOrientation:(NSInteger)arg1
{
	return (isPanorama && (PanoGridOn || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) ? 1 : %orig;
}

- (BOOL)_gridLinesShouldBeHidden
{
	return isPanorama && PanoGridOn ? NO : %orig;
}

%end

%hook PLCameraPanoramaView

- (id)initWithFrame:(CGRect)frame centerYOffset:(CGFloat)offset panoramaPreviewScale:(CGFloat)scale panoramaPreviewSize:(CGSize)size
{
	self = %orig;
	if (self != nil) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			int direction = MSHookIvar<int>(self, "_direction");
			int trueDirection = direction - 1;
			if (defaultDirection != trueDirection) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[self _arrowWasTapped:nil];
				});
			}
		});
	}
	return self;
}

- (void)updateUI
{
	%orig;
	UIView *labelBG = MSHookIvar<UIView *>(self, "_instructionalTextBackground");
	UIImageView *ghostImg = MSHookIvar<UIImageView *>(self, "_previewGhostImageView");
	labelBG.hidden = hideLabelBG;
	ghostImg.hidden = hideGhostImg;
}

%end

%hook PLCameraPanoramaBrokenArrowView

- (id)initWithFrame:(CGRect)frame
{
	self = %orig;
	if (self) {
		MSHookIvar<UIImageView *>(self, "_arrowTailGlow").hidden = noArrowTail;
		self.hidden = hideArrow;
	}
	return self;
}

- (CGPathRef)_newTailPiecesPathOfWidth:(float *)width
{
	return noArrowTail ? nil : %orig;
}

%end

%hook PLCameraLargeShutterButton

+ (id)backgroundPanoOffPressedImageName
{
	return bluePanoBtn ? @"PLCameraLargeShutterButtonPanoOnPressed_2only_-568h" : %orig;
}

+ (id)backgroundPanoOffImageName
{
	return bluePanoBtn ? @"PLCameraLargeShutterButtonPanoOn_2only_-568h" : %orig;
}

%end

%hook PLCameraController

- (CGSize)panoramaPreviewSize
{
	return CGSizeMake(PreviewWidth, PreviewHeight);
}

%end

%hook PLCameraPanoramaTextLabel

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

%hook PLCameraLevelView

- (id)initWithFrame:(CGRect)frame
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
