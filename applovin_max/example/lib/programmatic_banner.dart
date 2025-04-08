import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class ProgrammaticBanner extends StatefulWidget {
  final String adUnitId;
  final bool isInitialized;
  final bool isWidgetBannerShowing;
  final bool isShowing;
  final void Function(bool) setShowing;
  final void Function(String) log;

  const ProgrammaticBanner({
    super.key,
    required this.adUnitId,
    required this.isInitialized,
    required this.isWidgetBannerShowing,
    required this.isShowing,
    required this.setShowing,
    required this.log,
  });

  @override
  State<ProgrammaticBanner> createState() => _ProgrammaticBannerState();
}

class _ProgrammaticBannerState extends State<ProgrammaticBanner> {
  bool _isCreated = false;

  @override
  void initState() {
    super.initState();

    AppLovinMAX.setBannerListener(AdViewAdListener(
      onAdLoadedCallback: (ad) => widget.log('Banner ad loaded from ${ad.networkName}'),
      onAdLoadFailedCallback: (adUnitId, error) => widget.log('Banner ad failed to load with error code ${error.code} and message: ${error.message}'),
      onAdClickedCallback: (ad) => widget.log('Banner ad clicked'),
      onAdExpandedCallback: (ad) => widget.log('Banner ad expanded'),
      onAdCollapsedCallback: (ad) => widget.log('Banner ad collapsed'),
      onAdRevenuePaidCallback: (ad) => widget.log('Banner ad revenue paid: ${ad.revenue}'),
    ));
  }

  void _createAndToggleBannerAd() {
    if (widget.isShowing) {
      AppLovinMAX.hideBanner(widget.adUnitId);
    } else {
      if (!_isCreated) {
        AppLovinMAX.createBanner(widget.adUnitId, AdViewPosition.bottomCenter);
        AppLovinMAX.setBannerBackgroundColor(widget.adUnitId, '#000000');
        _isCreated = true;
      }
      AppLovinMAX.showBanner(widget.adUnitId);
    }
    widget.setShowing(!widget.isShowing);
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: widget.isShowing ? 'Hide Programmatic Banner' : 'Show Programmatic Banner',
      onPressed: widget.isInitialized && !widget.isWidgetBannerShowing ? _createAndToggleBannerAd : null,
    );
  }
}
