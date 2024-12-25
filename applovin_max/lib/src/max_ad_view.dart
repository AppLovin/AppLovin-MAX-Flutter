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

  /// A unique identifier representing the platform widget AdView instance.
  /// Used to manage and track the specific platform widget AdView.
  final AdViewId? adViewId;

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

  /// If null, the widget will compute an appropriate width based on the ad format
  /// and the available constraints from the parent widget.
  ///
  /// - For [AdFormat.banner]: Defaults to 320 for phones or 728 for tablets
  /// - For [AdFormat.mrec]: Defaults to 300.
  ///
  /// If [adaptive_banner] is enabled, the width will match the screen width.
  final double? width;

  /// If null, the widget will compute an appropriate height based on the ad format
  /// and the available constraints from the parent widget.
  ///
  /// - For [AdFormat.banner]: Defaults to 50 for phones or 90 for tablets
  /// - For [AdFormat.mrec]: Defaults to 250.
  ///
  /// If [adaptive_banner] is enabled, the height will be calculated dynamically
  /// using [AppLovinMAX.getAdaptiveBannerHeightForWidth(width)].
  final double? height;

  /// Creates a new ad view directly in the user's widget tree.
  ///
  /// * [Widget Method](https://developers.applovin.com/en/flutter/ad-formats/banner-mrec-ads#widget-method)
  const MaxAdView({
    Key? key,
    required this.adUnitId,
    required this.adFormat,
    this.adViewId,
    this.placement,
    this.customData,
    this.extraParameters,
    this.localExtraParameters,
    this.listener,
    this.isAutoRefreshEnabled = true,
    this.width,
    this.height,
  }) : super(key: key);

  /// @nodoc
  @override
  State<MaxAdView> createState() => _MaxAdViewState();
}

class _MaxAdViewState extends State<MaxAdView> {
  /// Unique [MethodChannel] to this [MaxAdView] instance.
  MethodChannel? _methodChannel;

  late bool _isTablet;
  late bool _adaptiveBannerEnabled;

  @override
  void initState() {
    super.initState();
    _adaptiveBannerEnabled = widget.extraParameters?['adaptive_banner'] == 'true' || widget.extraParameters == null;
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
    // https://stackoverflow.com/questions/49484549/can-we-check-the-device-to-be-a-smartphone-or-a-tablet-in-flutter
    _isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return FutureBuilder(
        future: _getAdViewSize(widget.width, widget.height),
        builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
          if (snapshot.hasData) {
            return buildAdView(context, snapshot.data!.width, snapshot.data!.height);
          }
          return Container(); // Return an empty container while waiting for the size.
        });
  }

  @override
  Widget buildAdView(BuildContext context, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
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

  /// Constructs the parameters to be sent to the platform-specific ad view.
  Map<String, dynamic> _createParams() {
    return {
      "ad_unit_id": widget.adUnitId,
      "ad_format": widget.adFormat.value,
      "ad_view_id": widget.adViewId,
      "is_auto_refresh_enabled": widget.isAutoRefreshEnabled,
      "custom_data": widget.customData,
      "placement": widget.placement,
      "extra_parameters": widget.extraParameters,
      "local_extra_parameters": widget.localExtraParameters,
    };
  }

  /// Handles the creation of the platform-specific ad view.
  void _onMaxAdViewCreated(int id) {
    _methodChannel = MethodChannel('${_viewType}_$id');
    _methodChannel?.setMethodCallHandler(_handleMethodCall);
  }

  /// Handles method calls from the platform.
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

  Future<Size> _getAdViewSize(double? width, double? height) async {
    width = (width != null) ? width : _getWidth();
    height = (height != null) ? height : (await _getHeight(width));
    return Size(width, height);
  }

  double _getWidth() {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecWidth;
    } else if (widget.adFormat == AdFormat.banner) {
      // Return the screen size when adaptive banner is enabled.
      if (_adaptiveBannerEnabled) {
        return MediaQuery.of(context).size.width;
      }
      return _isTablet ? _leaderWidth : _bannerWidth;
    } else {
      throw StateError('Unexpected ad format: ${widget.adFormat}');
    }
  }

  Future<double> _getHeight(double width) async {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecHeight;
    } else if (widget.adFormat == AdFormat.banner) {
      if (_adaptiveBannerEnabled) {
        return await AppLovinMAX.getAdaptiveBannerHeightForWidth(width) ?? (_isTablet ? _leaderHeight : _bannerHeight);
      }
      return _isTablet ? _leaderHeight : _bannerHeight;
    } else {
      throw StateError('Unexpected ad format: ${widget.adFormat}');
    }
  }
}
