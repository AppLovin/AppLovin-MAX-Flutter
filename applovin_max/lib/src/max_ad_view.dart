import 'dart:ui' as ui;

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double _bannerWidth = 320;
const double _bannerHeight = 50;
const double _leaderWidth = 728;
const double _leaderHeight = 90;
const double _mrecWidth = 300;
const double _mrecHeight = 250;

const String _viewType = "applovin_max/adview";

/// Represents an AdView ad (Banner / MREC).
class MaxAdView extends StatefulWidget {
  /// A string value representing the ad unit ID to load ads for.
  final String adUnitId;

  /// A string value representing the ad format to load ads for. Should be
  /// either [AdFormat.banner] or [AdFormat.mrec].
  final AdFormat adFormat;

  /// A string value representing the placement name that you assign when you
  /// integrate each ad format, for granular reporting in ad events.
  final String? placement;

  /// A string value representing the customData name that you assign when you
  /// integrate each ad format, for granular reporting in ad events.
  final String? customData;

  /// A list of extra parameter key/value pairs for the ad.
  final Map<String, String?>? extraParameters;

  /// A list of local extra parameters to pass to the adapter instances.
  final Map<String, dynamic>? localExtraParameters;

  /// The listener for various ad callbacks.
  final AdViewAdListener? listener;

  /// A boolean value representing whether the ad currently has auto-refresh
  /// enabled or not. Defaults to true.
  final bool isAutoRefreshEnabled;

  /// Creates a new ad view directly in the user's widget tree.
  ///
  /// * [Widget Method](https://developers.applovin.com/en/flutter/ad-formats/banner-mrec-ads#widget-method)
  const MaxAdView({
    Key? key,
    required this.adUnitId,
    required this.adFormat,
    this.placement,
    this.customData,
    this.extraParameters,
    this.localExtraParameters,
    this.listener,
    this.isAutoRefreshEnabled = true,
  }) : super(key: key);

  /// @nodoc
  @override
  State<MaxAdView> createState() => _MaxAdViewState();
}

class _MaxAdViewState extends State<MaxAdView> {
  /// Unique [MethodChannel] to this [MaxAdView] instance.
  MethodChannel? _methodChannel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(MaxAdView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isAutoRefreshEnabled != widget.isAutoRefreshEnabled) {
      if (widget.isAutoRefreshEnabled) {
        _methodChannel?.invokeMethod('startAutoRefresh');
      } else {
        _methodChannel?.invokeMethod('stopAutoRefresh');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _getWidth(),
      height: _getHeight(),
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        child: defaultTargetPlatform == TargetPlatform.android
            ? AndroidView(
                viewType: _viewType,
                creationParams: _createParams(),
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onMaxAdViewCreated,
              )
            : UiKitView(
                viewType: _viewType,
                creationParams: _createParams(),
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onMaxAdViewCreated,
              ),
      ),
    );
  }

  Map<String, dynamic> _createParams() {
    return {
      "ad_unit_id": widget.adUnitId,
      "ad_format": widget.adFormat.value,
      "is_auto_refresh_enabled": widget.isAutoRefreshEnabled,
      "custom_data": widget.customData,
      "placement": widget.placement,
      "extra_parameters": widget.extraParameters,
      "local_extra_parameters": widget.localExtraParameters,
    };
  }

  void _onMaxAdViewCreated(int id) {
    _methodChannel = MethodChannel('${_viewType}_$id');
    _methodChannel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      final String method = call.method;
      final Map<dynamic, dynamic>? arguments = call.arguments;

      if (arguments == null) {
        throw ArgumentError('Arguments for method $method cannot be null.');
      }

      if ("OnAdViewAdLoadedEvent" == method) {
        widget.listener?.onAdLoadedCallback(AppLovinMAX.createMaxAd(arguments));
      } else if ("OnAdViewAdLoadFailedEvent" == method) {
        widget.listener?.onAdLoadFailedCallback(arguments["adUnitId"], AppLovinMAX.createMaxError(arguments));
      } else if ("OnAdViewAdClickedEvent" == method) {
        widget.listener?.onAdClickedCallback(AppLovinMAX.createMaxAd(arguments));
      } else if ("OnAdViewAdExpandedEvent" == method) {
        widget.listener?.onAdExpandedCallback(AppLovinMAX.createMaxAd(arguments));
      } else if ("OnAdViewAdCollapsedEvent" == method) {
        widget.listener?.onAdCollapsedCallback(AppLovinMAX.createMaxAd(arguments));
      } else if ("OnAdViewAdRevenuePaidEvent" == method) {
        widget.listener?.onAdRevenuePaidCallback?.call(AppLovinMAX.createMaxAd(arguments));
      } else {
        throw MissingPluginException('No handler for method $method');
      }
    } catch (e) {
      debugPrint('Error handling method call ${call.method} with arguments ${call.arguments}: $e');
    }
  }

  double? _getWidth() {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecWidth;
    } else if (widget.adFormat == AdFormat.banner) {
      return _isTablet() ? _leaderWidth : _bannerWidth;
    }
    debugPrint('Unexpected ad format: ${widget.adFormat}');
    // Use `null` for the SizedBox to size itself based on its child or its constraints.
    return null;
  }

  double? _getHeight() {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecHeight;
    } else if (widget.adFormat == AdFormat.banner) {
      return _isTablet() ? _leaderHeight : _bannerHeight;
    }
    debugPrint('Unexpected ad format: ${widget.adFormat}');
    // Use `null` for the SizedBox to size itself based on its child or its constraints.
    return null;
  }

  bool _isTablet() {
    final double devicePixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final ui.Size size = ui.PlatformDispatcher.instance.views.first.physicalSize;
    final double width = size.width;
    final double height = size.height;

    return (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) || (devicePixelRatio == 2 && (width >= 1920 || height >= 1920));
  }
}
