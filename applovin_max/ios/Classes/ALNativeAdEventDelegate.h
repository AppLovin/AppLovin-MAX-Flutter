//
//  ALNativeAdEventDelegate.h
//  AppLovinSDK
//
//  Created by Thomas So on 12/13/21.
//

#import <Foundation/Foundation.h>

@class ALNativeAd;

NS_ASSUME_NONNULL_BEGIN

@protocol ALNativeAdEventDelegate<NSObject>

/**
 * This method is invoked when the ad is clicked.
 * <p>
 * This method is invoked on the main UI thread.
 *
 * @param ad Ad that was just clicked. Guaranteed not to be null.
 */
- (void)didClickNativeAd:(ALNativeAd *)ad;

@end

NS_ASSUME_NONNULL_END
