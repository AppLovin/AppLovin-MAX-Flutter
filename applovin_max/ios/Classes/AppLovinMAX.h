#import <Flutter/Flutter.h>
#import <AppLovinSDK/AppLovinSDK.h>

#define DEVICE_SPECIFIC_ADVIEW_AD_FORMAT ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? MAAdFormat.leader : MAAdFormat.banner

@interface AppLovinMAX : NSObject<FlutterPlugin>

/**
 * Shared instance of this plugin.
 */
@property (nonatomic, strong, readonly, class) AppLovinMAX *shared;

/**
 * The instance of the AppLovin SDK the module is using.
 */
@property (nonatomic, weak, readonly) ALSdk *sdk;

/**
 * Returns a dictionay value of adInfo for the specified ad.
 */
- (NSDictionary<NSString *, id> *)adInfoForAd:(MAAd *)ad;

/**
 * Utility method for sending ad events through the Flutter channel into Dart.
 */
- (void)sendEventWithName:(NSString *)name ad:(MAAd *)ad channel:(FlutterMethodChannel *)channel;

/**
 * Utility method for sending generic events through the Flutter channel into Dart.
 */
- (void)sendEventWithName:(NSString *)name body:(NSDictionary<NSString *, id> *)body channel:(FlutterMethodChannel *)channel;

/**
 * Utility method for sending error events through the Flutter channel into Dart.
 */
- (void)sendErrorEventWithName:(NSString *)name
           forAdUnitIdentifier:(NSString *)adUnitIdentifier
                     withError:(MAError *)error
                       channel:(FlutterMethodChannel *)channel;

+ (void)log:(NSString *)format, ...;

@end
