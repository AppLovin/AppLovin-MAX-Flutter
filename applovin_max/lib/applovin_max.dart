import 'package:applovin_max/src/ad_classes.dart';
import 'package:applovin_max/src/ad_listeners.dart';
import 'package:applovin_max/src/enums.dart';
import 'package:flutter/services.dart';

export 'package:applovin_max/src/ad_listeners.dart';
export 'package:applovin_max/src/enums.dart';

class AppLovinMAX {
  static const version = "1.0.3";

  static MethodChannel _channel = const MethodChannel('applovin_max');

  static AdViewAdListener? _bannerAdListener;
  static AdViewAdListener? _mrecAdListener;
  static InterstitialListener? _interstitialListener;
  static RewardedAdListener? _rewardedAdListener;

  static Future<Map?> initialize(String sdkKey) {
    _channel.setMethodCallHandler((MethodCall call) async {
      var method = call.method;
      var arguments = call.arguments;

      var adUnitId = arguments["adUnitId"];

      /// Banner Ad Events
      if ("OnBannerAdLoadedEvent" == method) {
        _bannerAdListener?.onAdLoadedCallback(_createAd(adUnitId, arguments));
      } else if ("OnBannerAdLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _bannerAdListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnBannerAdClickedEvent" == method) {
        _bannerAdListener?.onAdClickedCallback(_createAd(adUnitId, arguments));
      } else if ("OnBannerAdExpandedEvent" == method) {
        _bannerAdListener?.onAdExpandedCallback(_createAd(adUnitId, arguments));
      } else if ("OnBannerAdCollapsedEvent" == method) {
        _bannerAdListener?.onAdCollapsedCallback(_createAd(adUnitId, arguments));
      }

      /// MREC Ad Events
      else if ("OnMRecAdLoadedEvent" == method) {
        _mrecAdListener?.onAdLoadedCallback(_createAd(adUnitId, arguments));
      } else if ("OnMRecAdLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _mrecAdListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnMRecAdClickedEvent" == method) {
        _mrecAdListener?.onAdClickedCallback(_createAd(adUnitId, arguments));
      } else if ("OnMrecAdExpandedEvent" == method) {
        _mrecAdListener?.onAdExpandedCallback(_createAd(adUnitId, arguments));
      } else if ("OnMrecAdCollapsedEvent" == method) {
        _mrecAdListener?.onAdCollapsedCallback(_createAd(adUnitId, arguments));
      }

      /// Interstitial Ad Events
      else if ("OnInterstitialLoadedEvent" == method) {
        _interstitialListener?.onAdLoadedCallback.call(_createAd(adUnitId, arguments));
      } else if ("OnInterstitialLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _interstitialListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnInterstitialClickedEvent" == method) {
        _interstitialListener?.onAdClickedCallback.call(_createAd(adUnitId, arguments));
      } else if ("OnInterstitialDisplayedEvent" == method) {
        _interstitialListener?.onAdDisplayedCallback.call(_createAd(adUnitId, arguments));
      } else if ("OnInterstitialAdFailedToDisplayEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _interstitialListener?.onAdDisplayFailedCallback(_createAd(adUnitId, arguments), error);
      } else if ("OnInterstitialHiddenEvent" == method) {
        _interstitialListener?.onAdHiddenCallback.call(_createAd(adUnitId, arguments));
      }

      /// Rewarded Ad Events
      else if ("OnRewardedAdLoadedEvent" == method) {
        _rewardedAdListener?.onAdLoadedCallback.call(_createAd(adUnitId, arguments));
      } else if ("OnRewardedAdLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _rewardedAdListener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnRewardedAdClickedEvent" == method) {
        _rewardedAdListener?.onAdClickedCallback.call(_createAd(adUnitId, arguments));
      } else if ("OnRewardedAdDisplayedEvent" == method) {
        _rewardedAdListener?.onAdDisplayedCallback.call(_createAd(adUnitId, arguments));
      } else if ("OnRewardedAdFailedToDisplayEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        _rewardedAdListener?.onAdDisplayFailedCallback(_createAd(adUnitId, arguments), error);
      } else if ("OnRewardedAdHiddenEvent" == method) {
        _rewardedAdListener?.onAdHiddenCallback.call(_createAd(adUnitId, arguments));
      } else if ("OnRewardedAdReceivedRewardEvent" == method) {
        var reward = MaxReward(int.parse(arguments["rewardAmount"]), arguments["rewardLabel"]);
        _rewardedAdListener?.onAdReceivedRewardCallback(_createAd(adUnitId, arguments), reward);
      }
    });

    return _channel.invokeMethod('initialize', {
      'plugin_version': version,
      'sdk_key': sdkKey,
    });
  }

  static MaxAd _createAd(String adUnitId, dynamic arguments) {
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
    return _channel.invokeMethod('isInitialized');
  }

  static void showMediationDebugger() {
    _channel.invokeMethod('showMediationDebugger');
  }

  ///
  /// PRIVACY APIs
  ///

  static Future<int?> getConsentDialogState() {
    return _channel.invokeMethod('getConsentDialogState');
  }

  static void setHasUserConsent(bool hasUserConsent) {
    _channel.invokeMethod('setHasUserConsent', {
      'value': hasUserConsent,
    });
  }

  static Future<bool?> hasUserConsent() {
    return _channel.invokeMethod('hasUserConsent');
  }

  static void setIsAgeRestrictedUser(bool isAgeRestrictedUser) {
    _channel.invokeMethod('setIsAgeRestrictedUser', {
      'value': isAgeRestrictedUser,
    });
  }

  static Future<bool?> isAgeRestrictedUser() {
    return _channel.invokeMethod('isAgeRestrictedUser');
  }

  static void setDoNotSell(bool isDoNotSell) {
    _channel.invokeMethod('setDoNotSell', {
      'value': isDoNotSell,
    });
  }

  static Future<bool?> isDoNotSell() {
    return _channel.invokeMethod('isDoNotSell');
  }

  ///
  /// GENERAL PUBLIC API
  ///

  static void setUserId(String userId) {
    _channel.invokeMethod('setUserId', {
      'value': userId,
    });
  }

  static void setMuted(bool muted) {
    _channel.invokeMethod('setMuted', {
      'value': muted,
    });
  }

  static void setVerboseLogging(enabled) {
    _channel.invokeMethod('setVerboseLogging', {
      'value': enabled,
    });
  }

  static void setTestDeviceAdvertisingIds(List advertisingIdentifiers) {
    _channel.invokeMethod('setTestDeviceAdvertisingIds', {
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
    _channel.invokeMethod('createBanner', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void setBannerBackgroundColor(String adUnitId, String hexColorCodeString) {
    _channel.invokeMethod('setBannerBackgroundColor', {
      'ad_unit_id': adUnitId,
      'hex_color_code': hexColorCodeString,
    });
  }

  static void setBannerPlacement(String adUnitId, String placement) {
    _channel.invokeMethod('setBannerPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  static void updateBannerPosition(String adUnitId, AdViewPosition position) {
    _channel.invokeMethod('updateBannerPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void setBannerExtraParameter(String adUnitId, String key, String value) {
    _channel.invokeMethod('setBannerExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  static void showBanner(String adUnitId) {
    _channel.invokeMethod('showBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  static void hideBanner(String adUnitId) {
    _channel.invokeMethod('hideBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  static void destroyBanner(String adUnitId) {
    _channel.invokeMethod('destroyBanner', {
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
    _channel.invokeMethod('createMRec', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void setMRecPlacement(String adUnitId, String placement) {
    _channel.invokeMethod('setMRecPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  static void updateMRecPosition(String adUnitId, AdViewPosition position) {
    _channel.invokeMethod('updateMRecPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  static void showMRec(String adUnitId) {
    _channel.invokeMethod('showMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  static void hideMRec(String adUnitId) {
    _channel.invokeMethod('hideMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  static void destroyMRec(String adUnitId) {
    _channel.invokeMethod('destroyMRec', {
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
    _channel.invokeMethod('loadInterstitial', {
      'ad_unit_id': adUnitId,
    });
  }

  static Future<bool?> isInterstitialReady(String adUnitId) {
    return _channel.invokeMethod('isInterstitialReady', {
      'ad_unit_id': adUnitId,
    });
  }

  static void showInterstitial(String adUnitId, {placement = null, customData = null}) {
    _channel.invokeMethod('showInterstitial', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  static void setInterstitialExtraParameter(String adUnitId, String key, String value) {
    _channel.invokeMethod('setInterstitialExtraParameter', {
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
    _channel.invokeMethod('loadRewardedAd', {
      'ad_unit_id': adUnitId,
    });
  }

  static Future<bool?> isRewardedAdReady(String adUnitId) {
    return _channel.invokeMethod('isRewardedAdReady', {
      'ad_unit_id': adUnitId,
    });
  }

  static void showRewardedAd(String adUnitId, {placement = null, customData = null}) {
    _channel.invokeMethod('showRewardedAd', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  static void setRewardedAdExtraParameter(String adUnitId, String key, String value) {
    _channel.invokeMethod('setRewardedAdExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }
}
