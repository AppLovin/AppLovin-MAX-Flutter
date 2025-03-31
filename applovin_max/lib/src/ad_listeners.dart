import 'package:applovin_max/src/ad_classes.dart';

/// Base listener interface for receiving general ad events.
abstract class AdListener {
  /// Called when a new ad has been loaded.
  final Function(MaxAd ad) onAdLoadedCallback;

  /// Called when an ad fails to load.
  final Function(String adUnitId, MaxError error) onAdLoadFailedCallback;

  /// Called when the ad is clicked.
  final Function(MaxAd ad) onAdClickedCallback;

  /// Called when a revenue event is detected for the ad.
  final Function(MaxAd ad)? onAdRevenuePaidCallback;

  /// @nodoc
  const AdListener({
    required this.onAdLoadedCallback,
    required this.onAdLoadFailedCallback,
    required this.onAdClickedCallback,
    this.onAdRevenuePaidCallback,
  });
}

/// Listener for fullscreen ad events (e.g., Interstitial, Rewarded, App Open).
abstract class FullscreenAdListener extends AdListener {
  /// Called when the ad is displayed.
  final Function(MaxAd ad) onAdDisplayedCallback;

  /// Called when the ad fails to display.
  final Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback;

  /// Called when the ad is dismissed.
  final Function(MaxAd ad) onAdHiddenCallback;

  /// @nodoc
  const FullscreenAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    Function(MaxAd ad)? onAdRevenuePaidCallback,
    required this.onAdDisplayedCallback,
    required this.onAdDisplayFailedCallback,
    required this.onAdHiddenCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdRevenuePaidCallback: onAdRevenuePaidCallback,
        );
}

/// Listener for [AdView] ads (Banner / MREC) to receive ad view events.
class AdViewAdListener extends AdListener {
  /// Called when the [MaxAdView] expands to fullscreen.
  final Function(MaxAd ad) onAdExpandedCallback;

  /// Called when the [MaxAdView] collapses back to its original size.
  final Function(MaxAd ad) onAdCollapsedCallback;

  /// @nodoc
  const AdViewAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    Function(MaxAd ad)? onAdRevenuePaidCallback,
    required this.onAdExpandedCallback,
    required this.onAdCollapsedCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdRevenuePaidCallback: onAdRevenuePaidCallback,
        );
}

/// Listener for [NativeAdView] to receive native ad events.
class NativeAdListener extends AdListener {
  /// @nodoc
  const NativeAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    Function(MaxAd ad)? onAdRevenuePaidCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdRevenuePaidCallback: onAdRevenuePaidCallback,
        );
}

/// Listener for interstitial ad events.
class InterstitialListener extends FullscreenAdListener {
  /// @nodoc
  const InterstitialListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdDisplayedCallback,
    required Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required Function(MaxAd ad) onAdHiddenCallback,
    Function(MaxAd ad)? onAdRevenuePaidCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdDisplayedCallback: onAdDisplayedCallback,
          onAdDisplayFailedCallback: onAdDisplayFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdHiddenCallback: onAdHiddenCallback,
          onAdRevenuePaidCallback: onAdRevenuePaidCallback,
        );
}

/// Listener for rewarded ad events.
class RewardedAdListener extends FullscreenAdListener {
  /// Called when the user has earned a reward.
  final Function(MaxAd ad, MaxReward reward) onAdReceivedRewardCallback;

  /// @nodoc
  const RewardedAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdDisplayedCallback,
    required Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required Function(MaxAd ad) onAdHiddenCallback,
    Function(MaxAd ad)? onAdRevenuePaidCallback,
    required this.onAdReceivedRewardCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdDisplayedCallback: onAdDisplayedCallback,
          onAdDisplayFailedCallback: onAdDisplayFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdHiddenCallback: onAdHiddenCallback,
          onAdRevenuePaidCallback: onAdRevenuePaidCallback,
        );
}

/// Listener for app open ad events.
class AppOpenAdListener extends FullscreenAdListener {
  /// @nodoc
  const AppOpenAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdDisplayedCallback,
    required Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required Function(MaxAd ad) onAdHiddenCallback,
    Function(MaxAd ad)? onAdRevenuePaidCallback,
  }) : super(
          onAdLoadedCallback: onAdLoadedCallback,
          onAdLoadFailedCallback: onAdLoadFailedCallback,
          onAdDisplayedCallback: onAdDisplayedCallback,
          onAdDisplayFailedCallback: onAdDisplayFailedCallback,
          onAdClickedCallback: onAdClickedCallback,
          onAdHiddenCallback: onAdHiddenCallback,
          onAdRevenuePaidCallback: onAdRevenuePaidCallback,
        );
}

/// Listener for a platform [AdView] widget (Banner / MREC) to receive ad view events.
class WidgetAdViewAdListener {
  /// Called when a new ad has been loaded.
  final Function(MaxAd ad) onAdLoadedCallback;

  /// Called when an ad fails to load.
  final Function(String adUnitId, MaxError error) onAdLoadFailedCallback;

  /// @nodoc
  const WidgetAdViewAdListener({
    required this.onAdLoadedCallback,
    required this.onAdLoadFailedCallback,
  });
}
