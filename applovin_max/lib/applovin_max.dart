import 'package:applovin_max/src/ad_classes.dart';
import 'package:applovin_max/src/ad_listeners.dart';
import 'package:applovin_max/src/enums.dart';
import 'package:flutter/services.dart';

export 'package:applovin_max/src/ad_listeners.dart';
export 'package:applovin_max/src/enums.dart';
export 'package:applovin_max/src/max_ad_view.dart';

class AppLovinMAX {
  static const version = "1.0.8";

  static MethodChannel channel = const MethodChannel('applovin_max');

  static AdViewAdListener? _bannerAdListener;
  static AdViewAdListener? _mrecAdListener;
  static InterstitialListener? _interstitialListener;
  static RewardedAdListener? _rewardedAdListener;

  static Future<Map?> initialize(String sdkKey) {
    channel.setMethodCallHandler((MethodCall call) async {
      var method = call.method;
      var arguments = call.arguments;

      var adUnitId = arguments["adUnitId"];

      /// Banner Ad Events
      if ("OnBannerAdLoadedEvent" == method) {
        _bannerAdListener?.onAdLoadedCallback(createAd(adUnitId, arguments));
      } else if ("OnBannerAdLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _bannerAdListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnBannerAdClickedEvent" == method) {
        _bannerAdListener?.onAdClickedCallback(createAd(adUnitId, arguments));
      } else if ("OnBannerAdExpandedEvent" == method) {
        _bannerAdListener?.onAdExpandedCallback(createAd(adUnitId, arguments));
      } else if ("OnBannerAdCollapsedEvent" == method) {
        _bannerAdListener?.onAdCollapsedCallback(createAd(adUnitId, arguments));
      }

      /// MREC Ad Events
      else if ("OnMRecAdLoadedEvent" == method) {
        _mrecAdListener?.onAdLoadedCallback(createAd(adUnitId, arguments));
      } else if ("OnMRecAdLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _mrecAdListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnMRecAdClickedEvent" == method) {
        _mrecAdListener?.onAdClickedCallback(createAd(adUnitId, arguments));
      } else if ("OnMrecAdExpandedEvent" == method) {
        _mrecAdListener?.onAdExpandedCallback(createAd(adUnitId, arguments));
      } else if ("OnMrecAdCollapsedEvent" == method) {
        _mrecAdListener?.onAdCollapsedCallback(createAd(adUnitId, arguments));
      }

      /// Interstitial Ad Events
      else if ("OnInterstitialLoadedEvent" == method) {
        _interstitialListener?.onAdLoadedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnInterstitialLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _interstitialListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnInterstitialClickedEvent" == method) {
        _interstitialListener?.onAdClickedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnInterstitialDisplayedEvent" == method) {
        _interstitialListener?.onAdDisplayedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnInterstitialAdFailedToDisplayEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _interstitialListener?.onAdDisplayFailedCallback(createAd(adUnitId, arguments), error);
      } else if ("OnInterstitialHiddenEvent" == method) {
        _interstitialListener?.onAdHiddenCallback.call(createAd(adUnitId, arguments));
      }

      /// Rewarded Ad Events
      else if ("OnRewardedAdLoadedEvent" == method) {
        _rewardedAdListener?.onAdLoadedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _rewardedAdListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnRewardedAdClickedEvent" == method) {
        _rewardedAdListener?.onAdClickedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdDisplayedEvent" == method) {
        _rewardedAdListener?.onAdDisplayedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdFailedToDisplayEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _rewardedAdListener?.onAdDisplayFailedCallback(createAd(adUnitId, arguments), error);
      } else if ("OnRewardedAdHiddenEvent" == method) {
        _rewardedAdListener?.onAdHiddenCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdReceivedRewardEvent" == method) {
        var reward = MaxReward(int.parse(arguments["rewardAmount"]), arguments["rewardLabel"]);
        _rewardedAdListener?.onAdReceivedRewardCallback(createAd(adUnitId, arguments), reward);
      }
    });

    return channel.invokeMethod('initialize', {
      'plugin_version': version,
      'sdk_key': sdkKey,
    });
  }

  static MaxAd createAd(String adUnitId, dynamic arguments) {
    return MaxAd(
      adUnitId,
      arguments["networkName"],
      arguments["revenue"],
      arguments["creativeId"],
      arguments["dspName"],
      arguments["placement"],
    );
  }

  static Future<bool?> isInitialized() {
    return channel.invokeMethod('isInitialized');
  }

  static void showMediationDebugger() {
    channel.invokeMethod('showMediationDebugger');
  }

  ///
  /// PRIVACY APIs
  ///

  static Future<int?> getConsentDialogState() {
    return channel.invokeMethod('getConsentDialogState');
  }

  static void setHasUserConsent(bool hasUserConsent) {
    channel.invokeMethod('setHasUserConsent', {
      'value': hasUserConsent,
    });
  }

  static Future<bool?> hasUserConsent() {
    return channel.invokeMethod('hasUserConsent');
  }

  static void setIsAgeRestrictedUser(bool isAgeRestrictedUser) {
    channel.invokeMethod('setIsAgeRestrictedUser', {
      'value': isAgeRestrictedUser,
    });
  }

  static Future<bool?> isAgeRestrictedUser() {
    return channel.invokeMethod('isAgeRestrictedUser');
  }

  static void setDoNotSell(bool isDoNotSell) {
    channel.invokeMethod('setDoNotSell', {
      'value': isDoNotSell,
    });
  }

  static Future<bool?> isDoNotSell() {
    return channel.invokeMethod('isDoNotSell');
  }

  ///
  /// GENERAL PUBLIC API
  ///

  static void setUserId(String userId) {
    channel.invokeMethod('setUserId', {
      'value': userId,
    });
  }

  static void setMuted(bool muted) {
    channel.invokeMethod('setMuted', {
      'value': muted,
    });
  }

  static void setVerboseLogging(enabled) {
    channel.invokeMethod('setVerboseLogging', {
      'value': enabled,
    });
  }

  static void setTestDeviceAdvertisingIds(List advertisingIdentifiers) {
    channel.invokeMethod('setTestDeviceAdvertisingIds', {
      'value': advertisingIdentifiers,
    });
  }

  ///
  /// BANNERS
  ///

  static void setBannerListener(AdViewAdListener listener) {
    _bannerAdListener = listener;
  }

  static void createBanner(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('createBanner', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void setBannerBackgroundColor(String adUnitId, String hexColorCodeString) {
    channel.invokeMethod('setBannerBackgroundColor', {
      'ad_unit_id': adUnitId,
      'hex_color_code': hexColorCodeString,
    });
  }

  static void setBannerPlacement(String adUnitId, String placement) {
    channel.invokeMethod('setBannerPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  static void updateBannerPosition(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('updateBannerPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void setBannerExtraParameter(String adUnitId, String key, String value) {
    channel.invokeMethod('setBannerExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  static void showBanner(String adUnitId) {
    channel.invokeMethod('showBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  static void hideBanner(String adUnitId) {
    channel.invokeMethod('hideBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  static void destroyBanner(String adUnitId) {
    channel.invokeMethod('destroyBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  ///
  /// MRECs
  ///

  static void setMRecListener(AdViewAdListener listener) {
    _mrecAdListener = listener;
  }

  static void createMRec(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('createMRec', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void setMRecPlacement(String adUnitId, String placement) {
    channel.invokeMethod('setMRecPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  static void updateMRecPosition(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('updateMRecPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void showMRec(String adUnitId) {
    channel.invokeMethod('showMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  static void hideMRec(String adUnitId) {
    channel.invokeMethod('hideMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  static void destroyMRec(String adUnitId) {
    channel.invokeMethod('destroyMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  ///
  /// Interstitials
  ///

  static void setInterstitialListener(InterstitialListener listener) {
    _interstitialListener = listener;
  }

  static void loadInterstitial(String adUnitId) {
    channel.invokeMethod('loadInterstitial', {
      'ad_unit_id': adUnitId,
    });
  }

  static Future<bool?> isInterstitialReady(String adUnitId) {
    return channel.invokeMethod('isInterstitialReady', {
      'ad_unit_id': adUnitId,
    });
  }

  static void showInterstitial(String adUnitId, {placement, customData}) {
    channel.invokeMethod('showInterstitial', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  static void setInterstitialExtraParameter(String adUnitId, String key, String value) {
    channel.invokeMethod('setInterstitialExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  ///
  /// Rewarded Ads
  ///

  static void setRewardedAdListener(RewardedAdListener listener) {
    _rewardedAdListener = listener;
  }

  static void loadRewardedAd(String adUnitId) {
    channel.invokeMethod('loadRewardedAd', {
      'ad_unit_id': adUnitId,
    });
  }

  static Future<bool?> isRewardedAdReady(String adUnitId) {
    return channel.invokeMethod('isRewardedAdReady', {
      'ad_unit_id': adUnitId,
    });
  }

  static void showRewardedAd(String adUnitId, {placement, customData}) {
    channel.invokeMethod('showRewardedAd', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  static void setRewardedAdExtraParameter(String adUnitId, String key, String value) {
    channel.invokeMethod('setRewardedAdExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }
}
