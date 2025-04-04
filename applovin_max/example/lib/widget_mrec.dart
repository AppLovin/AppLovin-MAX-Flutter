import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

class WidgetMRecAdView extends StatelessWidget {
  final String adUnitId;
  final AdViewId? adViewId;
  final bool isShowing;
  final void Function(String) log;

  const WidgetMRecAdView({
    super.key,
    required this.adUnitId,
    required this.adViewId,
    required this.isShowing,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    if (!isShowing) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: MaxAdView(
        adUnitId: adUnitId,
        adFormat: AdFormat.mrec,
        adViewId: adViewId,
        listener: AdViewAdListener(
          onAdLoadedCallback: (ad) => log('MREC widget ad (${ad.adViewId}) loaded from ${ad.networkName}'),
          onAdLoadFailedCallback: (adUnitId, error) =>
              log('MREC widget ad (${error.adViewId}) failed to load with error code ${error.code} and message: ${error.message}'),
          onAdClickedCallback: (ad) => log('MREC widget ad (${ad.adViewId}) clicked'),
          onAdExpandedCallback: (ad) => log('MREC widget ad (${ad.adViewId}) expanded'),
          onAdCollapsedCallback: (ad) => log('MREC widget ad (${ad.adViewId}) collapsed'),
          onAdRevenuePaidCallback: (ad) => log('MREC widget ad (${ad.adViewId}) revenue paid: ${ad.revenue}'),
        ),
      ),
    );
  }
}
