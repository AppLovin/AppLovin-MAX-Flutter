//
//  ALNativeAd.h
//  AppLovinSDK
//
//  Created by Thomas So on 12/13/21.
//

#import <Foundation/Foundation.h>
#import "ALStoreKitAd.h"
#import "ALNativeAdEventDelegate.h"
#import "ALMediaView.h"
#import "ALOptionsView.h"
#import "ALVASTAd.h"
#import "ALOpenMeasurementAd.h"
#import "ALOpenMeasurementNativeAdEventTracker.h"
#import "ALPostbackHTTPRequest.h"

#define AD_RESPONSE_TYPE_APPLOVIN  @"applovin"
#define AD_RESPONSE_TYPE_ORTB      @"ortb"
#define AD_RESPONSE_TYPE_UNDEFINED @"undefined"

NS_ASSUME_NONNULL_BEGIN

@class ALNativeAdBuilder;

/**
 * Typedef of a block used for creating a ALVASTAdBuilder.
 */
typedef void (^ALNativeAdBuilderBlock) (ALNativeAdBuilder *builder);

@interface ALNativeAd : NSObject<ALStoreKitAd, ALOpenMeasurementAd>

// NOTE: For initial release - AL native ads are private to MAX only
#pragma mark - Public API

/**
 * Represents a unique ID for the current ad. Please include this if you report a broken/bad ad to AppLovin Support.
 *
 * @return A unique identifier of the ad.
 */
@property (nonatomic, strong, readonly) NSNumber *adIdNumber;

/**
 * @return The title of this native ad.
 */
@property (nonatomic, copy, readonly) NSString *title;

/**
 * @return The advertiser of this native ad.
 */
@property (nonatomic, copy, readonly) NSString *advertiser;

/**
 * @return The body of text describing this ad.
 */
@property (nonatomic, copy, readonly) NSString *body;

/**
 * @return The title of the CTA of this ad.
 */
@property (nonatomic, copy, readonly) NSString *callToAction;

/**
 * @return The _cached_ icon @c NSURL of the app.
 */
@property (nonatomic, copy, readonly) NSURL *iconURL;

/**
 * @return The _cached_ privacy icon @c NSURL of the app.
 */
@property (nonatomic, copy, readonly) NSURL *privacyIconURL;

/**
 * @return A view responsible for displaying the ad's main image or video.
 */
@property (nonatomic, strong, readonly) ALMediaView *mediaView;

/**
 * @return A view responsible for displaying ad options.
 */
@property (nonatomic, strong, readonly) ALOptionsView *optionsView;

/**
 * Attaches click handlers to the provided views displaying this native ad and attaches listeners that fire impressions for the native ad view.
 */
- (void)registerViewsForInteraction:(NSArray<NSString *> *)views forAdView:(UIView *)adView;

/**
 * Removes any interactions that views were previously registered with.
 */
- (void)unregisterViewsForInteraction;

/**
 * Invoke cleanup logic for this native ad.
 */
- (void)destroy;

#pragma mark - Private API - Dynamic

/**
 * Kill-switch for pausing feature allowing video to mix (and not pause) user's music. Defaults to @c YES.
 */
@property (assign, nonatomic, readonly, getter=shouldAllowBackgroundAudio) BOOL allowBackgroundAudio;

/**
 * The cache prefix to apply to the filename before caching to disk, if any.
 */
@property (nonatomic, copy, readonly, nullable) NSString *cachePrefix;

/**
 * The typeo of native ad this is. The following are possible values:
 *
 * @c "applovin" - These are direct AppLovin ads.
 * @c "ortb" - These are DSP ads.
 * @c "undefined" - None provided from backend.
 */
@property (nonatomic, copy, readonly) NSString *type;

/**
 * The native ad-specific Open Measurement tracker.
 */
@property (nonatomic, strong, readonly) ALOpenMeasurementNativeAdEventTracker *adEventTracker;

/**
 * The name of the DSP responsible for this ad, if any.
 */
@property (nonatomic, copy, readonly, nullable) NSString *DSPName;

#pragma mark - Private API - Assets

/**
 * @return The _cached_ main image @c NSURL of the app.
 */
@property (nonatomic, copy, readonly) NSURL *mainImageURL;

@property (nonatomic, strong, readonly, nullable) UIView *nativeAdView;
@property (nonatomic, strong, readonly, nullable) ALVASTAd *vastAd;
@property (nonatomic, strong, readonly, nullable) NSURL *privacyDestinationURL;
@property (nonatomic, strong, readonly, nullable) NSURL *clickDestinationURL;
@property (nonatomic, strong, readonly, nullable) NSURL *clickDestinationBackupURL;
@property (nonatomic, strong, readonly) NSArray<NSURL *> *clickTrackingURLs;
@property (nonatomic,   copy, readonly, nullable) NSString *jsTracker;
@property (nonatomic, strong, readonly) NSArray<ALPostbackHTTPRequest *> *impressionRequests;
@property (nonatomic, strong, readonly) NSArray<ALPostbackHTTPRequest *> *viewableMRC50Requests;
@property (nonatomic, strong, readonly) NSArray<ALPostbackHTTPRequest *> *viewableMRC100Requests;
@property (nonatomic, strong, readonly) NSArray<ALPostbackHTTPRequest *> *viewableVideo50Requests;

#pragma mark - Private API - Setup

/**
 * Set up the @c ALMediaView and @c ALOptionsView
 * @c ALMediaView for displaying the @c mainImageURL and the video in the @c vastAd if exists.
 * @c ALOptionsView for displaying ad options.
 */
- (void)setUpNativeAdViewComponents;

/**
 * Invoke didMoveToWindow logic for this native ad.
 */
- (void)handleDidMoveToWindowIfNeeded;

/**
 * The event delegate for this native ad. Only tracks clicks events for now.
 */
@property (nonatomic, strong, nullable) id<ALNativeAdEventDelegate> eventDelegate;

#pragma mark - Registered View Tap Handling

- (void)handleViewClicked;

+ (instancetype)nativeAdWithBuilderBlock:(NS_NOESCAPE ALNativeAdBuilderBlock)builderBlock;

@end

@interface ALNativeAdBuilder : NSObject

@property (nonatomic, weak) ALSdk *sdk;
@property (nonatomic, strong) NSDictionary<NSString *, id> *adObject;
@property (nonatomic, strong) NSDictionary<NSString *, id> *fullResponse;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *advertiser;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *callToAction;
@property (nonatomic, strong) NSURL *iconURL;
@property (nonatomic, strong) NSURL *mainImageURL;
@property (nonatomic, strong) NSURL *privacyIconURL;
@property (nonatomic, strong, nullable) ALVASTAd *vastAd;
@property (nonatomic, strong, nullable) NSURL *privacyDestinationURL;
@property (nonatomic, strong, nullable) NSURL *clickDestinationURL;
@property (nonatomic, strong, nullable) NSURL *clickDestinationBackupURL;
@property (nonatomic, strong) NSArray<NSURL *> *clickTrackingURLs;
@property (nonatomic, copy, nullable) NSString *jsTracker;
@property (nonatomic, strong) NSArray<ALPostbackHTTPRequest *> *impressionRequests;
@property (nonatomic, strong) NSArray<ALPostbackHTTPRequest *> *viewableMRC50Requests;
@property (nonatomic, strong) NSArray<ALPostbackHTTPRequest *> *viewableMRC100Requests;
@property (nonatomic, strong) NSArray<ALPostbackHTTPRequest *> *viewableVideo50Requests;

@end

NS_ASSUME_NONNULL_END
