//
//  AppLovinMAXAdView.m
//  applovin_max
//
//  Created by Thomas So on 7/17/22.
//

#import "AppLovinMAXAdView.h"
#import "AppLovinMAX.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinMAXAdView()<MAAdViewAdDelegate, MAAdRevenueDelegate>
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) MAAdView *adView;
@end

@implementation AppLovinMAXAdView

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                     adFormat:(MAAdFormat *)adFormat
                    placement:(nullable NSString *)placement
                   customData:(nullable NSString *)customData
                    messenger:(id<FlutterBinaryMessenger>)messenger sdk:(ALSdk *)sdk
{
    self = [super init];
    if ( self )
    {
        NSString *uniqueChannelName = [NSString stringWithFormat: @"applovin_max/adview_%lld", viewId];
        self.channel = [FlutterMethodChannel methodChannelWithName: uniqueChannelName binaryMessenger: messenger];
        
        self.adView = [[MAAdView alloc] initWithAdUnitIdentifier: adUnitId adFormat: adFormat sdk: sdk];
        self.adView.frame = frame;
        self.adView.delegate = self;
        self.adView.revenueDelegate = self;
        
        self.adView.placement = placement;
        self.adView.customData = customData;
        
        [self.adView loadAd];
    }
    return self;
}

- (UIView *)view
{
    return self.adView;
}

#pragma mark - Ad Callbacks

- (void)didLoadAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnAdViewAdLoadedEvent" ad: ad];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    [[AppLovinMAX shared] sendErrorEventWithName: @"OnAdViewAdLoadFailedEvent"
                             forAdUnitIdentifier: adUnitIdentifier
                                       withError: error];
}

- (void)didClickAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnAdViewAdClickedEvent" ad: ad];
}

- (void)didExpandAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnAdViewAdExpandedEvent" ad: ad];
}

- (void)didCollapseAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnAdViewAdCollapsedEvent" ad: ad];
}

- (void)didPayRevenueForAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnAdViewAdRevenuePaidEvent" ad: ad];
}

- (void)didDisplayAd:(MAAd *)ad {}
- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {}
- (void)didHideAd:(MAAd *)ad {}

- (void)sendEventWithName:(NSString *)name ad:(MAAd *)ad
{
    [[AppLovinMAX shared] sendEventWithName: name ad: ad channel: self.channel];
}

@end
