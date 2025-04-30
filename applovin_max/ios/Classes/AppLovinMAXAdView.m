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
@property (nonatomic, copy) NSNumber *adViewId;
@end

@implementation AppLovinMAXAdView

static NSMutableDictionary<NSNumber *, AppLovinMAXAdViewWidget *> *widgetInstances;
static NSMutableDictionary<NSNumber *, AppLovinMAXAdViewWidget *> *preloadedWidgetInstances;

+ (void)initialize
{
    [super initialize];
    widgetInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
    preloadedWidgetInstances = [NSMutableDictionary dictionaryWithCapacity: 2];
}

// Returns an MAAdView to support Amazon integrations. This method returns the first instance that
// matches the Ad Unit ID, consistent with the behavior introduced when this feature was first
// implemented.
+ (nullable MAAdView *)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    for ( id key in preloadedWidgetInstances )
    {
        AppLovinMAXAdViewWidget *widget = preloadedWidgetInstances[key];
        if ( [widget.adUnitIdentifier isEqualToString: adUnitIdentifier] )
        {
            return widget.adView;
        }
    }
    
    for ( id key in widgetInstances )
    {
        AppLovinMAXAdViewWidget *widget = widgetInstances[key];
        if ( [widget.adUnitIdentifier isEqualToString: adUnitIdentifier] )
        {
            return widget.adView;
        }
    }
    
    return nil;
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
    AppLovinMAXAdViewWidget *preloadedWidget = [[AppLovinMAXAdViewWidget alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat shouldPreload: YES];
    preloadedWidgetInstances[@(preloadedWidget.hash)] = preloadedWidget;
    
    [preloadedWidget setPlacement: placement];
    [preloadedWidget setCustomData: customData];
    [preloadedWidget setExtraParameters: extraParameters];
    [preloadedWidget setLocalExtraParameters: localExtraParameters];
    
    [preloadedWidget loadAd];
    
    result(@(preloadedWidget.hash));
}

+ (void)destroyWidgetAdView:(NSNumber *)adViewId withResult:(FlutterResult)result
{
    AppLovinMAXAdViewWidget *preloadedWidget = preloadedWidgetInstances[adViewId];
    if ( !preloadedWidget )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"No preloaded AdView found to destroy" details: nil]);
        return;
    }
    
    if ( [preloadedWidget hasContainerView] )
    {
        result([FlutterError errorWithCode: @"AppLovinMAX" message: @"Cannot destroy - the preloaded AdView is currently in use" details: nil]);
        return;
    }
    
    [preloadedWidgetInstances removeObjectForKey: adViewId];
    
    [preloadedWidget detachAdView];
    [preloadedWidget destroy];
    
    result(nil);
}

#pragma mark - AdView

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                     adFormat:(MAAdFormat *)adFormat
                     adViewId:(nullable NSNumber *)adViewId
      isAdaptiveBannerEnabled:(BOOL)isAdaptiveBannerEnabled
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
        
        self.widget = preloadedWidgetInstances[adViewId];
        if ( self.widget )
        {
            // Attach the preloaded widget if available, otherwise create a new widget for the same ad unit.
            if ( ![self.widget hasContainerView] )
            {
                [AppLovinMAX log: @"Mounting the preloaded AdView (%@) for Ad Unit ID %@", adViewId, adUnitId];
                
                self.widget.adView.frame = frame;
                self.adViewId = adViewId;
                [self.widget setAutoRefreshEnabled: isAutoRefreshEnabled];
                [self.widget attachAdView: self];
                return self;
            }
        }
        
        self.widget = [[AppLovinMAXAdViewWidget alloc] initWithAdUnitIdentifier: adUnitId adFormat: adFormat];
        self.widget.adView.frame = frame;
        self.adViewId = @(self.widget.hash);
        widgetInstances[self.adViewId] = self.widget;
        
        [AppLovinMAX log: @"Mounting a new AdView (%@) for Ad Unit ID %@", self.adViewId, adUnitId];
        
        [self.widget setPlacement: placement];
        [self.widget setCustomData: customData];
        [self.widget setExtraParameters: extraParameters];
        [self.widget setLocalExtraParameters: localExtraParameters];
        [self.widget setAdaptiveBannerEnabled: isAdaptiveBannerEnabled];
        [self.widget setAutoRefreshEnabled: isAutoRefreshEnabled];
        
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
    
    AppLovinMAXAdViewWidget *preloadedWidget = preloadedWidgetInstances[self.adViewId];
    
    if ( self.widget == preloadedWidget )
    {
        [AppLovinMAX log: @"Unmounting the preloaded AdView (%@) for Ad Unit ID %@", self.adViewId, self.widget.adUnitIdentifier];
        [self.widget setAutoRefreshEnabled: NO];
    }
    else
    {
        [AppLovinMAX log: @"Unmounting the AdView (%@) to destroy for Ad Unit ID %@", self.adViewId, self.widget.adUnitIdentifier];
        [widgetInstances removeObjectForKey: self.adViewId];
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
