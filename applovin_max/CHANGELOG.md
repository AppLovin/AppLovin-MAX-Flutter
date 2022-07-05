## Versions

## x.x.x
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
