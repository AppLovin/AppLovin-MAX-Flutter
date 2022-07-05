//
//  ALRewardedInterstitialAd.h
//  AppLovinSDK
//
//  Created by Thomas So on 6/5/20.
//

#import <Foundation/Foundation.h>
#import "ALAdRewardDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This class represents a fullscreen ad which the user can skip and be granted a reward upon successful completion of the ad.
 */
@interface ALRewardedInterstitialAd : NSObject

#pragma mark - Initialization

/**
 * Initialize an instance of this class with a SDK instance.
 *
 * @param sdk The AppLovin SDK instance to use.
 */
- (instancetype)initWithSdk:(ALSdk *)sdk;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark - Ad Delegates

/**
 * An object conforming to the ALAdDisplayDelegate protocol, which, if set, will be notified of ad show/hide events.
 */
@property (nonatomic, strong, nullable) id<ALAdDisplayDelegate> adDisplayDelegate;

/**
 * An object conforming to the ALAdVideoPlaybackDelegate protocol, which, if set, will be notified of video start/finish events.
 */
@property (nonatomic, strong, nullable) id<ALAdVideoPlaybackDelegate> adVideoPlaybackDelegate;

#pragma mark - Showing

/**
 * Show a rewarded interstitial with the provided ad.
 *
 * Using the ALAdRewardDelegate, you will be able to verify with AppLovin servers that the video view is legitimate,
 * as we will confirm whether the specific ad was actually served - then we will ping your server with a url for you to update
 * the user's balance. The Reward Validation Delegate will tell you whether we were able to reach our servers or not. If you receive
 * a successful response, you should refresh the user's balance from your server. For more info, see the documentation.
 *
 * @param ad                                The ad to render into this rewarded interstitial ad.
 * @param adRewardDelegate The reward delegate to notify upon validating reward authenticitye with AppLovin.
 */
- (void)showAd:(ALAd *)ad andNotify:(nullable id<ALAdRewardDelegate>)adRewardDelegate;

@end

NS_ASSUME_NONNULL_END
