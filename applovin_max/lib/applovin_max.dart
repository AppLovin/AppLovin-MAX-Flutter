import 'dart:async';

import 'package:applovin_max/src/ad_classes.dart';
import 'package:applovin_max/src/ad_listeners.dart';
import 'package:applovin_max/src/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

export 'package:applovin_max/src/ad_classes.dart';
export 'package:applovin_max/src/ad_listeners.dart';
export 'package:applovin_max/src/enums.dart';
export 'package:applovin_max/src/max_ad_view.dart';
export 'package:applovin_max/src/max_native_ad_view.dart';

/// The current version of the SDK.
const String _version = "4.2.1";

/// Represents the AppLovin SDK.
class AppLovinMAX {
  /// @nodoc
  static const MethodChannel _methodChannel = MethodChannel('applovin_max');

  static bool _hasInitializeInvoked = false;
  static final Completer<MaxConfiguration> _initializeCompleter = Completer<MaxConfiguration>();

  static AdViewAdListener? _bannerAdListener;
  static AdViewAdListener? _mrecAdListener;
  static InterstitialListener? _interstitialListener;
  static RewardedAdListener? _rewardedAdListener;
  static AppOpenAdListener? _appOpenAdListener;
  static WidgetAdViewAdListener? _widgetAdViewAdListener;

  /// @nodoc
  ///
  /// Disabled dartdoc.
  AppLovinMAX();

  /// Initializes the SDK with the provided [sdkKey].
  ///
  /// For more information, see the [Initialize the SDK](https://developers.applovin.com/en/flutter/overview/integration).
  static Future<MaxConfiguration?> initialize(String sdkKey) async {
    if (_hasInitializeInvoked) {
      // Return a future object even when the actual value is not ready.
      return _initializeCompleter.future;
    }

    _hasInitializeInvoked = true;

    _methodChannel.setMethodCallHandler(_handleNativeMethodCall);

    try {
      // isInitialized() returns true when Flutter is performing hot restart
      bool isPlatformSDKInitialized = await isInitialized() ?? false;
      if (isPlatformSDKInitialized) {
        Map conf = await _methodChannel.invokeMethod('getConfiguration');
        _initializeCompleter.complete(MaxConfiguration.fromJson(Map<String, dynamic>.from(conf)));
        return _initializeCompleter.future;
      }

      var conf = await _methodChannel.invokeMethod('initialize', {
        'plugin_version': _version,
        'sdk_key': sdkKey,
      }) as Map;

      _initializeCompleter.complete(MaxConfiguration.fromJson(Map<String, dynamic>.from(conf)));

      return _initializeCompleter.future;
    } catch (e) {
      debugPrint('Error initializing AppLovin SDK: $e');
      _initializeCompleter.completeError(e);
      return null;
    }
  }

  static Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    try {
      final String method = call.method;
      final Map<dynamic, dynamic>? arguments = call.arguments;

      if (arguments == null) {
        throw ArgumentError('Arguments for method $method cannot be null.');
      }

      final MaxAd? ad = arguments.containsKey('networkName') ? createMaxAd(arguments) : null;

      final methodHandlers = {
        /// Banner Ad Events
        "OnBannerAdLoadedEvent": () => _bannerAdListener?.onAdLoadedCallback(ad!),
        "OnBannerAdLoadFailedEvent": () => _bannerAdListener?.onAdLoadFailedCallback(arguments["adUnitId"], createMaxError(arguments)),
        "OnBannerAdClickedEvent": () => _bannerAdListener?.onAdClickedCallback(ad!),
        "OnBannerAdExpandedEvent": () => _bannerAdListener?.onAdExpandedCallback(ad!),
        "OnBannerAdCollapsedEvent": () => _bannerAdListener?.onAdCollapsedCallback(ad!),
        "OnBannerAdRevenuePaid": () => _bannerAdListener?.onAdRevenuePaidCallback?.call(ad!),

        /// MREC Ad Events
        "OnMRecAdLoadedEvent": () => _mrecAdListener?.onAdLoadedCallback(ad!),
        "OnMRecAdLoadFailedEvent": () => _mrecAdListener?.onAdLoadFailedCallback(arguments["adUnitId"], createMaxError(arguments)),
        "OnMRecAdClickedEvent": () => _mrecAdListener?.onAdClickedCallback(ad!),
        "OnMRecAdExpandedEvent": () => _mrecAdListener?.onAdExpandedCallback(ad!),
        "OnMRecAdCollapsedEvent": () => _mrecAdListener?.onAdCollapsedCallback(ad!),
        "OnMRecAdRevenuePaid": () => _mrecAdListener?.onAdRevenuePaidCallback?.call(ad!),

        /// Interstitial Ad Events
        "OnInterstitialLoadedEvent": () => _interstitialListener?.onAdLoadedCallback(ad!),
        "OnInterstitialLoadFailedEvent": () => _interstitialListener?.onAdLoadFailedCallback(arguments["adUnitId"], createMaxError(arguments)),
        "OnInterstitialClickedEvent": () => _interstitialListener?.onAdClickedCallback(ad!),
        "OnInterstitialDisplayedEvent": () => _interstitialListener?.onAdDisplayedCallback(ad!),
        "OnInterstitialAdFailedToDisplayEvent": () =>
            _interstitialListener?.onAdDisplayFailedCallback(createMaxAd(arguments['ad']), createMaxError(arguments['error'])),
        "OnInterstitialHiddenEvent": () => _interstitialListener?.onAdHiddenCallback(ad!),
        "OnInterstitialAdRevenuePaid": () => _interstitialListener?.onAdRevenuePaidCallback?.call(ad!),

        /// Rewarded Ad Events
        "OnRewardedAdLoadedEvent": () => _rewardedAdListener?.onAdLoadedCallback(ad!),
        "OnRewardedAdLoadFailedEvent": () => _rewardedAdListener?.onAdLoadFailedCallback(arguments["adUnitId"], createMaxError(arguments)),
        "OnRewardedAdClickedEvent": () => _rewardedAdListener?.onAdClickedCallback(ad!),
        "OnRewardedAdDisplayedEvent": () => _rewardedAdListener?.onAdDisplayedCallback(ad!),
        "OnRewardedAdFailedToDisplayEvent": () =>
            _rewardedAdListener?.onAdDisplayFailedCallback(createMaxAd(arguments['ad']), createMaxError(arguments['error'])),
        "OnRewardedAdHiddenEvent": () => _rewardedAdListener?.onAdHiddenCallback(ad!),
        "OnRewardedAdReceivedRewardEvent": () {
          final MaxReward reward = MaxReward(arguments["rewardAmount"], arguments["rewardLabel"]);
          _rewardedAdListener?.onAdReceivedRewardCallback(ad!, reward);
        },
        "OnRewardedAdRevenuePaid": () => _rewardedAdListener?.onAdRevenuePaidCallback?.call(ad!),

        /// App Open Ad Events
        "OnAppOpenAdLoadedEvent": () => _appOpenAdListener?.onAdLoadedCallback(ad!),
        "OnAppOpenAdLoadFailedEvent": () => _appOpenAdListener?.onAdLoadFailedCallback(arguments["adUnitId"], createMaxError(arguments)),
        "OnAppOpenAdClickedEvent": () => _appOpenAdListener?.onAdClickedCallback(ad!),
        "OnAppOpenAdDisplayedEvent": () => _appOpenAdListener?.onAdDisplayedCallback(ad!),
        "OnAppOpenAdFailedToDisplayEvent": () =>
            _appOpenAdListener?.onAdDisplayFailedCallback(createMaxAd(arguments['ad']), createMaxError(arguments['error'])),
        "OnAppOpenAdHiddenEvent": () => _appOpenAdListener?.onAdHiddenCallback(ad!),
        "OnAppOpenAdRevenuePaid": () => _appOpenAdListener?.onAdRevenuePaidCallback?.call(ad!),

        /// Widget AdView Ad Events
        "OnWidgetAdViewAdLoadedEvent": () => _widgetAdViewAdListener?.onAdLoadedCallback(ad!),
        "OnWidgetAdViewAdLoadFailedEvent": () => _widgetAdViewAdListener?.onAdLoadFailedCallback(arguments["adUnitId"], createMaxError(arguments)),
      };

      final handler = methodHandlers[method];
      if (handler != null) {
        handler();
      } else {
        throw MissingPluginException('No handler for method $method');
      }
    } catch (e) {
      debugPrint('Error handling native method call ${call.method} with arguments ${call.arguments}: $e');
    }
  }

  /// @nodoc
  static MaxAd createMaxAd(dynamic arguments) {
    return MaxAd.fromJson(Map<String, dynamic>.from(arguments));
  }

  /// @nodoc
  static MaxError createMaxError(dynamic arguments) {
    return MaxError.fromJson(Map<String, dynamic>.from(arguments));
  }

  /// Checks if the SDK has fully been initialized without errors.
  static Future<bool?> isInitialized() async {
    try {
      return _methodChannel.invokeMethod('isInitialized');
    } catch (e) {
      debugPrint('Error checking if initialized: $e');
      return null;
    }
  }

  /// Displays the Mediation Debugger.
  ///
  /// Mediation Debugger is a suite of testing tools.
  /// These tools help you integrate and launch faster with MAX.
  /// You can use them to confirm the validity of network integrations.
  /// This ensures that you can successfully load and show ads, among other things.
  ///
  /// [Mediation Debugger](https://developers.applovin.com/en/flutter/testing-networks/mediation-debugger)
  static void showMediationDebugger() {
    _methodChannel.invokeMethod('showMediationDebugger');
  }

  //
  // PRIVACY APIs
  //

  /// Sets whether or not the user has provided consent for interest-based advertising.
  ///
  /// [Consent Flags in GDPR and Other Regions](https://developers.applovin.com/en/flutter/overview/privacy#consent-and-age-related-flags-in-gdpr-and-other-regions)
  static void setHasUserConsent(bool hasUserConsent) {
    _methodChannel.invokeMethod('setHasUserConsent', {
      'value': hasUserConsent,
    });
  }

  /// Checks if the user has set a consent flag.
  ///
  /// [Consent Flags in GDPR and Other Regions](https://developers.applovin.com/en/flutter/overview/privacy#consent-and-age-related-flags-in-gdpr-and-other-regions)
  static Future<bool?> hasUserConsent() {
    return _methodChannel.invokeMethod('hasUserConsent');
  }

  /// Sets true to indicate that the user has opted out of interest-based advertising.
  ///
  /// Or, sets false to indicate that the user has not opted out of interest-based advertising.
  ///
  /// [California Consumer Privacy Act (“CCPA”)](https://developers.applovin.com/en/flutter/overview/privacy#multi-state-consumer-privacy-laws)
  static void setDoNotSell(bool isDoNotSell) {
    _methodChannel.invokeMethod('setDoNotSell', {
      'value': isDoNotSell,
    });
  }

  /// Returns true if the user has opted out of interest-based advertising.
  ///
  /// Or, returns false if the user has not opted out of interest-based advertising.
  ///
  /// [California Consumer Privacy Act (“CCPA”)](https://developers.applovin.com/en/flutter/overview/privacy#multi-state-consumer-privacy-laws)
  static Future<bool?> isDoNotSell() {
    return _methodChannel.invokeMethod('isDoNotSell');
  }

  //
  // GENERAL PUBLIC API
  //

  /// Sets the internal user ID for the current user to a string value of your choice.
  ///
  /// MAX passes this internal user ID back to you via the {USER_ID} macro in its MAX S2S Rewarded Callback requests.
  ///
  /// [Setting an Internal User ID](https://developers.applovin.com/en/advanced-features/s2s-rewarded-callback-api#setting-an-internal-user-id)
  static void setUserId(String userId) {
    _methodChannel.invokeMethod('setUserId', {
      'value': userId,
    });
  }

  /// Sets whether to begin video ads in a muted state or not.
  ///
  /// Note that this functionality is not available for all networks.
  ///
  /// [Mute Audio](https://developers.applovin.com/en/flutter/overview/advanced-settings#mute-audio)
  static void setMuted(bool muted) {
    _methodChannel.invokeMethod('setMuted', {
      'value': muted,
    });
  }

  /// Enables verbose logging for the SDK.
  ///
  /// [Enable Verbose Logging](https://developers.applovin.com/en/flutter/overview/advanced-settings#enable-verbose-logging)
  static void setVerboseLogging(bool enabled) {
    _methodChannel.invokeMethod('setVerboseLogging', {
      'value': enabled,
    });
  }

  /// Whether the creative debugger will be displayed on fullscreen ads after flipping the device screen down twice. Defaults to true.
  ///
  /// [Enable Creative Debugger](https://developers.applovin.com/en/flutter/testing-networks/creative-debugger)
  static void setCreativeDebuggerEnabled(bool enabled) {
    _methodChannel.invokeMethod('setCreativeDebuggerEnabled', {
      'value': enabled,
    });
  }

  /// Enables devices to receive test ads by passing in the advertising identifier (IDFA or IDFV) of
  /// each test device. Refer to AppLovin logs for the IDFA or IDFV of your current device.
  ///
  static void setTestDeviceAdvertisingIds(List<String> advertisingIdentifiers) {
    _methodChannel.invokeMethod('setTestDeviceAdvertisingIds', {
      'value': advertisingIdentifiers,
    });
  }

  /// Whether or not the AppLovin SDK will collect the device location. Defaults to true.
  ///
  /// [Location Passing](https://developers.applovin.com/en/flutter/overview/data-and-keyword-passing#location-passing)
  static void setLocationCollectionEnabled(bool enabled) {
    _methodChannel.invokeMethod('setLocationCollectionEnabled', {
      'value': enabled,
    });
  }

  /// Sets an extra parameter to pass to the AppLovin server.
  static void setExtraParameter(String key, String? value) {
    _methodChannel.invokeMethod('setExtraParameter', {
      'key': key,
      'value': value,
    });
  }

  /// Sets a list of the ad units for the SDK to initialize only those networks.
  /// Should be set before initializing the SDK.
  static void setInitializationAdUnitIds(List<String> adUnitIds) {
    _methodChannel.invokeMethod('setInitializationAdUnitIds', {
      'value': adUnitIds,
    });
  }

  /// Enables the MAX Terms and Privacy Policy Flow.
  static void setTermsAndPrivacyPolicyFlowEnabled(bool enabled) {
    _methodChannel.invokeMethod('setTermsAndPrivacyPolicyFlowEnabled', {
      'value': enabled,
    });
  }

  /// The URL of your company’s privacy policy, as a string. This is required in
  /// order to enable the Terms Flow.
  static void setPrivacyPolicyUrl(String urlString) {
    _methodChannel.invokeMethod('setPrivacyPolicyUrl', {
      'value': urlString,
    });
  }

  /// The URL of your company’s terms of service, as a string. This is optional;
  /// you can enable the Terms Flow with or without it.
  static void setTermsOfServiceUrl(String urlString) {
    _methodChannel.invokeMethod('setTermsOfServiceUrl', {
      'value': urlString,
    });
  }

  /// Set debug user geography. You may use this to test CMP flow by setting
  /// this to [ConsentFlowUserGeography.GDPR].
  static void setConsentFlowDebugUserGeography(ConsentFlowUserGeography userGeography) {
    _methodChannel.invokeMethod('setConsentFlowDebugUserGeography', {
      'value': userGeography.value,
    });
  }

  /// Shows the CMP flow to an existing user.
  /// Note that this resets the user’s existing consent information.
  ///
  /// The function returns when the flow finishes showing. On success, returns
  /// null. On failure, returns [MaxCMPError].
  static Future<MaxCMPError?> showCmpForExistingUser() async {
    Map? error = await _methodChannel.invokeMethod('showCmpForExistingUser') as Map?;
    if (error == null) return null;
    return MaxCMPError.fromJson(Map<String, dynamic>.from(error));
  }

  /// Returns true if a supported CMP SDK is detected.
  static Future<bool?> hasSupportedCmp() {
    return _methodChannel.invokeMethod('hasSupportedCmp');
  }

  //
  // BANNERS
  //

  /// Sets an [AdViewAdListener] listener with which you can receive notifications about ad events.
  static void setBannerListener(AdViewAdListener? listener) {
    _bannerAdListener = listener;
  }

  /// Creates a banner using your [adUnitId] at the specified [AdViewPosition] position.
  ///
  /// [Creating a Banner](https://developers.applovin.com/en/flutter/ad-formats/banner-mrec-ads)
  static void createBanner(String adUnitId, AdViewPosition position) {
    _methodChannel.invokeMethod('createBanner', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
    setBannerExtraParameter(adUnitId, "adaptive_banner", "true");
  }

  /// Sets a background color for the banner with the specified [adUnitId].
  ///
  /// Only hex strings ('#xxxxxx') are accepted.
  static void setBannerBackgroundColor(String adUnitId, String hexColorCodeString) {
    _methodChannel.invokeMethod('setBannerBackgroundColor', {
      'ad_unit_id': adUnitId,
      'hex_color_code': hexColorCodeString,
    });
  }

  /// Sets an ad placement name for the banner with the specified [adUnitId].
  ///
  /// [Setting an Ad Placement Name](https://developers.applovin.com/en/advanced-features/s2s-impression-level-api#setting-an-ad-placement-name)
  static void setBannerPlacement(String adUnitId, String placement) {
    _methodChannel.invokeMethod('setBannerPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  static void setBannerWidth(String adUnitId, double width) {
    _methodChannel.invokeMethod('setBannerWidth', {
      'ad_unit_id': adUnitId,
      'width': width.round(),
    });
  }

  /// Updates the banner position with the specified [adUnitId].
  static void updateBannerPosition(String adUnitId, AdViewPosition position) {
    _methodChannel.invokeMethod('updateBannerPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  /// Sets an extra parameter to the banner with the specified [adUnitId].
  ///
  /// For example, pass "adaptive_banner" and "false" to this method as the key/value pair
  /// to disable Adaptive Banners for the specified [adUnitId.
  ///
  /// [Adaptive Banners](https://developers.applovin.com/en/flutter/ad-formats/banner-mrec-ads#adaptive-banners)
  static void setBannerExtraParameter(String adUnitId, String key, String value) {
    _methodChannel.invokeMethod('setBannerExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  /// Shows the banner with the specified [adUnitId].
  ///
  /// [Displaying a Banner](https://developers.applovin.com/en/flutter/ad-formats/banner-mrec-ads#displaying-a-banner)
  static void showBanner(String adUnitId) {
    _methodChannel.invokeMethod('showBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Hides the banner with the specified [adUnitId].
  ///
  /// [Displaying a Banner](https://developers.applovin.com/en/flutter/ad-formats/banner-mrec-ads#displaying-a-banner)
  static void hideBanner(String adUnitId) {
    _methodChannel.invokeMethod('hideBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Starts or resumes auto-refreshing of the banner for the specified [adUnitId].
  static void startBannerAutoRefresh(String adUnitId) {
    _methodChannel.invokeMethod('startBannerAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Pauses auto-refreshing of the banner for the specified [adUnitId].
  static void stopBannerAutoRefresh(String adUnitId) {
    _methodChannel.invokeMethod('stopBannerAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Load a new banner ad.
  /// NOTE: The [createBanner] method loads the first banner ad and initiates an automated banner refresh process.
  /// You only need to call this method if you pause banner refresh.
  static void loadBanner(String adUnitId) {
    _methodChannel.invokeMethod('loadBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Cleans up system resources allocated for the banner.
  static void destroyBanner(String adUnitId) {
    _methodChannel.invokeMethod('destroyBanner', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Gets the adaptive banner size for the provided width.
  static Future<double?> getAdaptiveBannerHeightForWidth(double width) {
    return _methodChannel.invokeMethod('getAdaptiveBannerHeightForWidth', {
      'width': width,
    });
  }

  //
  // MRECs
  //

  /// Sets an [AdViewAdListener] listener with which you can receive notifications about ad events.
  static void setMRecListener(AdViewAdListener? listener) {
    _mrecAdListener = listener;
  }

  /// Creates an MREC using your [adUnitId] at the specified [AdViewPosition] position.
  ///
  /// [Programmatic Method](https://developers.applovin.com/en/flutter/ad-formats/banner-mrec-ads#loading-a-banner-or-mrec)
  static void createMRec(String adUnitId, AdViewPosition position) {
    _methodChannel.invokeMethod('createMRec', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  /// Sets an ad placement name for the MREC with the specified [adUnitId].
  ///
  /// [Setting an Ad Placement Name](https://developers.applovin.com/en/advanced-features/s2s-impression-level-api#setting-an-ad-placement-name)
  static void setMRecPlacement(String adUnitId, String placement) {
    _methodChannel.invokeMethod('setMRecPlacement', {
      'ad_unit_id': adUnitId,
      'placement': placement,
    });
  }

  /// Updates the MREC position with the specified [adUnitId].
  static void updateMRecPosition(String adUnitId, AdViewPosition position) {
    _methodChannel.invokeMethod('updateMRecPosition', {
      'ad_unit_id': adUnitId,
      'position': position.value,
    });
  }

  /// Sets an extra parameter to the MREC with the specified [adUnitId].
  static void setMRecExtraParameter(String adUnitId, String key, String value) {
    _methodChannel.invokeMethod('setMRecExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  /// Shows the MREC with the specified [adUnitId].
  static void showMRec(String adUnitId) {
    _methodChannel.invokeMethod('showMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Hides the MREC with the specified [adUnitId].
  static void hideMRec(String adUnitId) {
    _methodChannel.invokeMethod('hideMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Starts or resumes auto-refreshing of the MREC for the specified [adUnitId].
  static void startMRecAutoRefresh(String adUnitId) {
    _methodChannel.invokeMethod('startMRecAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Pauses auto-refreshing of the MREC for the specified [adUnitId].
  static void stopMRecAutoRefresh(String adUnitId) {
    _methodChannel.invokeMethod('stopMRecAutoRefresh', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Load a new MREC ad.
  /// NOTE: The [createMRec] method loads the first MREC ad and initiates an automated MREC refresh process.
  /// You only need to call this method if you pause MREC refresh.
  static void loadMRec(String adUnitId) {
    _methodChannel.invokeMethod('loadMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Cleans up system resources allocated for the MREC.
  static void destroyMRec(String adUnitId) {
    _methodChannel.invokeMethod('destroyMRec', {
      'ad_unit_id': adUnitId,
    });
  }

  //
  // Interstitials
  //

  /// Sets an [InterstitialListener] listener with which you can receive notifications about ad events.
  static void setInterstitialListener(InterstitialListener? listener) {
    _interstitialListener = listener;
  }

  /// Loads an interstitial ad using your [adUnitId].
  ///
  /// [Loading an Interstitial Ad](https://developers.applovin.com/en/flutter/ad-formats/interstitial-ads#loading-an-interstitial-ad)
  static void loadInterstitial(String adUnitId) {
    _methodChannel.invokeMethod('loadInterstitial', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Check if the ad is ready to be shown with the specified [adUnitId].
  static Future<bool?> isInterstitialReady(String adUnitId) {
    return _methodChannel.invokeMethod('isInterstitialReady', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Shows the interstitial ad with the specified [adUnitId].
  ///
  /// [Showing an Interstitial Ad](https://developers.applovin.com/en/flutter/ad-formats/interstitial-ads#showing-an-interstitial-ad)
  static void showInterstitial(String adUnitId, {String? placement, String? customData}) {
    _methodChannel.invokeMethod('showInterstitial', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  /// Sets an extra parameter to the interstitial ad with the specified [adUnitId].
  static void setInterstitialExtraParameter(String adUnitId, String key, String value) {
    _methodChannel.invokeMethod('setInterstitialExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  //
  // Rewarded Ads
  //

  /// Sets a [RewardedAdListener] listener with which you can receive notifications about ad events.
  static void setRewardedAdListener(RewardedAdListener? listener) {
    _rewardedAdListener = listener;
  }

  /// Loads a rewarded ad using your [adUnitId].
  ///
  /// [Loading a Rewarded Ad](https://developers.applovin.com/en/flutter/ad-formats/rewarded-ads/#loading-a-rewarded-ad)
  static void loadRewardedAd(String adUnitId) {
    _methodChannel.invokeMethod('loadRewardedAd', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Check if the ad is ready to be shown with the specified [adUnitId].
  static Future<bool?> isRewardedAdReady(String adUnitId) {
    return _methodChannel.invokeMethod('isRewardedAdReady', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Shows the rewarded ad with the specified [adUnitId].
  ///
  /// [Showing a Rewarded Ad](https://developers.applovin.com/en/flutter/ad-formats/rewarded-ads#showing-a-rewarded-ad)
  static void showRewardedAd(String adUnitId, {String? placement, String? customData}) {
    _methodChannel.invokeMethod('showRewardedAd', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  /// Sets an extra parameter to the rewarded ad with the specified [adUnitId].
  static void setRewardedAdExtraParameter(String adUnitId, String key, String value) {
    _methodChannel.invokeMethod('setRewardedAdExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  //
  // App Open Ad
  //

  /// Sets a [AppOpenAdListener] listener with which you can receive notifications about ad events.
  static void setAppOpenAdListener(AppOpenAdListener? listener) {
    _appOpenAdListener = listener;
  }

  /// Check if the ad is ready to be shown with the specified [adUnitId].
  static Future<bool?> isAppOpenAdReady(String adUnitId) {
    return _methodChannel.invokeMethod('isAppOpenAdReady', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Loads an app open ad using your [adUnitId].
  static void loadAppOpenAd(String adUnitId) {
    _methodChannel.invokeMethod('loadAppOpenAd', {
      'ad_unit_id': adUnitId,
    });
  }

  /// Shows the app open ad with the specified [adUnitId].
  static void showAppOpenAd(String adUnitId, {String? placement, String? customData}) {
    _methodChannel.invokeMethod('showAppOpenAd', {
      'ad_unit_id': adUnitId,
      'placement': placement,
      'custom_data': customData,
    });
  }

  /// Sets an extra parameter to the rewarded ad with the specified [adUnitId].
  static void setAppOpenAdExtraParameter(String adUnitId, String key, String value) {
    _methodChannel.invokeMethod('setAppOpenAdExtraParameter', {
      'ad_unit_id': adUnitId,
      'key': key,
      'value': value,
    });
  }

  //
  // AdView Preloading
  //

  /// Sets a [WidgetAdViewAdListener] to receive notifications about
  /// [MaxAdView] ad events when preloading a [MaxAdView] platform widget with
  /// [preloadWidgetAdView].
  static void setWidgetAdViewAdListener(WidgetAdViewAdListener? listener) {
    _widgetAdViewAdListener = listener;
  }

  /// Preloads a [MaxAdView] platform widget for the specified [adUnitId] and [adFormat].
  ///
  /// Preloading a [MaxAdView] improves ad rendering speed when the widget is later
  /// mounted in the widget tree. The preloaded platform widget is reused across
  /// mounts for the same [adViewId] until explicitly destroyed, reducing load times.
  ///
  /// - **Behavior**:
  ///   - When a [MaxAdView] is mounted with the preloaded [adViewId], it uses the
  ///     preloaded platform widget for faster rendering.
  ///
  /// - **Important**: Preloaded platform widgets must be destroyed manually using
  ///   [destroyWidgetAdView] when they are no longer needed to free up resources.
  ///
  /// - **Return**:
  ///   A `Future<AdViewId?>` that completes when the preload operation starts
  ///   successfully. If the operation fails, the `Future` completes with an error.
  static Future<AdViewId?> preloadWidgetAdView(
    String adUnitId,
    AdFormat adFormat, {
    String? placement,
    String? customData,
    Map<String, String?>? extraParameters,
    Map<String, dynamic>? localExtraParameters,
  }) {
    Map<String, String?> extraParametersWithAdaptiveBanner = Map<String, String?>.from(extraParameters ?? {});

    if (extraParameters?['adaptive_banner'] == null) {
      // Set the default value for 'adaptive_banner'
      extraParametersWithAdaptiveBanner['adaptive_banner'] = 'true';
    }

    return _methodChannel.invokeMethod('preloadWidgetAdView', {
      'ad_unit_id': adUnitId,
      'ad_format': adFormat.value,
      'placement': placement,
      'custom_data': customData,
      'extra_parameters': extraParametersWithAdaptiveBanner,
      'local_extra_parameters': localExtraParameters,
    });
  }

  /// Destroys the preloaded [MaxAdView] platform widget associated with the specified [adViewId].
  ///
  /// This method releases resources associated with the preloaded platform widget,
  /// ensuring that no unnecessary memory or platform-side resources remain allocated.
  ///
  /// - **Return**:
  ///   A `Future<void>` that completes once the destruction operation is successful.
  ///   If the operation fails, the `Future` completes with an error.
  static Future<void> destroyWidgetAdView(AdViewId adViewId) {
    return _methodChannel.invokeMethod('destroyWidgetAdView', {
      'ad_view_id': adViewId,
    });
  }

  //
  // Segment Targeting
  //

  /// Adds a segment.
  static void addSegment(int key, List<int> values) {
    _methodChannel.invokeMethod('addSegment', {
      'key': key,
      'values': values,
    });
  }

  /// Returns a list of the segments.
  static Future<Map<int, List<int>>?> getSegments() async {
    Map? untypedSegments = await _methodChannel.invokeMethod('getSegments');
    if (untypedSegments == null) return null;

    Map<int, List<int>> typedSegments = {};
    untypedSegments.forEach((key, value) {
      if (key is int && value is List) {
        bool areAllInt = value.every((element) => element is int);
        if (areAllInt) {
          typedSegments[key] = List<int>.from(value);
        }
      }
    });

    return typedSegments;
  }
}
