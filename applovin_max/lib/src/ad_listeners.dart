import 'package:applovin_max/applovin_max.dart';
import 'package:applovin_max/src/ad_classes.dart';

/// Defines a base listener to be notified about ad events.
abstract class AdListener {
  /// The SDK invokes this method when a new ad has been loaded.
  final Function(MaxAd ad) onAdLoadedCallback;
  /// The SDK invokes this method when an ad could not be retrieved.
  final Function(String adUnitId, MaxError error) onAdLoadFailedCallback;
  /// The SDK invokes this method when the ad is clicked.
  final Function(MaxAd ad) onAdClickedCallback;

  /// @nodoc
  const AdListener({
    required this.onAdLoadedCallback,
    required this.onAdLoadFailedCallback,
    required this.onAdClickedCallback,
  });
}

/// Defines a fullscreen ad listener.
abstract class FullscreenAdListener extends AdListener {
  /// The SDK invokes this method when the ad has been successfully displayed.
  final Function(MaxAd ad) onAdDisplayedCallback;
  /// The SDK invokes this method when the ad could not be displayed.
  final Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback;
  /// The SDK invokes this method when the ad has been dismissed.
  final Function(MaxAd ad) onAdHiddenCallback;

  /// @nodoc
  const FullscreenAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required this.onAdDisplayedCallback,
    required this.onAdDisplayFailedCallback,
    required this.onAdHiddenCallback,
  }) : super(onAdLoadedCallback: onAdLoadedCallback, onAdLoadFailedCallback: onAdLoadFailedCallback, onAdClickedCallback: onAdClickedCallback);
}

/// Defines an AdView ad (Banner / MREC) listener to be notified about ad view events.
class AdViewAdListener extends AdListener {
  /// The SDK invokes this method when the [MaxAdView] has expanded to the full screen.
  final Function(MaxAd ad) onAdExpandedCallback;
  /// The SDK invokes this method when the [MaxAdView] has collapsed back to its original size.
  final Function(MaxAd ad) onAdCollapsedCallback;

  /// @nodoc
  const AdViewAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required this.onAdExpandedCallback,
    required this.onAdCollapsedCallback,
  }) : super(onAdLoadedCallback: onAdLoadedCallback, onAdLoadFailedCallback: onAdLoadFailedCallback, onAdClickedCallback: onAdClickedCallback);
}

/// Defines an interstitial ad listener.
class InterstitialListener extends FullscreenAdListener {
  /// @nodoc
  const InterstitialListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdDisplayedCallback,
    required Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required Function(MaxAd ad) onAdHiddenCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdDisplayedCallback: onAdDisplayedCallback,
          onAdDisplayFailedCallback: onAdDisplayFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdHiddenCallback: onAdHiddenCallback,
        );
}

/// Defines a rewarded ad listener.
class RewardedAdListener extends FullscreenAdListener {
  /// The SDK invokes this method when a reward was granted.
  final Function(MaxAd ad, MaxReward reward) onAdReceivedRewardCallback;

  /// @nodoc
  const RewardedAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdDisplayedCallback,
    required Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required Function(MaxAd ad) onAdHiddenCallback,
    required this.onAdReceivedRewardCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdDisplayedCallback: onAdDisplayedCallback,
          onAdDisplayFailedCallback: onAdDisplayFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdHiddenCallback: onAdHiddenCallback,
        );
}
