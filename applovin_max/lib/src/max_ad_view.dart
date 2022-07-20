import 'dart:ui' as ui;

import 'package:applovin_max/applovin_max.dart';
import 'package:applovin_max/src/ad_classes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum AdFormat {
  banner("banner"),
  mrec("mrec");

  final String value;

  const AdFormat(this.value);
}

class MaxAdView extends StatefulWidget {
  /// A string value representing the ad unit id to load ads for.
  final String adUnitId;

  /// A string value representing the ad format to load ads for. Should be either `AdFormat.banner` or `AdFormat.mrec`.
  final AdFormat adFormat;

  /// A string value representing the placement name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? placement;

  /// A string value representing the customData name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? customData;

  /// The listener for various ad callbacks.
  final AdViewAdListener? listener;

  const MaxAdView({
    Key? key,
    required this.adUnitId,
    required this.adFormat,
    this.placement,
    this.customData,
    this.listener,
  }) : super(key: key);

  @override
  _MaxAdViewState createState() => _MaxAdViewState();
}

class _MaxAdViewState extends State<MaxAdView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return SizedBox(
        width: _getWidth(),
        height: _getHeight(),
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          child: AndroidView(
            viewType: "applovin_max/adview",
            creationParams: <String, dynamic>{
              "ad_unit_id": widget.adUnitId,
              "ad_format": widget.adFormat.value,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onMaxAdViewCreated,
          ),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: _getWidth(),
        height: _getHeight(),
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          child: UiKitView(
            viewType: "applovin_max/adview",
            creationParams: <String, dynamic>{
              "ad_unit_id": widget.adUnitId,
              "ad_format": widget.adFormat.value,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onMaxAdViewCreated,
          ),
        ),
      );
    }

    return Container();
  }

  void _onMaxAdViewCreated(int id) {
    final MethodChannel channel = MethodChannel('applovin_max/adview_$id');

    channel.setMethodCallHandler((call) async {
      var method = call.method;
      var arguments = call.arguments;

      var adUnitId = arguments["adUnitId"];

      if ("OnAdViewAdLoadedEvent" == method) {
        widget.listener?.onAdLoadedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnAdViewAdLoadFailedEvent" == method) {
        var error = MaxError(arguments["errorCode"], arguments["errorMessage"]);
        widget.listener?.onAdLoadFailedCallback(adUnitId, error);
      } else if ("OnAdViewAdClickedEvent" == method) {
        widget.listener?.onAdClickedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnAdViewAdExpandedEvent" == method) {
        widget.listener?.onAdExpandedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnAdViewAdCollapsedEvent" == method) {
        widget.listener?.onAdCollapsedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      }
    });
  }

  double _getWidth() {
    if (widget.adFormat == AdFormat.mrec) {
      return 250;
    } else if (widget.adFormat == AdFormat.banner) {
      return _isTablet() ? 728 : 320;
    }

    return -1;
  }

  double _getHeight() {
    if (widget.adFormat == AdFormat.mrec) {
      return 300;
    } else if (widget.adFormat == AdFormat.banner) {
      return _isTablet() ? 90 : 50;
    }

    return -1;
  }

  bool _isTablet() {
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final ui.Size size = ui.window.physicalSize;
    final double width = size.width;
    final double height = size.height;

    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      return true;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      return true;
    } else {
      return false;
    }
  }
}
