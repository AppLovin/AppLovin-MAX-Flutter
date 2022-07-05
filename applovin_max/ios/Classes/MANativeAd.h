//
//  MANativeAd.h
//  AppLovinSDK
//
//  Created by Thomas So on 5/5/20.
//

#import "MAAdFormat.h"

NS_ASSUME_NONNULL_BEGIN

@class MANativeAdBuilder;
@class MANativeAdImage;
@class MANativeAdView;

typedef void (^MANativeAdBuilderBlock) (MANativeAdBuilder *builder);

@interface MANativeAdBuilder : NSObject

@property (nonatomic, copy,   nullable) NSString *title;
@property (nonatomic, copy,   nullable) NSString *advertiser;
@property (nonatomic, copy,   nullable) NSString *body;
@property (nonatomic, copy,   nullable) NSString *callToAction;
@property (nonatomic, strong, nullable) MANativeAdImage *icon;
@property (nonatomic, strong, nullable) MANativeAdImage *mainImage;
@property (nonatomic, strong, nullable) UIView *iconView;
@property (nonatomic, strong, nullable) UIView *optionsView;
@property (nonatomic, strong, nullable) UIView *mediaView;
@property (nonatomic, assign) CGFloat mediaContentAspectRatio;

@end

@interface MANativeAdImage : NSObject

/**
 * The native ad image.
 */
@property (nonatomic, strong, readonly, nullable) UIImage *image;

/**
 * The native ad image URL.
 */
@property (nonatomic, copy, readonly, nullable) NSURL *URL;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface MANativeAd : NSObject

/**
 * The native ad format.
 */
@property (nonatomic, weak, readonly) MAAdFormat *format;

/**
 * The native ad title text.
 */
@property (nonatomic, copy, readonly, nullable) NSString *title;

/**
 * The native ad advertiser text.
 */
@property (nonatomic, copy, readonly, nullable) NSString *advertiser;

/**
 * The native ad body text.
 */
@property (nonatomic, copy, readonly, nullable) NSString *body;

/**
 * The native ad CTA button text.
 */
@property (nonatomic, copy, readonly, nullable) NSString *callToAction;

/**
 * The native ad icon image.
 */
@property (nonatomic, strong, readonly, nullable) MANativeAdImage *icon;

/**
 * The native ad icon image view.
 * Note: This is only used for banners using native APIs. Native ads must provide a `MANativeAdImage` instead.
 */
@property (nonatomic, strong, readonly, nullable) UIView *iconView;

/**
 * The native ad options view.
 */
@property (nonatomic, strong, readonly, nullable) UIView *optionsView;

/**
 * The native ad media view.
 */
@property (nonatomic, strong, readonly, nullable) UIView *mediaView;

/**
 * The native ad main image (cover image). May or may not be a locally cached file:// resource file.
 *
 * Please make sure you continue to render your native ad using @c MANativeAdLoader so impression tracking is not affected.
 */
@property (nonatomic, strong, readonly, nullable) MANativeAdImage *mainImage;

/**
 * The aspect ratio for the media view if provided by the network. Otherwise returns 0.0f.
 */
@property (nonatomic, assign, readonly) CGFloat mediaContentAspectRatio;

/**
 * For internal use only.
 */
- (void)performClick;

/**
 * This method is called before the ad view is returned to the publisher.
 * The adapters should override this method to register the rendered native ad view and make sure that the view is interactable.
 *
 * @param nativeAdView a rendered native ad view.
 */
- (void)prepareViewForInteraction:(MANativeAdView *)nativeAdView;

- (instancetype)initWithFormat:(MAAdFormat *)format builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
