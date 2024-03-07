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

static NSMutableDictionary<NSString *, MAAdView *> *adViewInstances;

+ (void)initialize
{
    [super initialize];
    adViewInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
}

+ (MAAdView *)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    return adViewInstances[adUnitIdentifier];
}

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                     adFormat:(MAAdFormat *)adFormat
         isAutoRefreshEnabled:(BOOL)isAutoRefreshEnabled
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
        __weak typeof(self) weakSelf = self;
        
        NSString *uniqueChannelName = [NSString stringWithFormat: @"applovin_max/adview_%lld", viewId];
        self.channel = [FlutterMethodChannel methodChannelWithName: uniqueChannelName binaryMessenger: messenger];
        [self.channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            
            if ( [@"startAutoRefresh" isEqualToString: call.method] )
            {
                [weakSelf.adView startAutoRefresh];
                result(nil);
            }
            else if ( [@"stopAutoRefresh" isEqualToString: call.method] )
            {
                [weakSelf.adView stopAutoRefresh];
                result(nil);
            }
            else
            {
                result(FlutterMethodNotImplemented);
            }
        }];
        
        self.adView = [[MAAdView alloc] initWithAdUnitIdentifier: adUnitId adFormat: adFormat sdk: sdk];
        self.adView.frame = frame;
        self.adView.delegate = self;
        self.adView.revenueDelegate = self;
        
        self.adView.placement = placement;
        self.adView.customData = customData;
        
        [self.adView setExtraParameterForKey: @"allow_pause_auto_refresh_immediately" value: @"true"];
        
        for ( NSString *key in extraParameters )
        {
            [self.adView setExtraParameterForKey: key value: extraParameters[key]];
        }
        
        for ( NSString *key in localExtraParameters )
        {
            [self.adView setLocalExtraParameterForKey: key value: localExtraParameters[key]];
        }
        
        [self.adView loadAd];
        
        if ( !isAutoRefreshEnabled )
        {
            [self.adView stopAutoRefresh];
        }

        adViewInstances[adUnitId] = self.adView;
    }
    return self;
}

- (UIView *)view
{
    return self.adView;
}

- (void)dealloc
{
    [adViewInstances removeObjectForKey: self.adView.adUnitIdentifier];

    [self.channel setMethodCallHandler: nil];
    self.channel = nil;
}

#pragma mark - Ad Callbacks

- (void)didLoadAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnAdViewAdLoadedEvent" ad: ad];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    NSDictionary *body = [[AppLovinMAX shared] adLoadFailedInfoForAdUnitIdentifier: adUnitIdentifier withError: error];
    [[AppLovinMAX shared] sendEventWithName: @"OnAdViewAdLoadFailedEvent" body: body channel: self.channel];
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
