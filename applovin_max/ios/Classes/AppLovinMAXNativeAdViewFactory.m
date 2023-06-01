#import "AppLovinMAXNativeAdViewFactory.h"
#import "AppLovinMAXNativeAdView.h"
#import "AppLovinMAX.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinMAXNativeAdViewFactory()
@property (nonatomic, strong) id<FlutterBinaryMessenger> messenger;
@end

@implementation AppLovinMAXNativeAdViewFactory

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
    
    [AppLovinMAX log: @"Creating MaxNativeAdView widget with Ad Unit ID: %@", adUnitId];
    
    // Optional params
    NSString *placement = [args[@"placement"] isKindOfClass: [NSString class]] ? args[@"placement"] : nil; // May be NSNull
    NSString *customData = [args[@"customData"] isKindOfClass: [NSString class]] ? args[@"customData"] : nil; // May be NSNull
    
    return [[AppLovinMAXNativeAdView alloc] initWithFrame: frame
                                             viewId: viewId
                                           adUnitId: adUnitId
                                          placement: placement
                                         customData: customData
                                          messenger: self.messenger
                                                sdk: sdk];
}

@end
