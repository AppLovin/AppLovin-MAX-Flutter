//
//  AppLovinMAXAdView.m
//  applovin_max
//
//  Created by Thomas So on 7/17/22.
//

#import <AppLovinSDK/AppLovinSDK.h>
#import "AppLovinMAX.h"
#import "AppLovinMAXAdView.h"
#import "AppLovinMAXAdViewUIComponent.h"


@interface AppLovinMAXAdView()
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong, nullable) AppLovinMAXAdViewUIComponent *uiComponent;
@end

@implementation AppLovinMAXAdView

static NSMutableDictionary<NSString *, AppLovinMAXAdViewUIComponent *> *uiComponentInstances;
static NSMutableDictionary<NSString *, AppLovinMAXAdViewUIComponent *> *preloadedUIComponentInstances;

+ (void)initialize
{
    [super initialize];
    uiComponentInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
    preloadedUIComponentInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
}

+ (MAAdView *)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    AppLovinMAXAdViewUIComponent *uiComponent = preloadedUIComponentInstances[adUnitIdentifier];
    if ( !uiComponent ) uiComponent = uiComponentInstances[adUnitIdentifier];
    return uiComponent ? uiComponent.adView : nil;
}

+ (void)preloadNativeUIComponentAdView:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat placement:(NSString *)placement  customData:(NSString *)customData extraParameters:(NSDictionary<NSString *, NSString *> *)extraParameters localExtraParameters:(NSDictionary<NSString *, id> *)localExtraParameters withResult:(FlutterResult)result
{
    AppLovinMAXAdViewUIComponent *preloadedUIComponent = preloadedUIComponentInstances[adUnitIdentifier];
    if ( preloadedUIComponent )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"Cannot preload more than one for a single Ad Unit ID." details: nil]);
        return;
    }
    
    preloadedUIComponent = [[AppLovinMAXAdViewUIComponent alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    preloadedUIComponentInstances[adUnitIdentifier] = preloadedUIComponent;
    
    preloadedUIComponent.placement = placement;
    preloadedUIComponent.customData = customData;
    preloadedUIComponent.extraParameters = extraParameters;
    preloadedUIComponent.localExtraParameters = localExtraParameters;
    
    [preloadedUIComponent loadAd];
    
    result(nil);
}

+ (void)destroyNativeUIComponentAdView:(NSString *)adUnitIdentifier withResult:(FlutterResult)result
{
    AppLovinMAXAdViewUIComponent *preloadedUIComponent = preloadedUIComponentInstances[adUnitIdentifier];
    if ( !preloadedUIComponent )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"No native UI component found to destroy" details: nil]);
        return;
    }
    
    if ( [preloadedUIComponent hasContainerView] )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"Cannot destroy - currently in use" details: nil]);
        return;
    }
    
    [preloadedUIComponentInstances removeObjectForKey: adUnitIdentifier];
    
    [preloadedUIComponent detachAdView];
    [preloadedUIComponent destroy];
    
    result(nil);
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
                [weakSelf.uiComponent.adView startAutoRefresh];
                result(nil);
            }
            else if ( [@"stopAutoRefresh" isEqualToString: call.method] )
            {
                [weakSelf.uiComponent.adView stopAutoRefresh];
                result(nil);
            }
            else
            {
                result(FlutterMethodNotImplemented);
            }
        }];
        
        self.uiComponent = preloadedUIComponentInstances[adUnitId];
        if ( self.uiComponent )
        {
            // Attach the preloaded uiComponent if possible, otherwise create a new one for the
            // same adUnitId
            if ( ![self.uiComponent hasContainerView] )
            {
                self.uiComponent.autoRefresh = isAutoRefreshEnabled;
                [self.uiComponent attachAdView: self];
                return self;
            }
        }
        
        self.uiComponent = [[AppLovinMAXAdViewUIComponent alloc] initWithAdUnitIdentifier: adUnitId adFormat: adFormat];
        uiComponentInstances[adUnitId] = self.uiComponent;
        
        self.uiComponent.placement = placement;
        self.uiComponent.customData = customData;
        self.uiComponent.extraParameters = extraParameters;
        self.uiComponent.localExtraParameters = localExtraParameters;
        self.uiComponent.autoRefresh = isAutoRefreshEnabled;
        
        [self.uiComponent attachAdView: self];
        [self.uiComponent loadAd];
    }
    return self;
}

- (UIView *)view
{
    return self.uiComponent.adView;
}

- (void)dealloc
{
    [self.uiComponent detachAdView];
    
    AppLovinMAXAdViewUIComponent *preloadedUIComponent = preloadedUIComponentInstances[self.uiComponent.adView.adUnitIdentifier];
    
    if ( self.uiComponent == preloadedUIComponent )
    {
        self.uiComponent.autoRefresh = NO;
    }
    else
    {
        [uiComponentInstances removeObjectForKey: self.uiComponent.adView.adUnitIdentifier];
        [self.uiComponent destroy];
    }
    
    [self.channel setMethodCallHandler: nil];
    self.channel = nil;
}

- (void)sendEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body;
{
    [[AppLovinMAX shared] sendEventWithName: name body: body channel: self.channel];
}

@end
