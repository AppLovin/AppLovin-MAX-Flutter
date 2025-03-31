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

/// Displays a native AdView for a banner or MREC ad using a platform view as its container.
///
/// This widget can be used to display:
/// - **Banners**: 320×50 on phones, 728×90 on tablets.
/// - **MRECs**: Fixed size of 300×250 on all devices.
///
/// All ad formats are rendered through a native AdView behind the scenes,
/// ensuring consistent behavior across platforms.
///
/// For adaptive banner sizing, use [AppLovinMAX.getAdaptiveHeightForWidth()] to determine the appropriate height.
///
/// **Preloading**:
/// If you preload an ad using [AppLovinMAX.preloadWidgetAdView()],
/// pass the returned [AdViewId] to this widget to display the preloaded instance.
///
/// ### Example:
/// ```dart
/// MaxAdView(
///   adUnitId: 'your_ad_unit_id',
///   adFormat: AdFormat.banner,
///   listener: AdViewAdListener(
///     onAdLoadedCallback: (ad) {},
///     onAdLoadFailedCallback: (adUnitId, error) {},
///     onAdClickedCallback: (ad) {},
///     onAdExpandedCallback: (ad) {},
///     onAdCollapsedCallback: (ad) {},
///     onAdRevenuePaidCallback: (ad) {},
///   ),
/// );
/// ```
///
/// For a complete implementation example, see:
/// https://github.com/AppLovin/AppLovin-MAX-Flutter/blob/master/applovin_max/example/lib/main.dart
///
/// **Note:** The AppLovin SDK must be initialized before using this widget.
class MaxAdView extends StatefulWidget {
  /// The ad unit ID to load ads for.
  final String adUnitId;

  /// The ad format to load. Must be either [AdFormat.banner] or [AdFormat.mrec].
  final AdFormat adFormat;

  /// Unique identifier used to reference the platform AdView instance.
  final AdViewId? adViewId;

  /// Placement name assigned for granular ad reporting.
  final String? placement;

  /// Custom data string for granular ad reporting.
  final String? customData;

  /// Additional key-value parameters for ad customization, passed to the SDK.
  final Map<String, String?>? extraParameters;

  /// Local extra parameters provided to mediation adapters for further customization.
  final Map<String, dynamic>? localExtraParameters;

  /// Listener for ad event callbacks.
  final AdViewAdListener? listener;

  /// Whether auto-refresh is enabled. Defaults to `true`.
  final bool isAutoRefreshEnabled;

  /// The ad width. If `null`, a default is computed based on [adFormat] and layout constraints.
  ///
  /// - [AdFormat.banner]: 320 (phones) or 728 (tablets)
  /// - [AdFormat.mrec]: 300
  ///
  /// If [adaptive_banner] is enabled, the width matches the screen width.
  final double? width;

  /// The ad height. If `null`, a default is computed based on [adFormat] and layout constraints.
  ///
  /// - [AdFormat.banner]: 50 (phones) or 90 (tablets)
  /// - [AdFormat.mrec]: 250
  ///
  /// If [adaptive_banner] is enabled, the height is calculated using
  /// [AppLovinMAX.getAdaptiveBannerHeightForWidth].
  final double? height;

  /// Creates an AdView ad that embeds directly into the widget tree.
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
  late Map<String, String?> extraParameters;

  @override
  void initState() {
    super.initState();

    extraParameters = Map<String, String?>.from(widget.extraParameters ?? {});
    if (extraParameters['adaptive_banner'] == null) {
      // Set the default value for 'adaptive_banner'
      extraParameters['adaptive_banner'] = 'true';
      _adaptiveBannerEnabled = true;
    } else {
      _adaptiveBannerEnabled = extraParameters['adaptive_banner'] == 'true';
    }
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
      "extra_parameters": extraParameters,
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
