//
//  AppLovinMAXAdViewFactory.h
//  applovin_max
//
//  Created by Thomas So on 7/17/22.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppLovinMAXAdViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger;

@end

NS_ASSUME_NONNULL_END
