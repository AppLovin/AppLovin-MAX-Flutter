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

@interface AppLovinMAXAdView : NSObject<FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                     adFormat:(MAAdFormat *)adFormat
                    placement:(nullable NSString *)placement
                   customData:(nullable NSString *)customData
                    messenger:(id<FlutterBinaryMessenger>)messenger
                          sdk:(ALSdk *)sdk;

@end

NS_ASSUME_NONNULL_END
