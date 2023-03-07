import 'dart:ui' as ui;

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Represents an ad format.
enum AdTemplate {
  /// The small ad.
  small("small"),

  /// The medium ad.
  medium("medium");

  /// @nodoc
  final String value;

  /// @nodoc
  const AdTemplate(this.value);
}

const double _smallWidth = 320;
const double _smallHeight = 50;
const double _leaderWidth = 728;
const double _leaderHeight = 90;
const double _mediumWidth = 300;
const double __mediumHeight = 250;

/// Represents an NativeAdView ad (small / medium).
class MaxNativeAdView extends StatefulWidget {
  /// A string value representing the ad unit ID to load ads for.
  final String adUnitId;

  /// A string value representing the ad template to load ads for. Should be either [AdTemplate.small] or [AdTemplate.medium].
  final AdTemplate adTemplate;

  /// A string value representing the placement name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? placement;

  /// A string value representing the customData name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? customData;

  /// The listener for various ad callbacks.
  final NativeAdViewAdListener? listener;
  
  /// Creates a new native ad view directly in the user's widget tree.
  const MaxNativeAdView({
    Key? key,
    required this.adUnitId,
    required this.adTemplate,
    this.placement,
    this.customData,
    this.listener,
  }) : super(key: key);

  /// @nodoc
  @override
  State<MaxNativeAdView> createState() => _MaxAdViewState();
}

class _MaxAdViewState extends State<MaxNativeAdView> {
  /// Unique [MethodChannel] to this [MaxNativeAdView] instance.
  MethodChannel? _methodChannel;
  
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
              "ad_template": widget.adTemplate.value,
              "ad_format": AdFormat.native.value,
              "customData": widget.customData,
              "placement": widget.placement
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
              "ad_template": widget.adTemplate.value,
              "ad_format": AdFormat.native.value,
              "customData": widget.customData,
              "placement": widget.placement
            },
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onMaxAdViewCreated,
          ),
        ),
      );
    }

    return Container();
  }

  Future<void> load() async {
     await _methodChannel?.invokeMethod("load");
  }
  
  void _onMaxAdViewCreated(int id) {
    _methodChannel = MethodChannel('applovin_max/adview_$id');
    _methodChannel!.setMethodCallHandler((call) async {
      var method = call.method;
      var arguments = call.arguments;

      var adUnitId = arguments["adUnitId"];

      if ("OnNativeAdViewAdLoadedEvent" == method) {
        widget.listener?.onAdLoadedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnNativeAdViewAdLoadFailedEvent" == method) {
        widget.listener?.onAdLoadFailedCallback(adUnitId, AppLovinMAX.createError(arguments));
      } else if ("OnNativeAdViewAdClickedEvent" == method) {
        widget.listener?.onAdClickedCallback(AppLovinMAX.createAd(adUnitId, arguments));
      } else if ("OnAdViewAdRevenuePaidEvent" == method) {
        widget.listener?.onAdRevenuePaidCallback?.call(AppLovinMAX.createAd(adUnitId, arguments));
      }
    });
  }

  double _getWidth() {
    if (widget.adTemplate == AdTemplate.medium) {
      return _mediumWidth;
    } else if (widget.adTemplate == AdTemplate.small) {
      return _isTablet() ? _leaderWidth : _smallWidth;
    }

    return -1;
  }

  double _getHeight() {
    if (widget.adTemplate == AdTemplate.medium) {
      return __mediumHeight;
    } else if (widget.adTemplate == AdTemplate.small) {
      return _isTablet() ? _leaderHeight : _smallHeight;
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
