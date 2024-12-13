@class MAAdView;

NS_ASSUME_NONNULL_BEGIN

@interface AppLovinMAXAdViewWidget : NSObject

@property (nonatomic, strong, readonly) MAAdView *adView;
@property (nonatomic, copy,   readonly) NSString *adUnitIdentifier;
@property (nonatomic, assign, readonly) BOOL hasContainerView;

- (void)setPlacement:(nullable NSString *)placement;
- (void)setCustomData:(nullable NSString *)customData;
- (void)setExtraParameters:(nullable NSDictionary<NSString *, id> *)extraParameters;
- (void)setLocalExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;
- (void)setAutoRefreshEnabled:(BOOL)autoRefreshEnabled;

- (void)loadAd;
- (void)attachAdView:(AppLovinMAXAdView *)view;
- (void)detachAdView;
- (void)destroy;

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat;
- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat shouldPreload:(BOOL)shouldPreload;

@end

NS_ASSUME_NONNULL_END
