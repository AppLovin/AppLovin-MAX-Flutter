import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class NativeAdView extends StatefulWidget {
  const NativeAdView({
    super.key,
    required this.adUnitId,
  });

  final String adUnitId;

  @override
  State createState() => _NativeAdViewState();
}

class _NativeAdViewState extends State<NativeAdView> {
  static const double _kMediaViewAspectRatio = 16 / 9;

  final MaxNativeAdViewController _nativeAdViewController = MaxNativeAdViewController();

  String _statusText = '';
  double _mediaViewAspectRatio = _kMediaViewAspectRatio;

  void _logStatus(String status) {
    /// ignore: avoid_print
    print(status);
    setState(() => _statusText = '$_statusText\n$status');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Native Ad'),
        ),
        body: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ScrolledStatusBar(statusText: _statusText),
          Container(
            margin: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            height: 300,
            child: _buildNativeAd(),
          ),
          AppButton(
            onPressed: () => _nativeAdViewController.loadAd(),
            text: 'Reload',
          ),
        ])));
  }

  // Render MaxNativeAdView within a container
  Widget _buildNativeAd() {
    return MaxNativeAdView(
      adUnitId: widget.adUnitId,
      controller: _nativeAdViewController,
      listener: NativeAdListener(
        onAdLoadedCallback: (ad) {
          _logStatus('Native ad loaded from ${ad.networkName}');
          // Dynamically update the MediaView aspect ratio based on the loaded ad
          setState(() {
            _mediaViewAspectRatio = ad.nativeAd?.mediaContentAspectRatio ?? _kMediaViewAspectRatio;
          });
        },
        onAdLoadFailedCallback: (adUnitId, error) => _logStatus('Native ad failed to load with error code ${error.code} and message: ${error.message}'),
        onAdClickedCallback: (ad) => _logStatus('Native ad clicked'),
        onAdRevenuePaidCallback: (ad) => _logStatus('Native ad revenue paid: ${ad.revenue}'),
      ),
      child: _buildAssetViews(),
    );
  }

  // Layout the asset views inside MaxNativeAdView
  Widget _buildAssetViews() {
    return Container(
      color: const Color(0xffefefef),
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          const Row(
            children: [
              MaxNativeAdIconView(
                width: 48,
                height: 48,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MaxNativeAdTitleView(
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                    MaxNativeAdAdvertiserView(
                      style: TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    MaxNativeAdStarRatingView(),
                  ],
                ),
              ),
              MaxNativeAdOptionsView(
                width: 20,
                height: 20,
              ),
            ],
          ),
          const MaxNativeAdBodyView(
            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: _mediaViewAspectRatio,
              child: const MaxNativeAdMediaView(),
            ),
          ),
          const SizedBox(
            width: double.infinity,
            child: MaxNativeAdCallToActionView(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
