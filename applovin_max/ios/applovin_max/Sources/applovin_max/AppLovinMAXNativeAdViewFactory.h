#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppLovinMAXNativeAdViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger;

@end

NS_ASSUME_NONNULL_END
