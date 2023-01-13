## Versions

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
