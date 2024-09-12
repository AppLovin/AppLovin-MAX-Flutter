import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

import 'native_ad.dart';
import 'scrolled_adview.dart';

enum AdLoadState { notLoaded, loading, loaded }

void main() {
  runApp(MaterialApp(
    title: 'AppLovin MAX Demo',
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.system,
    home: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

// Create constants
const String _sdkKey = 'YOUR_SDK_KEY';

final String _interstitialAdUnitId = Platform.isAndroid ? 'ANDROID_INTER_AD_UNIT_ID' : 'IOS_INTER_AD_UNIT_ID';
final String _rewardedAdUnitId = Platform.isAndroid ? 'ANDROID_REWARDED_AD_UNIT_ID' : 'IOS_REWARDED_AD_UNIT_ID';
final String _bannerAdUnitId = Platform.isAndroid ? 'ANDROID_BANNER_AD_UNIT_ID' : 'IOS_BANNER_AD_UNIT_ID';
final String _mrecAdUnitId = Platform.isAndroid ? 'ANDROID_MREC_AD_UNIT_ID' : 'IOS_MREC_AD_UNIT_ID';
final String _nativeAdUnitId = Platform.isAndroid ? 'ANDROID_NATIVE_AD_UNIT_ID' : 'IOS_NATIVE_AD_UNIT_ID';

const int _maxExponentialRetryCount = 6;

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

var _statusText = '';

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initializePlugin();
  }

  // NOTE: Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initializePlugin() async {
    logStatus('Initializing SDK...');

    // MAX Consent Flow - https://developers.applovin.com/en/flutter/overview/terms-and-privacy-policy-flow
    AppLovinMAX.setTermsAndPrivacyPolicyFlowEnabled(true);
    AppLovinMAX.setPrivacyPolicyUrl('https://your_company_name.com/privacy');
    AppLovinMAX.setTermsOfServiceUrl('https://your_company_name.com/terms');

    MaxConfiguration? configuration = await AppLovinMAX.initialize(_sdkKey);
    if (configuration != null) {
      _isInitialized = true;

      logStatus('SDK Initialized in ${configuration.countryCode}');

      attachAdListeners();

      // If you need to preload banners/MRECs ahead of time such that the
      // contents are readily available when displayed.
      preloadAdViewAd();
    }
  }

  void attachAdListeners() {
    /// Interstitial Ad Listeners
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) {
        _interstitialLoadState = AdLoadState.loaded;

        // Interstitial ad is ready to be shown. AppLovinMAX.isInterstitialAdReady(_interstitial_ad_unit_id) will now return 'true'
        logStatus('Interstitial ad loaded from ${ad.networkName}');

        // Reset retry attempt
        _interstitialRetryAttempt = 0;
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        _interstitialLoadState = AdLoadState.notLoaded;

        if (error.code == ErrorCode.fullscreenAdAlreadyLoading) {
          logStatus('Interstitial ad failed: ad is already loading');
          return;
        } else if (error.code == ErrorCode.fullscreenAdLoadWhileShowing) {
          logStatus('Interstitial ad failed: ad is currently being shown for this ad unit');
          return;
        }

        // Interstitial ad failed to load
        // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
        _interstitialRetryAttempt = _interstitialRetryAttempt + 1;
        if (_interstitialRetryAttempt > _maxExponentialRetryCount) {
          logStatus('Interstitial ad failed to load with code ${error.code}');
          return;
        }

        int retryDelay = pow(2, min(_maxExponentialRetryCount, _interstitialRetryAttempt)).toInt();
        logStatus('Interstitial ad failed to load with code ${error.code} - retrying in ${retryDelay}s');

        Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
          _interstitialLoadState = AdLoadState.loading;
          logStatus('Interstitial ad retrying to load...');
          AppLovinMAX.loadInterstitial(_interstitialAdUnitId);
        });
      },
      onAdDisplayedCallback: (ad) {
        logStatus('Interstitial ad displayed');
      },
      onAdDisplayFailedCallback: (ad, error) {
        _interstitialLoadState = AdLoadState.notLoaded;
        logStatus('Interstitial ad failed to display with code ${error.code} and message ${error.message}');
      },
      onAdClickedCallback: (ad) {
        logStatus('Interstitial ad clicked');
      },
      onAdHiddenCallback: (ad) {
        _interstitialLoadState = AdLoadState.notLoaded;
        logStatus('Interstitial ad hidden');
      },
      onAdRevenuePaidCallback: (ad) {
        logStatus('Interstitial ad revenue paid: ${ad.revenue}');
      },
    ));

    /// Rewarded Ad Listeners
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(onAdLoadedCallback: (ad) {
      _rewardedAdLoadState = AdLoadState.loaded;

      // Rewarded ad is ready to be shown. AppLovinMAX.isRewardedAdReady(_rewarded_ad_unit_id) will now return 'true'
      logStatus('Rewarded ad loaded from ${ad.networkName}');

      // Reset retry attempt
      _rewardedAdRetryAttempt = 0;
    }, onAdLoadFailedCallback: (adUnitId, error) {
      _rewardedAdLoadState = AdLoadState.notLoaded;

      if (error.code == ErrorCode.fullscreenAdAlreadyLoading) {
        logStatus('Rewarded ad failed: ad is already loading');
        return;
      } else if (error.code == ErrorCode.fullscreenAdLoadWhileShowing) {
        logStatus('Rewarded ad failed: ad is currently being shown for this ad unit');
        return;
      }

      // Rewarded ad failed to load
      // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
      _rewardedAdRetryAttempt = _rewardedAdRetryAttempt + 1;
      if (_rewardedAdRetryAttempt > _maxExponentialRetryCount) {
        logStatus('Rewarded ad failed to load with code ${error.code}');
        return;
      }

      int retryDelay = pow(2, min(_maxExponentialRetryCount, _rewardedAdRetryAttempt)).toInt();
      logStatus('Rewarded ad failed to load with code ${error.code} - retrying in ${retryDelay}s');

      Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
        _rewardedAdLoadState = AdLoadState.loading;
        logStatus('Rewarded ad retrying to load...');
        AppLovinMAX.loadRewardedAd(_rewardedAdUnitId);
      });
    }, onAdDisplayedCallback: (ad) {
      logStatus('Rewarded ad displayed');
    }, onAdDisplayFailedCallback: (ad, error) {
      _rewardedAdLoadState = AdLoadState.notLoaded;
      logStatus('Rewarded ad failed to display with code ${error.code} and message ${error.message}');
    }, onAdClickedCallback: (ad) {
      logStatus('Rewarded ad clicked');
    }, onAdHiddenCallback: (ad) {
      _rewardedAdLoadState = AdLoadState.notLoaded;
      logStatus('Rewarded ad hidden');
    }, onAdReceivedRewardCallback: (ad, reward) {
      logStatus('Rewarded ad granted reward');
    }, onAdRevenuePaidCallback: (ad) {
      logStatus('Rewarded ad revenue paid: ${ad.revenue}');
    }));

    /// Banner Ad Listeners
    AppLovinMAX.setBannerListener(AdViewAdListener(onAdLoadedCallback: (ad) {
      logStatus('Banner ad loaded from ${ad.networkName}');
    }, onAdLoadFailedCallback: (adUnitId, error) {
      logStatus('Banner ad failed to load with error code ${error.code} and message: ${error.message}');
    }, onAdClickedCallback: (ad) {
      logStatus('Banner ad clicked');
    }, onAdExpandedCallback: (ad) {
      logStatus('Banner ad expanded');
    }, onAdCollapsedCallback: (ad) {
      logStatus('Banner ad collapsed');
    }, onAdRevenuePaidCallback: (ad) {
      logStatus('Banner ad revenue paid: ${ad.revenue}');
    }));

    /// MREC Ad Listeners
    AppLovinMAX.setMRecListener(AdViewAdListener(onAdLoadedCallback: (ad) {
      logStatus('MREC ad loaded from ${ad.networkName}');
    }, onAdLoadFailedCallback: (adUnitId, error) {
      logStatus('MREC ad failed to load with error code ${error.code} and message: ${error.message}');
    }, onAdClickedCallback: (ad) {
      logStatus('MREC ad clicked');
    }, onAdExpandedCallback: (ad) {
      logStatus('MREC ad expanded');
    }, onAdCollapsedCallback: (ad) {
      logStatus('MREC ad collapsed');
    }, onAdRevenuePaidCallback: (ad) {
      logStatus('MREC ad revenue paid: ${ad.revenue}');
    }));
  }

  // Preload banners/MRECs
  void preloadAdViewAd() {
    AppLovinMAX.setWidgetAdViewAdListener(WidgetAdViewAdListener(onAdLoadedCallback: (ad) {
      if (ad.adUnitId == _bannerAdUnitId) {
        print('Banner ad preloaded from ${ad.networkName}');
      } else if (ad.adUnitId == _mrecAdUnitId) {
        print('MREC ad preloaded from ${ad.networkName}');
      } else {
        print('Error: unexpected ad preloaded for ${ad.adUnitId}');
      }
    }, onAdLoadFailedCallback: (adUnitId, error) {
      if (adUnitId == _bannerAdUnitId) {
        print('Banner ad failed to preload with error code ${error.code} and message: ${error.message}');
      } else if (adUnitId == _mrecAdUnitId) {
        print('MREC ad failed to preload with error code ${error.code} and message: ${error.message}');
      } else {
        print('Error: unexpected ad failed to preload for $adUnitId');
      }
    }));

    AppLovinMAX.preloadWidgetAdView(_bannerAdUnitId, AdFormat.banner).then((_) {
      print('Started preloading a banner ad for $_bannerAdUnitId');
    }).catchError((e) {
      print('Error: failed to preload a banner ad for $_bannerAdUnitId: $e');
    });

    AppLovinMAX.preloadWidgetAdView(
      _mrecAdUnitId, AdFormat.mrec,
      // additional parameters
      placement: 'placement',
      customData: 'customData',
      extraParameters: {'key1': 'value1', 'key2': 'value2'},
      localExtraParameters: {'key1': 100, 'key2': 200},
    ).then((_) {
      print('Started preloading a MREC ad for $_mrecAdUnitId');
    }).catchError((e) {
      print('Error: failed to preload a MREC ad for $_mrecAdUnitId: $e');
    });
  }

  String getInterstitialButtonTitle() {
    if (_interstitialLoadState == AdLoadState.notLoaded) {
      return 'Load Interstitial';
    } else if (_interstitialLoadState == AdLoadState.loading) {
      return 'Loading...';
    } else {
      return 'Show Interstitial'; // adLoadState.loaded
    }
  }

  String getRewardedButtonTitle() {
    if (_rewardedAdLoadState == AdLoadState.notLoaded) {
      return 'Load Rewarded Ad';
    } else if (_rewardedAdLoadState == AdLoadState.loading) {
      return 'Loading...';
    } else {
      return 'Show Rewarded Ad'; // adLoadState.loaded
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
    // ignore_for_file: avoid_print
    print(status);

    setState(() {
      _statusText = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: true,
        title: Container(
          height: 42,
          alignment: Alignment.center,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              isDarkMode ? Colors.white : Colors.black, // Tint color for dark or light mode
              BlendMode.srcIn,
            ),
            child: Image.asset('assets/applovin_logo.png', fit: BoxFit.cover),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity, // Expands to the screen width
            padding: const EdgeInsets.all(10.0), // Padding inside the banner
            color: Colors.green, // Background color of the banner
            child: Text(
              _statusText,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 40, right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                AppButton(
                  onPressed: _isInitialized
                      ? () {
                          AppLovinMAX.showMediationDebugger();
                        }
                      : null,
                  text: 'Mediation Debugger',
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized && _interstitialLoadState != AdLoadState.loading)
                      ? () async {
                          bool isReady = (await AppLovinMAX.isInterstitialReady(_interstitialAdUnitId))!;
                          if (isReady) {
                            AppLovinMAX.showInterstitial(_interstitialAdUnitId);
                          } else {
                            logStatus('Loading interstitial ad...');
                            _interstitialLoadState = AdLoadState.loading;
                            AppLovinMAX.loadInterstitial(_interstitialAdUnitId);
                          }
                        }
                      : null,
                  text: getInterstitialButtonTitle(),
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized && _rewardedAdLoadState != AdLoadState.loading)
                      ? () async {
                          bool isReady = (await AppLovinMAX.isRewardedAdReady(_rewardedAdUnitId))!;
                          if (isReady) {
                            AppLovinMAX.showRewardedAd(_rewardedAdUnitId);
                          } else {
                            logStatus('Loading rewarded ad...');
                            _rewardedAdLoadState = AdLoadState.loading;
                            AppLovinMAX.loadRewardedAd(_rewardedAdUnitId);
                          }
                        }
                      : null,
                  text: getRewardedButtonTitle(),
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized && !_isWidgetBannerShowing)
                      ? () async {
                          if (_isProgrammaticBannerShowing) {
                            AppLovinMAX.hideBanner(_bannerAdUnitId);
                          } else {
                            if (!_isProgrammaticBannerCreated) {
                              //
                              // Programmatic banner creation - banners are automatically sized to 320x50 on phones and 728x90 on tablets
                              //
                              AppLovinMAX.createBanner(_bannerAdUnitId, AdViewPosition.bottomCenter);

                              // Set banner background color to black - PLEASE USE HEX STRINGS ONLY
                              AppLovinMAX.setBannerBackgroundColor(_bannerAdUnitId, '#000000');

                              _isProgrammaticBannerCreated = true;
                            }

                            AppLovinMAX.showBanner(_bannerAdUnitId);
                          }

                          setState(() {
                            _isProgrammaticBannerShowing = !_isProgrammaticBannerShowing;
                          });
                        }
                      : null,
                  text: getProgrammaticBannerButtonTitle(),
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized && !_isProgrammaticBannerShowing)
                      ? () async {
                          setState(() {
                            _isWidgetBannerShowing = !_isWidgetBannerShowing;
                          });
                        }
                      : null,
                  text: getWidgetBannerButtonTitle(),
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized && !_isWidgetMRecShowing)
                      ? () async {
                          if (_isProgrammaticMRecShowing) {
                            AppLovinMAX.hideMRec(_mrecAdUnitId);
                          } else {
                            if (!_isProgrammaticMRecCreated) {
                              AppLovinMAX.createMRec(_mrecAdUnitId, AdViewPosition.bottomCenter);

                              _isProgrammaticMRecCreated = true;
                            }

                            AppLovinMAX.showMRec(_mrecAdUnitId);
                          }

                          setState(() {
                            _isProgrammaticMRecShowing = !_isProgrammaticMRecShowing;
                          });
                        }
                      : null,
                  text: getProgrammaticMRecButtonTitle(),
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized && !_isProgrammaticMRecShowing)
                      ? () async {
                          setState(() {
                            _isWidgetMRecShowing = !_isWidgetMRecShowing;
                          });
                        }
                      : null,
                  text: getWidgetMRecButtonTitle(),
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized)
                      ? () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NativeAdView(adUnitId: _nativeAdUnitId)),
                          );
                        }
                      : null,
                  text: 'Show Native Ad',
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: (_isInitialized)
                      ? () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ScrolledAdView(
                                      bannerAdUnitId: _bannerAdUnitId,
                                      mrecAdUnitId: _mrecAdUnitId,
                                    )),
                          );
                        }
                      : null,
                  text: 'Show Scrolled Banner/MREC',
                ),
                if (_isWidgetBannerShowing)
                  MaxAdView(
                      adUnitId: _bannerAdUnitId,
                      adFormat: AdFormat.banner,
                      listener: AdViewAdListener(onAdLoadedCallback: (ad) {
                        logStatus('Banner widget ad loaded from ${ad.networkName}');
                      }, onAdLoadFailedCallback: (adUnitId, error) {
                        logStatus('Banner widget ad failed to load with error code ${error.code} and message: ${error.message}');
                      }, onAdClickedCallback: (ad) {
                        logStatus('Banner widget ad clicked');
                      }, onAdExpandedCallback: (ad) {
                        logStatus('Banner widget ad expanded');
                      }, onAdCollapsedCallback: (ad) {
                        logStatus('Banner widget ad collapsed');
                      }, onAdRevenuePaidCallback: (ad) {
                        logStatus('Banner widget ad revenue paid: ${ad.revenue}');
                      })),
                if (_isWidgetMRecShowing)
                  MaxAdView(
                      adUnitId: _mrecAdUnitId,
                      adFormat: AdFormat.mrec,
                      listener: AdViewAdListener(onAdLoadedCallback: (ad) {
                        logStatus('MREC widget ad loaded from ${ad.networkName}');
                      }, onAdLoadFailedCallback: (adUnitId, error) {
                        logStatus('MREC widget ad failed to load with error code ${error.code} and message: ${error.message}');
                      }, onAdClickedCallback: (ad) {
                        logStatus('MREC widget ad clicked');
                      }, onAdExpandedCallback: (ad) {
                        logStatus('MREC widget ad expanded');
                      }, onAdCollapsedCallback: (ad) {
                        logStatus('MREC widget ad collapsed');
                      }, onAdRevenuePaidCallback: (ad) {
                        logStatus('MREC widget ad revenue paid: ${ad.revenue}');
                      })),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Nullable onPressed

  const AppButton({
    super.key,
    required this.text,
    this.onPressed, // Optional onPressed
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36, // Set button height
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Custom border radius
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18, // Set text font size to 18
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
