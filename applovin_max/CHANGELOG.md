## Versions

## 4.5.1
* Depends on Android SDK v13.3.1 and iOS SDK v13.3.1.
## 4.5.0
* Depends on Android SDK v13.3.0 and iOS SDK v13.3.0.
* Add optional `isAdaptive` flag to `AppLovinMAX.createBanner()` and `AppLovinMAX.preloadWidgetAdView()` to enable adaptive banners (default: true).
* Fix support for adaptive banners. For more info, check out our [docs](https://developers.applovin.com/en/max/flutter/ad-formats/banner-and-mrec-ads#adaptive-banners).
## 4.4.0
* Depends on Android SDK v13.2.0 and iOS SDK v13.2.0.
## 4.3.1
* Fix CTA not clickable.
* Remove deprecated `AppLovinMAX.setLocationCollectionEnabled()` API.
## 4.3.0
* Update `MaxAd` to include `adFormat`, `networkPlacement`, and `latencyMills`.
* Depends on Android SDK v13.1.0 and iOS SDK v13.1.0.
## 4.2.1
* Update the example.
## 4.2.0
* Add support for adaptive banners. For more info, check out our [docs](https://developers.applovin.com/en/max/flutter/ad-formats/banner-and-mrec-ads#adaptive-banners).
## 4.1.2
* Fix preloaded banners and MRECs not resuming auto-refresh on iOS.
## 4.1.1
* Remove the mistakenly enabled adaptive banner from Android to prevent app-side errors.
* Remove obsolete MAX Error Codes - `ErrorCode.fullscreenAdAlreadyLoading` and `ErrorCode.fullscreenAdLoadWhileShowing`.
## 4.1.0
* Enhance banner and MREC (`MaxAdView`) preloading to support preloading multiple `MaxAdView` instances.
* Update preloaded banners and MRECs (`MaxAdView`) to suspend auto-refresh while not visible in background.
* Depends on Android SDK v13.0.1 and iOS SDK v13.0.1.
## 4.0.2
* Update IconView to support native ad icon image view, primarily for BigoAds native ads.
## 4.0.1
* Crash if plugin version is incompatible with native SDK version.
* Add support for Yandex native ads.
* Update listener APIs to allow for null values for unsetting.
## 4.0.0
* Depends on Android SDK v13.0.0 and iOS SDK v13.0.0.
* Removed COPPA support.
* Add constants for MAX Error Codes. For more info, check out our [docs](https://developers.applovin.com/en/max/flutter/overview/error-handling#max-error-codes).
## 3.11.1
* Depends on Android SDK v12.6.1 and iOS SDK v12.6.1.
* Add APIs to preload widgets for banners and MRECs. For more info, check out our [docs](https://developers.applovin.com/en/max/flutter/ad-formats/banner-mrec-ads#ad-preloading).
## 3.11.0
* Replace targeting data APIs with new numeric segments targeting APIs. For migration instructions, please see [here](https://developers.applovin.com/en/flutter/overview/data-and-keyword-passing/#segment-targeting).
* Depends on Android SDK v12.6.0 and iOS SDK v12.6.0.
* Fix ad callbacks not firing after hot restart. https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/229
* Fix `Null check operator used on a null value` warning in `MaxNativeAdView.dispose()`.
## 3.10.1
* Update `AppLovinMAX.initialize()` to return a `Future` on hot restart.
## 3.10.0
* Depends on Android SDK v12.5.0 and iOS SDK v12.5.0.
## 3.9.2
* Fix crash on `AppLovinMAX.initialize()` with `java.lang.IllegalStateException: Reply already submitted`.
## 3.9.1
* Depends on Android SDK v12.4.2 and iOS SDK v12.4.1.
## 3.9.0
* Depends on Android SDK v12.4.0 and iOS SDK v12.4.0.
## 3.8.1
* Depends on Android SDK v12.3.1 and iOS SDK v12.3.1.
## 3.8.0
* Depends on Android SDK v12.3.0 and iOS SDK v12.3.0.
* Add support to classify waterfall objects. For more info, check out our [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/advanced-settings#waterfall-information-api).
* Refactored error handling logic.
## 3.7.0
* Depends on Android SDK v12.2.0 and iOS SDK v12.2.1.
* Add `MaxCMPError` to encapsulate a return object of `AppLovinMAX.showCmpForExistingUser()`. For more info, check out our [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/terms-and-privacy-policy-flow#showing-gdpr-flow-to-existing-users).
* Fix banner/MREC background not hiding.
* Update the comment description for `AppLovinMAX.setTestDeviceAdvertisingIds(...)`.
* Fix NPE for accessing a `null` `methodChannel` in `MaxAdView`. https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/176
* Fix linter warnings.
## 3.6.0
* Fix NPE for accessing a null native ad on Android.
* Update `AppLovinMAX.showCmpForExistingUser()` to return `CmpError` instead of `int` raw value.
* Add `MaxConfiguration` to encapsulate a return object of `AppLovinMAX.initialize(...)`.
* Add support for Amazon bidding for rewarded ads.
## 3.5.0
* Add support for showing Google UMP to existing users for integrations using our Google UMP Automation feature. For more info, check out our [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/terms-and-privacy-policy-flow#showing-gdpr-flow-to-existing-users).
* Add better support for Amazon bidding.
## 3.4.1
* Allow calls to `AppLovinMAX.setMuted(...)` before SDK is initialized.
* Depends on Android SDK v12.1.0 and iOS SDK v12.1.0.
## 3.4.0
* Add support for Selective Init. For more info, check out our [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/advanced-settings#selective-init).
* Add support for Terms and Privacy Policy Flow. For more info, check out our [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/terms-and-privacy-policy-flow).
* Add support for `AppLovinMAX.setMRecExtraParameter()` API.
* Add support for `AppLovinMAX.setExtraParameter()` API.
* Depends on Android SDK v12.0.0 and iOS SDK v12.0.0.
* Fix `starRating` not correctly converting from platform on iOS.
## 3.3.0
* Add `revenuePrecision` API to the `MaxAd` object returned in ad callbacks. For more info, check out our [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/advanced-settings#impression-level-user-revenue-api).
* Replace `MediaQuery.devicePixelRatioOf` with `MediaQuery.of().devicePixelRatio`. https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/120
## 3.2.0
* Add support for widget adaptive banners via `MaxAdView(extraParameters: {"adaptive_banner": "true"}, ... )`.
## 3.1.2
* Fix `LateInitializationError` when building native ad widget. Fixes https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/113.
## 3.1.1
* Depends on Android SDK v11.11.2 and iOS SDK v11.11.2.
## 3.1.0
* Depends on Android SDK v11.11.1 and iOS SDK v11.11.2.
* Fix banner and MREC widgets occupying space before it is loaded. https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/40
* Add API for passing extra parameters and local extra parameters for widget banners, MRECs, and native ads.
* Fix blank media views for Mintegral native ads.
## 3.0.1
* Fix native ad app icon not rendering on Android.
## 3.0.0
* Add support for native ads. Please refer to our documentation [here](https://dash.applovin.com/documentation/mediation/flutter/ad-formats/native-manual)) for more info. Addresses https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/26.
## 2.6.0
* Depends on Android SDK v11.10.1 and iOS SDK v11.10.1.
## 2.5.0
* Depends on Android SDK v11.9.0 and iOS SDK v11.9.0.
* Fix ad load failure callbacks not firing for widget banners/MRECs. Fixes https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/62.
## 2.4.6
* Depends on Android SDK v11.8.2 and iOS SDK v11.8.2.
## 2.4.4
* Fix iOS widget banners/MRECs crash when not passing in placement or custom data.
## 2.4.3
* Fix placements and custom data not being passed for widget banners/MRECs.
## 2.4.2
* Fix hot restart not working. Fixes https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/20.
## 2.4.1
* Depends on Android SDK v11.7.1 and iOS SDK v11.7.1.
* Fix `MaxAdView` widget creation error on Android. Fixes https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/76.
## 2.4.0
* Add support for stopping/starting banner and MREC auto-refresh programmatically and via the is `MaxAdView.isAutoRefreshEnabled` state (banner [docs](https://dash.applovin.com/documentation/mediation/flutter/ad-formats/banners#stopping-and-starting-auto-refresh), MREC [docs](https://dash.applovin.com/documentation/mediation/flutter/ad-formats/mrecs#stopping-and-starting-auto-refresh)).
* Add support for manually loading banner and MREC ads if auto-refesh is stopped via `AppLovinMAX.loadBanner()` and `AppLovinMAX.loadMRec()`.
## 2.3.3
* Depends on Android SDK v11.6.1 and iOS SDK v11.6.1.
## 2.3.2
* Depends on Android SDK v11.6.0 and iOS SDK v11.6.0.
* Add support for waterfall info API.
* Add support for `AppLovinMAX.setLocationCollectionEnabled(bool enabled)` API.
## 2.3.1
* Fix banner/MREC widget ad issue on Android. (https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/32)
## 2.3.0
* Depends on Android SDK v11.5.5 and iOS SDK v11.5.5.
* Add support for App Open ads.
* Add support for passing additional data.
## 2.2.0
* Depends on Android SDK v11.5.3 and iOS SDK v11.5.3.
* Add support for ad revenue callbacks.
## 2.1.0
* Depends on Android SDK v11.5.2 and iOS SDK v11.5.1.
* Add API to enable or disable the Creative Debugger `AppLovinMAX.setCreativeDebuggerEnabled(...)`.
* Add API documentation.
* Fix warnings from `flutter analyze`.
## 2.0.0
* Add support for rendering banners [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/banners#widget-method) and MRECs [docs](https://dash.applovin.com/documentation/mediation/flutter/getting-started/mrecs#widget-method) as widgets.
## 1.0.8
* Fix impression counting for fullscreen ads on iOS. Fixes https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/19.
## 1.0.7
* Depends on Android SDK v11.4.4 and iOS SDK v11.4.3.
## 1.0.6
* Add `s.static_framework = true` in `applovin_max.podspec`. Fixes https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/10.
## 1.0.5
* Fix linter warnings.
* Fix `OnRewardedAdReceivedRewardEvent()` callback not being called on Android. Fixes https://github.com/AppLovin/AppLovin-MAX-Flutter/issues/14.
## 1.0.4
* Add support for `AppLovinMAX.isInitialized()` API.
* Add support for getting DSP name if the ad is served by AppLovin Exchange via `ad.dspName`.
## 1.0.3
* Use `api` for Android AppLovin MAX SDK dependency.
* Depends on Android SDK v11.4.3.
## 1.0.2
* Fix `RewardededAdListener` typo to be `RewardedAdListener`.
## 1.0.1
* Fix README.
## 1.0.0
* Initial implementation for interstitials, rewarded videos, and programmatic banners & MRECs.
