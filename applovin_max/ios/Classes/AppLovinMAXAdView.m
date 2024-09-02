//
//  AppLovinMAXAdView.m
//  applovin_max
//
//  Created by Thomas So on 7/17/22.
//

#import "AppLovinMAX.h"
#import "AppLovinMAXAdView.h"
#import "AppLovinMAXAdViewWidget.h"
#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinMAXAdView()
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong, nullable) AppLovinMAXAdViewWidget *widget;
@end

@implementation AppLovinMAXAdView

static NSMutableDictionary<NSString *, AppLovinMAXAdViewWidget *> *widgetInstances;
static NSMutableDictionary<NSString *, AppLovinMAXAdViewWidget *> *preloadedWidgetInstances;

+ (void)initialize
{
    [super initialize];
    widgetInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
    preloadedWidgetInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
}

+ (MAAdView *)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    return (preloadedWidgetInstances[adUnitIdentifier] ?: widgetInstances[adUnitIdentifier]).adView;
}

#pragma mark - Preloading

+ (void)preloadWidgetAdView:(NSString *)adUnitIdentifier
                   adFormat:(MAAdFormat *)adFormat
                  placement:(nullable NSString *)placement
                 customData:(nullable NSString *)customData
            extraParameters:(nullable NSDictionary<NSString *, id> *)extraParameters
       localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                 withResult:(FlutterResult)result
{
    AppLovinMAXAdViewWidget *preloadedWidget = preloadedWidgetInstances[adUnitIdentifier];
    if ( preloadedWidget )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"Cannot preload more than once for a single Ad Unit ID." details: nil]);
        return;
    }
    
    preloadedWidget = [[AppLovinMAXAdViewWidget alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat shouldPreload: YES];
    preloadedWidgetInstances[adUnitIdentifier] = preloadedWidget;
    
    preloadedWidget.placement = placement;
    preloadedWidget.customData = customData;
    preloadedWidget.extraParameters = extraParameters;
    preloadedWidget.localExtraParameters = localExtraParameters;
    
    [preloadedWidget loadAd];
    
    result(nil);
}

+ (void)destroyWidgetAdView:(NSString *)adUnitIdentifier withResult:(FlutterResult)result
{
    AppLovinMAXAdViewWidget *preloadedWidget = preloadedWidgetInstances[adUnitIdentifier];
    if ( !preloadedWidget )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"No widget found to destroy" details: nil]);
        return;
    }
    
    if ( [preloadedWidget hasContainerView] )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"Cannot destroy - currently in use" details: nil]);
        return;
    }
    
    [preloadedWidgetInstances removeObjectForKey: adUnitIdentifier];
    
    [preloadedWidget detachAdView];
    [preloadedWidget destroy];
    
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
                [weakSelf.widget.adView startAutoRefresh];
                result(nil);
            }
            else if ( [@"stopAutoRefresh" isEqualToString: call.method] )
            {
                [weakSelf.widget.adView stopAutoRefresh];
                result(nil);
            }
            else
            {
                result(FlutterMethodNotImplemented);
            }
        }];
        
        self.widget = preloadedWidgetInstances[adUnitId];
        if ( self.widget )
        {
            // Attach the preloaded widget if possible, otherwise create a new one for the
            // same adUnitId
            if ( ![self.widget hasContainerView] )
            {
                self.widget.autoRefreshEnabled = isAutoRefreshEnabled;
                [self.widget attachAdView: self];
                return self;
            }
        }
        
        self.widget = [[AppLovinMAXAdViewWidget alloc] initWithAdUnitIdentifier: adUnitId adFormat: adFormat];
        widgetInstances[adUnitId] = self.widget;
        
        self.widget.placement = placement;
        self.widget.customData = customData;
        self.widget.extraParameters = extraParameters;
        self.widget.localExtraParameters = localExtraParameters;
        self.widget.autoRefreshEnabled = isAutoRefreshEnabled;
        
        [self.widget attachAdView: self];
        [self.widget loadAd];
    }
    return self;
}

- (UIView *)view
{
    return self.widget.adView;
}

- (void)dealloc
{
    [self.widget detachAdView];
    
    AppLovinMAXAdViewWidget *preloadedWidget = preloadedWidgetInstances[self.widget.adView.adUnitIdentifier];
    
    if ( self.widget != preloadedWidget )
    {
        [widgetInstances removeObjectForKey: self.widget.adView.adUnitIdentifier];
        [self.widget destroy];
    }
    
    [self.channel setMethodCallHandler: nil];
    self.channel = nil;
}

- (void)sendEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body;
{
    [[AppLovinMAX shared] sendEventWithName: name body: body channel: self.channel];
}

@end
