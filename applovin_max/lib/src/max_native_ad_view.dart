import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _viewType = "applovin_max/nativeadview";

/// An inherited widget for [MaxNativeAdView] to propagate information down the widget tree.
class _NativeAdViewScope extends InheritedWidget {
  const _NativeAdViewScope({
    required _MaxNativeAdViewState nativeAdViewState,
    required super.child,
  }) : _scope = nativeAdViewState;

  final _MaxNativeAdViewState _scope;

  static _MaxNativeAdViewState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_NativeAdViewScope>()!._scope;
  }

  @override
  bool updateShouldNotify(_NativeAdViewScope oldWidget) {
    return true;
  }
}

/// Controls the behavior of a [MaxNativeAdView].
class MaxNativeAdViewController extends ChangeNotifier {
  /// Requests the native ad view to load a new ad.
  void loadAd() {
    notifyListeners();
  }
}

/// Displays a native ad with its associated asset views:
///
/// - [MaxNativeAdIconView]
/// - [MaxNativeAdTitleView]
/// - [MaxNativeAdAdvertiserView]
/// - [MaxNativeAdStarRatingView]
/// - [MaxNativeAdBodyView]
/// - [MaxNativeAdMediaView]
/// - [MaxNativeAdCallToActionView]
///
/// Each asset view must be manually positioned and styled.
/// Ad content is populated automatically once the ad is loaded.
/// Use the widget’s controller (`loadAd()`) to reload the ad as needed.
///
/// **Note:** The AppLovin SDK must be initialized before using this widget.
///
/// ### Example:
/// For a complete implementation example, see:
/// https://github.com/AppLovin/AppLovin-MAX-Flutter/blob/master/applovin_max/example/lib/native_ad.dart
class MaxNativeAdView extends StatefulWidget {
  /// The ad unit ID to load ads for.
  final String adUnitId;

  /// Placement name assigned for granular ad reporting.
  final String? placement;

  /// Custom data string for granular ad reporting.
  final String? customData;

  /// Additional key-value parameters for ad customization, passed to the SDK.
  final Map<String, String?>? extraParameters;

  /// Local extra parameters provided to mediation adapters for further customization.
  final Map<String, dynamic>? localExtraParameters;

  /// Listener for native ad event callbacks.
  final NativeAdListener? listener;

  /// The width of the native ad. Defaults to [double.infinity].
  final double? width;

  /// The height of the native ad. Defaults to [double.infinity].
  final double? height;

  /// The controller that reloads a native ad.
  final MaxNativeAdViewController? controller;

  /// The child widget that contains the asset views of the native ad.
  final Widget child;

  /// Creates a native ad view with the provided asset views.
  const MaxNativeAdView({
    Key? key,
    required this.adUnitId,
    this.placement,
    this.customData,
    this.extraParameters,
    this.localExtraParameters,
    this.listener,
    this.width = double.infinity,
    this.height = double.infinity,
    this.controller,
    required this.child,
  }) : super(key: key);

  /// @nodoc
  @override
  State<MaxNativeAdView> createState() => _MaxNativeAdViewState();
}

class _MaxNativeAdViewState extends State<MaxNativeAdView> {
  final GlobalKey _nativeAdViewKey = GlobalKey();

  // Unique [MethodChannel] for this [MaxNativeAdView] instance.
  MethodChannel? _methodChannel;

  // The native ad instance received from the platform.
  MaxNativeAd? _nativeAd;

  // Keys for native ad asset view components.
  GlobalKey? _titleViewKey;
  GlobalKey? _advertiserViewKey;
  GlobalKey? _bodyViewKey;
  GlobalKey? _callToActionViewKey;
  GlobalKey? _iconViewKey;
  GlobalKey? _optionsViewKey;
  GlobalKey? _starRatingViewKey;
  GlobalKey? _mediaViewKey;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NativeAdViewScope(
      nativeAdViewState: this,
      child: SizedBox(
        key: _nativeAdViewKey,
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return widget.child;
              },
            ),
            if (defaultTargetPlatform == TargetPlatform.android)
              AndroidView(
                viewType: _viewType,
                creationParams: _createParams(),
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onMaxNativeAdViewCreated,
              ),
            if (defaultTargetPlatform == TargetPlatform.iOS)
              UiKitView(
                viewType: _viewType,
                creationParams: _createParams(),
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onMaxNativeAdViewCreated,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _createParams() {
    return {
      "ad_unit_id": widget.adUnitId,
      "custom_data": widget.customData,
      "placement": widget.placement,
      "extra_parameters": widget.extraParameters,
      "local_extra_parameters": widget.localExtraParameters,
    };
  }

  // Handles ad load requests triggered by the [MaxNativeAdViewController].
  void _handleControllerChanged() {
    _methodChannel?.invokeMethod("loadAd");
  }

  void _onMaxNativeAdViewCreated(int id) {
    _methodChannel = MethodChannel('${_viewType}_$id');
    _methodChannel?.setMethodCallHandler(_handleNativeMethodCall);
  }

  // Handles incoming method calls from the native platform.
  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    try {
      final String method = call.method;
      final Map<dynamic, dynamic>? arguments = call.arguments;

      if (arguments == null) {
        throw ArgumentError('Arguments for method $method cannot be null.');
      }

      if ("OnNativeAdLoadedEvent" == method) {
        MaxAd maxAd = AppLovinMAX.createMaxAd(arguments);
        widget.listener?.onAdLoadedCallback(maxAd);

        // Add or update all native ad asset views (e.g., title, body, icon) on the platform.
        await _updateAllAssetViews();

        // Register clickable views and initiate the rendering of the native ad on the platform.
        await _renderAd();

        // Update the Flutter asset views with the native ad.
        setState(() {
          _nativeAd = maxAd.nativeAd;
        });
      } else if ("OnNativeAdLoadFailedEvent" == method) {
        widget.listener?.onAdLoadFailedCallback(arguments["adUnitId"], AppLovinMAX.createMaxError(arguments));
      } else if ("OnNativeAdClickedEvent" == method) {
        widget.listener?.onAdClickedCallback(AppLovinMAX.createMaxAd(arguments));
      } else if ("OnNativeAdRevenuePaidEvent" == method) {
        widget.listener?.onAdRevenuePaidCallback?.call(AppLovinMAX.createMaxAd(arguments));
      } else {
        throw MissingPluginException('No handler for method $method');
      }
    } catch (e) {
      debugPrint('Error handling native method call ${call.method} with arguments ${call.arguments}: $e');
    }
  }

  // Updates all native asset views by invoking their corresponding methods on the platform.
  Future _updateAllAssetViews() async {
    return Future.wait([
      _updateAssetView(_mediaViewKey, "addMediaView"),
      _updateAssetView(_iconViewKey, "addIconView"),
      _updateAssetView(_optionsViewKey, "addOptionsView"),
      _updateAssetView(_titleViewKey, "addTitleView"),
      _updateAssetView(_advertiserViewKey, "addAdvertiserView"),
      _updateAssetView(_bodyViewKey, "addBodyView"),
      _updateAssetView(_callToActionViewKey, "addCallToActionView")
    ]);
  }

  // Updates the specified asset view's position and size on the platform using the provided method name.
  Future _updateAssetView(GlobalKey? key, String method) async {
    if (key == null) return;

    Rect rect = _getViewSize(key, _nativeAdViewKey);
    if (rect.isEmpty) return;

    Map<String, dynamic> params;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      params = {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      };
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      params = {
        'x': (rect.left * devicePixelRatio).round(),
        'y': (rect.top * devicePixelRatio).round(),
        'width': (rect.width * devicePixelRatio).round(),
        'height': (rect.height * devicePixelRatio).round(),
      };
    } else {
      return;
    }

    return _methodChannel?.invokeMethod(method, params);
  }

  // Requests the platform to render the loaded native ad.
  Future _renderAd() async {
    return _methodChannel?.invokeMethod("renderAd");
  }

  // Returns the position and size of the given view [key] relative to its [parentKey].
  Rect _getViewSize(GlobalKey key, GlobalKey parentKey) {
    RenderBox? renderedObject = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderedObject == null) return Rect.zero;
    Offset globalPosition = renderedObject.localToGlobal(Offset.zero);
    RenderBox parentRenderedObject = parentKey.currentContext?.findRenderObject() as RenderBox;
    Offset relativePosition = parentRenderedObject.globalToLocal(globalPosition);
    return relativePosition & renderedObject.size;
  }
}

/// Represents the title text of a native ad.
class MaxNativeAdTitleView extends StatelessWidget {
  /// Displays the title text of the native ad using a [Text] widget.
  /// The title text is provided by the native ad loader.
  const MaxNativeAdTitleView({
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
  });

  /// The text style to apply.
  final TextStyle? style;

  /// How each line of text in the Text widget should be aligned horizontally.
  final TextAlign? textAlign;

  /// Whether the text should break at soft line breaks.
  final bool? softWrap;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._titleViewKey = _NativeAdViewScope.of(context)._titleViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._updateAssetView(_NativeAdViewScope.of(context)._titleViewKey, "addTitleView");
          _NativeAdViewScope.of(context)._renderAd();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          _NativeAdViewScope.of(context)._nativeAd?.title ?? '',
          key: _NativeAdViewScope.of(context)._titleViewKey,
          style: style,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

/// Represents the advertiser text of a native ad.
class MaxNativeAdAdvertiserView extends StatelessWidget {
  /// Displays the advertiser text of the native ad using a [Text] widget.
  /// The advertiser text is provided by the native ad loader.
  const MaxNativeAdAdvertiserView({
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
  });

  /// The text style to apply.
  final TextStyle? style;

  /// How each line of text in the Text widget should be aligned horizontally.
  final TextAlign? textAlign;

  /// Whether the text should break at soft line breaks.
  final bool? softWrap;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._advertiserViewKey = _NativeAdViewScope.of(context)._advertiserViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._updateAssetView(_NativeAdViewScope.of(context)._advertiserViewKey, "addAdvertiserView");
          _NativeAdViewScope.of(context)._renderAd();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          _NativeAdViewScope.of(context)._nativeAd?.advertiser ?? '',
          key: _NativeAdViewScope.of(context)._advertiserViewKey,
          style: style,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

/// Represents the body text of a native ad.
class MaxNativeAdBodyView extends StatelessWidget {
  /// Displays the body text of the native ad using a [Text] widget.
  /// The body text is provided by the native ad loader.
  const MaxNativeAdBodyView({
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
  });

  /// The text style to apply.
  final TextStyle? style;

  /// How each line of text in the Text widget should be aligned horizontally.
  final TextAlign? textAlign;

  /// Whether the text should break at soft line breaks.
  final bool? softWrap;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._bodyViewKey = _NativeAdViewScope.of(context)._bodyViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._updateAssetView(_NativeAdViewScope.of(context)._bodyViewKey, "addBodyView");
          _NativeAdViewScope.of(context)._renderAd();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          _NativeAdViewScope.of(context)._nativeAd?.body ?? '',
          key: _NativeAdViewScope.of(context)._bodyViewKey,
          style: style,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

/// Represents the CTA button text of a native ad.
class MaxNativeAdCallToActionView extends StatelessWidget {
  /// Displays the call-to-action (CTA) text as an [ElevatedButton].
  /// The CTA text is provided by the native ad loader.
  const MaxNativeAdCallToActionView({
    super.key,
    this.style,
  });

  /// The button style to apply.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._callToActionViewKey = _NativeAdViewScope.of(context)._callToActionViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._updateAssetView(_NativeAdViewScope.of(context)._callToActionViewKey, "addCallToActionView");
          _NativeAdViewScope.of(context)._renderAd();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: ElevatedButton(
          key: _NativeAdViewScope.of(context)._callToActionViewKey,
          style: style,
          onPressed: () {},
          child: Text(
            _NativeAdViewScope.of(context)._nativeAd?.callToAction?.toUpperCase() ?? '',
          ),
        ),
      ),
    );
  }
}

/// Represents the icon image view of a native ad.
class MaxNativeAdIconView extends StatelessWidget {
  /// Displays a transparent [Container] as a placeholder for the icon view.
  /// The platform overlays it with the native icon content.
  const MaxNativeAdIconView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  /// If non-null, the widget will have exactly this width.
  final double? width;

  /// If non-null, the widget will have exactly this height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._iconViewKey = _NativeAdViewScope.of(context)._iconViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._updateAssetView(_NativeAdViewScope.of(context)._iconViewKey, "addIconView");
          _NativeAdViewScope.of(context)._renderAd();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          key: _NativeAdViewScope.of(context)._iconViewKey,
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

/// Represents the options view of a native ad.
class MaxNativeAdOptionsView extends StatelessWidget {
  /// Displays a transparent [Container] as a placeholder for the options view.
  /// The platform overlays it with the native options view.
  const MaxNativeAdOptionsView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  /// If non-null, the widget will have exactly this width.
  final double? width;

  /// If non-null, the widget will have exactly this height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._optionsViewKey = _NativeAdViewScope.of(context)._optionsViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._updateAssetView(_NativeAdViewScope.of(context)._optionsViewKey, "addOptionsView");
          _NativeAdViewScope.of(context)._renderAd();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          key: _NativeAdViewScope.of(context)._optionsViewKey,
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

/// Represents the ad media view of a native ad.
class MaxNativeAdMediaView extends StatelessWidget {
  /// Displays a transparent [Container] as a placeholder for the media view.
  /// The platform overlays it with the native media view.
  /// The aspect ratio for the media view needs to be adjusted with
  /// [mediaContentAspectRatio] of [MaxNativeAd].
  const MaxNativeAdMediaView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  /// If non-null, the widget will have exactly this width.
  final double? width;

  /// If non-null, the widget will have exactly this height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._mediaViewKey = _NativeAdViewScope.of(context)._mediaViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._updateAssetView(_NativeAdViewScope.of(context)._mediaViewKey, "addMediaView");
          _NativeAdViewScope.of(context)._renderAd();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          key: _NativeAdViewScope.of(context)._mediaViewKey,
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    this.rating,
    this.color,
    this.size,
  });

  static const int kStarCount = 5;
  static const Color kStartColor = Color(0xffffe234);
  static const double kStarSize = 8.0;

  final double? rating;
  final Color? color;
  final double? size;

  Widget buildStar(BuildContext context, int index) {
    Icon icon;
    double theRating = rating ?? .0;
    if (index >= theRating) {
      icon = Icon(
        Icons.star_border,
        color: color ?? kStartColor,
        size: size ?? kStarSize,
      );
    } else if (index > theRating - 1 && index < theRating) {
      icon = Icon(
        Icons.star_half,
        color: color ?? kStartColor,
        size: size ?? kStarSize,
      );
    } else {
      icon = Icon(
        Icons.star,
        color: color ?? kStartColor,
        size: size ?? kStarSize,
      );
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(kStarCount, (index) => buildStar(context, index)));
  }
}

/// Represents the star rating view of a native ad.
class MaxNativeAdStarRatingView extends StatelessWidget {
  /// Creates [Container] with an internal star rating widget. The platform
  /// native ad loader provides a star rating. If not available, the container
  /// will be empty.
  const MaxNativeAdStarRatingView({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
  });

  /// If non-null, the widget will have exactly this width.
  final double? width;

  /// If non-null, the widget will have exactly this height.
  final double? height;

  /// The color of each star. The default value is 0xffffe234.
  final Color? color;

  /// The size of each star. The default value is 8.0.
  final double? size;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._starRatingViewKey = _NativeAdViewScope.of(context)._starRatingViewKey ?? GlobalKey();
    return Container(
        key: _NativeAdViewScope.of(context)._starRatingViewKey,
        // minimum size
        constraints: BoxConstraints(
          minHeight: size ?? _StarRating.kStarSize,
          minWidth: (size ?? _StarRating.kStarSize) * _StarRating.kStarCount,
        ),
        width: width,
        height: height,
        child: (_NativeAdViewScope.of(context)._nativeAd?.starRating != null)
            ? _StarRating(
                size: size,
                color: color,
                rating: _NativeAdViewScope.of(context)._nativeAd?.starRating!,
              )
            : null);
  }
}
