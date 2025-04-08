import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class ProgrammaticMRec extends StatefulWidget {
  final String adUnitId;
  final bool isInitialized;
  final bool isWidgetMRecShowing;
  final bool isShowing;
  final void Function(bool) setShowing;
  final void Function(String) log;

  const ProgrammaticMRec({
    super.key,
    required this.adUnitId,
    required this.isInitialized,
    required this.isWidgetMRecShowing,
    required this.isShowing,
    required this.setShowing,
    required this.log,
  });

  @override
  State<ProgrammaticMRec> createState() => _ProgrammaticMRecState();
}

class _ProgrammaticMRecState extends State<ProgrammaticMRec> {
  bool _isCreated = false;

  @override
  void initState() {
    super.initState();

    AppLovinMAX.setMRecListener(AdViewAdListener(
      onAdLoadedCallback: (ad) => widget.log('MREC ad loaded from ${ad.networkName}'),
      onAdLoadFailedCallback: (adUnitId, error) => widget.log('MREC ad failed to load with error code ${error.code} and message: ${error.message}'),
      onAdClickedCallback: (ad) => widget.log('MREC ad clicked'),
      onAdExpandedCallback: (ad) => widget.log('MREC ad expanded'),
      onAdCollapsedCallback: (ad) => widget.log('MREC ad collapsed'),
      onAdRevenuePaidCallback: (ad) => widget.log('MREC ad revenue paid: ${ad.revenue}'),
    ));
  }

  void _createAndToggleMRecAd() {
    if (widget.isShowing) {
      AppLovinMAX.hideMRec(widget.adUnitId);
    } else {
      if (!_isCreated) {
        AppLovinMAX.createMRec(widget.adUnitId, AdViewPosition.bottomCenter);
        _isCreated = true;
      }
      AppLovinMAX.showMRec(widget.adUnitId);
    }
    widget.setShowing(!widget.isShowing);
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: widget.isShowing ? 'Hide Programmatic MREC' : 'Show Programmatic MREC',
      onPressed: widget.isInitialized && !widget.isWidgetMRecShowing ? _createAndToggleMRecAd : null,
    );
  }
}
