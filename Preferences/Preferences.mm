#import "../PanoMod.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <Social/Social.h>

#include <objc/runtime.h>
#include <sys/utsname.h>
#import <notify.h>

static NSString *Model()
{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	return modelName;
}

@interface BannerCell : PSTableCell {
	UILabel *tweakName;
}
@end

@interface PanoFAQViewController : PSViewController <UITableViewDelegate, UITableViewDataSource>
- (UITableView *)tableView;
@end

@interface PanoGuideViewController : PSViewController <UITableViewDelegate, UITableViewDataSource>
- (UITableView *)tableView;
@end

@interface PanoCreditsViewController : PSViewController <UITableViewDelegate, UITableViewDataSource>
- (UITableView *)tableView;
@end

@interface PanoSlidersController : PSListController
@property (nonatomic, retain) PSSpecifier *maxWidthSpec;
@property (nonatomic, retain) PSSpecifier *maxWidthSliderSpec;
@property (nonatomic, retain) PSSpecifier *maxWidthInputSpec;
@property (nonatomic, retain) PSSpecifier *previewWidthSpec;
@property (nonatomic, retain) PSSpecifier *previewWidthSliderSpec;
@property (nonatomic, retain) PSSpecifier *previewWidthInputSpec;
@property (nonatomic, retain) PSSpecifier *previewHeightSpec;
@property (nonatomic, retain) PSSpecifier *previewHeightSliderSpec;
@property (nonatomic, retain) PSSpecifier *previewHeightInputSpec;
@property (nonatomic, retain) PSSpecifier *minFPSSpec;
@property (nonatomic, retain) PSSpecifier *minFPSSliderSpec;
@property (nonatomic, retain) PSSpecifier *minFPSInputSpec;
@property (nonatomic, retain) PSSpecifier *maxFPSSpec;
@property (nonatomic, retain) PSSpecifier *maxFPSSliderSpec;
@property (nonatomic, retain) PSSpecifier *maxFPSInputSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaBufferRingSizeSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaBufferRingSizeSliderSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaBufferRingSizeInputSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurBiasSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurBiasSliderSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurBiasInputSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurSlopeSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurSlopeSliderSpec;
@property (nonatomic, retain) PSSpecifier *PanoramaPowerBlurSlopeInputSpec;
@end

@interface PanoUIController : PSListController
@property (nonatomic, retain) PSSpecifier *hideTextSpec;
@property (nonatomic, retain) PSSpecifier *hideBGSpec;
@property (nonatomic, retain) PSSpecifier *customTextSpec;
@property (nonatomic, retain) PSSpecifier *inputTextSpec;
@property (nonatomic, retain) PSSpecifier *blueButtonDescSpec;
@property (nonatomic, retain) PSSpecifier *blueButtonSwitchSpec;
@property (nonatomic, retain) PSSpecifier *borderSpec;
@property (nonatomic, retain) PSSpecifier *borderDescSpec;
@end

@interface PanoSysController : PSListController
@property (nonatomic, retain) PSSpecifier *LLBPanoDescSpec;
@property (nonatomic, retain) PSSpecifier *LLBPanoSwitchSpec;
@property (nonatomic, retain) PSSpecifier *PanoDarkFixDescSpec;
@property (nonatomic, retain) PSSpecifier *PanoDarkFixSwitchSpec;
@property (nonatomic, retain) PSSpecifier *FMDescSpec;
@property (nonatomic, retain) PSSpecifier *FMSwitchSpec;
@property (nonatomic, retain) PSSpecifier *Pano8MPSpec;
@property (nonatomic, retain) PSSpecifier *Pano8MPDescSpec;
@property (nonatomic, retain) PSSpecifier *BPNRSpec;
@property (nonatomic, retain) PSSpecifier *BPNRDescSpec;
@end

#define kFontSize 14
#define CELL_CONTENT_MARGIN 25
#define PanoModBrief \
@"Enable Panorama on every unsupported devices.\n\
Then Customize the interface and properties of panorama with PanoMod."

#define Id [spec identifier]

#define getSpec(mySpec, string)	if ([Id isEqualToString:string]) \
                			self.mySpec = [spec retain];


static void updateValue(PSListController *self, PSSpecifier *targetSpec, PSSpecifier *sliderSpec, NSString *string)
{
	[targetSpec setProperty:[NSString stringWithFormat:string, [[self readPreferenceValue:sliderSpec] intValue]] forKey:@"footerText"];
  	[self reloadSpecifier:targetSpec animated:NO];
  	[self reloadSpecifier:sliderSpec animated:NO];
}

static void updateFloatValue(PSListController *self, PSSpecifier *targetSpec, PSSpecifier *sliderSpec, NSString *string)
{
	[targetSpec setProperty:[NSString stringWithFormat:string, round([[self readPreferenceValue:sliderSpec] floatValue])] forKey:@"footerText"];
  	[self reloadSpecifier:targetSpec animated:NO];
  	[self reloadSpecifier:sliderSpec animated:NO];
}

static void resetValue(PSListController *self, int intValue, PSSpecifier *spec, PSSpecifier *inputSpec)
{
	[self setPreferenceValue:@(intValue) specifier:spec];
	[self setPreferenceValue:[@(intValue) stringValue] specifier:inputSpec];
	[self reloadSpecifier:spec animated:NO];
	[self reloadSpecifier:inputSpec animated:NO];
}

static void orig(PSListController *self, id value, PSSpecifier *spec)
{
	[self setPreferenceValue:value specifier:spec];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

static CGFloat cellHeight(id self, UITableView *tableView, NSString *string)
{
	CGSize size;
	CGSize maxSize = CGSizeMake(tableView.frame.size.width, MAXFLOAT);
	UIFont *font = [UIFont systemFontOfSize:kFontSize];
	if ([string respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
		NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
		style.lineBreakMode = NSLineBreakByWordWrapping;
		style.alignment = NSTextAlignmentLeft;
		NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:style};
		size = [string boundingRectWithSize:maxSize options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
	} else {
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		size = [string sizeWithFont:font constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
		#pragma clang diagnostic pop
	}
	return ceilf(size.height);
}
				
static void openLink(NSString *url)
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
				
static id rangeFix(int min, int max, id value)
{
	id val;
	int value2 = [value intValue];
	if (value2 > max)
		val = @(max);
	else if (value2 < min)
		val = @(min);
	else
		val = @([value intValue]);
	return val;
}

static id rangeFixFloat(float min, float max, id value)
{
	id val;
	float value2 = [value floatValue];
	if (value2 > max)
		val = @(max);
	else if (value2 < min)
		val = @(min);
	else
		val = @(round(value2));
	return val;
}
									
static void setAvailable(PSListController *self, BOOL available, PSSpecifier *spec)
{
	[spec setProperty:@(available) forKey:@"enabled"];
	[self reloadSpecifier:spec];
}

static void update()
{
	/*if (isiOS7) {
		CFPropertyListRef settings = CFPreferencesCopyValue(CFSTR("CameraStreamInfo"), CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
		CFPreferencesSetValue(CFSTR("CameraStreamInfo"), settings, CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize(CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
	}*/
	system("killall Camera");
	notify_post("com.ps.panomod.roothelper");
}

static NSDictionary *prefDict()
{
	return [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
}

static int integerValueForKey(NSString *key, int defaultValue)
{
	return prefDict()[key] ? [prefDict()[key] intValue] : defaultValue;
}

static void writeIntegerValueForKey(int value, NSString *key)
{
	NSMutableDictionary *dict = [prefDict() mutableCopy] ?: [NSMutableDictionary dictionary];
	[dict setObject:@(value) forKey:key];
	[dict writeToFile:PREF_PATH atomically:YES];
}


@interface actHackPreferenceController : PSListController
@property (nonatomic, retain) PSSpecifier *PanoEnabledSpec;
@end

@implementation actHackPreferenceController

- (id)init
{
	if (self == [super init]) {
		UIButton *heart = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
		[heart setImage:[UIImage imageNamed:@"Heart" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/PanoPreferences.bundle"]] forState:UIControlStateNormal];
		[heart sizeToFit];
		[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:heart] autorelease];
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	[twitter setInitialText:@"#PanoMod by @PoomSmart is awesome!"];
	if (twitter != nil)
		[[self navigationController] presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

- (void)donate:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_DONATE_URL]];
}

- (void)showController:(PSSpecifier *)param
{
	Class controllerClass = objc_getClass([[param identifier] UTF8String]);
	UIViewController *controller = [[[controllerClass alloc] init] autorelease];
	UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
	BOOL moreOptions = [controller respondsToSelector:@selector(reset)];
	UIBarButtonItem *rightBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(commonDismiss)] autorelease];
	[controller navigationItem].rightBarButtonItem = rightBtn;
	if (moreOptions) {
		UIBarButtonItem *leftBtn = [[[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:controller action:@selector(reset)] autorelease];
		[controller navigationItem].leftBarButtonItem = leftBtn;
	}
	nav.modalPresentationStyle = 2;
	[self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)commonDismiss
{
	[self.presentedViewController]dismissViewControllerAnimated:YES completion:nil];
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"PanoPreferences" target:self]];
		for (PSSpecifier *spec in specs) {
			getSpec(PanoEnabledSpec, @"PanoEnabled")
		}
		NSString *model = Model();
		BOOL panoDevice = isiPhone4S || isiPhone5Up || isiPod5 || isiPadAir2;
		if (panoDevice)
			[specs removeObject:self.PanoEnabledSpec];
		_specifiers = [specs copy];
	}
	return _specifiers;
}

@end

@implementation BannerCell

- (id)initWithSpecifier:(PSSpecifier *)specifier
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Banner" specifier:specifier];
	if (self) {
		CGFloat width = 320.0f;
		CGRect frame = CGRectMake(0.0f, -10.0f, width, 60.0f);

		tweakName = [[UILabel alloc] initWithFrame:frame];
		tweakName.numberOfLines = 1;
		tweakName.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		tweakName.font = [UIFont fontWithName:@"HelveticaNeue" size:60.0f];
		tweakName.textColor = [UIColor colorWithRed:0.4f green:0.4f blue:0.49f alpha:1.0f];
		tweakName.shadowColor = [UIColor whiteColor];
		tweakName.shadowOffset = CGSizeMake(0.0f, 1.0f);
		tweakName.text = @"PanoMod";
		tweakName.backgroundColor = [UIColor clearColor];
		tweakName.textAlignment = NSTextAlignmentCenter;
		[self addSubview:tweakName];
	}
    return self;
}

- (void)layoutSubviews
{
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1
{
    return isiOS6 ? 90.0f : 70.0f;
}

@end

@implementation PanoFAQViewController

- (NSString *)title
{
	return @"FAQ";
}

- (UITableView *)tableView
{
    return (UITableView *)self.view;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.autoresizingMask = 1;
	tableView.editing = NO;
	tableView.allowsSelectionDuringEditing = NO;
	self.view = tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0: return @"PanoMod";
		case 1: return @"(iPad) Sometimes camera view flashes frequently when taking Panorama";
		case 2: return @"Panorama sometimes still dark even with \"Pano Dark Fix\" enabled";
		case 3: return @"(iOS 7, unsupported devices) Panorama doesn't work in Lockscreen Camera";
		case 4: return @"Supported iOS Versions";
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PanoFAQCell"];
    
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"PanoFAQCell"] autorelease];
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.font = [UIFont systemFontOfSize:kFontSize];
		cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
	}
    
	switch (indexPath.section)
	{
		case 0:	[cell.textLabel setText:PanoModBrief]; break;
		case 1: [cell.textLabel setText:@"This issue related with AE or Auto Exposure of Panorama, if you lock AE (Long tap the camera preview) will temporary fix the issue."]; break;
		case 2: [cell.textLabel setText:@"This issue related with memory and performance."]; break;
		case 3: [cell.textLabel setText:@"The limitation of hooking methods in iOS 7 causes this."]; break;
		case 4: [cell.textLabel setText:@"iOS 6.0 - 9.1"]; break;
    }
    return cell;
}

@end

@implementation PanoGuideViewController

- (NSString *)title
{
	return @"Guides";
}

- (UITableView *)tableView
{
    return (UITableView *)self.view;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.autoresizingMask = 1;
	tableView.editing = NO;
	tableView.allowsSelectionDuringEditing = NO;
	self.view = tableView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 1: return @"Enable Panorama";
		case 2: return @"Panoramic Images Maximum Width";
		case 3: return @"Preview Width & Preview Height";
		case 4: return @"Min & Max Framerate";
		case 5: return @"ACTPanorama(BufferRingSize, PowerBlurBias, PowerBlurSlope)";
		case 6: return @"Panorama Default Direction";
		case 7: return @"Instructional Text";
		case 8: return @"Enable Zoom";
		case 9: return @"Enable Grid";
		case 10: return @"Blue Button";
		case 11: return @"Panorama Low Light Boost";
		case 12: return @"Fix Dark issue";
		case 13: return @"Ability to Toggle Torch";
		case 14: return @"White Arrow";
		case 15: return @"Blue line in the middle";
		case 16: return @"White Border";
		case 17: return @"Panorama 8 MP";
		case 18: return @"Panorama BPNR Mode";
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   	return 19;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *ident = [NSString stringWithFormat:@"j%li", (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (cell == nil) {
    	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident] autorelease];
    	cell.textLabel.numberOfLines = 0;
    	cell.textLabel.backgroundColor = [UIColor clearColor];
    	cell.textLabel.font = [UIFont systemFontOfSize:kFontSize];
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
	switch (indexPath.section) {
		case 0:
			cell.textLabel.text = @"We will explain each option how they work."; break;
		case 1:
			cell.textLabel.text = @"Only available if iDevice doesn't support Panorama by default, by injecting some code that tell Camera this device supported Panorama."; break;
		case 2:
			cell.textLabel.text = @"Adjust the maximum panoramic image width."; break;
 		case 3:
			cell.textLabel.text = @"Adjust the Panorama Preview sizes in the middle, default value, 306 pixel Width and 86 pixel Height.\nKeep in mind that this function doesn’t work well with iPads when Preview Width is more than the original value."; break;
		case 4:
			cell.textLabel.text = @"Adjust the FPS of Panorama, but keep in mind in that don’t set it too high or too low or you may face the pink preview issue or camera crashing."; break;
		case 5:
			cell.textLabel.text = @"Some Panorama properties, just included them if you want to play around."; break;
		case 6:
			cell.textLabel.text = @"Set the default arrow direction when you enter Panorama mode."; break;
		case 7:
			cell.textLabel.text = @"This is what Panorama talks to you, when you capture Panorama, this function provided some customization including Hide Text, Hide BG (Hide Black translucent background, iOS 6 only) and Custom Text. (Set it to whatever you want)"; break;
		case 8:
			cell.textLabel.text = @"Enabling ability to zoom in Panorama mode.\nNOTE: This affects on panoramic image in iOS 7+"; break;
		case 9:
			cell.textLabel.text = @"Showing grid in Panorama mode."; break;
		case 10:
			cell.textLabel.text = @"iOS 6 only, like \"Better Pano Button\" that changes your Panorama button color for 4-inches Tall-iDevices to blue."; break;
  		case 11:
			cell.textLabel.text = @"Like \"LLBPano\", works only in Low Light Boost-capable iDevices or only iPhone 5, iPhone 5c, and iPod touch 5G, fix dark issue using Low Light Boost method.\nFor iPod touch 5G users, you must have tweak \"LLBiPT5\" installed first."; break;
		case 12:
			cell.textLabel.text = @"For those iDevices without support Low Light Boost feature, this function will fix the dark issue in the another way and it works for all iDevices and you will see the big different in camera brightness/lighting performance.\nBut reason why Apple limits the brightness is simple, to fix Panorama overbright issue that you can face it in daytime."; break;
		case 13:
			cell.textLabel.text = @"Like \"Flashorama\" that allows you to toggle torch using Flash button in Panorama mode.\nSupported for iPhone or iPod with LED-Flash capable."; break;
		case 14:
			cell.textLabel.text = @"The white arrow that follows you when you move around to capture Panorama, you can hide it or remove its tail animation."; break;
		case 15:
			cell.textLabel.text = @"Hiding the blue (iOS 6) or yellow (iOS 7+) horizontal line at the middle of screen, if you don't want it."; break;
		case 16:
			cell.textLabel.text = @"iOS 6 only, Hiding the border crops the small Panorama preview, sometimes this function is recommended to enable when you set Panoramic images maximum width into different values."; break;
		case 17:
			cell.textLabel.text = @"By default, the Panorama sensor resolution is 5 MP, this option can changes the sensor resolution to 8 MP if your device is capable. (iPhone 4S or newer) This makes the panoramic images more clear."; break;
		case 18:
			cell.textLabel.text = @"iOS 7+, \"BPNR\" or Auto exposure adjustments during the pan of Panorama capture, was introduced in iPhone 5s, to even out exposure in scenes where brightness varies across the frame."; break;
  	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return cellHeight(self, tableView, [self tableView:tableView cellForRowAtIndexPath:indexPath].textLabel.text) + CELL_CONTENT_MARGIN;
}

@end

@implementation PanoCreditsViewController

- (NSString *)title
{
	return @"Thanks";
}

- (UITableView *)tableView
{
    return (UITableView *)self.view;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.autoresizingMask = 1;
	tableView.editing = NO;
	tableView.allowsSelectionDuringEditing = NO;
	self.view = tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 14;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	switch (indexPath.row)
	{
		case 0:
			openLink(PS_TWITTER_URL); break;
		case 1:
			openLink(@"twitter://user?screen_name=Pix3lDemon"); break;
		case 2:
			openLink(@"twitter://user?screen_name=BassamKassem1"); break;
		case 3:
			openLink(@"twitter://user?screen_name=H4lfSc0p3R"); break;
		case 4:
			openLink(@"twitter://user?screen_name=iPMisterX"); break;
		case 5:
			openLink(@"twitter://user?screen_name=nenocrack"); break;
		case 6:
			openLink(@"twitter://user?screen_name=Raem0n"); break;
		case 7:
			openLink(@"twitter://user?screen_name=NTD123"); break;
		case 8:
			openLink(@"https://www.facebook.com/itenb?fref=ts"); break;
		case 9:
			openLink(@"twitter://user?screen_name=xtoyou"); break;
		case 10:
			openLink(@"twitter://user?screen_name=n4te2iver"); break;
		case 11:
			openLink(@"twitter://user?screen_name=NavehIDL"); break;
		case 12:
			openLink(@"https://www.facebook.com/omkung?fref=ts"); break;
		case 13:
			openLink(@"twitter://user?screen_name=iPFaHaD"); break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *const ident = [NSString stringWithFormat:@"u%li", (long)indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident] autorelease];
		cell.textLabel.numberOfLines = 0;
		cell.detailTextLabel.numberOfLines = 0;
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:kFontSize + 2];
		cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
	}
	
	#define addPerson(numCase, TextLabel, DetailTextLabel) \
	case numCase: \
	{ \
		cell.detailTextLabel.text = DetailTextLabel; \
		cell.textLabel.text = TextLabel; \
		break; \
	}
	
	switch (indexPath.row)
	{
		addPerson(0, 	@"@PoomSmart (Main Developer)", @"Tested: iPod touch 4G, iPod touch 5G, iPhone 4S, iPad 2G (GSM).")
		addPerson(1, 	@"@Pix3lDemon", 				@"Tested: iPhone 3GS, iPhone 4, iPod touch 4G, iPad 2G, iPad 3G.")
		addPerson(2,	@"@BassamKassem1", 				@"Tested: iPhone 4 GSM.")
		addPerson(3,	@"@H4lfSc0p3R",					@"Tested: iPhone 4 GSM, iPhone 4S, iPod touch 4G.")
		addPerson(4, 	@"@iPMisterX", 					@"Tested: iPhone 3GS.")
		addPerson(5,	@"@nenocrack", 					@"Tested: iPhone 4 GSM.")
		addPerson(6, 	@"@Raemon", 					@"Tested: iPhone 4 GSM, iPad mini 1G (Global).")
		addPerson(7, 	@"@Ntd123",						@"Tested: iPhone 4 GSM.")
		addPerson(8, 	@"Liewlom Bunnag",				@"Tested: iPad 2G (Wi-Fi).")
		addPerson(9, 	@"@Xtoyou",						@"Tested: iPad 3G (Global), iPad mini 2G.")
		addPerson(10, 	@"@n4te2iver",					@"Tested: iPad 4G (Wi-Fi).")
		addPerson(11, 	@"@NavehIDL",					@"Tested: iPad mini 1G (Wi-Fi).")
		addPerson(12, 	@"Srsw Omegax Akrw",			@"Tested: iPad mini 1G (GSM).")
		addPerson(13,	@"@iPFaHaD",					@"Tested: iPhone 4 GSM.")
	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return cellHeight(self, tableView, [self tableView:tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text) + CELL_CONTENT_MARGIN + kFontSize;
}

@end

@implementation PanoSlidersController

- (NSString *)title
{
	return @"Values";
}

- (void)updateCommonValues
{
	updateValue(self, self.maxWidthSpec, self.maxWidthSliderSpec, @"Current Width: %d pixels");
	updateFloatValue(self, self.previewWidthSpec, self.previewWidthSliderSpec, @"Current Width: %.2f pixels");
	updateFloatValue(self, self.previewHeightSpec, self.previewHeightSliderSpec, @"Current Height: %.2f pixels");
	updateValue(self, self.minFPSSpec, self.minFPSSliderSpec, @"Current Framerate: %d FPS");
	updateValue(self, self.maxFPSSpec, self.maxFPSSliderSpec, @"Current Framerate: %d FPS");
	updateValue(self, self.PanoramaBufferRingSizeSpec, self.PanoramaBufferRingSizeSliderSpec, @"Current Value: %d");
	updateValue(self, self.PanoramaPowerBlurBiasSpec, self.PanoramaPowerBlurBiasSliderSpec, @"Current Value: %d");
	updateValue(self, self.PanoramaPowerBlurSlopeSpec, self.PanoramaPowerBlurSlopeSliderSpec, @"Current Value: %d");
}

- (void)reset
{
	NSString *model = Model();
	resetValue(self, isNeedConfigDevice ? 4000 : 10800, self.maxWidthSliderSpec, self.maxWidthInputSpec);
	resetValue(self, (isiPhone4S || isiPhone5Up || isiPadAir || isiPadAir2 || isiPadMini2G || isiPadMini3G) ? 20 : 15, self.maxFPSSliderSpec, self.maxFPSInputSpec);
	resetValue(self, 15, self.minFPSSliderSpec, self.minFPSInputSpec);
	resetValue(self, (isiPhone5Up || isiPad3or4) ? 5 : 7, self.PanoramaBufferRingSizeSliderSpec, self.PanoramaBufferRingSizeInputSpec);

	if (isiPhone5Up || isiPad3or4 || isiPadMini2G || isiPadAir || isiPadAir2) {
		resetValue(self, 15, self.PanoramaPowerBlurSlopeSliderSpec, self.PanoramaPowerBlurSlopeInputSpec);
	} else if (isiPod5 || isiPadMini1G || isiPad2 || isiPod4) {
		resetValue(self, 13, self.PanoramaPowerBlurSlopeSliderSpec, self.PanoramaPowerBlurSlopeInputSpec);
	} else {
		resetValue(self, 20, self.PanoramaPowerBlurSlopeSliderSpec, self.PanoramaPowerBlurSlopeInputSpec);
	}

	resetValue(self, 306, self.previewWidthSliderSpec, self.previewWidthInputSpec);
	resetValue(self, 86, self.previewHeightSliderSpec, self.previewHeightInputSpec);
	resetValue(self, 30, self.PanoramaPowerBlurBiasSliderSpec, self.PanoramaPowerBlurBiasInputSpec);
	
	[self updateCommonValues];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	update();
}

- (void)setWidth:(id)value specifier:(PSSpecifier *)spec
{
	NSString *model = Model();
	value = isSlow ? rangeFix(1000, 4096, value) : rangeFix(3000, 21600, value);
	orig(self, value, spec);
	updateValue(self, self.maxWidthSpec, self.maxWidthSliderSpec, @"Current Width: %d pixels");
	update();
}

- (void)setPreviewWidth:(id)value specifier:(PSSpecifier *)spec
{
	value = rangeFixFloat(100, 576, value);
	orig(self, value, spec);
	updateFloatValue(self, self.previewWidthSpec, self.previewWidthSliderSpec, @"Current Width: %.2f pixels");
	update();
}

- (void)setPreviewHeight:(id)value specifier:(PSSpecifier *)spec
{
	value = rangeFixFloat(40, 576, value);
	orig(self, value, spec);
	updateFloatValue(self, self.previewHeightSpec, self.previewHeightSliderSpec, @"Current Height: %.2f pixels");
	update();
}

- (void)setMinFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.maxFPSSliderSpec] intValue] < [value intValue]) {
		resetValue(self, [value intValue], self.maxFPSSliderSpec, self.maxFPSInputSpec);
	}

	value = rangeFix(1, 30, value);
	orig(self, value, spec);
	updateValue(self, self.maxFPSSpec, self.maxFPSSliderSpec, @"Current Framerate: %d FPS");
	updateValue(self, self.minFPSSpec, self.minFPSSliderSpec, @"Current Framerate: %d FPS");
	update();
}

- (void)setMaxFPS:(id)value specifier:(PSSpecifier *)spec
{
	if ([[self readPreferenceValue:self.minFPSSliderSpec] intValue] > [value intValue]) {
		resetValue(self, [value intValue], self.minFPSSliderSpec, self.minFPSInputSpec);
	}
	
	value = rangeFix(15, 60, value);
	orig(self, value, spec);
	updateValue(self, self.minFPSSpec, self.minFPSSliderSpec, @"Current Framerate: %d FPS");
	updateValue(self, self.maxFPSSpec, self.maxFPSSliderSpec, @"Current Framerate: %d FPS");
	update();
}

- (void)setPanoramaBufferRingSize:(id)value specifier:(PSSpecifier *)spec
{
	value = rangeFix(1, 30, value);
	orig(self, value, spec);
	updateValue(self, self.PanoramaBufferRingSizeSpec, self.PanoramaBufferRingSizeSliderSpec, @"Current Value: %d");
	update();
}

- (void)setPanoramaPowerBlurBias:(id)value specifier:(PSSpecifier *)spec
{
	value = rangeFix(1, 60, value);
	orig(self, value, spec);
	updateValue(self, self.PanoramaPowerBlurBiasSpec, self.PanoramaPowerBlurBiasSliderSpec, @"Current Value: %d");
	update();
}

- (void)setPanoramaPowerBlurSlope:(id)value specifier:(PSSpecifier *)spec
{
	value = rangeFix(1, 60, value);
	orig(self, value, spec);
	updateValue(self, self.PanoramaPowerBlurSlopeSpec, self.PanoramaPowerBlurSlopeSliderSpec, @"Current Value: %d");
	update();
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [[NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"Sliders" target:self]] retain];
		
		for (PSSpecifier *spec in specs) {
			getSpec(maxWidthSpec, @"MaxWidth")
			getSpec(maxWidthSliderSpec, @"MaxWidthSlider")
			getSpec(maxWidthInputSpec, @"MaxWidthInput")
			getSpec(previewWidthSpec, @"PreviewWidth")
			getSpec(previewWidthSliderSpec, @"PreviewWidthSlider")
			getSpec(previewWidthInputSpec, @"PreviewWidthInput")
			getSpec(previewHeightSpec, @"PreviewHeight")
			getSpec(previewHeightSliderSpec, @"PreviewHeightSlider")
			getSpec(previewHeightInputSpec, @"PreviewHeightInput")
			getSpec(minFPSSpec, @"MinFrameRate")
			getSpec(minFPSSliderSpec, @"MinFrameRateSlider")
			getSpec(minFPSInputSpec, @"MinFPSInput")
			getSpec(maxFPSSpec, @"MaxFrameRate")
			getSpec(maxFPSSliderSpec, @"MaxFrameRateSlider")
			getSpec(maxFPSInputSpec, @"MaxFPSInput")
			getSpec(minFPSInputSpec, @"MinFrameRateInput")
			getSpec(PanoramaBufferRingSizeSpec, @"PanoramaBufferRingSize")
			getSpec(PanoramaBufferRingSizeSliderSpec, @"PanoramaBufferRingSizeSlider")
			getSpec(PanoramaBufferRingSizeInputSpec, @"RingSizeInput")
			getSpec(PanoramaPowerBlurBiasSpec, @"PanoramaPowerBlurBias")
			getSpec(PanoramaPowerBlurBiasSliderSpec, @"PanoramaPowerBlurBiasSlider")
			getSpec(PanoramaPowerBlurBiasInputSpec, @"BlurBiasInput")
			getSpec(PanoramaPowerBlurSlopeSpec, @"PanoramaPowerBlurSlope")
			getSpec(PanoramaPowerBlurSlopeSliderSpec, @"PanoramaPowerBlurSlopeSlider")
			getSpec(PanoramaPowerBlurSlopeInputSpec, @"BlurSlopeInput")
		}
        
		NSString *model = Model();
		if (isSlow)
			[self.maxWidthSliderSpec setProperty:@4096 forKey:@"max"];
		else {
			[self.maxWidthSliderSpec setProperty:@21600 forKey:@"max"];
			[self.maxWidthSliderSpec setProperty:@3000 forKey:@"min"];
		}

		[self updateCommonValues];
				
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end

@interface PanoDirectionCell : PSTableCell
@end

@implementation PanoDirectionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier
{
	if (self == [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier]) {
		UISegmentedControl *directions = [[[UISegmentedControl alloc] initWithItems:@[@"Left", @"Right"]] autorelease];
		[directions addTarget:self action:@selector(directionAction:) forControlEvents:UIControlEventValueChanged];
		if (!isiOS7Up) {
			CGRect frame = directions.frame;
			directions.frame = CGRectMake(frame.origin.x, frame.origin.y, 115, 30);
		}
		directions.selectedSegmentIndex = integerValueForKey(@"defaultDirection", 0);
		[self setAccessoryView:directions];
	}
	return self;
}

- (void)directionAction:(UISegmentedControl *)segment
{
	writeIntegerValueForKey(segment.selectedSegmentIndex, @"defaultDirection");
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PreferencesChangedNotification, NULL, NULL, YES);
}

- (SEL)action
{
	return nil;
}

- (id)target
{
	return nil;
}

- (SEL)cellAction
{
	return nil;
}

- (id)cellTarget
{
	return nil;
}

- (void)dealloc
{
	[super dealloc];
}

@end

@implementation PanoUIController

- (void)setTextHide:(id)value specifier:(PSSpecifier *)spec
{
	orig(self, value, spec);
	BOOL specAvailable = ![value boolValue];
	setAvailable(self, specAvailable, self.customTextSpec);
	setAvailable(self, specAvailable, self.inputTextSpec);
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [[NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"UI" target:self]] retain];
		
		for (PSSpecifier *spec in specs) {
			getSpec(hideTextSpec, @"hideText")
			getSpec(hideBGSpec, @"hideBG")
			getSpec(customTextSpec, @"customText")
			getSpec(inputTextSpec, @"inputText")
			getSpec(blueButtonDescSpec, @"blueButtonDesc")
			getSpec(blueButtonSwitchSpec, @"blueButtonSwitch")
			getSpec(borderSpec, @"border")
			getSpec(borderDescSpec, @"borderDesc")
		}
        
		NSString *model = Model();
		if (isiOS7Up) {
			[specs removeObject:self.hideBGSpec];
			[specs removeObject:self.borderSpec];
			[specs removeObject:self.borderDescSpec];
		}
		if (!(isiPhone5Up || isiPod5) || isiOS7Up) {
			[specs removeObject:self.blueButtonDescSpec];
			[specs removeObject:self.blueButtonSwitchSpec];
		}
		
		BOOL specAvailable = ![[self readPreferenceValue:self.hideTextSpec] boolValue];
		setAvailable(self, specAvailable, self.customTextSpec);
		setAvailable(self, specAvailable, self.inputTextSpec);
				
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end

@implementation PanoSysController

- (void)update:(id)value specifier:(PSSpecifier *)spec
{
	orig(self, value, spec);
	update();
}

- (void)fixCelestial:(id)param
{
	//CFPropertyListRef settings = CFPreferencesCopyValue(CFSTR("CameraStreamInfo"), CFSTR("com.apple.celestial"), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
	notify_post("com.ps.panomod.flush");
	//system("killall mediaserverd");
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [[NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"Sys" target:self]] retain];
		
		for (PSSpecifier *spec in specs) {
			getSpec(LLBPanoDescSpec, @"LLBPanoDesc")
			getSpec(LLBPanoSwitchSpec, @"LLBPanoSwitch")
			getSpec(PanoDarkFixDescSpec, @"PanoDarkFixDesc")
			getSpec(PanoDarkFixSwitchSpec, @"PanoDarkFixSwitch")
			getSpec(FMDescSpec, @"FMDesc")
			getSpec(FMSwitchSpec, @"FMSwitch")
			getSpec(Pano8MPSpec, @"8MPs")
			getSpec(Pano8MPDescSpec, @"8MP")
			getSpec(BPNRSpec, @"BPNRs")
			getSpec(BPNRDescSpec, @"BPNR")
		}
        
		NSString *model = Model();
		if (!isiOS7Up || isiPhone5s || isiPhone6 || isiPhone6ss) {
			[specs removeObject:self.BPNRSpec];
			[specs removeObject:self.BPNRDescSpec];
		}
		if (!(isiPhone5 || isiPod5)) {
			[specs removeObject:self.LLBPanoDescSpec];
			[specs removeObject:self.LLBPanoSwitchSpec];
		}
		if (isiPad || isiPod4) {
			[specs removeObject:self.FMDescSpec];
			[specs removeObject:self.FMSwitchSpec];
		}
		if (!is8MPCamDevice) {
			[specs removeObject:self.Pano8MPSpec];
			[specs removeObject:self.Pano8MPDescSpec];
		}
				
		_specifiers = [specs copy];
  	}
	return _specifiers;
}

@end