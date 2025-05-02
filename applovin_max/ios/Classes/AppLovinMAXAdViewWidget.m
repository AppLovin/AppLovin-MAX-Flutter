#import <AppLovinSDK/AppLovinSDK.h>
#import "AppLovinMAX.h"
#import "AppLovinMAXAdView.h"
#import "AppLovinMAXAdViewWidget.h"

@interface AppLovinMAXAdViewWidget()<MAAdViewAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, strong) MAAdView *adView;
@property (nonatomic, weak, nullable) AppLovinMAXAdView *containerView;
@property (nonatomic, assign) BOOL shouldPreload;

@end

@implementation AppLovinMAXAdViewWidget

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat isAdaptiveBannerEnabled:(BOOL)isAdaptiveBannerEnabled
{
    return [self initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat isAdaptiveBannerEnabled: isAdaptiveBannerEnabled shouldPreload: NO];
}

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat isAdaptiveBannerEnabled:(BOOL)isAdaptiveBannerEnabled shouldPreload:(BOOL)shouldPreload
{
    self = [super init];
    if ( self )
    {
        self.shouldPreload = shouldPreload;
        
        MAAdViewConfiguration *config = [MAAdViewConfiguration configurationWithBuilderBlock:^(MAAdViewConfigurationBuilder *builder) {
            builder.adaptiveType =  isAdaptiveBannerEnabled ? MAAdViewAdaptiveTypeAnchored : MAAdViewAdaptiveTypeNone;
        }];
        
        self.adView = [[MAAdView alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat configuration: config];
        self.adView.delegate = self;
        self.adView.revenueDelegate = self;
        
        // Set this extra parameter to work around a SDK bug that ignores calls to stopAutoRefresh()
        [self.adView setExtraParameterForKey: @"allow_pause_auto_refresh_immediately" value: @"true"];
        
        [self.adView stopAutoRefresh];
        
        // Set an initial frame size to avoid zero-area errors.
        self.adView.frame = (CGRect) { CGPointZero, adFormat.size };
        
        self.adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (NSString *)adUnitIdentifier
{
    return self.adView.adUnitIdentifier;
}

- (void)setPlacement:(nullable NSString *)placement
{
    self.adView.placement = placement;
}

- (void)setCustomData:(nullable NSString *)customData
{
    self.adView.customData = customData;
}

- (void)setExtraParameters:(nullable NSDictionary<NSString *, id> *)extraParameters
{
    for ( NSString *key in extraParameters )
    {
        [self.adView setExtraParameterForKey: key value: [extraParameters al_stringForKey: key]];
    }
}

- (void)setLocalExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
{
    for ( NSString *key in localExtraParameters )
    {
        id value = localExtraParameters[key];
        [self.adView setLocalExtraParameterForKey: key value: (value != [NSNull null] ? value : nil)];
    }
}

- (void)setAutoRefreshEnabled:(BOOL)autoRefreshEnabled
{
    if ( autoRefreshEnabled )
    {
        [self.adView startAutoRefresh];
    }
    else
    {
        [self.adView stopAutoRefresh];
    }
}

- (BOOL)hasContainerView
{
    return self.containerView != nil;
}

- (void)attachAdView:(AppLovinMAXAdView *)view
{
    self.containerView = view;
}

- (void)detachAdView
{
    self.containerView = nil;
    
    [self.adView removeFromSuperview];
}

- (void)loadAd
{
    [self.adView loadAd];
}

- (void)destroy
{
    [self detachAdView];
    
    self.adView.delegate = nil;
    self.adView.revenueDelegate = nil;
}

#pragma mark - MAAdDelegate Protocol

- (void)didLoadAd:(MAAd *)ad
{
    NSMutableDictionary *adInfo = [@{@"adViewId": @(self.hash)} mutableCopy];
    [adInfo addEntriesFromDictionary: [[AppLovinMAX shared] adInfoForAd: ad]];
    
    if ( self.shouldPreload )
    {
        [[AppLovinMAX shared] sendEventWithName: @"OnWidgetAdViewAdLoadedEvent" body: adInfo];
    }
    
    if ( self.containerView )
    {
        [self.containerView sendEventWithName: @"OnAdViewAdLoadedEvent" body: adInfo];
    }
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    NSMutableDictionary *adLoadFailedInfo = [@{@"adViewId": @(self.hash)} mutableCopy];
    [adLoadFailedInfo addEntriesFromDictionary: [[AppLovinMAX shared] adLoadFailedInfoForAdUnitIdentifier: adUnitIdentifier withError: error]];
    
    if ( self.shouldPreload )
    {
        [[AppLovinMAX shared] sendEventWithName: @"OnWidgetAdViewAdLoadFailedEvent" body: adLoadFailedInfo];
    }
    
    if ( self.containerView )
    {
        [self.containerView sendEventWithName: @"OnAdViewAdLoadFailedEvent" body: adLoadFailedInfo];
    }
}

- (void)didClickAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSMutableDictionary *adInfo = [@{@"adViewId": @(self.hash)} mutableCopy];
        [adInfo addEntriesFromDictionary: [[AppLovinMAX shared] adInfoForAd: ad]];
        
        [self.containerView sendEventWithName: @"OnAdViewAdClickedEvent" body: adInfo];
    }
}

#pragma mark - MAAdViewAdDelegate Protocol

- (void)didExpandAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSMutableDictionary *adInfo = [@{@"adViewId": @(self.hash)} mutableCopy];
        [adInfo addEntriesFromDictionary: [[AppLovinMAX shared] adInfoForAd: ad]];
        
        [self.containerView sendEventWithName: @"OnAdViewAdExpandedEvent" body: adInfo];
    }
}

- (void)didCollapseAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSMutableDictionary *adInfo = [@{@"adViewId": @(self.hash)} mutableCopy];
        [adInfo addEntriesFromDictionary: [[AppLovinMAX shared] adInfoForAd: ad]];
        
        [self.containerView sendEventWithName: @"OnAdViewAdCollapsedEvent" body: adInfo];
    }
}

#pragma mark - MAAdRevenueDelegate Protocol

- (void)didPayRevenueForAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSMutableDictionary *adInfo = [@{@"adViewId": @(self.hash)} mutableCopy];
        [adInfo addEntriesFromDictionary: [[AppLovinMAX shared] adInfoForAd: ad]];
        
        [self.containerView sendEventWithName: @"OnAdViewAdRevenuePaidEvent" body: adInfo];
    }
}

#pragma mark - Deprecated Callbacks

- (void)didDisplayAd:(MAAd *)ad {}
- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {}
- (void)didHideAd:(MAAd *)ad {}

@end
