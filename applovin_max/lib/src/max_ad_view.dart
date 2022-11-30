import 'dart:ui' as ui;

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Represents an ad format.
enum AdFormat {
  /// The banner ad.
  banner("banner"),
  /// The MREC ad.
  mrec("mrec");

  /// @nodoc
  final String value;

  /// @nodoc
  const AdFormat(this.value);
}

const double _bannerWidth = 320;
const double _bannerHeight = 50;
const double _leaderWidth = 728;
const double _leaderHeight = 90;
const double _mrecWidth = 300;
const double _mrecHeight = 250;

/// Represents an AdView ad (Banner / MREC).
class MaxAdView extends StatefulWidget {
  /// A string value representing the ad unit ID to load ads for.
  final String adUnitId;

  /// A string value representing the ad format to load ads for. Should be either [AdFormat.banner] or [AdFormat.mrec].
  final AdFormat adFormat;

  /// A string value representing the placement name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? placement;

  /// A string value representing the customData name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? customData;

  /// The listener for various ad callbacks.
  final AdViewAdListener? listener;

  /// Creates a new ad view directly in the user's widget tree.
  ///
  /// * [Banner Widget Method](https://dash.applovin.com/documentation/mediation/flutter/getting-started/banners#widget-method)
  /// * [MREC Widget Method](https://dash.applovin.com/documentation/mediation/flutter/getting-started/mrecs#widget-method)
  const MaxAdView({
    Key? key,
    required this.adUnitId,
    required this.adFormat,
    this.placement,
    this.customData,
    this.listener,
  }) : super(key: key);

  /// @nodoc
  @override
  State<MaxAdView> createState() => _MaxAdViewState();
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
        widget.listener?.onAdLoadFailedCallback(adUnitId, AppLovinMAX.createError(arguments));
      } else if ("OnAdViewAdClickedEvent" == method) {
        widget.listener?.onAdClickedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnAdViewAdExpandedEvent" == method) {
        widget.listener?.onAdExpandedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnAdViewAdCollapsedEvent" == method) {
        widget.listener?.onAdCollapsedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnAdViewAdRevenuePaidEvent" == method) {
        widget.listener?.onAdRevenuePaidCallback?.call(AppLovinMAX.createAd(adUnitId, arguments));
      }
    });
  }

  double _getWidth() {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecWidth;
    } else if (widget.adFormat == AdFormat.banner) {
      return _isTablet() ? _leaderWidth : _bannerWidth;
    }

    return -1;
  }

  double _getHeight() {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecHeight;
    } else if (widget.adFormat == AdFormat.banner) {
      return _isTablet() ? _leaderHeight : _bannerHeight;
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
