#import "AppLovinMAXNativeAdView.h"
#import "AppLovinMAX.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinMAXNativeAdView()<MANativeAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) MANativeAdLoader *nativeAdLoader;
@property (nonatomic, strong) MAAd *nativeAd;
@property (nonatomic, strong) UIView *nativeAdView;
@property (nonatomic, strong) UIView *_view;
@end

@implementation AppLovinMAXNativeAdView

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                    placement:(nullable NSString *)placement
                   customData:(nullable NSString *)customData
                    messenger:(id<FlutterBinaryMessenger>)messenger
                          sdk:(ALSdk *)sdk
{
    self = [super init];
    if ( self )
    {

        __weak typeof(self) weakSelf = self;
        self._view = [[UIView alloc] initWithFrame: frame];
        NSString *uniqueChannelName = [NSString stringWithFormat: @"applovin_max/adview_%lld", viewId];
        self.channel = [FlutterMethodChannel methodChannelWithName: uniqueChannelName binaryMessenger: messenger];
        [self.channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            
            if ( [@"load" isEqualToString: call.method] )
            {
                [weakSelf.nativeAdLoader loadAd];
                result(nil);
            }
            else
            {
                result(FlutterMethodNotImplemented);
            }
        }];
        
        self.nativeAdLoader = [[MANativeAdLoader alloc] initWithAdUnitIdentifier: adUnitId sdk: sdk];
        self.nativeAdLoader.nativeAdDelegate = self;
        self.nativeAdLoader.revenueDelegate = self;

        self.nativeAdLoader.placement = placement;
        self.nativeAdLoader.customData = customData;

        [self.nativeAdLoader loadAd];

    }
    return self;
}

- (UIView *)view
{
    return self._view;
}

- (void)dealloc
{
    // Clean up any pre-existing native ad to prevent memory leaks
    if ( self.nativeAd )
    {
        [self.nativeAdLoader destroyAd: self.nativeAd];
    }
    [self.channel setMethodCallHandler: nil];
    self.channel = nil;
}

#pragma mark - Ad Callbacks

- (void)didLoadNativeAd:(MANativeAdView *)nativeAdView forAd:(MAAd *)ad
{
    // Clean up any pre-existing native ad to prevent memory leaks
    if ( self.nativeAd )
    {
        [self.nativeAdLoader destroyAd: self.nativeAd];
    }
    // Save ad for cleanup
    self.nativeAd = ad;

    if ( self.nativeAdView )
    {
        [self.nativeAdView removeFromSuperview];
    }
    
    // Add ad view to view
    self.nativeAdView = nativeAdView;
    [self._view addSubview: nativeAdView];
    [self sendEventWithName: @"OnNativeAdViewAdLoadedEvent" ad: ad];
}

- (void)didFailToLoadNativeAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    [[AppLovinMAX shared] sendErrorEventWithName: @"OnNativeAdViewAdLoadFailedEvent"
                             forAdUnitIdentifier: adUnitIdentifier
                                       withError: error];
}

- (void)didPayRevenueForAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnNativeAdViewAdRevenuePaidEvent" ad: ad];
}

- (void)sendEventWithName:(NSString *)name ad:(MAAd *)ad
{
    [[AppLovinMAX shared] sendEventWithName: name ad: ad channel: self.channel];
}

@end
