import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controls a native ad widget
class MaxNativeAdViewController extends ChangeNotifier {
  /// Loads a native ad
  void load() {
    notifyListeners();
  }
}

/// Represents a native ad widget
class MaxNativeAdView extends StatefulWidget {
  const MaxNativeAdView({
    Key? key,
    required this.adUnitId,
    this.placement,
    this.customData,
    this.listener,
    this.width = double.infinity,
    this.height = double.infinity,
    this.controller,
    required this.child,
  }) : super(key: key);

  /// A string value representing the ad unit ID to load ads for.
  final String adUnitId;

  /// A string value representing the placement name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? placement;

  /// A string value representing the customData name that you assign when you integrate each ad format, for granular reporting in ad events.
  final String? customData;

  /// The listener for various native ad callbacks.
  final NativeAdViewAdListener? listener;

  /// If non-null, requires the child to have exactly this width.
  final double? width;

  /// If non-null, requires the child to have exactly this height.
  final double? height;

  /// The controller that reloads a native ad.
  final MaxNativeAdViewController? controller;

  /// The [child] contained by the MaxNativeAdView container.
  final Widget child;

  /// @no doc
  @override
  State<MaxNativeAdView> createState() => _MaxNativeAdViewState();
}

class _MaxNativeAdViewState extends State<MaxNativeAdView> {
  final GlobalKey _nativeAdViewKey = GlobalKey();

  /// Unique [MethodChannel] to this [MaxNativeAdView] instance.
  MethodChannel? _methodChannel;

  /// An instance of [MaxNativeAd]
  MaxNativeAd? _nativeAd;

  GlobalKey? _titleViewKey;
  GlobalKey? _advertiserViewKey;
  GlobalKey? _bodyViewKey;
  GlobalKey? _callToActionViewKey;
  GlobalKey? _iconViewKey;
  GlobalKey? _optionsViewKey;
  GlobalKey? _starRatingViewKey;
  GlobalKey? _mediaViewKey;

  /// The number of device pixels for each logical pixel.
  late double devicePixelRatio;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(() {
      _methodChannel!.invokeMethod("load");
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (defaultTargetPlatform == TargetPlatform.android) {
      MediaQueryData queryData = MediaQuery.of(context);
      devicePixelRatio = queryData.devicePixelRatio;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _NativeAdViewScope(
          data: this,
          child: SizedBox(
            key: _nativeAdViewKey,
            width: widget.width,
            height: widget.height,
            child: Stack(children: <Widget>[
              LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                return widget.child;
              }),
              AndroidView(
                viewType: "applovin_max/nativeadview",
                creationParams: <String, dynamic>{"ad_unit_id": widget.adUnitId, "customData": widget.customData, "placement": widget.placement},
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onMaxNativeAdViewCreated,
              ),
            ]),
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _NativeAdViewScope(
          data: this,
          child: SizedBox(
            key: _nativeAdViewKey,
            width: widget.width,
            height: widget.height,
            child: Stack(children: <Widget>[
              LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                return widget.child;
              }),
              UiKitView(
                  viewType: "applovin_max/nativeadview",
                  creationParams: <String, dynamic>{"ad_unit_id": widget.adUnitId, "customData": widget.customData, "placement": widget.placement},
                  creationParamsCodec: const StandardMessageCodec(),
                  onPlatformViewCreated: _onMaxNativeAdViewCreated),
            ]),
          ));
    }

    return Container();
  }

  void _onMaxNativeAdViewCreated(int id) {
    _methodChannel = MethodChannel('applovin_max/nativeadview_$id');
    _methodChannel!.setMethodCallHandler(_handleNativeMethodCall);
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    var method = call.method;
    var arguments = call.arguments;
    var adUnitId = arguments["adUnitId"];

    if ("OnNativeAdViewAdLoadedEvent" == method) {
      MaxAd maxAd = AppLovinMAX.createAd(adUnitId, arguments);
      widget.listener?.onAdLoadedCallback(maxAd);

      // add native ad components in the platform
      _addNativeAdComponent(_iconViewKey, "addIconView");
      _addNativeAdComponent(_optionsViewKey, "addOptionsView");
      _addNativeAdComponent(_mediaViewKey, "addMediaView");
      _addNativeAdComponent(_titleViewKey, "addTitleView");
      _addNativeAdComponent(_advertiserViewKey, "addAdvertiserView");
      _addNativeAdComponent(_bodyViewKey, "addBodyView");
      _addNativeAdComponent(_callToActionViewKey, "addCallToActionView");
      // send a notice for the platform to wrap up the view addition for the native ad components
      _methodChannel!.invokeMethod("completeViewAddition");

      // update the all native ad components with the native ad
      _applyNativeAdToComponents(maxAd);
    } else if ("OnNativeAdViewAdLoadFailedEvent" == method) {
      widget.listener?.onAdLoadFailedCallback(adUnitId, AppLovinMAX.createError(arguments));
    } else if ("OnNativeAdViewAdClickedEvent" == method) {
      widget.listener?.onAdClickedCallback(AppLovinMAX.createAd(adUnitId, arguments));
    } else if ("OnNativeAdViewAdRevenuePaidEvent" == method) {
      widget.listener?.onAdRevenuePaidCallback?.call(AppLovinMAX.createAd(adUnitId, arguments));
    }
  }

  // add a native ad component in the platform or update with the current position and size
  void _addNativeAdComponent(GlobalKey? key, String method) {
    if (key == null) return;
    Rect rect = _getViewSize(key, _nativeAdViewKey);
    if (defaultTargetPlatform == TargetPlatform.android) {
      _methodChannel!.invokeMethod(method, <String, dynamic>{
        'x': (rect.left * devicePixelRatio).round(),
        'y': (rect.top * devicePixelRatio).round(),
        'width': (rect.width * devicePixelRatio).round(),
        'height': (rect.height * devicePixelRatio).round(),
      });
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      _methodChannel!.invokeMethod(method, <String, dynamic>{
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      });
    }
  }

  // update the all native ad components with the native ad
  void _applyNativeAdToComponents(MaxAd ad) {
    setState(() {
      _nativeAd = ad.nativeAd;
    });
  }

  // get a frame(rect) size with a relative position to parent
  Rect _getViewSize(GlobalKey? key, GlobalKey parentKey) {
    RenderBox renderedObject = key?.currentContext?.findRenderObject() as RenderBox;
    Offset globalPosition = renderedObject.localToGlobal(Offset.zero);
    RenderBox parentRenderedObject = parentKey.currentContext?.findRenderObject() as RenderBox;
    Offset relativePosition = parentRenderedObject.globalToLocal(globalPosition);
    return relativePosition & renderedObject.size;
  }
}

class MaxNativeAdTitleView extends StatelessWidget {
  const MaxNativeAdTitleView({
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
  });

  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._titleViewKey = _NativeAdViewScope.of(context)._titleViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._addNativeAdComponent(_NativeAdViewScope.of(context)._titleViewKey, "addTitleView");
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          _NativeAdViewScope.of(context)._nativeAd?.title ?? '',
          key: _NativeAdViewScope.of(context)._titleViewKey,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

class MaxNativeAdAdvertiserView extends StatelessWidget {
  const MaxNativeAdAdvertiserView({
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
  });

  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._advertiserViewKey = _NativeAdViewScope.of(context)._advertiserViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._addNativeAdComponent(_NativeAdViewScope.of(context)._advertiserViewKey, "addAdvertiserView");
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          _NativeAdViewScope.of(context)._nativeAd?.advertiser ?? '',
          key: _NativeAdViewScope.of(context)._advertiserViewKey,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

class MaxNativeAdBodyView extends StatelessWidget {
  const MaxNativeAdBodyView({
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
  });

  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._bodyViewKey = _NativeAdViewScope.of(context)._bodyViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._addNativeAdComponent(_NativeAdViewScope.of(context)._bodyViewKey, "addBodyView");
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          _NativeAdViewScope.of(context)._nativeAd?.body ?? '',
          key: _NativeAdViewScope.of(context)._bodyViewKey,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

class MaxNativeAdCallToActionView extends StatelessWidget {
  const MaxNativeAdCallToActionView({
    super.key,
    this.style,
  });

  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._callToActionViewKey = _NativeAdViewScope.of(context)._callToActionViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._addNativeAdComponent(_NativeAdViewScope.of(context)._callToActionViewKey, "addCallToActionView");
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

class MaxNativeAdIconView extends StatelessWidget {
  const MaxNativeAdIconView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._iconViewKey = _NativeAdViewScope.of(context)._iconViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._addNativeAdComponent(_NativeAdViewScope.of(context)._iconViewKey, "addIconView");
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

class MaxNativeAdOptionsView extends StatelessWidget {
  const MaxNativeAdOptionsView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._optionsViewKey = _NativeAdViewScope.of(context)._optionsViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._addNativeAdComponent(_NativeAdViewScope.of(context)._optionsViewKey, "addOptionsView");
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

class MaxNativeAdMediaView extends StatelessWidget {
  const MaxNativeAdMediaView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._mediaViewKey = _NativeAdViewScope.of(context)._mediaViewKey ?? GlobalKey();
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _NativeAdViewScope.of(context)._addNativeAdComponent(_NativeAdViewScope.of(context)._mediaViewKey, "addMediaView");
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

class MaxNativeAdStarRatingView extends StatelessWidget {
  const MaxNativeAdStarRatingView({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
  });

  final double? width;
  final double? height;

  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    _NativeAdViewScope.of(context)._starRatingViewKey = _NativeAdViewScope.of(context)._starRatingViewKey ?? GlobalKey();
    return Container(
        key: _NativeAdViewScope.of(context)._starRatingViewKey,
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

class _NativeAdViewScope extends InheritedWidget {
  const _NativeAdViewScope({
    required this.data,
    required super.child,
  });

  final _MaxNativeAdViewState data;

  static _MaxNativeAdViewState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_NativeAdViewScope>()!.data;
  }

  @override
  bool updateShouldNotify(_NativeAdViewScope oldWidget) => true;
}
