//
//  AppLovinMAXAdView.h
//  applovin_max
//
//  Created by Thomas So on 7/17/22.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <AppLovinSDK/AppLovinSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class MAAdView;

@interface AppLovinMAXAdView : NSObject<FlutterPlatformView>

+ (nullable MAAdView *)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier;

+ (void)preloadWidgetAdView:(NSString *)adUnitIdentifier 
                   adFormat:(MAAdFormat *)adFormat
                  placement:(nullable NSString *)placement
                 customData:(nullable NSString *)customData
            extraParameters:(nullable NSDictionary<NSString *, id> *)extraParameters
       localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                 withResult:(FlutterResult)result;

+ (void)destroyWidgetAdView:(NSNumber *)adViewId withResult:(FlutterResult)result;

- (void)sendEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body;

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                     adFormat:(MAAdFormat *)adFormat
                     adViewId:(nullable NSNumber *)adViewId
         isAutoRefreshEnabled:(BOOL)isAutoRefreshEnabled
                    placement:(nullable NSString *)placement
                   customData:(nullable NSString *)customData
              extraParameters:(nullable NSDictionary *)extraParameters
         localExtraParameters:(nullable NSDictionary *)localExtraParameters
                    messenger:(id<FlutterBinaryMessenger>)messenger
                          sdk:(ALSdk *)sdk;

@end

NS_ASSUME_NONNULL_END
