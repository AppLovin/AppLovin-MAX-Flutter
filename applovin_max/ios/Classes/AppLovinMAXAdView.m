//
//  AppLovinMAXAdView.m
//  applovin_max
//
//  Created by Thomas So on 7/17/22.
//

#import "AppLovinMAX.h"
#import "AppLovinMAXAdView.h"
#import "AppLovinMAXAdViewPlatformWidget.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinMAXAdView()
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong, nullable) AppLovinMAXAdViewPlatformWidget *platformWidget;
@end

@implementation AppLovinMAXAdView

static NSMutableDictionary<NSString *, AppLovinMAXAdViewPlatformWidget *> *platformWidgetInstances;
static NSMutableDictionary<NSString *, AppLovinMAXAdViewPlatformWidget *> *preloadedPlatformWidgetInstances;

+ (void)initialize
{
    [super initialize];
    platformWidgetInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
    preloadedPlatformWidgetInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
}

+ (MAAdView *)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    return (preloadedPlatformWidgetInstances[adUnitIdentifier] ?: platformWidgetInstances[adUnitIdentifier]).adView;
}

#pragma mark - Preloading

+ (void)preloadPlatformWidgetAdView:(NSString *)adUnitIdentifier 
                           adFormat:(MAAdFormat *)adFormat
                          placement:(nullable NSString *)placement  
                         customData:(nullable NSString *)customData
                    extraParameters:(nullable NSDictionary<NSString *, id> *)extraParameters
               localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                         withResult:(FlutterResult)result
{
    AppLovinMAXAdViewPlatformWidget *preloadedPlatformWidget = preloadedPlatformWidgetInstances[adUnitIdentifier];
    if ( preloadedPlatformWidget )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"Cannot preload more than one for a single Ad Unit ID." details: nil]);
        return;
    }
    
    preloadedPlatformWidget = [[AppLovinMAXAdViewPlatformWidget alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat shouldPreload: YES];
    preloadedPlatformWidgetInstances[adUnitIdentifier] = preloadedPlatformWidget;
    
    preloadedPlatformWidget.placement = placement;
    preloadedPlatformWidget.customData = customData;
    preloadedPlatformWidget.extraParameters = extraParameters;
    preloadedPlatformWidget.localExtraParameters = localExtraParameters;
    
    [preloadedPlatformWidget loadAd];
    
    result(nil);
}

+ (void)destroyPlatformWidgetAdView:(NSString *)adUnitIdentifier withResult:(FlutterResult)result
{
    AppLovinMAXAdViewPlatformWidget *preloadedPlatformWidget = preloadedPlatformWidgetInstances[adUnitIdentifier];
    if ( !preloadedPlatformWidget )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"No native UI component found to destroy" details: nil]);
        return;
    }
    
    if ( [preloadedPlatformWidget hasContainerView] )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"Cannot destroy - currently in use" details: nil]);
        return;
    }
    
    [preloadedPlatformWidgetInstances removeObjectForKey: adUnitIdentifier];
    
    [preloadedPlatformWidget detachAdView];
    [preloadedPlatformWidget destroy];
    
    result(nil);
}

#pragma mark - AdView

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
                [weakSelf.platformWidget.adView startAutoRefresh];
                result(nil);
            }
            else if ( [@"stopAutoRefresh" isEqualToString: call.method] )
            {
                [weakSelf.platformWidget.adView stopAutoRefresh];
                result(nil);
            }
            else
            {
                result(FlutterMethodNotImplemented);
            }
        }];
        
        self.platformWidget = preloadedPlatformWidgetInstances[adUnitId];
        if ( self.platformWidget )
        {
            // Attach the preloaded widget if possible, otherwise create a new one for the
            // same adUnitId
            if ( ![self.platformWidget hasContainerView] )
            {
                self.platformWidget.autoRefreshEnabled = isAutoRefreshEnabled;
                [self.platformWidget attachAdView: self];
                return self;
            }
        }
        
        self.platformWidget = [[AppLovinMAXAdViewPlatformWidget alloc] initWithAdUnitIdentifier: adUnitId adFormat: adFormat];
        platformWidgetInstances[adUnitId] = self.platformWidget;
        
        self.platformWidget.placement = placement;
        self.platformWidget.customData = customData;
        self.platformWidget.extraParameters = extraParameters;
        self.platformWidget.localExtraParameters = localExtraParameters;
        self.platformWidget.autoRefreshEnabled = isAutoRefreshEnabled;
        
        [self.platformWidget attachAdView: self];
        [self.platformWidget loadAd];
    }
    return self;
}

- (UIView *)view
{
    return self.platformWidget.adView;
}

- (void)dealloc
{
    [self.platformWidget detachAdView];
    
    AppLovinMAXAdViewPlatformWidget *preloadedPlatformWidget = preloadedPlatformWidgetInstances[self.platformWidget.adView.adUnitIdentifier];
    
    if ( self.platformWidget != preloadedPlatformWidget )
    {
        [platformWidgetInstances removeObjectForKey: self.platformWidget.adView.adUnitIdentifier];
        [self.platformWidget destroy];
    }
    
    [self.channel setMethodCallHandler: nil];
    self.channel = nil;
}

- (void)sendEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body;
{
    [[AppLovinMAX shared] sendEventWithName: name body: body channel: self.channel];
}

@end
