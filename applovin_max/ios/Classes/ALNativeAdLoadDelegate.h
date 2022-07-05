//
//  ALNativeAdLoadDelegate.h
//  AppLovinSDK
//
//  Created by Thomas So on 12/13/21.
//

#import <Foundation/Foundation.h>
#import "ALNativeAd.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This protocol defines a delegate intended to be notified about native ad events.
 */
@protocol ALNativeAdLoadDelegate<NSObject>

/**
 * The SDK invokes this callback when it successfully loads a native ad view.
 * <p>
 * The SDK invokes this callback on the UI thread.
 *
 * @param ad The ad that the SDK successfully loaded.
 */
- (void)didLoadNativeAd:(ALNativeAd *)ad;

/**
 * The SDK invokes this callback when it fails to load a native ad.
 * <p>
 * To see the error code, see @c ALErrorCodes.h.
 * <p>
 * The SDK invokes this callback on the UI thread.
 *
 * @param errorCode An error code representing the reason the ad failed to load. Common error codes are defined in @c ALErrorCodes.h.
 */
- (void)didFailToLoadNativeAdWithErrorCode:(NSInteger)errorCode;

@end

NS_ASSUME_NONNULL_END
