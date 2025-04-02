import 'dart:math';

import 'package:applovin_flutter/utils.dart';
import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

enum RewardedAdLoadState { notLoaded, loading, loaded }

class RewardedAd extends StatefulWidget {
  final String adUnitId;
  final bool isInitialized;
  final void Function(String) log;

  const RewardedAd({
    super.key,
    required this.adUnitId,
    required this.isInitialized,
    required this.log,
  });

  @override
  State<RewardedAd> createState() => _RewardedAdState();
}

class _RewardedAdState extends State<RewardedAd> {
  static const int _maxRetryCount = 6;

  RewardedAdLoadState _loadState = RewardedAdLoadState.notLoaded;
  int _retryAttempt = 0;

  @override
  void initState() {
    super.initState();

    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
      onAdLoadedCallback: (ad) {
        setState(() => _loadState = RewardedAdLoadState.loaded);
        _retryAttempt = 0;
        widget.log('Rewarded ad loaded from ${ad.networkName}');
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        setState(() => _loadState = RewardedAdLoadState.notLoaded);

        // Increment the retry attempt counter
        _retryAttempt++;

        // If retry attempts exceed the max allowed, stop trying and log the error
        if (_retryAttempt > _maxRetryCount) {
          widget.log('Rewarded ad failed to load with code ${error.code}');
          return;
        }

        // Calculate the retry delay using exponential backoff
        final retryDelay = pow(2, min(_maxRetryCount, _retryAttempt)).toInt();
        widget.log('Rewarded ad failed to load with code ${error.code} - retrying in ${retryDelay}s');

        // Retry after a delay by setting the state to loading and attempting to load again
        Future.delayed(Duration(seconds: retryDelay), () {
          setState(() => _loadState = RewardedAdLoadState.loading);
          widget.log('Rewarded ad retrying to load...');
          AppLovinMAX.loadRewardedAd(widget.adUnitId);
        });
      },
      onAdDisplayedCallback: (ad) => widget.log('Rewarded ad displayed'),
      onAdDisplayFailedCallback: (ad, error) {
        setState(() => _loadState = RewardedAdLoadState.notLoaded);
        widget.log('Rewarded ad failed to display with code ${error.code} and message ${error.message}');
      },
      onAdClickedCallback: (ad) => widget.log('Rewarded ad clicked'),
      onAdHiddenCallback: (ad) {
        setState(() => _loadState = RewardedAdLoadState.notLoaded);
        widget.log('Rewarded ad hidden');
      },
      onAdReceivedRewardCallback: (ad, reward) => widget.log('Rewarded ad granted reward'),
      onAdRevenuePaidCallback: (ad) => widget.log('Rewarded ad revenue paid: ${ad.revenue}'),
    ));
  }

  String get _buttonText {
    if (_loadState == RewardedAdLoadState.notLoaded) {
      return 'Load Rewarded Ad';
    } else if (_loadState == RewardedAdLoadState.loading) {
      return 'Loading...';
    } else {
      return 'Show Rewarded Ad';
    }
  }

  void _createAndShowRewardedAd() async {
    final isReady = await AppLovinMAX.isRewardedAdReady(widget.adUnitId) ?? false;
    if (isReady) {
      AppLovinMAX.showRewardedAd(widget.adUnitId);
    } else {
      widget.log('Loading rewarded ad...');
      setState(() => _loadState = RewardedAdLoadState.loading);
      AppLovinMAX.loadRewardedAd(widget.adUnitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: _buttonText,
      onPressed: widget.isInitialized && _loadState != RewardedAdLoadState.loading ? _createAndShowRewardedAd : null,
    );
  }
}
