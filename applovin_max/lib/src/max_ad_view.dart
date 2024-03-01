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

  /// A list of extra parameter key/value pairs for the ad.
  final Map<String, String?>? extraParameters;

  /// A list of local extra parameters to pass to the adapter instances.
  final Map<String, dynamic>? localExtraParameters;

  /// The listener for various ad callbacks.
  final AdViewAdListener? listener;

  /// A boolean value representing whether the ad currently has auto-refresh enabled or not. Defaults to true.
  final bool isAutoRefreshEnabled;

  /// A boolean value to switch between showing the widget or hiding it until an initial ad is loaded.  Defaults to true.
  final bool visible;

  /// The width of the banner for adaptive banners.
  final double? adaptiveBannerWidth;

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
    this.extraParameters,
    this.localExtraParameters,
    this.listener,
    this.isAutoRefreshEnabled = true,
    this.visible = true,
    this.adaptiveBannerWidth,
  }) : super(key: key);

  /// @nodoc
  @override
  State<MaxAdView> createState() => _MaxAdViewState();
}

class _MaxAdViewState extends State<MaxAdView> {
  /// Unique [MethodChannel] to this [MaxAdView] instance.
  MethodChannel? _methodChannel;

  late double _width;
  late double _height;
  late bool _visible;
  late bool _adaptiveBannerEnabled;

  @override
  void initState() {
    super.initState();
    _visible = widget.visible;
    _adaptiveBannerEnabled = (widget.extraParameters?['adaptive_banner'] == 'true');
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
    return FutureBuilder(
        future: _getAdViewSize(),
        builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
          if (snapshot.hasData) {
            _width = snapshot.data!.width;
            _height = snapshot.data!.height;
            return buildAdView(context);
          }
          return Container();
        });
  }

  Widget buildAdView(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Visibility(
          maintainState: true,
          maintainAnimation: true,
          visible: _visible,
          child: SizedBox(
            width: _width,
            height: _height,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              child: AndroidView(
                viewType: "applovin_max/adview",
                creationParams: <String, dynamic>{
                  "ad_unit_id": widget.adUnitId,
                  "ad_format": widget.adFormat.value,
                  "is_auto_refresh_enabled": widget.isAutoRefreshEnabled,
                  "custom_data": widget.customData,
                  "placement": widget.placement,
                  "extra_parameters": widget.extraParameters,
                  "local_extra_parameters": widget.localExtraParameters,
                },
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onMaxAdViewCreated,
              ),
            ),
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Visibility(
          maintainState: true,
          maintainAnimation: true,
          visible: _visible,
          child: SizedBox(
            width: _width,
            height: _height,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              child: UiKitView(
                viewType: "applovin_max/adview",
                creationParams: <String, dynamic>{
                  "ad_unit_id": widget.adUnitId,
                  "ad_format": widget.adFormat.value,
                  "is_auto_refresh_enabled": widget.isAutoRefreshEnabled,
                  "custom_data": widget.customData,
                  "placement": widget.placement,
                  "extra_parameters": widget.extraParameters,
                  "local_extra_parameters": widget.localExtraParameters,
                },
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onMaxAdViewCreated,
              ),
            ),
          ));
    }

    return Container();
  }

  void _onMaxAdViewCreated(int id) {
    _methodChannel = MethodChannel('applovin_max/adview_$id');
    _methodChannel!.setMethodCallHandler((call) async {
      var method = call.method;
      var arguments = call.arguments;

      if ("OnAdViewAdLoadedEvent" == method) {
        if (!_visible) _visible = true;
        widget.listener?.onAdLoadedCallback(AppLovinMAX.createAd(arguments));
      } else if ("OnAdViewAdLoadFailedEvent" == method) {
        widget.listener?.onAdLoadFailedCallback(arguments["adUnitId"], AppLovinMAX.createError(arguments));
      } else if ("OnAdViewAdClickedEvent" == method) {
        widget.listener?.onAdClickedCallback(AppLovinMAX.createAd(arguments));
      } else if ("OnAdViewAdExpandedEvent" == method) {
        widget.listener?.onAdExpandedCallback(AppLovinMAX.createAd(arguments));
      } else if ("OnAdViewAdCollapsedEvent" == method) {
        widget.listener?.onAdCollapsedCallback(AppLovinMAX.createAd(arguments));
      } else if ("OnAdViewAdRevenuePaidEvent" == method) {
        widget.listener?.onAdRevenuePaidCallback?.call(AppLovinMAX.createAd(arguments));
      }
    });
  }

  Future<Size> _getAdViewSize() async {
    double width = _getWidth();
    double height = (await _getHeight(width))!;
    return Size(width, height);
  }

  double _getWidth() {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecWidth;
    } else if (widget.adFormat == AdFormat.banner) {
      if (_adaptiveBannerEnabled) {
        if (widget.adaptiveBannerWidth != null) {
          return widget.adaptiveBannerWidth!;
        }
      }
      return _isTablet() ? _leaderWidth : _bannerWidth;
    }

    return -1;
  }

  Future<double?> _getHeight(double width) async {
    if (widget.adFormat == AdFormat.mrec) {
      return _mrecHeight;
    } else if (widget.adFormat == AdFormat.banner) {
      if (_adaptiveBannerEnabled) {
        return await AppLovinMAX.getAdaptiveBannerHeightForWidth(width);
      }
      return _isTablet() ? _leaderHeight : _bannerHeight;
    }

    return -1;
  }

  bool _isTablet() {
    final double devicePixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final ui.Size size = ui.PlatformDispatcher.instance.views.first.physicalSize;
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
