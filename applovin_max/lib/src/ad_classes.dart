import 'dart:ui';
import 'package:applovin_max/src/enums.dart';

/// A unique identifier used to reference a specific platform widget AdView instance.
typedef AdViewId = num;

/// Represents an ad that has been served by AppLovin MAX.
class MaxAd {
  /// The ad unit ID for which this ad was loaded.
  final String adUnitId;

  /// The ad format of this ad.
  final String adFormat;

  /// The unique ID of the platform widget AdView.
  final AdViewId? adViewId;

  /// The ad network from which this ad was loaded.
  final String networkName;

  /// The ad network placement for which this ad was loaded.
  final String networkPlacement;

  /// The revenue amount for this ad. Returns `0` if unavailable.
  final double revenue;

  /// The precision of the revenue value for this ad.
  ///
  /// Possible values:
  /// * "publisher_defined" - If the revenue is the price assigned to the line item by the publisher.
  /// * "exact" - If the revenue is the resulting price of a real-time auction.
  /// * "estimated" - If the revenue is the price obtained by auto-CPM.
  /// * "undefined" - If we do not have permission from the ad network to share impression-level data.
  /// * "" - An empty string, if revenue and precision are not valid (for example, in test mode).
  final String revenuePrecision;

  /// The creative ID tied to the ad, if any. You can report creative issues to
  /// the corresponding ad network using this ID.
  final String creativeId;

  /// The DSP that served the ad when using AppLovin Exchange.
  final String dspName;

  /// The custom placement name assigned during integration.
  final String placement;

  /// The latency of the mediation ad load request in milliseconds.
  final int latencyMillis;

  /// The underlying waterfall of ad responses.
  final MaxAdWaterfallInfo waterfall;

  /// An instance of [MaxNativeAd], available only for native ads.
  final MaxNativeAd? nativeAd;

  /// The size of the AdView format ad.
  final Size? size;

  /// @nodoc
  MaxAd(this.adUnitId, this.adFormat, this.adViewId, this.networkName, this.networkPlacement, this.revenue, this.revenuePrecision, this.creativeId,
      this.dspName, this.placement, this.latencyMillis, this.waterfall, this.nativeAd, this.size);

  /// @nodoc
  factory MaxAd.fromJson(Map<String, dynamic> json) {
    MaxNativeAd? nativeAd;
    if (json['nativeAd'] is Map) {
      nativeAd = MaxNativeAd.fromJson(Map<String, dynamic>.from(json['nativeAd']));
    }

    final double? width = json['width'] != null ? (json['width'] as num).toDouble() : null;
    final double? height = json['height'] != null ? (json['height'] as num).toDouble() : null;
    final Size? size = (width != null && height != null) ? Size(width, height) : null;

    return MaxAd(
      json['adUnitId'] as String,
      json['adFormat'] as String,
      json['adViewId'] as AdViewId?,
      json['networkName'] as String,
      json['networkPlacement'] as String,
      double.tryParse(json['revenue']?.toString() ?? '0.0') ?? 0.0,
      json['revenuePrecision'] as String,
      json['creativeId'] as String,
      json['dspName'] as String,
      json['placement'] as String,
      int.tryParse(json['latencyMillis']?.toString() ?? '0') ?? 0,
      MaxAdWaterfallInfo.fromJson(Map<String, dynamic>.from(json['waterfall'])),
      nativeAd,
      size,
    );
  }

  @override
  String toString() {
    return '{MaxAd: {adUnitId: $adUnitId'
        ', adFormat: $adFormat'
        ', adViewId: $adViewId'
        ', networkName: $networkName'
        ', networkPlacement: $networkPlacement'
        ', revenue: $revenue'
        ', revenuePrecision: $revenuePrecision'
        ', creativeId: $creativeId'
        ', dspName: $dspName'
        ', placement: $placement'
        ', latencyMillis: $latencyMillis'
        ', waterfall: $waterfall'
        ', nativeAd: $nativeAd}}';
  }
}

/// Represents a reward given to the user.
class MaxReward {
  /// The rewarded amount.
  final int amount;

  /// The reward label.
  final String label;

  /// @nodoc
  MaxReward(this.amount, this.label);

  @override
  String toString() {
    return '{MaxReward: {amount: $amount, label: $label}}';
  }
}

/// Represents a native ad.
class MaxNativeAd {
  /// The native ad title text.
  final String? title;

  /// The native ad advertiser text.
  final String? advertiser;

  /// The native ad body text.
  final String? body;

  /// The native ad CTA button text.
  final String? callToAction;

  /// The star rating for the native ad, if available. Ranges from `0.0` to `5.0`.
  final double? starRating;

  /// The aspect ratio for the media view if provided by the network.
  final double? mediaContentAspectRatio;

  /// Indicates whether an icon image is available.
  final bool isIconImageAvailable;

  /// Indicates whether an options view is available.
  final bool isOptionsViewAvailable;

  /// Indicates whether a media view is available.
  final bool isMediaViewAvailable;

  /// @nodoc
  MaxNativeAd(this.title, this.advertiser, this.body, this.callToAction, this.starRating, this.mediaContentAspectRatio, this.isIconImageAvailable,
      this.isMediaViewAvailable, this.isOptionsViewAvailable);

  /// @nodoc
  MaxNativeAd.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String?,
        advertiser = json['advertiser'] as String?,
        body = json['body'] as String?,
        callToAction = json['callToAction'] as String?,
        starRating = double.tryParse(json['starRating'].toString()),
        mediaContentAspectRatio = double.tryParse(json['mediaContentAspectRatio'].toString()),
        isIconImageAvailable = json['isIconImageAvailable'] as bool,
        isOptionsViewAvailable = json['isOptionsViewAvailable'] as bool,
        isMediaViewAvailable = json['isMediaViewAvailable'] as bool;

  @override
  String toString() {
    return '{MaxNativeAd: {title: $title'
        ', advertiser: $advertiser'
        ', body: $body'
        ', callToAction: $callToAction'
        ', starRating: $starRating'
        ', mediaContentAspectRatio: $mediaContentAspectRatio'
        ', isIconImageAvailable: $isIconImageAvailable'
        ', isOptionsViewAvailable: $isOptionsViewAvailable'
        ', isMediaViewAvailable: $isMediaViewAvailable}}';
  }
}

/// Encapsulates various data for MAX load and display errors.
class MaxError {
  /// The error code that describes the failure.
  final ErrorCode code;

  /// The error message for the error.
  final String message;

  /// The unique ID of the platform widget AdView.
  final AdViewId? adViewId;

  /// The ad waterfall that resulted in this error, if available.
  final MaxAdWaterfallInfo? waterfall;

  /// @nodoc
  MaxError(this.code, this.message, this.adViewId, this.waterfall);

  /// @nodoc
  factory MaxError.fromJson(Map<String, dynamic> json) {
    ErrorCode code = ErrorCode.fromValue(json['code'] as int);

    AdViewId? adViewId = json['adViewId'] as AdViewId?;

    MaxAdWaterfallInfo? waterfall;
    if (json['waterfall'] != null) {
      var waterfallData = Map<String, dynamic>.from(json['waterfall']);
      if (waterfallData.isNotEmpty) {
        waterfall = MaxAdWaterfallInfo.fromJson(waterfallData);
      }
    }

    return MaxError(code, json['message'] as String, adViewId, waterfall);
  }

  @override
  String toString() {
    return '{MaxError: {code: $code, message: $message, waterfall: $waterfall}}';
  }
}

/// Encapsulates various flags related to the SDK configuration.
class MaxConfiguration {
  /// The country code for this user.
  final String? countryCode;

  /// Whether or not test mode is enabled for this session.
  final bool? isTestModeEnabled;

  /// The user's geography used to determine the type of consent flow shown to the user.
  final ConsentFlowUserGeography? consentFlowUserGeography;

  /// Indicates whether the user has authorized tracking via app-related data.
  final AppTrackingStatus? appTrackingStatus;

  /// @nodoc
  MaxConfiguration(this.countryCode, this.isTestModeEnabled, this.consentFlowUserGeography, this.appTrackingStatus);

  /// @nodoc
  factory MaxConfiguration.fromJson(Map<String, dynamic> json) {
    ConsentFlowUserGeography? consentFlowUserGeography;
    if (json['consentFlowUserGeography'] != null) {
      consentFlowUserGeography =
          ConsentFlowUserGeography.values.firstWhere((v) => v.value == json['consentFlowUserGeography'], orElse: () => ConsentFlowUserGeography.unknown);
    }

    AppTrackingStatus? appTrackingStatus;
    if (json['appTrackingStatus'] != null) {
      appTrackingStatus = AppTrackingStatus.values.firstWhere((v) => v.value == json['appTrackingStatus'], orElse: () => AppTrackingStatus.unavailable);
    }

    return MaxConfiguration(json['countryCode'] as String?, json['isTestModeEnabled'] as bool?, consentFlowUserGeography, appTrackingStatus);
  }

  @override
  String toString() {
    return '{MaxConfiguration: {countryCode: $countryCode'
        ', isTestModeEnabled: $isTestModeEnabled'
        ', consentFlowUserGeography: $consentFlowUserGeography'
        ', appTrackingStatus: $appTrackingStatus}}';
  }
}

/// Represents an error for CMP.
class MaxCMPError {
  /// The error code for this error.
  final CMPErrorCode code;

  /// The error message for this error.
  final String message;

  /// The error code returned by the CMP.
  final int cmpCode;

  /// The error message returned by the CMP.
  final String cmpMessage;

  /// @nodoc
  MaxCMPError(this.code, this.message, this.cmpCode, this.cmpMessage);

  /// @nodoc
  MaxCMPError.fromJson(Map<String, dynamic> json)
      : code = CMPErrorCode.values.firstWhere((v) => v.value == json['code'], orElse: () => CMPErrorCode.unspecified),
        message = json['message'] as String,
        cmpCode = json['cmpCode'] as int,
        cmpMessage = json['cmpMessage'] as String;

  @override
  String toString() {
    return '{MaxCMPError: {code: $code, message: $message, cmpCode: $cmpCode, cmpMessage: $cmpMessage}}';
  }
}

/// Represents an ad waterfall in AppLovin's MAX mediation.
class MaxAdWaterfallInfo {
  /// The ad waterfall name.
  final String name;

  /// The ad waterfall test name.
  final String testName;

  /// The list of [MaxNetworkResponse] info objects relating to each ad in
  /// the waterfall, ordered by their position.
  final List<MaxNetworkResponse> networkResponses;

  /// The total latency in milliseconds for this waterfall to finish processing.
  final int latencyMillis;

  /// @nodoc
  MaxAdWaterfallInfo(this.name, this.testName, this.networkResponses, this.latencyMillis);

  /// @nodoc
  factory MaxAdWaterfallInfo.fromJson(Map<String, dynamic> json) {
    var networkResponses = json['networkResponses'] as List<dynamic>? ?? [];
    List<MaxNetworkResponse> networkResponseList =
        networkResponses.map((response) => MaxNetworkResponse.fromJson(Map<String, dynamic>.from(response))).toList();

    int latencyMillis = int.tryParse(json['latencyMillis']?.toString() ?? '0') ?? 0;

    return MaxAdWaterfallInfo(json['name'] as String? ?? "", json['testName'] as String? ?? "", networkResponseList, latencyMillis);
  }

  @override
  String toString() {
    return '{MaxAdWaterfallInfo: {name: $name'
        ', testName: $testName'
        ', networkResponses: $networkResponses'
        ', latencyMillis: $latencyMillis}}';
  }
}

/// Represents an ad response in a waterfall.
class MaxNetworkResponse {
  /// The state of the ad that this [MaxNetworkResponse] object represents. For
  /// more info, see the [AdLoadState] enum.
  final AdLoadState adLoadState;

  /// The mediated network that this adapter response info object represents.
  final MaxMediatedNetworkInfo mediatedNetwork;

  /// The credentials used to load an ad from this adapter, as entered in the
  /// AppLovin MAX dashboard.
  final Map<String, dynamic> credentials;

  /// The amount of time the network took to load (either successfully or not)
  /// an ad, in seconds. If an attempt to load an ad has not been made (i.e. the
  /// loadState is [AdLoadState.adLoadNotAttempted]), the value will be -1.
  final int latencyMillis;

  /// The ad load error this network response resulted in. Will be null if an
  /// attempt to load an ad has not been made or an ad was loaded successfully
  /// (i.e. the loadState is NOT [AdLoadState.adFailedToLoad]).
  final MaxError? error;

  /// @nodoc
  MaxNetworkResponse(this.adLoadState, this.mediatedNetwork, this.credentials, this.latencyMillis, this.error);

  /// @nodoc
  factory MaxNetworkResponse.fromJson(Map<String, dynamic> json) {
    AdLoadState adLoadState;
    try {
      adLoadState = AdLoadState.values.elementAt(json['adLoadState']);
    } catch (_) {
      adLoadState = AdLoadState.adLoaded;
    }

    MaxMediatedNetworkInfo mediatedNetwork = (json['mediatedNetwork'] is Map)
        ? MaxMediatedNetworkInfo.fromJson(Map<String, dynamic>.from(json['mediatedNetwork']))
        : MaxMediatedNetworkInfo.fromJson({});

    Map<String, dynamic> credentials = (json['credentials'] is Map) ? Map<String, dynamic>.from(json['credentials']) : {};

    int latencyMillis = int.tryParse(json['latencyMillis']?.toString() ?? '0') ?? 0;

    MaxError? error;
    if (json['error'] is Map) {
      error = MaxError.fromJson(Map<String, dynamic>.from(json['error']));
    }

    return MaxNetworkResponse(adLoadState, mediatedNetwork, credentials, latencyMillis, error);
  }

  @override
  String toString() {
    return '{MaxNetworkResponse: {adLoadState: $adLoadState'
        ', mediatedNetwork: $mediatedNetwork'
        ', credentials: $credentials'
        ', latencyMillis: $latencyMillis'
        ', error: $error}}';
  }
}

/// Represents information for a mediated network.
class MaxMediatedNetworkInfo {
  /// The name of the network being mediated.
  final String name;

  /// The class name of the adapter for the mediated network.
  final String adapterClassName;

  /// The version of the adapter for the mediated network.
  final String adapterVersion;

  /// The version of the mediated network’s SDK.
  final String sdkVersion;

  /// @nodoc
  MaxMediatedNetworkInfo(this.name, this.adapterClassName, this.adapterVersion, this.sdkVersion);

  /// @nodoc
  MaxMediatedNetworkInfo.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String? ?? "",
        adapterClassName = json['adapterClassName'] as String? ?? "",
        adapterVersion = json['adapterVersion'] as String? ?? "",
        sdkVersion = json['sdkVersion'] as String? ?? "";

  @override
  String toString() {
    return '{MaxMediatedNetworkInfo: {name: $name'
        ', adapterClassName: $adapterClassName'
        ', adapterVersion: $adapterVersion'
        ', sdkVersion: $sdkVersion}}';
  }
}
