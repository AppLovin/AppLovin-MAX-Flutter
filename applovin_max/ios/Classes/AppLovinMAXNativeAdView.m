#import "AppLovinMAXNativeAdView.h"
#import "AppLovinMAX.h"
#import <AppLovinSDK/AppLovinSDK.h>

#define TITLE_LABEL_TAG          1
#define MEDIA_VIEW_CONTAINER_TAG 2
#define ICON_VIEW_TAG            3
#define BODY_VIEW_TAG            4
#define CALL_TO_ACTION_VIEW_TAG  5
#define ADVERTISER_VIEW_TAG      8

@interface UIView (ALUtils)
- (void)al_removeAllSubviews;
@end

@interface MANativeAdLoader()
- (void)registerClickableViews:(NSArray<UIView *> *)clickableViews
                 withContainer:(UIView *)container
                         forAd:(MAAd *)ad;
- (void)handleNativeAdViewRenderedForAd:(MAAd *)ad;
@end

@interface AppLovinMAXNativeAdView()<MANativeAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, strong) FlutterMethodChannel *channel;

@property (nonatomic, strong, nullable) MANativeAdLoader *adLoader;
@property (nonatomic, strong, nullable) MAAd *nativeAd;
@property (nonatomic, strong) ALAtomicBoolean *isLoading; // Guard against repeated ad loads

@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy, nullable) NSString *placement;
@property (nonatomic, copy, nullable) NSString *customData;
@property (nonatomic, copy, nullable) NSDictionary *extraParameters;
@property (nonatomic, copy, nullable) NSDictionary *localExtraParameters;

@property (nonatomic, strong) UIView *nativeAdView;
@property (nonatomic, strong, nullable) UIView *titleView;
@property (nonatomic, strong, nullable) UIView *advertiserView;
@property (nonatomic, strong, nullable) UIView *bodyView;
@property (nonatomic, strong, nullable) UIView *callToActionView;
@property (nonatomic, strong, nullable) UIImageView *iconView;
@property (nonatomic, strong, nullable) UIView *optionsViewContainer;
@property (nonatomic, strong, nullable) UIView *mediaViewContainer;

@property (nonatomic, strong) NSMutableArray<UIView *> *clickableViews;

@end

@implementation AppLovinMAXNativeAdView

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                    placement:(nullable NSString *)placement
                   customData:(nullable NSString *)customData
              extraParameters:(nullable NSDictionary *)extraParameters
         localExtraParameters:(nullable NSDictionary *)localExtraParameters
                    messenger:(id<FlutterBinaryMessenger>)messenger
                          sdk:(ALSdk *)sdk
{
    self = [super init];
    if ( self )
    {
        self.adUnitId = adUnitId;
        self.placement = placement;
        self.customData = customData;
        self.extraParameters = extraParameters;
        self.localExtraParameters = localExtraParameters;
        self.isLoading = [[ALAtomicBoolean alloc] init];
        self.clickableViews = [NSMutableArray array];
        
        NSString *uniqueChannelName = [NSString stringWithFormat: @"applovin_max/nativeadview_%lld", viewId];
        self.channel = [FlutterMethodChannel methodChannelWithName: uniqueChannelName binaryMessenger: messenger];
        
        __weak typeof(self) weakSelf = self;
        [self.channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            
            if ( [@"addTitleView" isEqualToString: call.method] )
            {
                [weakSelf addTitleViewForCall: call];
                result(nil);
            }
            else if ( [@"addAdvertiserView" isEqualToString: call.method] )
            {
                [weakSelf addAdvertiserViewForCall: call];
                result(nil);
            }
            else if ( [@"addBodyView" isEqualToString: call.method] )
            {
                [weakSelf addBodyViewForCall: call];
                result(nil);
            }
            else if ( [@"addCallToActionView" isEqualToString: call.method] )
            {
                [weakSelf addCallToActionViewForCall: call];
                result(nil);
            }
            else if ( [@"addIconView" isEqualToString: call.method] )
            {
                [weakSelf addIconViewForCall: call];
                result(nil);
            }
            else if ( [@"addOptionsView" isEqualToString: call.method] )
            {
                [weakSelf addOptionsViewForCall: call];
                result(nil);
            }
            else if ( [@"addMediaView" isEqualToString: call.method] )
            {
                [weakSelf addMediaViewForCall: call];
                result(nil);
            }
            else if ( [@"renderAd" isEqualToString: call.method] )
            {
                [weakSelf renderAd];
                result(nil);
            }
            else if ( [@"loadAd" isEqualToString: call.method] )
            {
                [weakSelf loadAd];
                result(nil);
            }
            else
            {
                result(FlutterMethodNotImplemented);
            }
        }];
        
        self.nativeAdView = [[UIView alloc] initWithFrame: frame];
        
        [self loadAd];
    }
    return self;
}

#pragma mark - Flutter Lifecycle Methods

- (UIView *)view
{
    return self.nativeAdView;
}

- (void)dealloc
{
    [self destroyCurrentAdIfNeeded];
    
    if ( self.titleView )
    {
        [self.titleView removeFromSuperview];
    }
    
    if ( self.advertiserView )
    {
        [self.advertiserView removeFromSuperview];
    }
    
    if ( self.bodyView )
    {
        [self.bodyView removeFromSuperview];
    }
    
    if ( self.callToActionView )
    {
        [self.callToActionView removeFromSuperview];
    }
    
    if ( self.iconView )
    {
        [self.iconView removeFromSuperview];
    }
    
    if ( self.optionsViewContainer )
    {
        [self.optionsViewContainer removeFromSuperview];
    }
    
    if ( self.mediaViewContainer )
    {
        [self.mediaViewContainer removeFromSuperview];
    }
    
    [self.channel setMethodCallHandler: nil];
    self.channel = nil;
}

#pragma mark - Ad Loader

// Lazily loaded for when Ad Unit ID is available
- (nullable MANativeAdLoader *)adLoader
{
    if ( ![self.adUnitId al_isValidString] ) return nil;
    
    if ( ![self.adUnitId isEqualToString: _adLoader.adUnitIdentifier] )
    {
        _adLoader = [[MANativeAdLoader alloc] initWithAdUnitIdentifier: self.adUnitId sdk: [AppLovinMAX shared].sdk];
        _adLoader.nativeAdDelegate = self;
        _adLoader.revenueDelegate = self;
    }
    
    return _adLoader;
}

- (void)loadAd
{
    if ( [self.isLoading compareAndSet: NO update: YES] )
    {
        [AppLovinMAX log: @"Loading a native ad for Ad Unit ID: %@...", self.adUnitId];
        
        self.adLoader.placement = self.placement;
        self.adLoader.customData = self.customData;
        
        for ( NSString *key in self.extraParameters )
        {
            [self.adLoader setExtraParameterForKey: key value: self.extraParameters[key]];
        }
        
        for ( NSString *key in self.localExtraParameters )
        {
            [self.adLoader setLocalExtraParameterForKey: key value: self.localExtraParameters[key]];
        }
        
        [self.adLoader loadAd];
    }
    else
    {
        [AppLovinMAX log: @"Ignoring request to load native ad for Ad Unit ID %@, another ad load in progress", self.adUnitId];
    }
}

#pragma mark - Ad Loader Delegate

- (void)didLoadNativeAd:(nullable MANativeAdView *)nativeAdView forAd:(MAAd *)ad
{
    [AppLovinMAX log: @"Native ad loaded: %@", ad];
    
    // Log a warning if it is a template native ad returned - as our plugin will be responsible for re-rendering the native ad's assets
    if ( nativeAdView )
    {
        [self handleAdLoadFailed: @"Native ad is of template type, failing ad load..." error: nil];
        return;
    }
    
    [self destroyCurrentAdIfNeeded];
    
    self.nativeAd = ad;
    
    [self sendAdLoadedReactNativeEventForAd: ad.nativeAd];
}

- (void)didFailToLoadNativeAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    [self handleAdLoadFailed: [NSString stringWithFormat: @"Failed to load native ad for Ad Unit ID %@ with error: %@", self.adUnitId, error]
                       error: error];
}

- (void)didClickNativeAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnNativeAdClickedEvent" ad: ad];
}

- (void)didPayRevenueForAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnNativeAdRevenuePaidEvent" ad: ad];
}

#pragma mark - Native Ad Components

- (void)addTitleViewForCall:(FlutterMethodCall *)call
{
    if ( !self.nativeAd.nativeAd.title ) return;
    
    if ( !self.titleView )
    {
        self.titleView = [[UIView alloc] init];
        self.titleView.tag = TITLE_LABEL_TAG;
        [self.nativeAdView addSubview: self.titleView];
    }
    
    [self.clickableViews addObject: self.titleView];
    
    self.titleView.frame = [self frameForCall: call];
}

- (void)addAdvertiserViewForCall:(FlutterMethodCall *)call
{
    if ( !self.nativeAd.nativeAd.advertiser ) return;
    
    if ( !self.advertiserView )
    {
        self.advertiserView = [[UIView alloc] init];
        self.advertiserView.tag = ADVERTISER_VIEW_TAG;
        [self.nativeAdView addSubview: self.advertiserView];
    }
    
    [self.clickableViews addObject: self.advertiserView];
    
    self.advertiserView.frame = [self frameForCall: call];
}

- (void)addBodyViewForCall:(FlutterMethodCall *)call
{
    if ( !self.nativeAd.nativeAd.body ) return;
    
    if ( !self.bodyView )
    {
        self.bodyView = [[UIView alloc] init];
        self.bodyView.tag = BODY_VIEW_TAG;
        [self.nativeAdView addSubview: self.bodyView];
    }
    
    [self.clickableViews addObject: self.bodyView];
    
    self.bodyView.frame = [self frameForCall: call];
}

- (void)addCallToActionViewForCall:(FlutterMethodCall *)call
{
    if ( !self.nativeAd.nativeAd.callToAction ) return;
    
    if ( !self.callToActionView )
    {
        self.callToActionView = [[UIView alloc] init];
        self.callToActionView.tag = CALL_TO_ACTION_VIEW_TAG;
        [self.nativeAdView addSubview: self.callToActionView];
    }
    
    [self.clickableViews addObject: self.callToActionView];
    
    self.callToActionView.frame = [self frameForCall: call];
}

- (void)addIconViewForCall:(FlutterMethodCall *)call
{
    MANativeAdImage *icon = self.nativeAd.nativeAd.icon;
    if ( !icon )
    {
        self.iconView.image = nil;
        return;
    }
    
    if ( !self.iconView )
    {
        self.iconView = [[UIImageView alloc] init];
        self.iconView.tag = ICON_VIEW_TAG;
        [self.nativeAdView addSubview: self.iconView];
    }
    
    [self.clickableViews addObject: self.iconView];
    
    self.iconView.frame = [self frameForCall: call];
    
    if ( icon.URL )
    {
        [self.iconView al_setImageWithURL: icon.URL];
    }
    else if ( icon.image )
    {
        self.iconView.image = icon.image;
    }
}

- (void)addOptionsViewForCall:(FlutterMethodCall *)call
{
    UIView *optionsView = self.nativeAd.nativeAd.optionsView;
    if ( !optionsView ) return;
    
    if ( !self.optionsViewContainer )
    {
        self.optionsViewContainer = [[UIView alloc] init];
        [self.nativeAdView addSubview: self.optionsViewContainer];
    }
    
    if ( !optionsView.superview )
    {
        [self.optionsViewContainer addSubview: optionsView];
        [optionsView al_pinToSuperview];
    }
    
    self.optionsViewContainer.frame = [self frameForCall: call];
}

- (void)addMediaViewForCall:(FlutterMethodCall *)call
{
    UIView *mediaView = self.nativeAd.nativeAd.mediaView;
    if ( !mediaView ) return;
    
    if ( !self.mediaViewContainer )
    {
        self.mediaViewContainer = [[UIView alloc] init];
        self.mediaViewContainer.tag = MEDIA_VIEW_CONTAINER_TAG;
        [self.nativeAdView addSubview: self.mediaViewContainer];
    }
    
    if ( !mediaView.superview )
    {
        [self.mediaViewContainer addSubview: mediaView];
        [mediaView al_pinToSuperview];
    }
    
    self.mediaViewContainer.frame = [self frameForCall: call];
}

- (void)renderAd
{
    if ( self.adLoader )
    {
        [self.adLoader registerClickableViews: self.clickableViews
                                withContainer: self.nativeAdView
                                        forAd: self.nativeAd];
        [self.adLoader handleNativeAdViewRenderedForAd: self.nativeAd];
    }
    else
    {
        [AppLovinMAX log: @"Attempting to render ad before ad has been loaded for Ad Unit ID %@", self.adUnitId];
    }
    
    [self.isLoading set: NO];
}

- (CGRect)frameForCall:(FlutterMethodCall *)call
{
    CGFloat x = ((NSNumber *)call.arguments[@"x"]).floatValue;
    CGFloat y = ((NSNumber *)call.arguments[@"y"]).floatValue;
    CGFloat width = ((NSNumber *)call.arguments[@"width"]).floatValue;
    CGFloat height = ((NSNumber *)call.arguments[@"height"]).floatValue;
    return CGRectMake(x, y, width, height);
}

#pragma mark - Utility Methods

- (void)sendEventWithName:(NSString *)name ad:(MAAd *)ad
{
    [[AppLovinMAX shared] sendEventWithName: name ad: ad channel: self.channel];
}

- (void)handleAdLoadFailed:(NSString *)message error:(MAError *)error
{
    [self.isLoading set: NO];
    
    [AppLovinMAX log: message];
    
    NSDictionary *body = [[AppLovinMAX shared] adLoadFailedInfoForAdUnitIdentifier: self.adUnitId withError: error];
    [[AppLovinMAX shared] sendEventWithName: @"OnNativeAdLoadFailedEvent" body: body channel: self.channel];
}

- (void)sendAdLoadedReactNativeEventForAd:(MANativeAd *)ad
{
    NSMutableDictionary<NSString *, id> *nativeAdInfo = [NSMutableDictionary dictionaryWithCapacity: 10];
    nativeAdInfo[@"title"] = ad.title;
    nativeAdInfo[@"advertiser"] = ad.advertiser;
    nativeAdInfo[@"body"] = ad.body;
    nativeAdInfo[@"callToAction"] = ad.callToAction;
    nativeAdInfo[@"starRating"] = ad.starRating;
    
    // The aspect ratio can be 0.0f when it is not provided by the network.
    if ( ad.mediaContentAspectRatio > 0 )
    {
        nativeAdInfo[@"mediaContentAspectRatio"] = @(ad.mediaContentAspectRatio);
    }
    
    nativeAdInfo[@"isIconImageAvailable"] = (ad.icon != nil) ? @YES : @NO;
    nativeAdInfo[@"isOptionsViewAvailable"] = (ad.optionsView != nil) ? @YES : @NO;
    nativeAdInfo[@"isMediaViewAvailable"] = (ad.mediaView != nil) ? @YES : @NO;
    
    NSMutableDictionary *adInfo = [[AppLovinMAX shared] adInfoForAd: self.nativeAd].mutableCopy;
    adInfo[@"nativeAd"] = nativeAdInfo;
    
    [[AppLovinMAX shared] sendEventWithName: @"OnNativeAdLoadedEvent" body: adInfo channel: self.channel];
}

- (void)destroyCurrentAdIfNeeded
{
    if ( self.nativeAd )
    {
        [self.mediaViewContainer al_removeAllSubviews];
        [self.optionsViewContainer al_removeAllSubviews];
        
        [self.adLoader destroyAd: self.nativeAd];
        
        self.nativeAd = nil;
    }
    
    [self.clickableViews removeAllObjects];
}

@end
