import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

enum AdLoadState { notLoaded, loading, loaded }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

// Create constants
final String _sdk_key = "YOUR_SDK_KEY";

final String _interstitial_ad_unit_id = Platform.isAndroid ? "ANDROID_INTER_AD_UNIT_ID" : "IOS_INTER_AD_UNIT_ID";
final String _rewarded_ad_unit_id = Platform.isAndroid ? "ANDROID_REWARDED_AD_UNIT_ID" : "IOS_REWARDED_AD_UNIT_ID";
final String _banner_ad_unit_id = Platform.isAndroid ? "ANDROID_BANNER_AD_UNIT_ID" : "IOS_BANNER_AD_UNIT_ID";
final String _mrec_ad_unit_id = Platform.isAndroid ? "ANDROID_MREC_AD_UNIT_ID" : "IOS_MREC_AD_UNIT_ID";

// Create states
var _isInitialized = false;
var _interstitialLoadState = AdLoadState.notLoaded;
var _interstitialRetryAttempt = 0;
var _rewardedAdLoadState = AdLoadState.notLoaded;
var _rewardedAdRetryAttempt = 0;
var _isProgrammaticBannerCreated = false;
var _isProgrammaticBannerShowing = false;
var _isWidgetBannerShowing = false;
var _isProgrammaticMRecCreated = false;
var _isProgrammaticMRecShowing = false;
var _isWidgetMRecShowing = false;

var _statusText = "";

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initializePlugin();
  }

  // NOTE: Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initializePlugin() async {
    logStatus("Initializing SDK...");

    Map? configuration = await AppLovinMAX.initialize(_sdk_key);
    if (configuration != null) {
      _isInitialized = true;

      logStatus("SDK Initialized: $configuration");

      attachAdListeners();
    }
  }

  void attachAdListeners() {
    /// Interstitial Ad Listeners
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) {
        _interstitialLoadState = AdLoadState.loaded;

        // Interstitial ad is ready to be shown. AppLovinMAX.isInterstitialAdReady(_interstitial_ad_unit_id) will now return 'true'
        logStatus('Interstitial ad loaded from ' + ad.networkName);

        // Reset retry attempt
        _interstitialRetryAttempt = 0;
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        _interstitialLoadState = AdLoadState.notLoaded;

        // Interstitial ad failed to load
        // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
        _interstitialRetryAttempt = _interstitialRetryAttempt + 1;

        int retryDelay = pow(2, min(6, _interstitialRetryAttempt)).toInt();
        logStatus('Interstitial ad failed to load with code ' + error.code.toString() + ' - retrying in ' + retryDelay.toString() + 's');

        Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
          AppLovinMAX.loadInterstitial(_interstitial_ad_unit_id);
        });
      },
      onAdDisplayedCallback: (ad) {
        logStatus('Interstitial ad displayed');
      },
      onAdDisplayFailedCallback: (ad, error) {
        _interstitialLoadState = AdLoadState.notLoaded;
        logStatus('Interstitial ad failed to display with code ' + error.code.toString() + ' and message ' + error.message);
      },
      onAdClickedCallback: (ad) {
        logStatus('Interstitial ad clicked');
      },
      onAdHiddenCallback: (ad) {
        _interstitialLoadState = AdLoadState.notLoaded;
        logStatus('Interstitial ad hidden');
      },
    ));

    /// Rewarded Ad Listeners
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(onAdLoadedCallback: (ad) {
      _rewardedAdLoadState = AdLoadState.loaded;

      // Rewarded ad is ready to be shown. AppLovinMAX.isRewardedAdReady(_rewarded_ad_unit_id) will now return 'true'
      logStatus('Rewarded ad loaded from ' + ad.networkName);

      // Reset retry attempt
      _rewardedAdRetryAttempt = 0;
    }, onAdLoadFailedCallback: (adUnitId, error) {
      _rewardedAdLoadState = AdLoadState.notLoaded;

      // Rewarded ad failed to load
      // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
      _rewardedAdRetryAttempt = _rewardedAdRetryAttempt + 1;

      int retryDelay = pow(2, min(6, _rewardedAdRetryAttempt)).toInt();
      logStatus('Rewarded ad failed to load with code ' + error.code.toString() + ' - retrying in ' + retryDelay.toString() + 's');

      Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
        AppLovinMAX.loadRewardedAd(_rewarded_ad_unit_id);
      });
    }, onAdDisplayedCallback: (ad) {
      logStatus('Rewarded ad displayed');
    }, onAdDisplayFailedCallback: (ad, error) {
      _rewardedAdLoadState = AdLoadState.notLoaded;
      logStatus('Rewarded ad failed to display with code ' + error.code.toString() + ' and message ' + error.message);
    }, onAdClickedCallback: (ad) {
      logStatus('Rewarded ad clicked');
    }, onAdHiddenCallback: (ad) {
      _rewardedAdLoadState = AdLoadState.notLoaded;
      logStatus('Rewarded ad hidden');
    }, onAdReceivedRewardCallback: (ad, reward) {
      logStatus('Rewarded ad granted reward');
    }));

    /// Banner Ad Listeners
    AppLovinMAX.setBannerListener(AdViewAdListener(onAdLoadedCallback: (ad) {
      logStatus('Banner ad loaded from ' + ad.networkName);
    }, onAdLoadFailedCallback: (adUnitId, error) {
      logStatus('Banner ad failed to load with error code ' + error.code.toString() + ' and message: ' + error.message);
    }, onAdClickedCallback: (ad) {
      logStatus('Banner ad clicked');
    }, onAdExpandedCallback: (ad) {
      logStatus('Banner ad expanded');
    }, onAdCollapsedCallback: (ad) {
      logStatus('Banner ad collapsed');
    }));

    /// MREC Ad Listeners
    AppLovinMAX.setMRecListener(AdViewAdListener(onAdLoadedCallback: (ad) {
      logStatus('MREC ad loaded from ' + ad.networkName);
    }, onAdLoadFailedCallback: (adUnitId, error) {
      logStatus('MREC ad failed to load with error code ' + error.code.toString() + ' and message: ' + error.message);
    }, onAdClickedCallback: (ad) {
      logStatus('MREC ad clicked');
    }, onAdExpandedCallback: (ad) {
      logStatus('MREC ad expanded');
    }, onAdCollapsedCallback: (ad) {
      logStatus('MREC ad collapsed');
    }));
  }

  String getInterstitialButtonTitle() {
    if (_interstitialLoadState == AdLoadState.notLoaded) {
      return "Load Interstitial";
    } else if (_interstitialLoadState == AdLoadState.loading) {
      return "Loading...";
    } else {
      return "Show Interstitial"; // adLoadState.loaded
    }
  }

  String getRewardedButtonTitle() {
    if (_rewardedAdLoadState == AdLoadState.notLoaded) {
      return "Load Rewarded Ad";
    } else if (_rewardedAdLoadState == AdLoadState.loading) {
      return "Loading...";
    } else {
      return "Show Rewarded Ad"; // adLoadState.loaded
    }
  }

  String getProgrammaticBannerButtonTitle() {
    return _isProgrammaticBannerShowing ? 'Hide Programmatic Banner' : 'Show Programmatic Banner';
  }

  String getWidgetBannerButtonTitle() {
    return _isWidgetBannerShowing ? 'Hide Widget Banner' : 'Show Widget Banner';
  }

  String getProgrammaticMRecButtonTitle() {
    return _isProgrammaticMRecShowing ? 'Hide Programmatic MREC' : 'Show Programmatic MREC';
  }

  String getWidgetMRecButtonTitle() {
    return _isWidgetMRecShowing ? 'Hide Widget MREC' : 'Show Widget MREC';
  }

  void logStatus(String status) {
    print(status);

    setState(() {
      _statusText = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text("AppLovin MAX Demo"),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Text(
                '$_statusText\n',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: _isInitialized
                    ? () {
                        AppLovinMAX.showMediationDebugger();
                      }
                    : null,
                child: Text("Mediation Debugger"),
              ),
              ElevatedButton(
                onPressed: (_isInitialized && _interstitialLoadState != AdLoadState.loading)
                    ? () async {
                        bool isReady = (await AppLovinMAX.isInterstitialReady(_interstitial_ad_unit_id))!;
                        if (isReady) {
                          AppLovinMAX.showInterstitial(_interstitial_ad_unit_id);
                        } else {
                          logStatus('Loading interstitial ad...');
                          _interstitialLoadState = AdLoadState.loading;
                          AppLovinMAX.loadInterstitial(_interstitial_ad_unit_id);
                        }
                      }
                    : null,
                child: Text(getInterstitialButtonTitle()),
              ),
              ElevatedButton(
                onPressed: (_isInitialized && _rewardedAdLoadState != AdLoadState.loading)
                    ? () async {
                        bool isReady = (await AppLovinMAX.isRewardedAdReady(_rewarded_ad_unit_id))!;
                        if (isReady) {
                          AppLovinMAX.showRewardedAd(_rewarded_ad_unit_id);
                        } else {
                          logStatus('Loading rewarded ad...');
                          _rewardedAdLoadState = AdLoadState.loading;
                          AppLovinMAX.loadRewardedAd(_rewarded_ad_unit_id);
                        }
                      }
                    : null,
                child: Text(getRewardedButtonTitle()),
              ),
              ElevatedButton(
                onPressed: (_isInitialized && !_isWidgetBannerShowing)
                    ? () async {
                        if (_isProgrammaticBannerShowing) {
                          AppLovinMAX.hideBanner(_banner_ad_unit_id);
                        } else {
                          if (!_isProgrammaticBannerCreated) {
                            //
                            // Programmatic banner creation - banners are automatically sized to 320x50 on phones and 728x90 on tablets
                            //
                            AppLovinMAX.createBanner(_banner_ad_unit_id, AdViewPosition.bottomCenter);

                            // Set banner background color to black - PLEASE USE HEX STRINGS ONLY
                            AppLovinMAX.setBannerBackgroundColor(_banner_ad_unit_id, '#000000');

                            _isProgrammaticBannerCreated = true;
                          }

                          AppLovinMAX.showBanner(_banner_ad_unit_id);
                        }

                        setState(() {
                          _isProgrammaticBannerShowing = !_isProgrammaticBannerShowing;
                        });
                      }
                    : null,
                child: Text(getProgrammaticBannerButtonTitle()),
              ),
              ElevatedButton(
                onPressed: (_isInitialized && !_isProgrammaticBannerShowing)
                    ? () async {
                        setState(() {
                          _isWidgetBannerShowing = !_isWidgetBannerShowing;
                        });
                      }
                    : null,
                child: Text(getWidgetBannerButtonTitle()),
              ),
              ElevatedButton(
                onPressed: (_isInitialized && !_isWidgetMRecShowing)
                    ? () async {
                        if (_isProgrammaticMRecShowing) {
                          AppLovinMAX.hideMRec(_mrec_ad_unit_id);
                        } else {
                          if (!_isProgrammaticMRecCreated) {
                            AppLovinMAX.createMRec(_mrec_ad_unit_id, AdViewPosition.bottomCenter);

                            _isProgrammaticMRecCreated = true;
                          }

                          AppLovinMAX.showMRec(_mrec_ad_unit_id);
                        }

                        setState(() {
                          _isProgrammaticMRecShowing = !_isProgrammaticMRecShowing;
                        });
                      }
                    : null,
                child: Text(getProgrammaticMRecButtonTitle()),
              ),
              ElevatedButton(
                onPressed: (_isInitialized && !_isProgrammaticMRecShowing)
                    ? () async {
                        setState(() {
                          _isWidgetMRecShowing = !_isWidgetMRecShowing;
                        });
                      }
                    : null,
                child: Text(getWidgetMRecButtonTitle()),
              ),
              if (_isWidgetBannerShowing)
                MaxAdView(
                    adUnitId: _banner_ad_unit_id,
                    adFormat: AdFormat.banner,
                    listener: AdViewAdListener(onAdLoadedCallback: (ad) {
                      logStatus('Banner widget ad loaded from ' + ad.networkName);
                    }, onAdLoadFailedCallback: (adUnitId, error) {
                      logStatus('Banner widget ad failed to load with error code ' + error.code.toString() + ' and message: ' + error.message);
                    }, onAdClickedCallback: (ad) {
                      logStatus('Banner widget ad clicked');
                    }, onAdExpandedCallback: (ad) {
                      logStatus('Banner widget ad expanded');
                    }, onAdCollapsedCallback: (ad) {
                      logStatus('Banner widget ad collapsed');
                    })),
              if (_isWidgetMRecShowing)
                MaxAdView(
                    adUnitId: _mrec_ad_unit_id,
                    adFormat: AdFormat.mrec,
                    listener: AdViewAdListener(onAdLoadedCallback: (ad) {
                      logStatus('MREC widget ad loaded from ' + ad.networkName);
                    }, onAdLoadFailedCallback: (adUnitId, error) {
                      logStatus('MREC widget ad failed to load with error code ' + error.code.toString() + ' and message: ' + error.message);
                    }, onAdClickedCallback: (ad) {
                      logStatus('MREC widget ad clicked');
                    }, onAdExpandedCallback: (ad) {
                      logStatus('MREC widget ad expanded');
                    }, onAdCollapsedCallback: (ad) {
                      logStatus('MREC widget ad collapsed');
                    })),
            ],
          )),
    );
  }
}
