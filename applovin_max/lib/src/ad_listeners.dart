abstract class AdListener {
  AdLoadListener(
      {required Function onAdLoadedCallback,
      required Function onAdLoadFailedCallback,
      required Function onAdDisplayedCallback,
      required Function onAdDisplayFailedCallback,
      required Function onAdHiddenCallback,
      required Function onAdClickedCallback}) {}
}

class InterstitialListener extends AdListener {
  InterstitialListener(
      {required Function onAdLoadedCallback,
      required Function onAdLoadFailedCallback,
      required Function onAdDisplayedCallback,
      required Function onAdDisplayFailedCallback,
      required Function onAdHiddenCallback,
      required Function onAdClickedCallback});
}

class RewardededAdListener extends AdListener {
  RewardededAdListener(
      {required Function onAdLoadedCallback,
      required Function onAdLoadFailedCallback,
      required Function onAdDisplayedCallback,
      required Function onAdDisplayFailedCallback,
      required Function onAdHiddenCallback,
      required Function onAdClickedCallback,
      required Function onAdReceivedRewardCallback});
}

class AdViewListener extends AdListener {
  AdViewListener(
      {required Function onAdLoadedCallback,
      required Function onAdLoadFailedCallback,
      required Function onAdDisplayedCallback,
      required Function onAdDisplayFailedCallback,
      required Function onAdHiddenCallback,
      required Function onAdClickedCallback,
      required Function onAdExpandedCallback,
      required Function onAdCollapsedCallback});
}