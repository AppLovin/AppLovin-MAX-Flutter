#import <AppLovinSDK/AppLovinSDK.h>
#import "AppLovinMAX.h"
#import "AppLovinMAXAdView.h"
#import "AppLovinMAXAdViewUIComponent.h"

@interface AppLovinMAXAdViewUIComponent()<MAAdViewAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, strong) MAAdView *adView;
@property (nonatomic, weak, nullable) AppLovinMAXAdView *containerView;

@end

@implementation AppLovinMAXAdViewUIComponent

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    self = [super init];
    if ( self )
    {
        self.adView = [[MAAdView alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat sdk: [AppLovinMAX shared].sdk];
        self.adView.delegate = self;
        self.adView.revenueDelegate = self;
        
        // Set this extra parameter to work around a SDK bug that ignores calls to stopAutoRefresh()
        [self.adView setExtraParameterForKey: @"allow_pause_auto_refresh_immediately" value: @"true"];
        
        // Set a frame size to suppress an error of zero area for MAAdView
        self.adView.frame = (CGRect) { CGPointZero, adFormat.size };
    }
    return self;
}

- (void)setPlacement:(NSString *)placement
{
    self.adView.placement = placement;
}

- (void)setCustomData:(NSString *)customData
{
    self.adView.customData = customData;
}

- (void)setAdaptiveBannerEnabled:(BOOL)adaptiveBannerEnabled
{
    [self.adView setExtraParameterForKey: @"adaptive_banner" value: adaptiveBannerEnabled ? @"true" : @"false"];
}

- (void)setAutoRefresh:(BOOL)autoRefresh
{
    if ( autoRefresh )
    {
        [self.adView startAutoRefresh];
    }
    else
    {
        [self.adView stopAutoRefresh];
    }
}

-(void)setExtraParameters:(NSDictionary<NSString *, id> *)parameterDict
{
    for (NSString *key in parameterDict)
    {
        NSString *value = (NSString *) parameterDict[key];
        [self.adView setExtraParameterForKey: key value: value];
    }
}

-(void)setLocalExtraParameters:(NSDictionary<NSString *, id> *)parameterDict
{
    for (NSString *key in parameterDict)
    {
        id value = parameterDict[key];
        [self.adView setLocalExtraParameterForKey: key value: value];
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
    NSDictionary *adInfo = [[AppLovinMAX shared] adInfoForAd: ad];
    
    [[AppLovinMAX shared] sendEventWithName:@"OnNativeUIComponentAdViewAdLoadedEvent" body: adInfo];
    
    if ( self.containerView )
    {
        [self.containerView sendEventWithName: @"OnAdViewAdLoadedEvent" body: adInfo];
    }
    else
    {
        [self setAutoRefresh: NO];
    }
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    NSDictionary *adLoadFailedInfo = [[AppLovinMAX shared] adLoadFailedInfoForAdUnitIdentifier: adUnitIdentifier withError: error];
    
    [[AppLovinMAX shared] sendEventWithName:@"OnNativeUIComponentAdViewAdLoadFailedEvent" body: adLoadFailedInfo];
    
    if ( self.containerView )
    {
        [self.containerView sendEventWithName: @"OnAdViewAdLoadFailedEvent" body: adLoadFailedInfo];
    }
}

- (void)didClickAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSDictionary *adInfo = [[AppLovinMAX shared] adInfoForAd: ad];
        [self.containerView sendEventWithName: @"OnAdViewAdClickedEvent" body: adInfo];
    }
}

#pragma mark - MAAdViewAdDelegate Protocol

- (void)didExpandAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSDictionary *adInfo = [[AppLovinMAX shared] adInfoForAd: ad];
        [self.containerView sendEventWithName: @"OnAdViewAdExpandedEvent" body: adInfo];
    }
}

- (void)didCollapseAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSDictionary *adInfo = [[AppLovinMAX shared] adInfoForAd: ad];
        [self.containerView sendEventWithName: @"OnAdViewAdCollapsedEvent" body: adInfo];
    }
}

#pragma mark - MAAdRevenueDelegate Protocol

- (void)didPayRevenueForAd:(MAAd *)ad
{
    if ( self.containerView )
    {
        NSDictionary *adInfo = [[AppLovinMAX shared] adInfoForAd: ad];
        [self.containerView sendEventWithName: @"OnAdViewAdRevenuePaidEvent" body: adInfo];
    }
}

#pragma mark - Deprecated Callbacks

- (void)didDisplayAd:(MAAd *)ad {}
- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {}
- (void)didHideAd:(MAAd *)ad {}

@end
