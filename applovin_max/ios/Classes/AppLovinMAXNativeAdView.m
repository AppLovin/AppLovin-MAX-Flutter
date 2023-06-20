#import "AppLovinMAXNativeAdView.h"
#import "AppLovinMAX.h"
#import <AppLovinSDK/AppLovinSDK.h>

#define TITLE_LABEL_TAG          1
#define MEDIA_VIEW_CONTAINER_TAG 2
#define ICON_VIEW_TAG            3
#define BODY_VIEW_TAG            4
#define CALL_TO_ACTION_VIEW_TAG  5
#define ADVERTISER_VIEW_TAG      8

@interface MANativeAdLoader()
- (void)registerClickableViews:(NSArray<UIView *> *)clickableViews
                 withContainer:(UIView *)container
                         forAd:(MAAd *)ad;
- (void)handleNativeAdViewRenderedForAd:(MAAd *)ad;
@end

@interface AppLovinMAXNativeAdView()<MANativeAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, strong) FlutterMethodChannel *channel;

@property (nonatomic, strong, nullable) MANativeAdLoader *adLoader;
@property (nonatomic, strong, nullable) MAAd *ad;
@property (nonatomic, strong, nullable) MANativeAd *nativeAd;
@property (nonatomic, strong) ALAtomicBoolean *isLoading; // Guard against repeated ad loads

@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy, nullable) NSString *placement;
@property (nonatomic, copy, nullable) NSString *customData;

@property (nonatomic, strong) UIView *nativeAdView;
@property (nonatomic, strong, nullable) UIView *titleView;
@property (nonatomic, strong, nullable) UIView *advertiserView;
@property (nonatomic, strong, nullable) UIView *bodyView;
@property (nonatomic, strong, nullable) UIView *callToActionView;
@property (nonatomic, strong, nullable) UIImageView *iconView;
@property (nonatomic, strong, nullable) UIView *optionsViewContainer;
@property (nonatomic, strong, nullable) UIView *mediaViewContainer;

@property (nonatomic, strong) NSMutableArray<UIView *> *clickableViews;

@end

@implementation AppLovinMAXNativeAdView

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                    placement:(nullable NSString *)placement
                   customData:(nullable NSString *)customData
                    messenger:(id<FlutterBinaryMessenger>)messenger
                          sdk:(ALSdk *)sdk
{
    self = [super init];
    if ( self )
    {
        self.isLoading = [[ALAtomicBoolean alloc] init];
        self.clickableViews = [NSMutableArray array];
        self.adUnitId = adUnitId;
        
        NSString *uniqueChannelName = [NSString stringWithFormat: @"applovin_max/nativeadview_%lld", viewId];
        self.channel = [FlutterMethodChannel methodChannelWithName: uniqueChannelName binaryMessenger: messenger];
        
        __weak typeof(self) weakSelf = self;
        [self.channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            if ( [@"addTitleView" isEqualToString: call.method] )
            {
                CGRect rect = [weakSelf getRect: call];
                [weakSelf addTitleView: rect];
                
                result(nil);
            }
            else if ( [@"addAdvertiserView" isEqualToString: call.method] )
            {
                CGRect rect = [weakSelf getRect: call];
                [weakSelf addAdvertiserView: rect];
                
                result(nil);
            }
            else if ( [@"addBodyView" isEqualToString: call.method] )
            {
                CGRect rect = [weakSelf getRect: call];
                [weakSelf addBodyView: rect];
                
                result(nil);
            }
            else if ( [@"addCallToActionView" isEqualToString: call.method] )
            {
                CGRect rect = [weakSelf getRect: call];
                [weakSelf addCallToActionView: rect];
                
                result(nil);
            }
            else if ( [@"addIconView" isEqualToString: call.method] )
            {
                CGRect rect = [weakSelf getRect: call];
                [weakSelf addIconView: rect];
                
                result(nil);
            }
            else if ( [@"addOptionsView" isEqualToString: call.method] )
            {
                CGRect rect = [weakSelf getRect: call];
                [weakSelf addOptionsView: rect];
                
                result(nil);
            }
            else if ( [@"addMediaView" isEqualToString: call.method] )
            {
                CGRect rect = [weakSelf getRect: call];
                [weakSelf addMediaView: rect];
                
                result(nil);
            }
            else if ( [@"completeViewAddition" isEqualToString: call.method] )
            {
                [weakSelf completeViewAddition];
                
                result(nil);
            }
            else if ( [@"load" isEqualToString: call.method] )
            {
                [weakSelf loadAd];
                
                result(nil);
            }
            else
            {
                result(FlutterMethodNotImplemented);
            }
        }];
        
        self.nativeAdView = [[UIView alloc] initWithFrame: frame];
        
        [self loadAd];
    }

    return self;
}

- (UIView *)view
{
    return self.nativeAdView;
}

-(void)dealloc
{
    [self destroyCurrentAdIfNeeded];
    
    if ( self.titleView )
    {
        [self.titleView removeFromSuperview];
    }
    
    if ( self.advertiserView )
    {
        [self.advertiserView removeFromSuperview];
    }
    
    if ( self.bodyView )
    {
        [self.bodyView removeFromSuperview];
    }
    
    if ( self.callToActionView )
    {
        [self.callToActionView removeFromSuperview];
    }
    
    if ( self.iconView )
    {
        [self.iconView removeFromSuperview];
    }
    
    if ( self.optionsViewContainer )
    {
        [self.optionsViewContainer removeFromSuperview];
    }
    
    if ( self.mediaViewContainer )
    {
        [self.mediaViewContainer removeFromSuperview];
    }
    
    [self.channel setMethodCallHandler: nil];
    self.channel = nil;
}

- (CGRect)getRect:(FlutterMethodCall *)call
{
    int x = ((NSNumber *)call.arguments[@"x"]).intValue;
    int y = ((NSNumber *)call.arguments[@"y"]).intValue;
    int width = ((NSNumber *)call.arguments[@"width"]).intValue;
    int height = ((NSNumber *)call.arguments[@"height"]).intValue;
    return CGRectMake(x, y, width, height);
}

#pragma mark - Ad Loader

// Lazily loaded for when Ad Unit ID is available
- (nullable MANativeAdLoader *)adLoader
{
    if ( ![self.adUnitId al_isValidString] ) return nil;
    
    if ( ![self.adUnitId isEqualToString: _adLoader.adUnitIdentifier] )
    {
        _adLoader = [[MANativeAdLoader alloc] initWithAdUnitIdentifier: self.adUnitId sdk: [AppLovinMAX shared].sdk];
        _adLoader.nativeAdDelegate = self;
        _adLoader.revenueDelegate = self;
    }
    
    return _adLoader;
}

- (void)loadAd
{
    if ( [self.isLoading compareAndSet: NO update: YES] )
    {
        [AppLovinMAX log: @"Loading a native ad for Ad Unit ID: %@...", self.adUnitId];
        
        self.adLoader.placement = self.placement;
        self.adLoader.customData = self.customData;
        
        [self.adLoader loadAd];
    }
    else
    {
        [AppLovinMAX log: @"Ignoring request to load native ad for Ad Unit ID %@, another ad load in progress", self.adUnitId];
    }
}

- (void)destroyCurrentAdIfNeeded
{
    if ( self.ad )
    {
        if ( self.nativeAd )
        {
            if ( self.nativeAd.mediaView )
            {
                [self.nativeAd.mediaView removeFromSuperview];
            }
            if ( self.nativeAd.optionsView )
            {
                [self.nativeAd.optionsView removeFromSuperview];
            }
        }
        
        [self.adLoader destroyAd: self.ad];
        
        self.nativeAd = nil;
        self.ad = nil;
    }
}

#pragma mark - Ad Loader Delegate

- (void)didLoadNativeAd:(nullable MANativeAdView *)nativeAdView forAd:(MAAd *)ad
{
    [AppLovinMAX log: @"Native ad loaded: %@", ad];
    
    // Log a warning if it is a template native ad returned - as our plugin will be responsible for re-rendering the native ad's assets
    if ( nativeAdView )
    {
        [self.isLoading set: NO];
        
        [AppLovinMAX log: @"Native ad is of template type, failing ad load..."];
        
        [self sendErrorEventWithName: @"OnNativeAdViewAdLoadFailedEvent" error: nil];
        
        return;
    }
    
    [self destroyCurrentAdIfNeeded];
    
    self.ad = ad;
    
    self.nativeAd = ad.nativeAd;
    
    [self sendEventWithName: @"OnNativeAdViewAdLoadedEvent" ad: ad];
    
    [self.isLoading set: NO];
}

- (void)didFailToLoadNativeAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    [self.isLoading set: NO];
    
    [AppLovinMAX log: @"Failed to load native ad for Ad Unit ID %@ with error: %@", self.adUnitId, error];
    
    [self sendErrorEventWithName: @"OnNativeAdViewAdLoadFailedEvent" error: error];
}

- (void)didClickNativeAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnNativeAdViewAdClickedEvent" ad: ad];
}

- (void)didPayRevenueForAd:(MAAd *)ad
{
    [self sendEventWithName: @"OnNativeAdViewAdRevenuePaidEvent" ad: ad];
}

- (void)sendEventWithName:(NSString *)name ad:(MAAd *)ad
{
    [[AppLovinMAX shared] sendEventWithName: name ad: ad channel: self.channel];
}

- (void)sendErrorEventWithName:(NSString *)name error:(MAError *)error
{
    [[AppLovinMAX shared] sendErrorEventWithName: name
                             forAdUnitIdentifier: self.adUnitId
                                       withError: error
                                         channel: self.channel];
}

#pragma mark - Native Ad Components

-(void)addTitleView:(CGRect)frame
{
    if ( !self.nativeAd.title ) return;
    
    if ( !self.titleView )
    {
        self.titleView = [[UIView alloc] init];
        self.titleView.tag = TITLE_LABEL_TAG;
        [self.nativeAdView addSubview: self.titleView];
        
        [self.clickableViews addObject: self.titleView];
    }
    
    self.titleView.frame = frame;
}

-(void)addAdvertiserView:(CGRect)frame
{
    if ( !self.nativeAd.advertiser ) return;
    
    if ( !self.advertiserView )
    {
        self.advertiserView = [[UIView alloc] init];
        self.advertiserView.tag = ADVERTISER_VIEW_TAG;
        [self.nativeAdView addSubview: self.advertiserView];
        
        [self.clickableViews addObject: self.advertiserView];
    }
    
    self.advertiserView.frame = frame;
}

-(void)addBodyView:(CGRect)frame
{
    if ( !self.nativeAd.body ) return;
    
    if ( !self.bodyView )
    {
        self.bodyView = [[UIView alloc] init];
        self.bodyView.tag = BODY_VIEW_TAG;
        [self.nativeAdView addSubview: self.bodyView];
        
        [self.clickableViews addObject: self.bodyView];
    }
    
    self.bodyView.frame = frame;
}

-(void)addCallToActionView:(CGRect)frame
{
    if ( !self.nativeAd.callToAction ) return;
    
    if ( !self.callToActionView )
    {
        self.callToActionView = [[UIView alloc] init];
        self.callToActionView.tag = CALL_TO_ACTION_VIEW_TAG;
        [self.nativeAdView addSubview: self.callToActionView];
        
        [self.clickableViews addObject: self.callToActionView];
    }
    
    self.callToActionView.frame = frame;
}

-(void)addIconView:(CGRect)frame
{
    if ( !self.nativeAd.icon ) return;
    
    if ( !self.iconView )
    {
        self.iconView = [[UIImageView alloc] init];
        self.iconView.tag = ICON_VIEW_TAG;
        self.iconView.userInteractionEnabled = YES;
        [self.nativeAdView addSubview: self.iconView];
        
        [self.clickableViews addObject: self.iconView];
    }
    
    self.iconView.frame = frame;
    
    if ( self.nativeAd.icon.URL )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL: self.nativeAd.icon.URL];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.iconView.image = [UIImage imageWithData:imageData];
            });
        });
    }
    else if ( self.nativeAd.icon.image )
    {
        self.iconView.image = self.nativeAd.icon.image;
    }
}

-(void)addOptionsView:(CGRect)frame
{
    if ( !self.nativeAd.optionsView ) return;
    
    if ( !self.optionsViewContainer )
    {
        self.optionsViewContainer = [[UIView alloc] init];
        [self.nativeAdView addSubview: self.optionsViewContainer];
    }
    
    [self.optionsViewContainer addSubview: self.nativeAd.optionsView];
    
    self.optionsViewContainer.frame = frame;
    
    self.nativeAd.optionsView.frame = CGRectOffset(frame, -frame.origin.x, -frame.origin.y);
    
}

-(void)addMediaView:(CGRect)frame
{
    if (  !self.nativeAd.mediaView ) return;
    
    if ( !self.mediaViewContainer )
    {
        self.mediaViewContainer = [[UIView alloc] init];
        self.mediaViewContainer.tag = MEDIA_VIEW_CONTAINER_TAG;
        [self.nativeAdView addSubview: self.mediaViewContainer];
    }
    
    [self.mediaViewContainer addSubview: self.nativeAd.mediaView];
    
    self.mediaViewContainer.frame = frame;
    
    self.nativeAd.mediaView.frame = CGRectOffset(frame, -frame.origin.x, -frame.origin.y);
}

-(void)completeViewAddition
{
    if ( !self.adLoader ) return;

    [self.adLoader registerClickableViews: self.clickableViews withContainer: self.nativeAdView forAd: self.ad];
    [self.adLoader handleNativeAdViewRenderedForAd: self.ad];
}

@end
