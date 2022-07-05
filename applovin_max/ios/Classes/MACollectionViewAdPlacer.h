//
//  MACollectionViewAdPlacer.h
//  AppLovinSDK
//
//  Created by Ritam Sarmah on 3/8/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MACustomAdPlacer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This class loads and places native ads into a corresponding @c UICollectionView. The collection view's original data source and delegate methods are wrapped by this class in order to automatically insert ad items, while maintaining the existing collection view's behavior.
 *
 * @note If you're using storyboards, the collection view's "Estimate Size" must be set to "None".
 */
@interface MACollectionViewAdPlacer : MACustomAdPlacer

/**
 * Initializes an ad placer for use with the provided collection view.
 *
 * @param collectionView A collection view to place ads in.
 * @param settings An ad placer settings object.
 */
+ (instancetype)placerWithCollectionView:(UICollectionView *)collectionView settings:(MAAdPlacerSettings *)settings;

- (instancetype)initWithSettings:(MAAdPlacerSettings *)settings NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
