//
//  ALNativeAdService.h
//  AppLovinSDK
//
//  Created by Thomas So on 12/14/21.
//

#import <Foundation/Foundation.h>
#import "ALNativeAdLoadDelegate.h"
#import "ALSdk.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALNativeAdService : NSObject

/**
 * Fetches a new ad for the given ad token.
 *
 * @param adToken   Ad token returned from AppLovin S2S API.
 * @param delegate  A callback that @c loadNextAdForAdToken calls to notify that the ad has been loaded.
 */
- (void)loadNextAdForAdToken:(NSString *)adToken andNotify:(id<ALNativeAdLoadDelegate>)delegate;

- (instancetype)initWithSdk:(ALSdk *)sdk;
- (instancetype)init __attribute__((unavailable("Access ALNativeAdService through ALSdk's nativeAdService property.")));
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
