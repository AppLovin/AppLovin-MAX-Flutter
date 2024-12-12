@class MAAdView;

NS_ASSUME_NONNULL_BEGIN

@interface AppLovinMAXAdViewWidget : NSObject

@property (nonatomic, strong, readonly) MAAdView *adView;
@property (nonatomic, copy,   readonly) NSString *adUnitIdentifier;
@property (nonatomic, assign, readonly) BOOL hasContainerView;

- (void)setPlacement:(NSString *)placement;
- (void)setCustomData:(NSString *)customData;
- (void)setExtraParameters:(NSDictionary<NSString *, id> *)parameterDict;
- (void)setLocalExtraParameters:(NSDictionary<NSString *, id> *)parameterDict;
- (void)setAutoRefreshEnabled:(BOOL)autoRefresh;

- (void)loadAd;
- (void)attachAdView:(AppLovinMAXAdView *)view;
- (void)detachAdView;
- (void)destroy;

- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat;
- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat shouldPreload:(BOOL)shouldPreload;

@end

NS_ASSUME_NONNULL_END
