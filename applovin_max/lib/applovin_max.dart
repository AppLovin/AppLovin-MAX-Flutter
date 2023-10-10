import 'package:applovin_max/src/ad_classes.dart';
import 'package:applovin_max/src/ad_listeners.dart';
import 'package:applovin_max/src/enums.dart';
import 'package:applovin_max/src/targeting_data.dart';
import 'package:flutter/services.dart';

export 'package:applovin_max/src/ad_classes.dart';
export 'package:applovin_max/src/ad_listeners.dart';
export 'package:applovin_max/src/enums.dart';
export 'package:applovin_max/src/max_ad_view.dart';
export 'package:applovin_max/src/max_native_ad_view.dart';
export 'package:applovin_max/src/targeting_data.dart';

/// Represents the AppLovin SDK.
class AppLovinMAX {
  /// The current version of the SDK.
  static const version = "3.3.0";

  /// @nodoc
  static MethodChannel channel = const MethodChannel('applovin_max');

  /// The targeting data object for you to provide user or app data that will improve how we target ads.
  static final TargetingData targetingData = TargetingData(channel);

  static AdViewAdListener? _bannerAdListener;
  static AdViewAdListener? _mrecAdListener;
  static InterstitialListener? _interstitialListener;
  static RewardedAdListener? _rewardedAdListener;
  static AppOpenAdListener? _appOpenAdListener;

  /// @nodoc
  ///
  /// Disabled dartdoc.
  AppLovinMAX();

  /// Initializes the SDK.
  ///
  /// [Initialize the SDK](https://dash.applovin.com/documentation/mediation/flutter/getting-started/integration#initialize-the-sdk)
  static Future<Map?> initialize(String sdkKey) {
    channel.setMethodCallHandler((MethodCall call) async {
      var method = call.method;
      var arguments = call.arguments;

      var adUnitId = arguments["adUnitId"];

      /// Banner Ad Events
      if ("OnBannerAdLoadedEvent" == method) {
        _bannerAdListener?.onAdLoadedCallback(createAd(adUnitId, arguments));
      } else if ("OnBannerAdLoadFailedEvent" == method) {
        _bannerAdListener?.onAdLoadFailedCallback(adUnitId, createError(arguments));
      } else if ("OnBannerAdClickedEvent" == method) {
        _bannerAdListener?.onAdClickedCallback(createAd(adUnitId, arguments));
      } else if ("OnBannerAdExpandedEvent" == method) {
        _bannerAdListener?.onAdExpandedCallback(createAd(adUnitId, arguments));
      } else if ("OnBannerAdCollapsedEvent" == method) {
        _bannerAdListener?.onAdCollapsedCallback(createAd(adUnitId, arguments));
      } else if ("OnBannerAdRevenuePaid" == method) {
        _bannerAdListener?.onAdRevenuePaidCallback?.call(createAd(adUnitId, arguments));
      }

      /// MREC Ad Events
      else if ("OnMRecAdLoadedEvent" == method) {
        _mrecAdListener?.onAdLoadedCallback(createAd(adUnitId, arguments));
      } else if ("OnMRecAdLoadFailedEvent" == method) {
        _mrecAdListener?.onAdLoadFailedCallback(adUnitId, createError(arguments));
      } else if ("OnMRecAdClickedEvent" == method) {
        _mrecAdListener?.onAdClickedCallback(createAd(adUnitId, arguments));
      } else if ("OnMRecAdExpandedEvent" == method) {
        _mrecAdListener?.onAdExpandedCallback(createAd(adUnitId, arguments));
      } else if ("OnMRecAdCollapsedEvent" == method) {
        _mrecAdListener?.onAdCollapsedCallback(createAd(adUnitId, arguments));
      } else if ("OnMRecAdRevenuePaid" == method) {
        _mrecAdListener?.onAdRevenuePaidCallback?.call(createAd(adUnitId, arguments));
      }

      /// Interstitial Ad Events
      else if ("OnInterstitialLoadedEvent" == method) {
        _interstitialListener?.onAdLoadedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnInterstitialLoadFailedEvent" == method) {
        _interstitialListener?.onAdLoadFailedCallback(adUnitId, createError(arguments));
      } else if ("OnInterstitialClickedEvent" == method) {
        _interstitialListener?.onAdClickedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnInterstitialDisplayedEvent" == method) {
        _interstitialListener?.onAdDisplayedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnInterstitialAdFailedToDisplayEvent" == method) {
        _interstitialListener?.onAdDisplayFailedCallback(createAd(adUnitId, arguments), createError(arguments));
      } else if ("OnInterstitialHiddenEvent" == method) {
        _interstitialListener?.onAdHiddenCallback.call(createAd(adUnitId, arguments));
      } else if ("OnInterstitialAdRevenuePaid" == method) {
        _interstitialListener?.onAdRevenuePaidCallback?.call(createAd(adUnitId, arguments));
      }

      /// Rewarded Ad Events
      else if ("OnRewardedAdLoadedEvent" == method) {
        _rewardedAdListener?.onAdLoadedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdLoadFailedEvent" == method) {
        _rewardedAdListener?.onAdLoadFailedCallback(adUnitId, createError(arguments));
      } else if ("OnRewardedAdClickedEvent" == method) {
        _rewardedAdListener?.onAdClickedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdDisplayedEvent" == method) {
        _rewardedAdListener?.onAdDisplayedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdFailedToDisplayEvent" == method) {
        _rewardedAdListener?.onAdDisplayFailedCallback(createAd(adUnitId, arguments), createError(arguments));
      } else if ("OnRewardedAdHiddenEvent" == method) {
        _rewardedAdListener?.onAdHiddenCallback.call(createAd(adUnitId, arguments));
      } else if ("OnRewardedAdReceivedRewardEvent" == method) {
        var reward = MaxReward(arguments["rewardAmount"], arguments["rewardLabel"]);
        _rewardedAdListener?.onAdReceivedRewardCallback(createAd(adUnitId, arguments), reward);
      } else if ("OnRewardedAdRevenuePaid" == method) {
        _rewardedAdListener?.onAdRevenuePaidCallback?.call(createAd(adUnitId, arguments));
      }

      /// App Open Ad Events
      else if ("OnAppOpenAdLoadedEvent" == method) {
        _appOpenAdListener?.onAdLoadedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnAppOpenAdLoadFailedEvent" == method) {
        _appOpenAdListener?.onAdLoadFailedCallback(adUnitId, createError(arguments));
      } else if ("OnAppOpenAdClickedEvent" == method) {
        _appOpenAdListener?.onAdClickedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnAppOpenAdDisplayedEvent" == method) {
        _appOpenAdListener?.onAdDisplayedCallback.call(createAd(adUnitId, arguments));
      } else if ("OnAppOpenAdFailedToDisplayEvent" == method) {
        _appOpenAdListener?.onAdDisplayFailedCallback(createAd(adUnitId, arguments), createError(arguments));
      } else if ("OnAppOpenAdHiddenEvent" == method) {
        _appOpenAdListener?.onAdHiddenCallback.call(createAd(adUnitId, arguments));
      } else if ("OnAppOpenAdRevenuePaid" == method) {
        _appOpenAdListener?.onAdRevenuePaidCallback?.call(createAd(adUnitId, arguments));
      }
    });

    return channel.invokeMethod('initialize', {
      'plugin_version': version,
      'sdk_key': sdkKey,
    });
  }

  /// @nodoc
  static MaxAd createAd(String adUnitId, dynamic arguments) {
    var rawNativeAd = arguments["nativeAd"];
    var jsonNativeAd = (rawNativeAd != null) ?  Map<String, dynamic>.from(rawNativeAd) : null;
    var nativeAd = (jsonNativeAd != null) ? MaxNativeAd.fromJson(jsonNativeAd) : null;

    return MaxAd(
      adUnitId,
      arguments["networkName"],
      arguments["revenue"],
      arguments["revenuePrecision"],
      arguments["creativeId"],
      arguments["dspName"],
      arguments["placement"],
      Map<String, dynamic>.from(arguments["waterfall"]),
      nativeAd,
    );
  }

  /// @nodoc
  static MaxError createError(dynamic arguments) {
    return MaxError(
      arguments["errorCode"],
      arguments["errorMessage"],
      Map<String, dynamic>.from(arguments["waterfall"]),
    );
  }

  /// Checks if the SDK has fully been initialized without errors.
  static Future<bool?> isInitialized() {
    return channel.invokeMethod('isInitialized');
  }

  /// Displays the Mediation Debugger.
  ///
  /// Mediation Debugger is a suite of testing tools.
  /// These tools help you integrate and launch faster with MAX.
  /// You can use them to confirm the validity of network integrations.
  /// This ensures that you can successfully load and show ads, among other things.
  ///
  /// [Mediation Debugger](https://dash.applovin.com/documentation/mediation/flutter/testing-networks/mediation-debugger)
  static void showMediationDebugger() {
    channel.invokeMethod('showMediationDebugger');
  }

  //
  // PRIVACY APIs
  //

  /// Returns an integer that encodes the state of the consent dialog.
  ///
  /// To learn more about how this information is encoded in the integer, see [ConsentDialogState].
  ///
  /// [Consent Flags in GDPR and Other Regions](https://dash.applovin.com/documentation/mediation/flutter/getting-started/privacy#consent-flags-in-gdpr-and-other-regions)
  static Future<int?> getConsentDialogState() {
    return channel.invokeMethod('getConsentDialogState');
  }

  /// Sets whether or not the user has provided consent for interest-based advertising.
  ///
  /// [Consent Flags in GDPR and Other Regions](https://dash.applovin.com/documentation/mediation/flutter/getting-started/privacy#consent-flags-in-gdpr-and-other-regions)
  static void setHasUserConsent(bool hasUserConsent) {
    channel.invokeMethod('setHasUserConsent', {
      'value': hasUserConsent,
    });
  }

  /// Checks if the user has set a consent flag.
  ///
  /// [Consent Flags in GDPR and Other Regions](https://dash.applovin.com/documentation/mediation/flutter/getting-started/privacy#consent-flags-in-gdpr-and-other-regions)
  static Future<bool?> hasUserConsent() {
    return channel.invokeMethod('hasUserConsent');
  }

  /// Marks the user as age-restricted.
  ///
  /// [Prohibition on Personal Information from Children](https://dash.applovin.com/documentation/mediation/flutter/getting-started/privacy#prohibition-on-personal-information-from-children)
  static void setIsAgeRestrictedUser(bool isAgeRestrictedUser) {
    channel.invokeMethod('setIsAgeRestrictedUser', {
      'value': isAgeRestrictedUser,
    });
  }

  /// Checks if the user is age-restricted.
  ///
  /// [Prohibition on Personal Information from Children](https://dash.applovin.com/documentation/mediation/flutter/getting-started/privacy#prohibition-on-personal-information-from-children)
  static Future<bool?> isAgeRestrictedUser() {
    return channel.invokeMethod('isAgeRestrictedUser');
  }

  /// Sets true to indicate that the user has opted out of interest-based advertising.
  ///
  /// Or, sets false to indicate that the user has not opted out of interest-based advertising.
  ///
  /// [California Consumer Privacy Act (“CCPA”)](https://dash.applovin.com/documentation/mediation/flutter/getting-started/privacy#california-consumer-privacy-act-(%E2%80%9Cccpa%E2%80%9D))
  static void setDoNotSell(bool isDoNotSell) {
    channel.invokeMethod('setDoNotSell', {
      'value': isDoNotSell,
    });
  }

  /// Returns true if the user has opted out of interest-based advertising.
  ///
  /// Or, returns false if the user has not opted out of interest-based advertising.
  ///
  /// [California Consumer Privacy Act (“CCPA”)](https://dash.applovin.com/documentation/mediation/flutter/getting-started/privacy#california-consumer-privacy-act-(%E2%80%9Cccpa%E2%80%9D))
  static Future<bool?> isDoNotSell() {
    return channel.invokeMethod('isDoNotSell');
  }

  //
  // GENERAL PUBLIC API
  //

  /// Sets the internal user ID for the current user to a string value of your choice.
  ///
  /// MAX passes this internal user ID back to you via the {USER_ID} macro in its MAX S2S Rewarded Callback requests.
  ///
  /// [Setting an Internal User ID](https://dash.applovin.com/documentation/mediation/s2s-rewarded-callback-api#setting-an-internal-user-id)
  static void setUserId(String userId) {
    channel.invokeMethod('setUserId', {
      'value': userId,
    });
  }

  /// Sets whether to begin video ads in a muted state or not.
  ///
  /// Note that this functionality is not available for all networks.
  ///
  /// [Mute Audio](https://dash.applovin.com/documentation/mediation/flutter/getting-started/advanced-settings#mute-audio)
  static void setMuted(bool muted) {
    channel.invokeMethod('setMuted', {
      'value': muted,
    });
  }

  /// Enables verbose logging for the SDK.
  ///
  /// [Enable Verbose Logging](https://dash.applovin.com/documentation/mediation/flutter/getting-started/advanced-settings#enable-verbose-logging)
  static void setVerboseLogging(bool enabled) {
    channel.invokeMethod('setVerboseLogging', {
      'value': enabled,
    });
  }

  /// Whether the creative debugger will be displayed on fullscreen ads after flipping the device screen down twice. Defaults to true.
  ///
  /// [Enable Creative Debugger](https://dash.applovin.com/documentation/mediation/flutter/testing-networks/creative-debugger)
  static void setCreativeDebuggerEnabled(bool enabled) {
    channel.invokeMethod('setCreativeDebuggerEnabled', {
      'value': enabled,
    });
  }

  /// @nodoc
  static void setTestDeviceAdvertisingIds(List advertisingIdentifiers) {
    channel.invokeMethod('setTestDeviceAdvertisingIds', {
      'value': advertisingIdentifiers,
    });
  }

  /// Whether or not the AppLovin SDK will collect the device location. Defaults to true.
  ///
  /// [Location Passing](https://dash.applovin.com/documentation/mediation/flutter/getting-started/data-passing#location-passing)
  static void setLocationCollectionEnabled(bool enabled) {
    channel.invokeMethod('setLocationCollectionEnabled', {
      'value': enabled,
    });
  }

  //
  // BANNERS
  //

  /// Sets an [AdViewAdListener] listener with which you can receive notifications about ad events.
  static void setBannerListener(AdViewAdListener listener) {
    _bannerAdListener = listener;
  }

  /// Creates a banner using your [adUnitId] at the specified [AdViewPosition] position.
  ///
  /// [Creating a Banner](https://dash.applovin.com/documentation/mediation/flutter/getting-started/banners#creating-a-banner)
  static void createBanner(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('createBanner', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  /// Sets a background color for the banner with the specified [adUnitId].
  ///
  /// Only hex strings ('#xxxxxx') are accepted.
  static void setBannerBackgroundColor(String adUnitId, String hexColorCodeString) {
    channel.invokeMethod('setBannerBackgroundColor', {
      'ad_unit_id': adUnitId,
      'hex_color_code': hexColorCodeString,
    });
  }

  /// Sets an ad placement name for the banner with the specified [adUnitId].
  ///
  /// [Setting an Ad Placement Name](https://dash.applovin.com/documentation/mediation/features/s2s-impression-revenue-api#setting-an-ad-placement-name)
  static void setBannerPlacement(String adUnitId, String placement) {
    channel.invokeMethod('setBannerPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  /// Updates the banner position with the specified [adUnitId].
  static void updateBannerPosition(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('updateBannerPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  /// Sets an extra parameter to the banner with the specified [adUnitId].
  ///
  /// For example, pass "adaptive_banner" and "false" to this method as the key/value pair
  /// to disable Adaptive Banners for the specified [adUnitId.
  ///
  /// [Adaptive Banners](https://dash.applovin.com/documentation/mediation/flutter/getting-started/banners#adaptive-banners)
  static void setBannerExtraParameter(String adUnitId, String key, String value) {
    channel.invokeMethod('setBannerExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  /// Shows the banner with the specified [adUnitId].
  ///
  /// [Displaying a Banner](https://dash.applovin.com/documentation/mediation/flutter/getting-started/banners#displaying-a-banner)
  static void showBanner(String adUnitId) {
    channel.invokeMethod('showBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Hides the banner with the specified [adUnitId].
  ///
  /// [Displaying a Banner](https://dash.applovin.com/documentation/mediation/flutter/getting-started/banners#displaying-a-banner)
  static void hideBanner(String adUnitId) {
    channel.invokeMethod('hideBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Starts or resumes auto-refreshing of the banner for the specified [adUnitId].
  static void startBannerAutoRefresh(String adUnitId) {
    channel.invokeMethod('startBannerAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Pauses auto-refreshing of the banner for the specified [adUnitId].
  static void stopBannerAutoRefresh(String adUnitId) {
    channel.invokeMethod('stopBannerAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Load a new banner ad.
  /// NOTE: The [createBanner] method loads the first banner ad and initiates an automated banner refresh process.
  /// You only need to call this method if you pause banner refresh.
  static void loadBanner(String adUnitId) {
    channel.invokeMethod('loadBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Cleans up system resources allocated for the banner.
  static void destroyBanner(String adUnitId) {
    channel.invokeMethod('destroyBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Gets the adaptive banner size for the provided width.
  static Future<double?> getAdaptiveBannerHeightForWidth(double width) {
    return channel.invokeMethod('getAdaptiveBannerHeightForWidth', {
        'width': width,
    });
  }

  //
  // MRECs
  //

  /// Sets an [AdViewAdListener] listener with which you can receive notifications about ad events.
  static void setMRecListener(AdViewAdListener listener) {
    _mrecAdListener = listener;
  }

  /// Creates an MREC using your [adUnitId] at the specified [AdViewPosition] position.
  ///
  /// [Programmatic Method](https://dash.applovin.com/documentation/mediation/flutter/getting-started/mrecs#programmatic-method)
  static void createMRec(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('createMRec', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  /// Sets an ad placement name for the MREC with the specified [adUnitId].
  ///
  /// [Setting an Ad Placement Name](https://dash.applovin.com/documentation/mediation/features/s2s-impression-revenue-api#setting-an-ad-placement-name)
  static void setMRecPlacement(String adUnitId, String placement) {
    channel.invokeMethod('setMRecPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  /// Updates the MREC position with the specified [adUnitId].
  static void updateMRecPosition(String adUnitId, AdViewPosition position) {
    channel.invokeMethod('updateMRecPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  /// Shows the MREC with the specified [adUnitId].
  static void showMRec(String adUnitId) {
    channel.invokeMethod('showMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Hides the MREC with the specified [adUnitId].
  static void hideMRec(String adUnitId) {
    channel.invokeMethod('hideMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Starts or resumes auto-refreshing of the MREC for the specified [adUnitId].
  static void startMRecAutoRefresh(String adUnitId) {
    channel.invokeMethod('startMRecAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Pauses auto-refreshing of the MREC for the specified [adUnitId].
  static void stopMRecAutoRefresh(String adUnitId) {
    channel.invokeMethod('stopMRecAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Load a new MREC ad.
  /// NOTE: The [createMRec] method loads the first MREC ad and initiates an automated MREC refresh process.
  /// You only need to call this method if you pause MREC refresh.
  static void loadMRec(String adUnitId) {
    channel.invokeMethod('loadMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Cleans up system resources allocated for the MREC.
  static void destroyMRec(String adUnitId) {
    channel.invokeMethod('destroyMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  //
  // Interstitials
  //

  /// Sets an [InterstitialListener] listener with which you can receive notifications about ad events.
  static void setInterstitialListener(InterstitialListener listener) {
    _interstitialListener = listener;
  }

  /// Loads an interstitial ad using your [adUnitId].
  ///
  /// [Loading an Interstitial Ad](https://dash.applovin.com/documentation/mediation/flutter/getting-started/interstitials#loading-an-interstitial-ad)
  static void loadInterstitial(String adUnitId) {
    channel.invokeMethod('loadInterstitial', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Check if the ad is ready to be shown with the specified [adUnitId].
  static Future<bool?> isInterstitialReady(String adUnitId) {
    return channel.invokeMethod('isInterstitialReady', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Shows the interstitial ad with the specified [adUnitId].
  ///
  /// [Showing an Interstitial Ad](https://dash.applovin.com/documentation/mediation/flutter/getting-started/interstitials#showing-an-interstitial-ad)
  static void showInterstitial(String adUnitId, {placement, customData}) {
    channel.invokeMethod('showInterstitial', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  /// Sets an extra parameter to the interstitial ad with the specified [adUnitId].
  static void setInterstitialExtraParameter(String adUnitId, String key, String value) {
    channel.invokeMethod('setInterstitialExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  //
  // Rewarded Ads
  //

  /// Sets a [RewardedAdListener] listener with which you can receive notifications about ad events.
  static void setRewardedAdListener(RewardedAdListener listener) {
    _rewardedAdListener = listener;
  }

  /// Loads a rewarded ad using your [adUnitId].
  ///
  /// [Loading a Rewarded Ad](https://dash.applovin.com/documentation/mediation/flutter/getting-started/rewarded-ads#loading-a-rewarded-ad)
  static void loadRewardedAd(String adUnitId) {
    channel.invokeMethod('loadRewardedAd', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Check if the ad is ready to be shown with the specified [adUnitId].
  static Future<bool?> isRewardedAdReady(String adUnitId) {
    return channel.invokeMethod('isRewardedAdReady', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Shows the rewarded ad with the specified [adUnitId].
  ///
  /// [Showing a Rewarded Ad](https://dash.applovin.com/documentation/mediation/flutter/getting-started/rewarded-ads#showing-a-rewarded-ad)
  static void showRewardedAd(String adUnitId, {placement, customData}) {
    channel.invokeMethod('showRewardedAd', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  /// Sets an extra parameter to the rewarded ad with the specified [adUnitId].
  static void setRewardedAdExtraParameter(String adUnitId, String key, String value) {
    channel.invokeMethod('setRewardedAdExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  //
  // App Open Ad
  //

  /// Sets a [AppOpenAdListener] listener with which you can receive notifications about ad events.
  static void setAppOpenAdListener(AppOpenAdListener listener) {
    _appOpenAdListener = listener;
  }

  /// Check if the ad is ready to be shown with the specified [adUnitId].
  static Future<bool?> isAppOpenAdReady(String adUnitId) {
    return channel.invokeMethod('isAppOpenAdReady', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Loads an app open ad using your [adUnitId].
  static void loadAppOpenAd(String adUnitId) {
    channel.invokeMethod('loadAppOpenAd', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Shows the app open ad with the specified [adUnitId].
  static void showAppOpenAd(String adUnitId, {placement, customData}) {
    channel.invokeMethod('showAppOpenAd', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  /// Sets an extra parameter to the rewarded ad with the specified [adUnitId].
  static void setAppOpenAdExtraParameter(String adUnitId, String key, String value) {
    channel.invokeMethod('setAppOpenAdExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }
}
