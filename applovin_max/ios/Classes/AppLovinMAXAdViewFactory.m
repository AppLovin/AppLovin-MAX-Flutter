//
//  AppLovinMAXAdViewFactory.m
//  applovin_max
//
//  Created by Thomas So on 7/17/22.
//

#import "AppLovinMAXAdViewFactory.h"
#import "AppLovinMAXAdView.h"
#import "AppLovinMAX.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinMAXAdViewFactory()
@property (nonatomic, strong) id<FlutterBinaryMessenger> messenger;
@end

@implementation AppLovinMAXAdViewFactory

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger
{
    self = [super init];
    if ( self )
    {
        self.messenger = messenger;
    }
    return self;
}

- (id<FlutterMessageCodec>)createArgsCodec
{
    return [FlutterStandardMessageCodec sharedInstance];
}

- (id<FlutterPlatformView>)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args
{
    // Ensure plugin has been initialized
    ALSdk *sdk = AppLovinMAX.shared.sdk;
    if ( !sdk )
    {
        [AppLovinMAX log: @"Failed to create MaxAdView widget - please ensure the AppLovin MAX plugin has been initialized by calling 'AppLovinMAX.initialize(...);'!"];
        return nil;
    }
    
    NSString *adUnitId = args[@"ad_unit_id"];
    NSString *adFormatStr = args[@"ad_format"];
    MAAdFormat *adFormat = [adFormatStr isEqualToString: @"mrec"] ? MAAdFormat.mrec : DEVICE_SPECIFIC_ADVIEW_AD_FORMAT;
    
    [AppLovinMAX log: @"Creating MaxAdView widget with Ad Unit ID: %@", adUnitId];
    
    // Optional params
    NSString *placement = args[@"placement"];
    NSString *customData = args[@"customData"];
    
    return [[AppLovinMAXAdView alloc] initWithFrame: (CGRect) { .size = adFormat.size }
                                             viewId: viewId
                                           adUnitId: adUnitId
                                           adFormat: adFormat
                                          placement: placement
                                         customData: customData
                                          messenger: self.messenger
                                                sdk: sdk];
}

@end
