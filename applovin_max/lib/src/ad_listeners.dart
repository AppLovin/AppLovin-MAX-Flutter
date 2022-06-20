import 'package:applovin_max/src/ad_classes.dart';

/// Base Ad Listener
abstract class AdListener {
  final Function(MaxAd ad) onAdLoadedCallback;
  final Function(String adUnitId, MaxError error) onAdLoadFailedCallback;
  final Function(MaxAd ad) onAdClickedCallback;

  const AdListener({
    required this.onAdLoadedCallback,
    required this.onAdLoadFailedCallback,
    required this.onAdClickedCallback,
  });
}

// Fullscreen Ad Listener
abstract class FullscreenAdListener extends AdListener {
  final Function(MaxAd ad) onAdDisplayedCallback;
  final Function(MaxAd ad, MaxError error) onAdDisplayFailedCallback;
  final Function(MaxAd ad) onAdHiddenCallback;

  const FullscreenAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required this.onAdDisplayedCallback,
    required this.onAdDisplayFailedCallback,
    required this.onAdHiddenCallback,
  }) : super(onAdLoadedCallback: onAdLoadedCallback, onAdLoadFailedCallback: onAdLoadFailedCallback, onAdClickedCallback: onAdClickedCallback);
}

// AdView Ad (Banner / MREC) Listener
class AdViewAdListener extends AdListener {
  final Function(MaxAd ad) onAdExpandedCallback;
  final Function(MaxAd ad) onAdCollapsedCallback;

  const AdViewAdListener({
    required Function(MaxAd ad) onAdLoadedCallback,
    required Function(String adUnitId, MaxError error) onAdLoadFailedCallback,
    required Function(MaxAd ad) onAdClickedCallback,
    required this.onAdExpandedCallback,
    required this.onAdCollapsedCallback,
  }) : super(onAdLoadedCallback: onAdLoadedCallback, onAdLoadFailedCallback: onAdLoadFailedCallback, onAdClickedCallback: onAdClickedCallback);
}

// Interstitial Ad Listener
class InterstitialListener extends FullscreenAdListener {
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

// Rewarded Ad Listener
class RewardededAdListener extends FullscreenAdListener {
  final Function(MaxAd ad, MaxReward reward) onAdReceivedRewardCallback;

  const RewardededAdListener({
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
