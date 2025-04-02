import 'dart:async';
import 'dart:io' show Platform;

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

import 'interstitial_ad.dart';
import 'native_ad.dart';
import 'programmatic_banner.dart';
import 'programmatic_mrec.dart';
import 'rewarded_ad.dart';
import 'scrolled_adview.dart';
import 'utils.dart';
import 'widget_banner.dart';
import 'widget_mrec.dart';

void main() {
  runApp(const MaterialApp(
    title: 'AppLovin MAX Demo',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // AppLovin MAX configuration
  final String _sdkKey = 'YOUR_SDK_KEY';
  final String _interstitialAdUnitId = Platform.isAndroid ? 'ANDROID_INTER_AD_UNIT_ID' : 'IOS_INTER_AD_UNIT_ID';
  final String _rewardedAdUnitId = Platform.isAndroid ? 'ANDROID_REWARDED_AD_UNIT_ID' : 'IOS_REWARDED_AD_UNIT_ID';
  final String _bannerAdUnitId = Platform.isAndroid ? 'ANDROID_BANNER_AD_UNIT_ID' : 'IOS_BANNER_AD_UNIT_ID';
  final String _mrecAdUnitId = Platform.isAndroid ? 'ANDROID_MREC_AD_UNIT_ID' : 'IOS_MREC_AD_UNIT_ID';
  final String _nativeAdUnitId = Platform.isAndroid ? 'ANDROID_NATIVE_AD_UNIT_ID' : 'IOS_NATIVE_AD_UNIT_ID';

  // App state tracking
  bool _isInitialized = false;
  bool _isWidgetBannerShowing = false;
  bool _isWidgetMRecShowing = false;
  bool _isProgrammaticBannerShowing = false;
  bool _isProgrammaticMRecShowing = false;

  // Preloaded widget ad references
  AdViewId? _preloadedBannerId;
  AdViewId? _preloadedMRecId;
  AdViewId? _preloadedBanner2Id;
  AdViewId? _preloadedMRec2Id;

  String _statusText = '';

  @override
  void initState() {
    super.initState();
    initializePlugin();
  }

  Future<void> initializePlugin() async {
    logStatus('Initializing SDK...');

    AppLovinMAX.setTermsAndPrivacyPolicyFlowEnabled(true);
    AppLovinMAX.setPrivacyPolicyUrl('https://your_company_name.com/privacy');
    AppLovinMAX.setTermsOfServiceUrl('https://your_company_name.com/terms');

    MaxConfiguration? configuration = await AppLovinMAX.initialize(_sdkKey);
    if (configuration == null) {
      logStatus('SDK failed to initialize.');
    } else {
      setState(() => _isInitialized = true);
      logStatus('SDK Initialized in ${configuration.countryCode}');

      // Optionally preload widget-based banner and MREC ads. Comment out if preloading isn't needed.
      preloadAdViewAd();
    }
  }

  void preloadAdViewAd() async {
    AppLovinMAX.setWidgetAdViewAdListener(WidgetAdViewAdListener(
      onAdLoadedCallback: (ad) => logStatus('${ad.adFormat} ad (${ad.adViewId}) preloaded from ${ad.networkName}'),
      onAdLoadFailedCallback: (adUnitId, error) => logStatus('Failed to preload $adUnitId: ${error.message}'),
    ));

    _preloadedBannerId = await AppLovinMAX.preloadWidgetAdView(_bannerAdUnitId, AdFormat.banner);
    _preloadedMRecId = await AppLovinMAX.preloadWidgetAdView(_mrecAdUnitId, AdFormat.mrec);
    _preloadedBanner2Id = await AppLovinMAX.preloadWidgetAdView(_bannerAdUnitId, AdFormat.banner);
    _preloadedMRec2Id = await AppLovinMAX.preloadWidgetAdView(_mrecAdUnitId, AdFormat.mrec);
  }

  void logStatus(String status) {
    // ignore_for_file: avoid_print
    print(status);
    setState(() => _statusText = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: true,
        title: Container(
          height: 42,
          alignment: Alignment.center,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black,
              BlendMode.srcIn,
            ),
            child: Image.asset('assets/applovin_logo.png', fit: BoxFit.cover),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusBar(statusText: _statusText),
          AppButton(
            onPressed: _isInitialized ? () => AppLovinMAX.showMediationDebugger() : null,
            text: 'Mediation Debugger',
          ),
          InterstitialAd(
            adUnitId: _interstitialAdUnitId,
            log: logStatus,
            isInitialized: _isInitialized,
          ),
          RewardedAd(
            adUnitId: _rewardedAdUnitId,
            log: logStatus,
            isInitialized: _isInitialized,
          ),
          ProgrammaticBanner(
            adUnitId: _bannerAdUnitId,
            isInitialized: _isInitialized,
            isWidgetBannerShowing: _isWidgetBannerShowing,
            isShowing: _isProgrammaticBannerShowing,
            setShowing: (showing) => setState(() => _isProgrammaticBannerShowing = showing),
            log: logStatus,
          ),
          ProgrammaticMRec(
            adUnitId: _mrecAdUnitId,
            isInitialized: _isInitialized,
            isWidgetMRecShowing: _isWidgetMRecShowing,
            isShowing: _isProgrammaticMRecShowing,
            setShowing: (showing) => setState(() => _isProgrammaticMRecShowing = showing),
            log: logStatus,
          ),
          AppButton(
            text: (_isInitialized && _isWidgetBannerShowing) ? 'Hide Widget Banner' : 'Show Widget Banner',
            onPressed: (_isInitialized && !_isProgrammaticBannerShowing) ? () async => setState(() => _isWidgetBannerShowing = !_isWidgetBannerShowing) : null,
          ),
          AppButton(
            text: (_isInitialized && _isWidgetMRecShowing) ? 'Hide Widget MREC' : 'Show Widget MREC',
            onPressed: (_isInitialized && !_isProgrammaticMRecShowing) ? () async => setState(() => _isWidgetMRecShowing = !_isWidgetMRecShowing) : null,
          ),
          AppButton(
            onPressed: (_isInitialized)
                ? () async => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NativeAdView(adUnitId: _nativeAdUnitId)),
                    )
                : null,
            text: 'Show Native Ad',
          ),
          AppButton(
            onPressed: (_isInitialized)
                ? () async => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ScrolledAdView(
                              bannerAdUnitId: _bannerAdUnitId,
                              mrecAdUnitId: _mrecAdUnitId,
                              preloadedBannerId: _preloadedBannerId,
                              preloadedMRecId: _preloadedMRecId,
                              preloadedBanner2Id: _preloadedBanner2Id,
                              preloadedMRec2Id: _preloadedMRec2Id)),
                    )
                : null,
            text: 'Show Scrolled Banner/MREC',
          ),
          WidgetBannerAdView(
            adUnitId: _bannerAdUnitId,
            adViewId: _preloadedBannerId,
            isShowing: _isWidgetBannerShowing,
            log: logStatus,
          ),
          WidgetMRecAdView(
            adUnitId: _mrecAdUnitId,
            adViewId: _preloadedMRecId,
            isShowing: _isWidgetMRecShowing,
            log: logStatus,
          ),
        ],
      ),
    );
  }
}
