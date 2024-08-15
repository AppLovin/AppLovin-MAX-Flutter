@class MAAdView;

NS_ASSUME_NONNULL_BEGIN

@interface AppLovinMAXAdViewPlatformWidget : NSObject

@property (nonatomic, strong, readonly) MAAdView *adView;
@property (nonatomic, assign, readonly) BOOL hasContainerView;

@property (nonatomic, copy, nullable) NSString *placement;
@property (nonatomic, copy, nullable) NSString *customData;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *extraParameters;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *localExtraParameters;
@property (nonatomic, assign, getter=isAutoRefreshEnabled) BOOL autoRefresh;

- (void)loadAd;
- (void)attachAdView:(AppLovinMAXAdView *)view;
- (void)detachAdView;
- (void)destroy;

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat;
- (instancetype)initWithAdUnitIdentifierForPreload:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat preload:(BOOL)preload;

@end

NS_ASSUME_NONNULL_END
