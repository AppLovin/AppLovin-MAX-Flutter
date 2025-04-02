import 'dart:math';

import 'package:applovin_flutter/utils.dart';
import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

enum InterstitialAdLoadState { notLoaded, loading, loaded }

class InterstitialAd extends StatefulWidget {
  final String adUnitId;
  final bool isInitialized;
  final void Function(String) log;

  const InterstitialAd({
    super.key,
    required this.adUnitId,
    required this.isInitialized,
    required this.log,
  });

  @override
  State<InterstitialAd> createState() => _InterstitialAdState();
}

class _InterstitialAdState extends State<InterstitialAd> {
  static const int _maxRetryCount = 6;

  InterstitialAdLoadState _loadState = InterstitialAdLoadState.notLoaded;
  int _retryAttempt = 0;

  @override
  void initState() {
    super.initState();

    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) {
        setState(() => _loadState = InterstitialAdLoadState.loaded);
        _retryAttempt = 0;
        widget.log('Interstitial ad loaded from ${ad.networkName}');
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        setState(() => _loadState = InterstitialAdLoadState.notLoaded);

        // Increment the retry attempt counter
        _retryAttempt++;

        // If retry attempts exceed the max allowed, stop trying and log the error
        if (_retryAttempt > _maxRetryCount) {
          widget.log('Interstitial ad failed to load with code ${error.code}');
          return;
        }

        // Calculate the retry delay using exponential backoff
        final retryDelay = pow(2, min(_maxRetryCount, _retryAttempt)).toInt();
        widget.log('Interstitial ad failed to load with code ${error.code} - retrying in ${retryDelay}s');

        // Retry after a delay by setting the state to loading and attempting to load again
        Future.delayed(Duration(seconds: retryDelay), () {
          setState(() => _loadState = InterstitialAdLoadState.loading);
          widget.log('Interstitial ad retrying to load...');
          AppLovinMAX.loadInterstitial(widget.adUnitId);
        });
      },
      onAdDisplayedCallback: (ad) => widget.log('Interstitial ad displayed'),
      onAdDisplayFailedCallback: (ad, error) {
        setState(() => _loadState = InterstitialAdLoadState.notLoaded);
        widget.log('Interstitial ad failed to display with code ${error.code} and message ${error.message}');
      },
      onAdClickedCallback: (ad) => widget.log('Interstitial ad clicked'),
      onAdHiddenCallback: (ad) {
        setState(() => _loadState = InterstitialAdLoadState.notLoaded);
        widget.log('Interstitial ad hidden');
      },
      onAdRevenuePaidCallback: (ad) => widget.log('Interstitial ad revenue paid: ${ad.revenue}'),
    ));
  }

  String get _buttonText {
    if (_loadState == InterstitialAdLoadState.notLoaded) {
      return 'Load Interstitial Ad';
    } else if (_loadState == InterstitialAdLoadState.loading) {
      return 'Loading...';
    } else {
      return 'Show Interstitial Ad';
    }
  }

  void _createAndShowInterstitialAd() async {
    final isReady = await AppLovinMAX.isInterstitialReady(widget.adUnitId) ?? false;
    if (isReady) {
      AppLovinMAX.showInterstitial(widget.adUnitId);
    } else {
      widget.log('Loading interstitial ad...');
      setState(() => _loadState = InterstitialAdLoadState.loading);
      AppLovinMAX.loadInterstitial(widget.adUnitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: _buttonText,
      onPressed: widget.isInitialized && _loadState != InterstitialAdLoadState.loading ? _createAndShowInterstitialAd : null,
    );
  }
}
