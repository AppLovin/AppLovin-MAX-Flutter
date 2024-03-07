#import "AppLovinMAX.h"
#import "AppLovinMAXAdView.h"
#import "AppLovinMAXAdViewFactory.h"
#import "AppLovinMAXNativeAdViewFactory.h"

#define ROOT_VIEW_CONTROLLER ([ALUtils topViewControllerFromKeyWindow])

// Internal
@interface UIColor (ALUtils)
+ (nullable UIColor *)al_colorWithHexString:(NSString *)hexString;
@end

@interface NSNumber (ALUtils)
+ (NSNumber *)al_numberWithString:(NSString *)string;
@end

@interface AppLovinMAX()<MAAdDelegate, MAAdViewAdDelegate, MARewardedAdDelegate, MAAdRevenueDelegate>

// Parent Fields
@property (nonatomic,  weak) ALSdk *sdk;
@property (nonatomic, assign, getter=isPluginInitialized) BOOL pluginInitialized;
@property (nonatomic, assign, getter=isSDKInitialized) BOOL sdkInitialized;
@property (nonatomic, strong) ALSdkConfiguration *sdkConfiguration;

// Store these values if pub attempts to set it before initializing
@property (nonatomic, strong, nullable) NSArray<NSString *> *initializationAdUnitIdentifiersToSet;
@property (nonatomic,   copy, nullable) NSString *userIdentifierToSet;
@property (nonatomic, strong, nullable) NSNumber *mutedToSet;
@property (nonatomic, strong, nullable) NSArray<NSString *> *testDeviceIdentifiersToSet;
@property (nonatomic, strong, nullable) NSNumber *verboseLoggingToSet;
@property (nonatomic, strong, nullable) NSNumber *creativeDebuggerEnabledToSet;
@property (nonatomic, strong, nullable) NSNumber *locationCollectionEnabledToSet;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *extraParametersToSet;

@property (nonatomic, strong, nullable) NSNumber *termsAndPrivacyPolicyFlowEnabledToSet;
@property (nonatomic, strong, nullable) NSURL *privacyPolicyURLToSet;
@property (nonatomic, strong, nullable) NSURL *termsOfServiceURLToSet;
@property (nonatomic,   copy, nullable) NSString *debugUserGeographyToSet;

@property (nonatomic, strong, nullable) NSNumber *targetingYearOfBirthToSet;
@property (nonatomic,   copy, nullable) NSString *targetingGenderToSet;
@property (nonatomic, strong, nullable) NSNumber *targetingMaximumAdContentRatingToSet;
@property (nonatomic,   copy, nullable) NSString *targetingEmailToSet;
@property (nonatomic,   copy, nullable) NSString *targetingPhoneNumberToSet;
@property (nonatomic, strong, nullable) NSArray<NSString *> *targetingKeywordsToSet;
@property (nonatomic, strong, nullable) NSArray<NSString *> *targetingInterestsToSet;

// Fullscreen Ad Fields
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAInterstitialAd *> *interstitials;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MARewardedAd *> *rewardedAds;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAAppOpenAd *> *appOpenAds;

// AdView Fields
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAAdView *> *adViews;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAAdFormat *> *adViewAdFormats;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *adViewPositions;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSLayoutConstraint *> *> *adViewConstraints;
@property (nonatomic, strong) NSMutableArray<NSString *> *adUnitIdentifiersToShowAfterCreate;
@property (nonatomic, strong) NSMutableSet<NSString *> *disabledAutoRefreshAdViewAdUnitIdentifiers;
@property (nonatomic, strong) UIView *safeAreaBackground;
@property (nonatomic, strong, nullable) UIColor *publisherBannerBackgroundColor;

@end

@implementation AppLovinMAX
static NSString *const SDK_TAG = @"AppLovinSdk";
static NSString *const TAG = @"AppLovinMAX";

static NSString *const USER_GEOGRAPHY_GDPR = @"G";
static NSString *const USER_GEOGRAPHY_OTHER = @"O";
static NSString *const USER_GEOGRAPHY_UNKNOWN = @"U";

static NSString *const APP_TRACKING_STATUS_NOTDETERMINED = @"N";
static NSString *const APP_TRACKING_STATUS_RESTRICTED = @"R";
static NSString *const APP_TRACKING_STATUS_DENIED = @"D";
static NSString *const APP_TRACKING_STATUS_AUTHORIZED = @"A";
static NSString *const APP_TRACKING_STATUS_UNAVAILABLE = @"U";

static AppLovinMAX *AppLovinMAXShared;

static FlutterMethodChannel *ALSharedChannel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar
{
    ALSharedChannel = [FlutterMethodChannel methodChannelWithName: @"applovin_max" binaryMessenger: [registrar messenger]];
    AppLovinMAX *instance = [[AppLovinMAX alloc] init];
    [registrar addMethodCallDelegate: instance channel: ALSharedChannel];
    
    AppLovinMAXAdViewFactory *adViewFactory = [[AppLovinMAXAdViewFactory alloc] initWithMessenger: [registrar messenger]];
    [registrar registerViewFactory: adViewFactory withId: @"applovin_max/adview"];
    
    AppLovinMAXNativeAdViewFactory *nativeAdViewFactory = [[AppLovinMAXNativeAdViewFactory alloc] initWithMessenger: [registrar messenger]];
    [registrar registerViewFactory: nativeAdViewFactory withId: @"applovin_max/nativeadview"];
}

+ (AppLovinMAX *)shared
{
    return AppLovinMAXShared;
}

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        AppLovinMAXShared = self;
        
        self.interstitials = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.rewardedAds = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.appOpenAds = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViews = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewAdFormats = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewPositions = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewConstraints = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adUnitIdentifiersToShowAfterCreate = [NSMutableArray arrayWithCapacity: 2];
        self.disabledAutoRefreshAdViewAdUnitIdentifiers = [NSMutableSet setWithCapacity: 2];
        self.extraParametersToSet = [NSMutableDictionary dictionaryWithCapacity: 8];

        self.safeAreaBackground = [[UIView alloc] init];
        self.safeAreaBackground.hidden = YES;
        self.safeAreaBackground.backgroundColor = UIColor.clearColor;
        self.safeAreaBackground.translatesAutoresizingMaskIntoConstraints = NO;
        self.safeAreaBackground.userInteractionEnabled = NO;
        [ROOT_VIEW_CONTROLLER.view addSubview: self.safeAreaBackground];
    }
    return self;
}

- (BOOL)isInitialized
{
    return [self isInitialized: nil];
}

- (BOOL)isInitialized:(nullable FlutterResult)result
{
    BOOL isInitialized = [self isPluginInitialized] && [self isSDKInitialized];
    
    if ( result )
    {
        result(@(isInitialized));
    }
    
    return isInitialized;
}

- (void)initializeWithPluginVersion:(NSString *)pluginVersion sdkKey:(NSString *)sdkKey andNotify:(FlutterResult)result
{
    // Guard against running init logic multiple times
    if ( [self isPluginInitialized] )
    {
        result([self initializationMessage]);
        return;
    }
    
    self.pluginInitialized = YES;
    
    [self log: @"Initializing AppLovin MAX Flutter v%@...", pluginVersion];
    
    // If SDK key passed in is empty, check Info.plist
    if ( ![sdkKey al_isValidString] )
    {
        if ( [[NSBundle mainBundle].infoDictionary al_containsValueForKey: @"AppLovinSdkKey"] )
        {
            sdkKey = [NSBundle mainBundle].infoDictionary[@"AppLovinSdkKey"];
        }
        else
        {
            [NSException raise: NSInternalInconsistencyException
                        format: @"Unable to initialize AppLovin SDK - no SDK key provided and not found in Info.plist!"];
        }
    }
    
    ALSdkSettings *settings = [[ALSdkSettings alloc] init];

    // Selective init
    if ( self.initializationAdUnitIdentifiersToSet )
    {
        settings.initializationAdUnitIdentifiers = self.initializationAdUnitIdentifiersToSet;
        self.initializationAdUnitIdentifiersToSet = nil;
    }

    if ( self.termsAndPrivacyPolicyFlowEnabledToSet )
    {
        settings.termsAndPrivacyPolicyFlowSettings.enabled = self.termsAndPrivacyPolicyFlowEnabledToSet.boolValue;
        self.termsAndPrivacyPolicyFlowEnabledToSet = nil;
    }

    if ( self.privacyPolicyURLToSet )
    {
        settings.termsAndPrivacyPolicyFlowSettings.privacyPolicyURL = self.privacyPolicyURLToSet;
        self.privacyPolicyURLToSet = nil;
    }

    if ( self.termsOfServiceURLToSet )
    {
        settings.termsAndPrivacyPolicyFlowSettings.termsOfServiceURL = self.termsOfServiceURLToSet;
        self.termsOfServiceURLToSet = nil;
    }

    if ( self.debugUserGeographyToSet )
    {
        settings.termsAndPrivacyPolicyFlowSettings.debugUserGeography = [self toAppLovinConsentFlowUserGeography: self.debugUserGeographyToSet];
        self.debugUserGeographyToSet = nil;
    }
    
    if ( self.mutedToSet )
    {
        settings.muted = self.mutedToSet;
        self.mutedToSet = nil;
    }

    if ( self.testDeviceIdentifiersToSet )
    {
        settings.testDeviceAdvertisingIdentifiers = self.testDeviceIdentifiersToSet;
        self.testDeviceIdentifiersToSet = nil;
    }
    
    if ( self.verboseLoggingToSet )
    {
        settings.verboseLoggingEnabled = self.verboseLoggingToSet.boolValue;
        self.verboseLoggingToSet = nil;
    }
    
    if ( self.creativeDebuggerEnabledToSet )
    {
        settings.creativeDebuggerEnabled = self.creativeDebuggerEnabledToSet.boolValue;
        self.creativeDebuggerEnabledToSet = nil;
    }
    
    if ( self.locationCollectionEnabledToSet )
    {
        settings.locationCollectionEnabled = self.locationCollectionEnabledToSet.boolValue;
        self.locationCollectionEnabledToSet = nil;
    }
    
    [self setPendingExtraParametersIfNeeded: settings];

    // Initialize SDK
    self.sdk = [ALSdk sharedWithKey: sdkKey settings: settings];
    [self.sdk setPluginVersion: [@"Flutter-" stringByAppendingString: pluginVersion]];
    [self.sdk setMediationProvider: ALMediationProviderMAX];
    
    if ( [self.userIdentifierToSet al_isValidString] )
    {
        self.sdk.userIdentifier = self.userIdentifierToSet;
        self.userIdentifierToSet = nil;
    }
    
    if ( self.targetingYearOfBirthToSet )
    {
        self.sdk.targetingData.yearOfBirth = self.targetingYearOfBirthToSet.intValue <= 0 ? nil : self.targetingYearOfBirthToSet;
        self.targetingYearOfBirthToSet = nil;
    }
    
    if ( self.targetingGenderToSet )
    {
        self.sdk.targetingData.gender = [self toAppLovinGender: self.targetingGenderToSet];
        self.targetingGenderToSet = nil;
    }
    
    if ( self.targetingMaximumAdContentRatingToSet )
    {
        self.sdk.targetingData.maximumAdContentRating = [self toAppLovinAdContentRating: self.targetingMaximumAdContentRatingToSet];
        self.targetingMaximumAdContentRatingToSet = nil;
    }
    
    if ( self.targetingEmailToSet )
    {
        self.sdk.targetingData.email = self.targetingEmailToSet;
        self.targetingEmailToSet = nil;
    }
    
    if ( self.targetingPhoneNumberToSet )
    {
        self.sdk.targetingData.phoneNumber = self.targetingPhoneNumberToSet;
        self.targetingPhoneNumberToSet = nil;
    }
    
    if ( self.targetingKeywordsToSet )
    {
        self.sdk.targetingData.keywords = self.targetingKeywordsToSet;
        self.targetingKeywordsToSet = nil;
    }
    
    if ( self.targetingInterestsToSet )
    {
        self.sdk.targetingData.interests = self.targetingInterestsToSet;
        self.targetingInterestsToSet = nil;
    }

    [self.sdk initializeSdkWithCompletionHandler:^(ALSdkConfiguration *configuration)
     {
        [self log: @"SDK initialized"];
        
        self.sdkConfiguration = configuration;
        self.sdkInitialized = YES;
        
        result([self initializationMessage]);
    }];
}

- (NSDictionary<NSString *, id> *)initializationMessage
{
    NSMutableDictionary<NSString *, id> *message = [NSMutableDictionary dictionaryWithCapacity: 5];
    
    if ( self.sdkConfiguration )
    {
        message[@"consentDialogState"] = @(self.sdkConfiguration.consentDialogState);
        message[@"countryCode"] = self.sdkConfiguration.countryCode;
        message[@"isTestModeEnabled"] = @(self.sdkConfiguration.isTestModeEnabled);
        message[@"consentFlowUserGeography"] = [self fromAppLovinConsentFlowUserGeography: self.sdkConfiguration.consentFlowUserGeography];
        message[@"appTrackingStatus"] = [self fromAppLovinAppTrackingStatus: self.sdkConfiguration.appTrackingTransparencyStatus];
    }
    else
    {
        message[@"consentDialogState"] = @(ALConsentDialogStateUnknown);
    }
    
    return message;
}

#pragma mark - General Public API

- (void)isTablet:(FlutterResult)result
{
    result(@([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad));
}

- (void)showMediationDebugger
{
    if ( !_sdk )
    {
        NSString *errorMessage = @"Failed to show mediation debugger - please ensure the AppLovin MAX Unity Plugin has been initialized by calling 'AppLovinMAX.initialize(...);'!";
        [self log: errorMessage];
        
        return;
    }
    
    [self.sdk showMediationDebugger];
}

- (void)getConsentDialogState:(FlutterResult)result
{
    if ( ![self isInitialized] )
    {
        result(@(ALConsentDialogStateUnknown));
        
        return;
    }
    
    result(@(self.sdkConfiguration.consentDialogState));
}

- (void)setHasUserConsent:(BOOL)hasUserConsent
{
    [ALPrivacySettings setHasUserConsent: hasUserConsent];
}

- (void)hasUserConsent:(FlutterResult)result
{
    result(@([ALPrivacySettings hasUserConsent]));
}

- (void)setIsAgeRestrictedUser:(BOOL)isAgeRestrictedUser
{
    [ALPrivacySettings setIsAgeRestrictedUser: isAgeRestrictedUser];
}

- (void)isAgeRestrictedUser:(FlutterResult)result
{
    result(@([ALPrivacySettings isAgeRestrictedUser]));
}

- (void)setDoNotSell:(BOOL)doNotSell
{
    [ALPrivacySettings setDoNotSell: doNotSell];
}

- (void)isDoNotSell:(FlutterResult)result
{
    result(@([ALPrivacySettings isDoNotSell]));
}

- (void)setUserId:(NSString *)userId
{
    if ( [self isPluginInitialized] )
    {
        self.sdk.userIdentifier = userId;
        self.userIdentifierToSet = nil;
    }
    else
    {
        self.userIdentifierToSet = userId;
    }
}

- (void)setMuted:(BOOL)muted
{
    if ( [self isPluginInitialized] )
    {
        self.sdk.settings.muted = muted;
        self.mutedToSet = nil;
    }
    else
    {
        self.mutedToSet = @(muted);
    }
}

- (void)setVerboseLogging:(BOOL)enabled
{
    if ( [self isPluginInitialized] )
    {
        self.sdk.settings.verboseLoggingEnabled = enabled;
        self.verboseLoggingToSet = nil;
    }
    else
    {
        self.verboseLoggingToSet = @(enabled);
    }
}

- (void)setCreativeDebuggerEnabled:(BOOL)enabled
{
    if ( [self isPluginInitialized] )
    {
        self.sdk.settings.creativeDebuggerEnabled = enabled;
        self.creativeDebuggerEnabledToSet = nil;
    }
    else
    {
        self.creativeDebuggerEnabledToSet = @(enabled);
    }
}

- (void)setTestDeviceAdvertisingIds:(NSArray<NSString *> *)testDeviceAdvertisingIds
{
    if ( [self isPluginInitialized] )
    {
        self.sdk.settings.testDeviceAdvertisingIdentifiers = testDeviceAdvertisingIds;
        self.testDeviceIdentifiersToSet = nil;
    }
    else
    {
        self.testDeviceIdentifiersToSet = testDeviceAdvertisingIds;
    }
}

- (void)setLocationCollectionEnabled:(BOOL)enabled
{
    if ( [self isPluginInitialized] )
    {
        self.sdk.settings.locationCollectionEnabled = enabled;
        self.locationCollectionEnabledToSet = nil;
    }
    else
    {
        self.locationCollectionEnabledToSet = @(enabled);
    }
}

- (void)setExtraParameter:(NSString *)key value:(NSString *)value
{
    if ( ![key al_isValidString] )
    {
        [self log: @"[%@] Failed to set extra parameter for nil or empty key: %@", TAG, key];
        return;
    }

    if ( self.sdk )
    {
        ALSdkSettings *settings = self.sdk.settings;
        [settings setExtraParameterForKey: key value: ( value != (id) [NSNull null] ) ? value : nil];
        [self setPendingExtraParametersIfNeeded: settings];
    }
    else
    {
        self.extraParametersToSet[key] = value;
    }
}

- (void)setInitializationAdUnitIds:(NSArray<NSString *> *)adUnitIds
{
    self.initializationAdUnitIdentifiersToSet = adUnitIds;
}

#pragma mark - MAX Terms and Privacy Policy Flow

- (void)setTermsAndPrivacyPolicyFlowEnabled:(BOOL)enabled
{
    self.termsAndPrivacyPolicyFlowEnabledToSet = @(enabled);
}

- (void)setPrivacyPolicyUrl:(NSString *)urlString
{
    self.privacyPolicyURLToSet = [NSURL URLWithString: urlString];
}

- (void)setTermsOfServiceUrl:(NSString *)urlString
{
    self.termsOfServiceURLToSet = [NSURL URLWithString: urlString];
}

- (void)setConsentFlowDebugUserGeography:(NSString *)userGeography
{
    self.debugUserGeographyToSet = userGeography;
}

- (void)showCmpForExistingUser:(FlutterResult)result
{
    if ( ![self isPluginInitialized] )
    {
        [self logUninitializedAccessError: @"showCmpForExistingUser" withResult: result];
        return;
    }

    [self.sdk.cmpService showCMPForExistingUserWithCompletion:^(ALCMPError * _Nullable error) {
        
        if ( !error )
        {
            result(nil);
            return;
        }

        result(@{@"code" : @(error.code),
                 @"message" : error.message ?: @"",
                 @"cmpCode" : @(error.cmpCode),
                 @"cmpMessage" : error.cmpMessage ?: @""});
    }];
}

- (void)hasSupportedCmp:(FlutterResult)result
{
    if ( ![self isPluginInitialized] )
    {
        [self logUninitializedAccessError: @"hasSupportedCmp" withResult: result];
        return;
    }

    result(@([self.sdk.cmpService hasSupportedCMP]));
}

#pragma mark - Data Passing

- (void)setTargetingDataYearOfBirth:(nullable NSNumber *)yearOfBirth
{
    if ( !self.sdk )
    {
        self.targetingYearOfBirthToSet = yearOfBirth;
        return;
    }
    
    if ( yearOfBirth )
    {
        self.sdk.targetingData.yearOfBirth = yearOfBirth.intValue <= 0 ? nil : yearOfBirth;
    }
    else
    {
        self.sdk.targetingData.yearOfBirth = nil;
    }
}

- (void)setTargetingDataGender:(nullable NSString *)gender
{
    if ( !self.sdk )
    {
        self.targetingGenderToSet = gender;
        return;
    }
    
    self.sdk.targetingData.gender = [self toAppLovinGender: gender];
}

- (void)setTargetingDataMaximumAdContentRating:(nullable NSNumber *)maximumAdContentRating
{
    if ( !self.sdk )
    {
        self.targetingMaximumAdContentRatingToSet = maximumAdContentRating;
        return;
    }
    
    self.sdk.targetingData.maximumAdContentRating = [self toAppLovinAdContentRating: maximumAdContentRating];
}

- (void)setTargetingDataEmail:(nullable NSString *)email
{
    if ( !self.sdk )
    {
        self.targetingEmailToSet = email;
        return;
    }
    
    self.sdk.targetingData.email = email;
}

- (void)setTargetingDataPhoneNumber:(nullable NSString *)phoneNumber
{
    if ( !self.sdk )
    {
        self.targetingPhoneNumberToSet = phoneNumber;
        return;
    }
    
    self.sdk.targetingData.phoneNumber = phoneNumber;
}

- (void)setTargetingDataKeywords:(nullable NSArray<NSString *> *)keywords
{
    if ( !self.sdk )
    {
        self.targetingKeywordsToSet = keywords;
        return;
    }
    
    self.sdk.targetingData.keywords = keywords;
}

- (void)setTargetingDataInterests:(nullable NSArray<NSString *> *)interests
{
    if ( !self.sdk )
    {
        self.targetingInterestsToSet = interests;
        return;
    }
    
    self.sdk.targetingData.interests = interests;
}

- (void)clearAllTargetingData
{
    if ( !self.sdk )
    {
        [self logUninitializedAccessError: @"clearAllTargetingData"];
        return;
    }
    
    [self.sdk.targetingData clearAll];
}

#pragma mark - Banners

- (void)createBannerForAdUnitIdentifier:(NSString *)adUnitIdentifier position:(NSString *)position
{
    [self createAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT atPosition: position];
}

- (void)setBannerBackgroundColorForAdUnitIdentifier:(NSString *)adUnitIdentifier color:(NSString *)hexColorCode
{
    [self setAdViewBackgroundColorForAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT hexColorCode: hexColorCode];
}

- (void)setBannerPlacementForAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement
{
    [self setAdViewPlacement: placement forAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)updateBannerPositionForAdUnitIdentifier:(NSString *)adUnitIdentifier position:(NSString *)position
{
    [self updateAdViewPosition: position forAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)setBannerExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(NSString *)value
{
    [self setAdViewExtraParameterForAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT key: key value: value];
}

- (void)showBannerForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self showAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)hideBannerForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self hideAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)startBannerAutoRefreshForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self startAdViewAutoRefreshForAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)stopBannerAutoRefreshForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self stopAdViewAutoRefreshForAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)loadBannerForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self loadAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)destroyBannerForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self destroyAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)getAdaptiveBannerHeightForWidth:(CGFloat)width andNotify:(FlutterResult)result
{
    result(@([DEVICE_SPECIFIC_ADVIEW_AD_FORMAT adaptiveSizeForWidth: width].height));
}

#pragma mark - MRECs

- (void)createMRecForAdUnitIdentifier:(NSString *)adUnitIdentifier position:(NSString *)position
{
    [self createAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec atPosition: position];
}

- (void)setMRecPlacementForAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement
{
    [self setAdViewPlacement: placement forAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)updateMRecPositionForAdUnitIdentifier:(NSString *)adUnitIdentifier position:(NSString *)position
{
    [self updateAdViewPosition: position forAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)setMRecExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(NSString *)value
{
    [self setAdViewExtraParameterForAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec key: key value: value];
}

- (void)showMRecForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self showAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)hideMRecForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self hideAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)startMRecAutoRefreshForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self startAdViewAutoRefreshForAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)stopMRecAutoRefreshForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self stopAdViewAutoRefreshForAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)loadMRecForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self loadAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)destroyMRecForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self destroyAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

#pragma mark - Interstitials

- (void)loadInterstitialForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    [interstitial setExtraParameterForKey: @"disable_auto_retries" value: @"true"];
    
    [interstitial loadAd];
}

- (void)isInterstitialReadyForAdUnitIdentifier:(NSString *)adUnitIdentifier result:(FlutterResult)result
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    result(@([interstitial isReady]));
}

- (void)showInterstitialForAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement customData:(NSString *)customData
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    [interstitial showAdForPlacement: placement customData: customData];
}

- (void)setInterstitialExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(NSString *)value
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    [interstitial setExtraParameterForKey: key value: value];
}

#pragma mark - Rewarded

- (void)loadRewardedAdForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    [rewardedAd loadAd];
}

- (void)isRewardedAdReadyForAdUnitIdentifier:(NSString *)adUnitIdentifier result:(FlutterResult)result
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    result(@([rewardedAd isReady]));
}

- (void)showRewardedAdForAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement customData:(NSString *)customData
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    [rewardedAd showAdForPlacement: placement customData: customData];
}

- (void)setRewardedAdExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(NSString *)value
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    [rewardedAd setExtraParameterForKey: key value: value];
}

#pragma mark - App Open Ad

- (void)loadAppOpenAdForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MAAppOpenAd *appOpenAd = [self retrieveAppOpenAdForAdUnitIdentifier: adUnitIdentifier];
    [appOpenAd loadAd];
}

- (void)isAppOpenAdReadyForAdUnitIdentifier:(NSString *)adUnitIdentifier result:(FlutterResult)result
{
    MAAppOpenAd *appOpenAd = [self retrieveAppOpenAdForAdUnitIdentifier: adUnitIdentifier];
    result(@([appOpenAd isReady]));
}

- (void)showAppOpenAdForAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement customData:(NSString *)customData
{
    MAAppOpenAd *appOpenAd = [self retrieveAppOpenAdForAdUnitIdentifier: adUnitIdentifier];
    [appOpenAd showAdForPlacement: placement customData: customData];
}

- (void)setAppOpenAdExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(NSString *)value
{
    MAAppOpenAd *appOpenAd = [self retrieveAppOpenAdForAdUnitIdentifier: adUnitIdentifier];
    [appOpenAd setExtraParameterForKey: key value: value];
}

#pragma mark - Ad Callbacks

- (void)didLoadAd:(MAAd *)ad
{
    NSString *name;
    MAAdFormat *adFormat = ad.format;
    if ( [adFormat isAdViewAd] )
    {
        MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: ad.adUnitIdentifier adFormat: adFormat];
        // An ad is now being shown, enable user interaction.
        adView.userInteractionEnabled = YES;
        
        name = ( MAAdFormat.mrec == adFormat ) ? @"OnMRecAdLoadedEvent" : @"OnBannerAdLoadedEvent";
        [self positionAdViewForAd: ad];
        
        // Do not auto-refresh by default if the ad view is not showing yet (e.g. first load during app launch and publisher does not automatically show banner upon load success)
        // We will resume auto-refresh in -[MAUnityAdManager showBannerWithAdUnitIdentifier:].
        if ( adView && [adView isHidden] )
        {
            [adView stopAutoRefresh];
        }
    }
    else if ( MAAdFormat.interstitial == adFormat )
    {
        name = @"OnInterstitialLoadedEvent";
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        name = @"OnRewardedAdLoadedEvent";
    }
    else if ( MAAdFormat.appOpen == adFormat )
    {
        name = @"OnAppOpenAdLoadedEvent";
    }
    else
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendEventWithName: name body: [self adInfoForAd: ad]];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    if ( !adUnitIdentifier )
    {
        [self log: @"adUnitIdentifier cannot be nil from %@", [NSThread callStackSymbols]];
        return;
    }
    
    NSString *name;
    if ( self.adViews[adUnitIdentifier] )
    {
        name = ( MAAdFormat.mrec == self.adViewAdFormats[adUnitIdentifier] ) ? @"OnMRecAdLoadFailedEvent" : @"OnBannerAdLoadFailedEvent";
    }
    else if ( self.interstitials[adUnitIdentifier] )
    {
        name = @"OnInterstitialLoadFailedEvent";
    }
    else if ( self.rewardedAds[adUnitIdentifier] )
    {
        name = @"OnRewardedAdLoadFailedEvent";
    }
    else if ( self.appOpenAds[adUnitIdentifier] )
    {
        name = @"OnAppOpenAdLoadFailedEvent";
    }
    else
    {
        [self log: @"invalid adUnitId from %@", [NSThread callStackSymbols]];
        return;
    }
    
    [self sendEventWithName: name body: [self adLoadFailedInfoForAdUnitIdentifier: adUnitIdentifier withError: error]];
}

- (void)didClickAd:(MAAd *)ad
{
    NSString *name;
    MAAdFormat *adFormat = ad.format;
    if ( MAAdFormat.banner == adFormat || MAAdFormat.leader == adFormat )
    {
        name = @"OnBannerAdClickedEvent";
    }
    else if ( MAAdFormat.mrec == adFormat )
    {
        name = @"OnMRecAdClickedEvent";
    }
    else if ( MAAdFormat.interstitial == adFormat )
    {
        name = @"OnInterstitialClickedEvent";
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        name = @"OnRewardedAdClickedEvent";
    }
    else if ( MAAdFormat.appOpen == adFormat )
    {
        name = @"OnAppOpenAdClickedEvent";
    }
    else
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendEventWithName: name body: [self adInfoForAd: ad]];
}

- (void)didDisplayAd:(MAAd *)ad
{
    // BMLs do not support [DISPLAY] events in Unity
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.interstitial && adFormat != MAAdFormat.rewarded && adFormat != MAAdFormat.appOpen ) return;
    
    NSString *name;
    if ( MAAdFormat.interstitial == adFormat )
    {
        name = @"OnInterstitialDisplayedEvent";
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        name = @"OnRewardedAdDisplayedEvent";
    }
    else // APP OPEN
    {
        name = @"OnAppOpenAdDisplayedEvent";
    }
    
    [self sendEventWithName: name body: [self adInfoForAd: ad]];
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error
{
    // BMLs do not support [DISPLAY] events in Unity
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.interstitial && adFormat != MAAdFormat.rewarded && adFormat != MAAdFormat.appOpen ) return;
    
    NSString *name;
    if ( MAAdFormat.interstitial == adFormat )
    {
        name = @"OnInterstitialAdFailedToDisplayEvent";
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        name = @"OnRewardedAdFailedToDisplayEvent";
    }
    else // APP OPEN
    {
        name = @"OnAppOpenAdFailedToDisplayEvent";
    }
    
    [self sendEventWithName: name body: [self adDisplayFailedInfoForAd: ad withError: error]];
}

- (void)didHideAd:(MAAd *)ad
{
    // BMLs do not support [HIDDEN] events in Unity
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.interstitial && adFormat != MAAdFormat.rewarded && adFormat != MAAdFormat.appOpen ) return;
    
    NSString *name;
    if ( MAAdFormat.interstitial == adFormat )
    {
        name = @"OnInterstitialHiddenEvent";
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        name = @"OnRewardedAdHiddenEvent";
    }
    else // APP OPEN
    {
        name = @"OnAppOpenAdHiddenEvent";
    }
    
    [self sendEventWithName: name body: [self adInfoForAd: ad]];
}

- (void)didExpandAd:(MAAd *)ad
{
    MAAdFormat *adFormat = ad.format;
    if ( ![adFormat isAdViewAd] )
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendEventWithName: ( MAAdFormat.mrec == adFormat ) ? @"OnMRecAdExpandedEvent" : @"OnBannerAdExpandedEvent"
                       body: [self adInfoForAd: ad]];
}

- (void)didCollapseAd:(MAAd *)ad
{
    MAAdFormat *adFormat = ad.format;
    if ( ![adFormat isAdViewAd] )
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendEventWithName: ( MAAdFormat.mrec == adFormat ) ? @"OnMRecAdCollapsedEvent" : @"OnBannerAdCollapsedEvent"
                       body: [self adInfoForAd: ad]];
}

- (void)didPayRevenueForAd:(MAAd *)ad
{
    NSString *name;
    MAAdFormat *adFormat = ad.format;
    if ( MAAdFormat.banner == adFormat || MAAdFormat.leader == adFormat )
    {
        name = @"OnBannerAdRevenuePaid";
    }
    else if ( MAAdFormat.mrec == adFormat )
    {
        name = @"OnMRecAdRevenuePaid";
    }
    else if ( MAAdFormat.interstitial == adFormat )
    {
        name = @"OnInterstitialAdRevenuePaid";
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        name = @"OnRewardedAdRevenuePaid";
    }
    else if ( MAAdFormat.appOpen == adFormat )
    {
        name = @"OnAppOpenAdRevenuePaid";
    }
    else
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendEventWithName: name body: [self adInfoForAd: ad]];
}

- (void)didCompleteRewardedVideoForAd:(MAAd *)ad
{
    // This event is not forwarded
}

- (void)didStartRewardedVideoForAd:(MAAd *)ad
{
    // This event is not forwarded
}

- (void)didRewardUserForAd:(MAAd *)ad withReward:(MAReward *)reward
{
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.rewarded )
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    NSMutableDictionary *body = [@{@"rewardLabel": reward.label ?: @"",
                                   @"rewardAmount": @(reward.amount)} mutableCopy];
    [body addEntriesFromDictionary: [self adInfoForAd: ad]];
    
    [self sendEventWithName: @"OnRewardedAdReceivedRewardEvent" body: body];
}

#pragma mark - Internal Methods

- (void)createAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat atPosition:(NSString *)adViewPosition
{
    [self log: @"Creating %@ with ad unit identifier \"%@\" and position: \"%@\"", adFormat, adUnitIdentifier, adViewPosition];
    
    // Retrieve ad view from the map
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat atPosition: adViewPosition];
    adView.hidden = YES;
    self.safeAreaBackground.hidden = YES;
    
    // Position ad view immediately so if publisher sets color before ad loads, it will not be the size of the screen
    self.adViewAdFormats[adUnitIdentifier] = adFormat;
    [self positionAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    
    [adView loadAd];
    
    // The publisher may have requested to show the banner before it was created. Now that the banner is created, show it.
    if ( [self.adUnitIdentifiersToShowAfterCreate containsObject: adUnitIdentifier] )
    {
        [self showAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        [self.adUnitIdentifiersToShowAfterCreate removeObject: adUnitIdentifier];
    }
}

- (void)setAdViewBackgroundColorForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat hexColorCode:(NSString *)hexColorCode
{
    [self log: @"Setting %@ with ad unit identifier \"%@\" to color: \"%@\"", adFormat, adUnitIdentifier, hexColorCode];
    
    // In some cases, black color may get redrawn on each frame update, resulting in an undesired flicker
    UIColor *convertedColor;
    if ( [hexColorCode containsString: @"FF000000"] )
    {
        convertedColor = [UIColor al_colorWithHexString: @"FF000001"];
    }
    else
    {
        convertedColor = [UIColor al_colorWithHexString: hexColorCode];
    }
    
    MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    self.publisherBannerBackgroundColor = convertedColor;
    self.safeAreaBackground.backgroundColor = view.backgroundColor = convertedColor;
}

- (void)setAdViewPlacement:(nullable NSString *)placement forAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    [self log: @"Setting placement \"%@\" for \"%@\" with ad unit identifier \"%@\"", placement, adFormat, adUnitIdentifier];
    
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    adView.placement = placement;
}

- (void)updateAdViewPosition:(NSString *)adViewPosition forAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    // Check if the previous position is same as the new position. If so, no need to update the position again.
    NSString *previousPosition = self.adViewPositions[adUnitIdentifier];
    if ( !adViewPosition || [adViewPosition isEqualToString: previousPosition] ) return;
    
    self.adViewPositions[adUnitIdentifier] = adViewPosition;
    [self positionAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
}

- (void)setAdViewExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat key:(NSString *)key value:(nullable NSString *)value
{
    [self log: @"Setting %@ extra with key: \"%@\" value: \"%@\"", adFormat, key, value];
    
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    [adView setExtraParameterForKey: key value: value];
    
    if (  [@"force_banner" isEqualToString: key] && MAAdFormat.mrec != adFormat )
    {
        // Handle local changes as needed
        MAAdFormat *adFormat;
        
        BOOL shouldForceBanner = [NSNumber al_numberWithString: value].boolValue;
        if ( shouldForceBanner )
        {
            adFormat = MAAdFormat.banner;
        }
        else
        {
            adFormat = DEVICE_SPECIFIC_ADVIEW_AD_FORMAT;
        }
        
        self.adViewAdFormats[adUnitIdentifier] = adFormat;
        [self positionAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    }
}

- (void)showAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    [self log: @"Showing %@ with ad unit identifier \"%@\"", adFormat, adUnitIdentifier];
    
    MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    if ( !view )
    {
        [self log: @"%@ does not exist for ad unit identifier %@.", adFormat, adUnitIdentifier];
        
        // The adView has not yet been created. Store the ad unit ID, so that it can be displayed once the banner has been created.
        [self.adUnitIdentifiersToShowAfterCreate addObject: adUnitIdentifier];
    }
    
    self.safeAreaBackground.hidden = NO;
    view.hidden = NO;
    
    [view startAutoRefresh];
}

- (void)hideAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    [self log: @"Hiding %@ with ad unit identifier \"%@\"", adFormat, adUnitIdentifier];
    [self.adUnitIdentifiersToShowAfterCreate removeObject: adUnitIdentifier];
    
    MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    view.hidden = YES;
    self.safeAreaBackground.hidden = YES;
    
    [view stopAutoRefresh];
}

- (void)loadAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    if ( !adView )
    {
        [self log: @"%@ does not exist for ad unit identifier %@.", adFormat.label, adUnitIdentifier];
        return;
    }
    
    if ( ![self.disabledAutoRefreshAdViewAdUnitIdentifiers containsObject: adUnitIdentifier] )
    {
        if ( [adView isHidden] )
        {
            [self log: @"Auto-refresh will resume when the %@ ad is shown. You should only call LoadBanner() or LoadMRec() if you explicitly pause auto-refresh and want to manually load an ad.", adFormat.label];
            return;
        }
        
        [self log: @"You must stop auto-refresh if you want to manually load %@ ads.", adFormat.label];
        return;
    }
    
    [adView loadAd];
}

- (void)startAdViewAutoRefreshForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    [self log: @"Starting %@ auto refresh for ad unit identifier \"%@\"", adFormat.label, adUnitIdentifier];
    
    [self.disabledAutoRefreshAdViewAdUnitIdentifiers removeObject: adUnitIdentifier];
    
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    if ( !adView )
    {
        [self log: @"%@ does not exist for ad unit identifier %@.", adFormat.label, adUnitIdentifier];
        return;
    }
    
    [adView startAutoRefresh];
}

- (void)stopAdViewAutoRefreshForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    [self log: @"Stopping %@ auto refresh for ad unit identifier \"%@\"", adFormat.label, adUnitIdentifier];
    
    [self.disabledAutoRefreshAdViewAdUnitIdentifiers addObject: adUnitIdentifier];
    
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    if ( !adView )
    {
        [self log: @"%@ does not exist for ad unit identifier %@.", adFormat.label, adUnitIdentifier];
        return;
    }
    
    [adView stopAutoRefresh];
}

- (void)destroyAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    [self log: @"Destroying %@ with ad unit identifier \"%@\"", adFormat, adUnitIdentifier];
    
    MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    view.delegate = nil;
    
    [view removeFromSuperview];
    
    [self.adViews removeObjectForKey: adUnitIdentifier];
    [self.adViewPositions removeObjectForKey: adUnitIdentifier];
    [self.adViewAdFormats removeObjectForKey: adUnitIdentifier];
}

- (void)setPendingExtraParametersIfNeeded:(ALSdkSettings *)settings
{
    if ( self.extraParametersToSet.count <= 0 ) return;
    
    for ( NSString *key in self.extraParametersToSet )
    {
        NSString *value = self.extraParametersToSet[key];
        [settings setExtraParameterForKey: key value: ( value != (id) [NSNull null] ) ? value : nil];
    }
    
    [self.extraParametersToSet removeAllObjects];
}

- (void)logInvalidAdFormat:(MAAdFormat *)adFormat
{
    [self log: @"invalid ad format: %@, from %@", adFormat, [NSThread callStackSymbols]];
}

- (void)logUninitializedAccessError:(NSString *)callingMethod
{
    [self logUninitializedAccessError: callingMethod withResult: nil];
}

- (void)logUninitializedAccessError:(NSString *)callingMethod withResult:(nullable FlutterResult)result
{
    NSString *message = [NSString stringWithFormat:@"ERROR: Failed to execute %@() - please ensure the AppLovin MAX React Native module has been initialized by calling 'AppLovinMAX.initialize(...);'!", callingMethod];

    if ( !result )
    {
        NSLog(@"[%@] [%@] %@", SDK_TAG, TAG, message);
        return;
    }

    result([FlutterError errorWithCode: TAG message: message details: nil]);
}

- (void)log:(NSString *)format, ...
{
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
    va_end(valist);
    
    NSLog(@"[%@] [%@] %@", SDK_TAG, TAG, message);
}

+ (void)log:(NSString *)format, ...
{
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
    va_end(valist);
    
    NSLog(@"[%@] [%@] %@", SDK_TAG, TAG, message);
}

// NOTE: Do not update signature as some integrations depend on it via Objective-C runtime
- (MAInterstitialAd *)retrieveInterstitialForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MAInterstitialAd *result = self.interstitials[adUnitIdentifier];
    if ( !result )
    {
        result = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: adUnitIdentifier sdk: self.sdk];
        result.delegate = self;
        
        self.interstitials[adUnitIdentifier] = result;
    }
    
    return result;
}

// NOTE: Do not update signature as some integrations depend on it via Objective-C runtime
- (MARewardedAd *)retrieveRewardedAdForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MARewardedAd *result = self.rewardedAds[adUnitIdentifier];
    if ( !result )
    {
        result = [MARewardedAd sharedWithAdUnitIdentifier: adUnitIdentifier sdk: self.sdk];
        result.delegate = self;
        
        self.rewardedAds[adUnitIdentifier] = result;
    }
    
    return result;
}

// NOTE: Do not update signature as some integrations depend on it via Objective-C runtime
- (MAAppOpenAd *)retrieveAppOpenAdForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MAAppOpenAd *result = self.appOpenAds[adUnitIdentifier];
    if ( !result )
    {
        result = [[MAAppOpenAd alloc] initWithAdUnitIdentifier: adUnitIdentifier sdk: self.sdk];
        result.delegate = self;
        
        self.appOpenAds[adUnitIdentifier] = result;
    }
    
    return result;
}

// NOTE: Do not update signature as some integrations depend on it via Objective-C runtime
- (MAAdView *)retrieveAdViewForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    return [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat atPosition: nil];
}

- (MAAdView *)retrieveAdViewForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat atPosition:(NSString *)adViewPosition
{
    return [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat atPosition: adViewPosition attach: YES];
}

- (MAAdView *)retrieveAdViewForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat atPosition:(NSString *)adViewPosition attach:(BOOL)attach
{
    MAAdView *result = self.adViews[adUnitIdentifier];
    if ( !result && adViewPosition )
    {
        result = [[MAAdView alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat sdk: self.sdk];
        result.delegate = self;
        result.userInteractionEnabled = NO;
        result.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.adViews[adUnitIdentifier] = result;
        
        // If this is programmatic
        if ( attach )
        {
            self.adViewPositions[adUnitIdentifier] = adViewPosition;
            [ROOT_VIEW_CONTROLLER.view addSubview: result];
        }
        
        // Allow pubs to pause auto-refresh immediately, by default.
        [result setExtraParameterForKey: @"allow_pause_auto_refresh_immediately" value: @"true"];
    }
    
    return result;
}

- (void)positionAdViewForAd:(MAAd *)ad
{
    [self positionAdViewForAdUnitIdentifier: ad.adUnitIdentifier adFormat: ad.format];
}

- (void)positionAdViewForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    NSString *adViewPosition = self.adViewPositions[adUnitIdentifier];
    
    UIView *superview = adView.superview;
    if ( !superview ) return;
    
    // Deactivate any previous constraints so that the banner can be positioned again.
    NSArray<NSLayoutConstraint *> *activeConstraints = self.adViewConstraints[adUnitIdentifier];
    [NSLayoutConstraint deactivateConstraints: activeConstraints];
    
    // Ensure superview contains the safe area background.
    if ( ![superview.subviews containsObject: self.safeAreaBackground] )
    {
        [self.safeAreaBackground removeFromSuperview];
        [superview insertSubview: self.safeAreaBackground belowSubview: adView];
    }
    
    // Deactivate any previous constraints and reset visibility state so that the safe area background can be positioned again.
    [NSLayoutConstraint deactivateConstraints: self.safeAreaBackground.constraints];
    self.safeAreaBackground.hidden = adView.hidden;
    
    CGSize adViewSize = [[self class] adViewSizeForAdFormat: adFormat];
    
    // All positions have constant height
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithObject: [adView.heightAnchor constraintEqualToConstant: adViewSize.height]];
    
    UILayoutGuide *layoutGuide = superview.safeAreaLayoutGuide;
    
    // If top of bottom center, stretch width of screen
    if ( [adViewPosition isEqual: @"top_center"] || [adViewPosition isEqual: @"bottom_center"] )
    {
        // If publisher actually provided a banner background color, span the banner across the realm
        if ( self.publisherBannerBackgroundColor && adFormat != MAAdFormat.mrec )
        {
            [constraints addObjectsFromArray: @[[self.safeAreaBackground.leftAnchor constraintEqualToAnchor: superview.leftAnchor],
                                                [self.safeAreaBackground.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
            
            if ( [adViewPosition isEqual: @"top_center"] )
            {
                [constraints addObjectsFromArray: @[[adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor],
                                                    [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor],
                                                    [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
                [constraints addObjectsFromArray: @[[self.safeAreaBackground.topAnchor constraintEqualToAnchor: superview.topAnchor],
                                                    [self.safeAreaBackground.bottomAnchor constraintEqualToAnchor: adView.topAnchor]]];
            }
            else // BottomCenter
            {
                [constraints addObjectsFromArray: @[[adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor],
                                                    [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor],
                                                    [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
                [constraints addObjectsFromArray: @[[self.safeAreaBackground.topAnchor constraintEqualToAnchor: adView.bottomAnchor],
                                                    [self.safeAreaBackground.bottomAnchor constraintEqualToAnchor: superview.bottomAnchor]]];
            }
        }
        // If pub does not have a background color set - we shouldn't span the banner the width of the realm (there might be user-interactable UI on the sides)
        else
        {
            self.safeAreaBackground.hidden = YES;
            
            // Assign constant width of 320 or 728
            [constraints addObject: [adView.widthAnchor constraintEqualToConstant: adViewSize.width]];
            [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor]];
            
            if ( [adViewPosition isEqual: @"top_center"] )
            {
                [constraints addObject: [adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor]];
            }
            else // BottomCenter
            {
                [constraints addObject: [adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor]];
            }
        }
    }
    // Otherwise, publisher will likely construct his own views around the adview
    else
    {
        self.safeAreaBackground.hidden = YES;
        
        // Assign constant width of 320 or 728
        [constraints addObject: [adView.widthAnchor constraintEqualToConstant: adViewSize.width]];
        
        if ( [adViewPosition isEqual: @"top_left"] )
        {
            [constraints addObjectsFromArray: @[[adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor],
                                                [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"top_right"] )
        {
            [constraints addObjectsFromArray: @[[adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor],
                                                [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"centered"] )
        {
            [constraints addObjectsFromArray: @[[adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor],
                                                [adView.centerYAnchor constraintEqualToAnchor: layoutGuide.centerYAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"bottom_left"] )
        {
            [constraints addObjectsFromArray: @[[adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor],
                                                [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"bottom_right"] )
        {
            [constraints addObjectsFromArray: @[[adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor],
                                                [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
        }
    }
    
    self.adViewConstraints[adUnitIdentifier] = constraints;
    
    [NSLayoutConstraint activateConstraints: constraints];
}

+ (CGSize)adViewSizeForAdFormat:(MAAdFormat *)adFormat
{
    if ( MAAdFormat.leader == adFormat )
    {
        return CGSizeMake(728.0f, 90.0f);
    }
    else if ( MAAdFormat.banner == adFormat )
    {
        return CGSizeMake(320.0f, 50.0f);
    }
    else if ( MAAdFormat.mrec == adFormat )
    {
        return CGSizeMake(300.0f, 250.0f);
    }
    else
    {
        [NSException raise: NSInvalidArgumentException format: @"Invalid ad format"];
        return CGSizeZero;
    }
}

- (NSDictionary<NSString *, id> *)adInfoForAd:(MAAd *)ad
{
    // NOTE: Empty strings might get co-erced into [NSNull null] through Flutter channel and cause issues
    return @{@"adUnitId" : ad.adUnitIdentifier,
             @"creativeId" : ad.creativeIdentifier ?: @"",
             @"networkName" : ad.networkName,
             @"placement" : ad.placement ?: @"",
             @"revenue" : @(ad.revenue),
             @"revenuePrecision" : ad.revenuePrecision,
             @"dspName" : ad.DSPName ?: @"",
             @"waterfall": [self createAdWaterfallInfo: ad.waterfall]};
}

- (NSDictionary<NSString *, id> *)adLoadFailedInfoForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    return ( error ) ?
    @{@"adUnitId": adUnitIdentifier,
      @"code" : @(error.code),
      @"message" : error.message,
      @"waterfall": [self createAdWaterfallInfo: error.waterfall]}
    :
    @{@"adUnitId": adUnitIdentifier,
      @"code" : @(MAErrorCodeUnspecified)};
}

- (NSDictionary<NSString *, id> *)adDisplayFailedInfoForAd:(MAAd *)ad withError:(MAError *)error
{
    return @{
        @"ad" : [self adInfoForAd: ad],
        @"error" : [self adLoadFailedInfoForAdUnitIdentifier: ad.adUnitIdentifier withError: error]
    };
}

- (NSDictionary<NSString *, id> *)createAdWaterfallInfo:(MAAdWaterfallInfo *)waterfallInfo
{
    NSMutableDictionary<NSString *, id> *waterfallInfoDict = [NSMutableDictionary dictionary];
    if ( !waterfallInfo ) return waterfallInfoDict;
    
    waterfallInfoDict[@"name"] = waterfallInfo.name;
    waterfallInfoDict[@"testName"] = waterfallInfo.testName;
    
    NSMutableArray<NSDictionary<NSString *, id> *> *networkResponsesArray = [NSMutableArray arrayWithCapacity: waterfallInfo.networkResponses.count];
    for ( MANetworkResponseInfo *response in  waterfallInfo.networkResponses )
    {
        [networkResponsesArray addObject: [self createNetworkResponseInfo: response]];
    }
    waterfallInfoDict[@"networkResponses"] = networkResponsesArray;
    
    // Convert latency from seconds to milliseconds to match Android.
    long long latencyMillis = waterfallInfo.latency * 1000;
    waterfallInfoDict[@"latencyMillis"] = @(latencyMillis);
    
    return waterfallInfoDict;
}

- (NSDictionary<NSString *, id> *)createNetworkResponseInfo:(MANetworkResponseInfo *)response
{
    NSMutableDictionary<NSString *, id> *networkResponseDict = [NSMutableDictionary dictionary];
    
    networkResponseDict[@"adLoadState"] = @(response.adLoadState);
    
    MAMediatedNetworkInfo *mediatedNetworkInfo = response.mediatedNetwork;
    if ( mediatedNetworkInfo )
    {
        NSMutableDictionary <NSString *, id> *networkInfoObject = [NSMutableDictionary dictionary];
        networkInfoObject[@"name"] = mediatedNetworkInfo.name;
        networkInfoObject[@"adapterClassName"] = mediatedNetworkInfo.adapterClassName;
        networkInfoObject[@"adapterVersion"] = mediatedNetworkInfo.adapterVersion;
        networkInfoObject[@"sdkVersion"] = mediatedNetworkInfo.sdkVersion;
        
        networkResponseDict[@"mediatedNetwork"] = networkInfoObject;
    }
    
    networkResponseDict[@"credentials"] = response.credentials;
    
    MAError *error = response.error;
    if ( error )
    {
        networkResponseDict[@"error"] = [self adLoadFailedInfoForAdUnitIdentifier: @"" withError: error];
    }
    
    // Convert latency from seconds to milliseconds to match Android.
    long long latencySeconds = response.latency * 1000;
    networkResponseDict[@"latencyMillis"] = @(latencySeconds);
    
    return networkResponseDict;
}

#pragma mark - Amazon

- (void)setAmazonResult:(id)result forBannerAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self setAmazonResult: result forAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.banner];
}

- (void)setAmazonResult:(id)result forMRecAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self setAmazonResult: result forAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.mrec];
}

- (void)setAmazonResult:(id)result forInterstitialAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self setAmazonResult: result forAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.interstitial];
}

- (void)setAmazonResult:(id)result forRewardedAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self setAmazonResult: result forAdUnitIdentifier: adUnitIdentifier adFormat: MAAdFormat.rewarded];
}

- (void)setAmazonResult:(id /* DTBAdResponse or DTBAdErrorInfo */)result forAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    if ( !self.sdk )
    {
        NSString *errorMessage = [NSString stringWithFormat: @"Failed to set Amazon result - SDK not initialized: %@", adUnitIdentifier];
        [self logUninitializedAccessError: errorMessage];
        
        return;
    }
    
    if ( !result )
    {
        [self log: @"Failed to set Amazon result - nil value"];
        return;
    }
    
    NSString *key = [self localExtraParameterKeyForAmazonResult: result];
    
    if ( adFormat == MAAdFormat.interstitial )
    {
        MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
        if ( !interstitial )
        {
            [self log: @"Failed to set Amazon result - unable to find interstitial"];
            return;
        }

        [interstitial setLocalExtraParameterForKey: key value: result];
    }
    else if ( adFormat == MAAdFormat.rewarded )
    {
        MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
        if ( !rewardedAd )
        {
            [self log: @"Failed to set Amazon result - unable to find rewarded ad"];
            return;
        }

        [rewardedAd setLocalExtraParameterForKey: key value: result];
    }
    else // MAAdFormat.banner or MAAdFormat.mrec
    {
        MAAdView *adView = [AppLovinMAXAdView sharedWithAdUnitIdentifier: adUnitIdentifier];

        if ( !adView )
        {
            adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        }
        
        if ( adView )
        {
            [adView setLocalExtraParameterForKey: key value: result];
        }
        else
        {
            [self log: @"Failed to set Amazon result - unable to find %@", adFormat];
        }
    }
}

- (NSString *)localExtraParameterKeyForAmazonResult:(id /* DTBAdResponse or DTBAdErrorInfo */)result
{
    NSString *className = NSStringFromClass([result class]);
    return [@"DTBAdResponse" isEqualToString: className] ? @"amazon_ad_response" : @"amazon_ad_error";
}

#pragma mark - Utility Methods

- (ALGender)toAppLovinGender:(nullable NSString *)gender
{
    if ( gender )
    {
        if ( [@"F" al_isEqualToStringIgnoringCase: gender] )
        {
            return ALGenderFemale;
        }
        else if ( [@"M" al_isEqualToStringIgnoringCase: gender] )
        {
            return ALGenderMale;
        }
        else if ( [@"O" al_isEqualToStringIgnoringCase: gender] )
        {
            return ALGenderOther;
        }
    }
    
    return ALGenderUnknown;
}

- (ALAdContentRating)toAppLovinAdContentRating:(nullable NSNumber *)maximumAdContentRating
{
    if ( maximumAdContentRating )
    {
        int intVal = maximumAdContentRating.intValue;
        
        if ( intVal == 1 )
        {
            return ALAdContentRatingAllAudiences;
        }
        else if ( intVal == 2 )
        {
            return ALAdContentRatingEveryoneOverTwelve;
        }
        else if ( intVal == 3 )
        {
            return ALAdContentRatingMatureAudiences;
        }
    }
    
    return ALAdContentRatingNone;
}

- (ALConsentFlowUserGeography)toAppLovinConsentFlowUserGeography:(NSString *)userGeography
{
    if ( [USER_GEOGRAPHY_GDPR al_isEqualToStringIgnoringCase: userGeography] )
    {
        return ALConsentFlowUserGeographyGDPR;
    }
    else if ( [USER_GEOGRAPHY_OTHER al_isEqualToStringIgnoringCase: userGeography] )
    {
        return ALConsentFlowUserGeographyOther;
    }

    return ALConsentFlowUserGeographyUnknown;
}

- (NSString *)fromAppLovinConsentFlowUserGeography:(ALConsentFlowUserGeography)userGeography
{
    if ( ALConsentFlowUserGeographyGDPR == userGeography )
    {
        return USER_GEOGRAPHY_GDPR;
    }
    else if ( ALConsentFlowUserGeographyOther == userGeography )
    {
        return USER_GEOGRAPHY_OTHER;
    }

    return USER_GEOGRAPHY_UNKNOWN;
}

- (NSString *)fromAppLovinAppTrackingStatus:(ALAppTrackingTransparencyStatus)status
{
    if ( ALAppTrackingTransparencyStatusNotDetermined == status )
    {
        return APP_TRACKING_STATUS_NOTDETERMINED;
    }
    else if ( ALAppTrackingTransparencyStatusRestricted == status )
    {
        return APP_TRACKING_STATUS_RESTRICTED;
    }
    else if ( ALAppTrackingTransparencyStatusDenied == status )
    {
        return APP_TRACKING_STATUS_DENIED;
    }
    else if ( ALAppTrackingTransparencyStatusAuthorized == status )
    {
        return APP_TRACKING_STATUS_AUTHORIZED;
    }

    return APP_TRACKING_STATUS_UNAVAILABLE;
}

#pragma mark - Flutter Event Channel

- (void)sendEventWithName:(NSString *)name ad:(MAAd *)ad channel:(FlutterMethodChannel *)channel
{
    [self sendEventWithName: name body: [self adInfoForAd: ad] channel: channel];
}

- (void)sendEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body
{
    [self sendEventWithName: name body: body channel: ALSharedChannel];
}

- (void)sendEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body channel:(FlutterMethodChannel *)channel
{
    [channel invokeMethod: name arguments: body];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result
{
    if ( [@"initialize" isEqualToString: call.method] )
    {
        NSString *pluginVersion = call.arguments[@"plugin_version"];
        NSString *sdkKey = call.arguments[@"sdk_key"];
        [self initializeWithPluginVersion: pluginVersion sdkKey: sdkKey andNotify: result];
    }
    else if ( [@"isInitialized" isEqualToString: call.method] )
    {
        [self isInitialized: result];
    }
    else if ( [@"isTablet" isEqualToString: call.method] )
    {
        [self isTablet: result];
    }
    else if ( [@"showMediationDebugger" isEqualToString: call.method] )
    {
        [self showMediationDebugger];
        
        result(nil);
    }
    else if ( [@"getConsentDialogState" isEqualToString: call.method] )
    {
        [self getConsentDialogState: result];
    }
    else if ( [@"setHasUserConsent" isEqualToString: call.method] )
    {
        BOOL hasUserConsent = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setHasUserConsent: hasUserConsent];
        
        result(nil);
    }
    else if ( [@"hasUserConsent" isEqualToString: call.method] )
    {
        [self hasUserConsent: result];
    }
    else if ( [@"setIsAgeRestrictedUser" isEqualToString: call.method] )
    {
        BOOL isAgeRestrictedUser = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setIsAgeRestrictedUser: isAgeRestrictedUser];
        
        result(nil);
    }
    else if ( [@"isAgeRestrictedUser" isEqualToString: call.method] )
    {
        [self isAgeRestrictedUser: result];
    }
    else if ( [@"setDoNotSell" isEqualToString: call.method] )
    {
        BOOL isDoNotSell = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setDoNotSell: isDoNotSell];
        
        result(nil);
    }
    else if ( [@"isDoNotSell" isEqualToString: call.method] )
    {
        [self isDoNotSell: result];
    }
    else if ( [@"setUserId" isEqualToString: call.method] )
    {
        NSString *userId = call.arguments[@"value"];
        [self setUserId: userId];
        
        result(nil);
    }
    else if ( [@"setMuted" isEqualToString: call.method] )
    {
        BOOL isMuted = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setMuted: isMuted];
        
        result(nil);
    }
    else if ( [@"setVerboseLogging" isEqualToString: call.method] )
    {
        BOOL isVerboseLogging = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setVerboseLogging: isVerboseLogging];
        
        result(nil);
    }
    else if ( [@"setCreativeDebuggerEnabled" isEqualToString: call.method] )
    {
        BOOL isCreativeDebuggerEnabled = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setCreativeDebuggerEnabled: isCreativeDebuggerEnabled];
        
        result(nil);
    }
    else if ( [@"setTestDeviceAdvertisingIds" isEqualToString: call.method] )
    {
        NSArray<NSString *> *testDeviceAdvertisingIds = call.arguments[@"value"];
        [self setTestDeviceAdvertisingIds: testDeviceAdvertisingIds];
        
        result(nil);
    }
    else if ( [@"setLocationCollectionEnabled" isEqualToString: call.method] )
    {
        BOOL isLocationCollectionEnabled = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setLocationCollectionEnabled: isLocationCollectionEnabled];
        
        result(nil);
    }
    else if ( [@"setExtraParameter" isEqualToString: call.method] )
    {
        NSString *key = call.arguments[@"key"];
        NSString *value = call.arguments[@"value"];
        [self setExtraParameter: key value: value];
        
        result(nil);
    }
    else if ( [@"setInitializationAdUnitIds" isEqualToString: call.method] )
    {
        NSArray<NSString *> *adUnitIds = call.arguments[@"value"];
        [self setInitializationAdUnitIds: adUnitIds];
        
        result(nil);
    }
    else if ( [@"setTermsAndPrivacyPolicyFlowEnabled" isEqualToString: call.method] )
    {
        BOOL isConsentFlowEnabled = ((NSNumber *)call.arguments[@"value"]).boolValue;
        [self setTermsAndPrivacyPolicyFlowEnabled: isConsentFlowEnabled];
        
        result(nil);
    }
    else if ( [@"setPrivacyPolicyUrl" isEqualToString: call.method] )
    {
        NSString *privacyPolicyUrl = call.arguments[@"value"];
        [self setPrivacyPolicyUrl: privacyPolicyUrl];
        
        result(nil);
    }
    else if ( [@"setTermsOfServiceUrl" isEqualToString: call.method] )
    {
        NSString *termsOfServiceUrl = call.arguments[@"value"];
        [self setTermsOfServiceUrl: termsOfServiceUrl];
        
        result(nil);
    }
    else if ( [@"setConsentFlowDebugUserGeography" isEqualToString: call.method] )
    {
        NSString *debugUserGeography = call.arguments[@"value"];
        [self setConsentFlowDebugUserGeography: debugUserGeography];
        
        result(nil);
    }
    else if ( [@"showCmpForExistingUser" isEqualToString: call.method] )
    {
        [self showCmpForExistingUser: result];
    }
    else if ( [@"hasSupportedCmp" isEqualToString: call.method] )
    {
        [self hasSupportedCmp: result];
    }
    else if ( [@"createBanner" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *position = call.arguments[@"position"];
        [self createBannerForAdUnitIdentifier: adUnitId position: position];
        
        result(nil);
    }
    else if ( [@"setBannerBackgroundColor" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *hexColorCode = call.arguments[@"hex_color_code"];
        [self setBannerBackgroundColorForAdUnitIdentifier: adUnitId color: hexColorCode];
        
        result(nil);
    }
    else if ( [@"setBannerPlacement" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        
        id rawPlacement = call.arguments[@"placement"];
        NSString *placement = ( rawPlacement != [NSNull null] ) ? rawPlacement : nil;
        
        [self setBannerPlacementForAdUnitIdentifier: adUnitId placement: placement];
        
        result(nil);
    }
    else if ( [@"updateBannerPosition" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *position = call.arguments[@"position"];
        [self updateBannerPositionForAdUnitIdentifier: adUnitId position: position];
        
        result(nil);
    }
    else if ( [@"setBannerExtraParameter" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *key = call.arguments[@"key"];
        NSString *value = call.arguments[@"value"];
        [self setBannerExtraParameterForAdUnitIdentifier: adUnitId key: key value: value];
        
        result(nil);
    }
    else if ( [@"showBanner" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self showBannerForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"hideBanner" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self hideBannerForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"startBannerAutoRefresh" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self startBannerAutoRefreshForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"stopBannerAutoRefresh" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self stopBannerAutoRefreshForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"loadBanner" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self loadBannerForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"destroyBanner" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self destroyBannerForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"getAdaptiveBannerHeightForWidth" isEqualToString: call.method] )
    {
        NSNumber *width = call.arguments[@"width"];
        [self getAdaptiveBannerHeightForWidth: [width doubleValue] andNotify: result];
    }
    else if ( [@"createMRec" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *position = call.arguments[@"position"];
        [self createMRecForAdUnitIdentifier: adUnitId position: position];
        
        result(nil);
    }
    else if ( [@"setMRecPlacement" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        
        id rawPlacement = call.arguments[@"placement"];
        NSString *placement = ( rawPlacement != [NSNull null] ) ? rawPlacement : nil;
        
        [self setMRecPlacementForAdUnitIdentifier: adUnitId placement: placement];
        
        result(nil);
    }
    else if ( [@"updateMRecPosition" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *position = call.arguments[@"position"];
        [self updateMRecPositionForAdUnitIdentifier: adUnitId position: position];
        
        result(nil);
    }
    else if ( [@"setMRecExtraParameter" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *key = call.arguments[@"key"];
        NSString *value = call.arguments[@"value"];
        [self setMRecExtraParameterForAdUnitIdentifier: adUnitId key: key value: value];
        
        result(nil);
    }
    else if ( [@"showMRec" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self showMRecForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"hideMRec" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self hideMRecForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"startMRecAutoRefresh" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self startMRecAutoRefreshForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"stopMRecAutoRefresh" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self stopMRecAutoRefreshForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"loadMRec" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self loadMRecForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"destroyMRec" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self destroyMRecForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"loadInterstitial" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self loadInterstitialForAdUnitIdentifier: adUnitId];
        
        // result(nil);
    }
    else if ( [@"isInterstitialReady" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self isInterstitialReadyForAdUnitIdentifier: adUnitId result: result];
    }
    else if ( [@"showInterstitial" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        
        id rawPlacement = call.arguments[@"placement"];
        NSString *placement = ( rawPlacement != [NSNull null] ) ? rawPlacement : nil;
        id rawCustomData = call.arguments[@"custom_data"];
        NSString *customData = ( rawCustomData != [NSNull null] ) ? rawCustomData : nil;
        
        [self showInterstitialForAdUnitIdentifier: adUnitId placement: placement customData: customData];
        
        result(nil);
    }
    else if ( [@"setInterstitialExtraParameter" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *key = call.arguments[@"key"];
        NSString *value = call.arguments[@"value"];
        [self setInterstitialExtraParameterForAdUnitIdentifier: adUnitId key: key value: value];
        
        result(nil);
    }
    else if ( [@"loadRewardedAd" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self loadRewardedAdForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"isRewardedAdReady" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self isRewardedAdReadyForAdUnitIdentifier: adUnitId result: result];
    }
    else if ( [@"showRewardedAd" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        
        id rawPlacement = call.arguments[@"placement"];
        NSString *placement = ( rawPlacement != [NSNull null] ) ? rawPlacement : nil;
        id rawCustomData = call.arguments[@"custom_data"];
        NSString *customData = ( rawCustomData != [NSNull null] ) ? rawCustomData : nil;
        
        [self showRewardedAdForAdUnitIdentifier: adUnitId placement: placement customData: customData];
        
        result(nil);
    }
    else if ( [@"setRewardedAdExtraParameter" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *key = call.arguments[@"key"];
        NSString *value = call.arguments[@"value"];
        [self setRewardedAdExtraParameterForAdUnitIdentifier: adUnitId key: key value: value];
        
        result(nil);
    }
    else if ( [@"loadAppOpenAd" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self loadAppOpenAdForAdUnitIdentifier: adUnitId];
        
        result(nil);
    }
    else if ( [@"isAppOpenAdReady" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        [self isAppOpenAdReadyForAdUnitIdentifier: adUnitId result: result];
    }
    else if ( [@"showAppOpenAd" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        
        id rawPlacement = call.arguments[@"placement"];
        NSString *placement = ( rawPlacement != [NSNull null] ) ? rawPlacement : nil;
        id rawCustomData = call.arguments[@"custom_data"];
        NSString *customData = ( rawCustomData != [NSNull null] ) ? rawCustomData : nil;
        
        [self showAppOpenAdForAdUnitIdentifier: adUnitId placement: placement customData: customData];
        
        result(nil);
    }
    else if ( [@"setAppOpenAdExtraParameter" isEqualToString: call.method] )
    {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *key = call.arguments[@"key"];
        NSString *value = call.arguments[@"value"];
        [self setAppOpenAdExtraParameterForAdUnitIdentifier: adUnitId key: key value: value];
        
        result(nil);
    }
    else if ( [@"setTargetingDataYearOfBirth" isEqualToString: call.method] )
    {
        id rawValue = call.arguments[@"value"];
        NSNumber *value = ( rawValue != [NSNull null] ) ? rawValue : nil;
        [self setTargetingDataYearOfBirth: value];
        
        result(nil);
    }
    else if ( [@"setTargetingDataGender" isEqualToString: call.method] )
    {
        id rawValue = call.arguments[@"value"];
        NSString *value = ( rawValue != [NSNull null] ) ? rawValue : nil;
        [self setTargetingDataGender: value];
        
        result(nil);
    }
    else if ( [@"setTargetingDataMaximumAdContentRating" isEqualToString: call.method] )
    {
        id rawValue = call.arguments[@"value"];
        NSNumber *value = ( rawValue != [NSNull null] ) ? rawValue : nil;
        [self setTargetingDataMaximumAdContentRating: value];
        
        result(nil);
    }
    else if ( [@"setTargetingDataEmail" isEqualToString: call.method] )
    {
        id rawValue = call.arguments[@"value"];
        NSString *value = ( rawValue != [NSNull null] ) ? rawValue : nil;
        [self setTargetingDataEmail: value];
        
        result(nil);
    }
    else if ( [@"setTargetingDataPhoneNumber" isEqualToString: call.method] )
    {
        id rawValue = call.arguments[@"value"];
        NSString *value = ( rawValue != [NSNull null] ) ? rawValue : nil;
        [self setTargetingDataPhoneNumber: value];
        
        result(nil);
    }
    else if ( [@"setTargetingDataKeywords" isEqualToString: call.method] )
    {
        id rawValue = call.arguments[@"value"];
        NSArray<NSString *> *value = ( rawValue != [NSNull null] ) ? rawValue : nil;
        [self setTargetingDataKeywords: value];
        
        result(nil);
    }
    else if ( [@"setTargetingDataInterests" isEqualToString: call.method] )
    {
        id rawValue = call.arguments[@"value"];
        NSArray<NSString *> *value = ( rawValue != [NSNull null] ) ? rawValue : nil;
        [self  setTargetingDataInterests: value];
        
        result(nil);
    }
    else if ( [@"clearAllTargetingData" isEqualToString: call.method] )
    {
        [self clearAllTargetingData];
        
        result(nil);
    }
    else
    {
        result(FlutterMethodNotImplemented);
    }
}

@end
