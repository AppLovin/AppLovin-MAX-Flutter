#import "AppLovinMAXNativeAdView.h"
#import "AppLovinMAX.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinMAXNativeAdView()<MANativeAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, weak) IBOutlet UIView *nativeAdContainerView;

@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) MANativeAdLoader *nativeAdLoader;
@property (nonatomic, strong) MAAd *nativeAd;
@property (nonatomic, strong) UIView *nativeAdView;
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
    return self.nativeAdView;
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
    [self.nativeAdContainerView addSubview: nativeAdView];

    // Set to false if modifying constraints after adding the ad view to your layout
    self.nativeAdContainerView.translatesAutoresizingMaskIntoConstraints = NO;

    // Set ad view to span width and height of container and center the ad
    [self.nativeAdContainerView addConstraint: [NSLayoutConstraint constraintWithItem: nativeAdView
                                                                            attribute: NSLayoutAttributeWidth
                                                                            relatedBy: NSLayoutRelationEqual
                                                                               toItem: self.nativeAdContainerView
                                                                            attribute: NSLayoutAttributeWidth
                                                                           multiplier: 1
                                                                             constant: 0]];
    [self.nativeAdContainerView addConstraint: [NSLayoutConstraint constraintWithItem: nativeAdView
                                                                            attribute: NSLayoutAttributeHeight
                                                                            relatedBy: NSLayoutRelationEqual
                                                                               toItem: self.nativeAdContainerView
                                                                            attribute: NSLayoutAttributeHeight
                                                                           multiplier: 1
                                                                             constant: 0]];
    [self.nativeAdContainerView addConstraint: [NSLayoutConstraint constraintWithItem: nativeAdView
                                                                            attribute: NSLayoutAttributeCenterX
                                                                            relatedBy: NSLayoutRelationEqual
                                                                               toItem: self.nativeAdContainerView
                                                                            attribute: NSLayoutAttributeCenterX
                                                                           multiplier: 1
                                                                             constant: 0]];
    [self.nativeAdContainerView addConstraint: [NSLayoutConstraint constraintWithItem: nativeAdView
                                                                            attribute: NSLayoutAttributeCenterY
                                                                            relatedBy: NSLayoutRelationEqual
                                                                               toItem: self.nativeAdContainerView
                                                                            attribute: NSLayoutAttributeCenterY
                                                                           multiplier: 1
                                                                             constant: 0]];


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