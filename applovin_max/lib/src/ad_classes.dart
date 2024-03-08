import 'package:applovin_max/src/enums.dart';

/// Represents an ad that has been served by AppLovin MAX.
class MaxAd {
  /// The ad unit ID for which this ad was loaded.
  final String adUnitId;

  /// The ad network from which this ad was loaded.
  final String networkName;

  /// The ad’s revenue amount, or 0 if no revenue amount exists.
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

  /// The creative ID tied to the ad, if any. You can report creative issues to the corresponding ad network using this ID.
  final String creativeId;

  /// The DSP network that provided the loaded ad when the ad is served through AppLovin Exchange.
  final String dspName;

  ///  The placement name that you assign when you integrate each ad format.
  final String placement;

  /// The underlying waterfall of ad responses.
  final MaxAdWaterfallInfo waterfall;

  /// An instance of [MaxNativeAd], available only for native ads
  final MaxNativeAd? nativeAd;

  /// @nodoc
  MaxAd(this.adUnitId, this.networkName, this.revenue, this.revenuePrecision, this.creativeId, this.dspName, this.placement, this.waterfall, this.nativeAd);

  /// @nodoc
  factory MaxAd.fromJson(Map<String, dynamic> json) {
    double? revenue = double.tryParse(json['revenue'].toString());
    revenue ??= 0.0;

    MaxNativeAd? nativeAd;
    var nativeAdData = json['nativeAd'];
    if (nativeAdData is Map) {
      nativeAd = MaxNativeAd.fromJson(Map<String, dynamic>.from(nativeAdData));
    }

    return MaxAd(
      json['adUnitId'],
      json['networkName'],
      revenue,
      json['revenuePrecision'],
      json['creativeId'],
      json['dspName'],
      json['placement'],
      MaxAdWaterfallInfo.fromJson(Map<String, dynamic>.from(json['waterfall'])),
      nativeAd,
    );
  }

  @override
  String toString() {
    return '[MaxAd adUnitId: $adUnitId, networkName: $networkName, revenue: $revenue'
        ', revenuePrecision: $revenuePrecision, dspName: $dspName, creativeId: $creativeId'
        ', placement: $placement, waterfall: $waterfall, nativeAd: $nativeAd]';
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
    return '[MaxReward amount: $amount, label: $label]';
  }
}

/// Represents a native ad
class MaxNativeAd {
  /// The native ad title text.
  final String? title;

  /// The native ad advertiser text
  final String? advertiser;

  /// The native ad body text
  final String? body;

  /// The native ad CTA button text.
  final String? callToAction;

  /// The star rating of the native ad in the [0.0, 5.0] range if provided by the network.
  final double? starRating;

  /// The aspect ratio for the media view if provided by the network
  final double? mediaContentAspectRatio;

  /// Whether or not the icon image is available.
  final bool isIconImageAvailable;

  /// Whether or not the options image is available.
  final bool isOptionsViewAvailable;

  /// Whether or not the media view is available.
  final bool isMediaViewAvailable;

  /// @nodoc
  MaxNativeAd(this.title, this.advertiser, this.body, this.callToAction, this.starRating, this.mediaContentAspectRatio, this.isIconImageAvailable,
      this.isMediaViewAvailable, this.isOptionsViewAvailable);

  /// @nodoc
  MaxNativeAd.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        advertiser = json['advertiser'],
        body = json['body'],
        callToAction = json['callToAction'],
        starRating = double.tryParse(json['starRating'].toString()),
        mediaContentAspectRatio = double.tryParse(json['mediaContentAspectRatio'].toString()),
        isIconImageAvailable = json['isIconImageAvailable'],
        isOptionsViewAvailable = json['isOptionsViewAvailable'],
        isMediaViewAvailable = json['isMediaViewAvailable'];

  @override
  String toString() {
    return '[MaxNativeAd title: $title, advertiser: $advertiser, body: $body, callToAction: $callToAction'
        ', starRating: $starRating, mediaContentAspectRatio: $mediaContentAspectRatio'
        ', isIconImageAvailable: $isIconImageAvailable, isMediaViewAvailable: $isMediaViewAvailable'
        ', isOptionsViewAvailable: $isOptionsViewAvailable]';
  }
}

/// Encapsulates various data for MAX load and display errors.
class MaxError {
  /// The error code for the error.
  final int code;

  /// The error message for the error.
  final String message;

  /// The underlying waterfall of ad responses.
  final MaxAdWaterfallInfo? waterfall;

  /// @nodoc
  MaxError(this.code, this.message, this.waterfall);

  /// @nodoc
  factory MaxError.fromJson(Map<String, dynamic> json) {
    MaxAdWaterfallInfo? waterfall;
    var waterfallData = Map<String, dynamic>.from(json['waterfall']);
    if (waterfallData.isNotEmpty) {
      waterfall = MaxAdWaterfallInfo.fromJson(waterfallData);
    }

    return MaxError(json['code'], json['message'], waterfall);
  }

  @override
  String toString() {
    return '[MaxError code: $code, message: $message, waterfall: $waterfall]';
  }
}

/// Encapsulates various flags related to the SDK configuration.
class MaxConfiguration {
  /// The state of the consent dialog.
  @Deprecated('Use ConsentFlowUserGeography instead.')
  final ConsentDialogState consentDialogState;

  /// The country code for this user.
  final String? countryCode;

  /// Whether or not test mode is enabled for this session.
  final bool? isTestModeEnabled;

  /// The user's geography used to determine the type of consent flow shown to the user.
  final ConsentFlowUserGeography? consentFlowUserGeography;

  // Whether or not the user authorizes access to app-related data that can be
  // used for tracking the user or the device.
  final AppTrackingStatus? appTrackingStatus;

  /// @nodoc
  MaxConfiguration(this.consentDialogState, this.countryCode, this.isTestModeEnabled, this.consentFlowUserGeography, this.appTrackingStatus);

  /// @nodoc
  factory MaxConfiguration.fromJson(Map<String, dynamic> json) {
    late ConsentDialogState consentDialogState;
    try {
      consentDialogState = ConsentDialogState.values.elementAt(json['consentDialogState']);
    } catch (_) {
      consentDialogState = ConsentDialogState.unknown;
    }

    String? countryCode = json['countryCode'];

    bool? isTestModeEnabled = json['isTestModeEnabled'];

    dynamic consentFlowUserGeography = json['consentFlowUserGeography'];
    if (consentFlowUserGeography != null) {
      consentFlowUserGeography =
          ConsentFlowUserGeography.values.firstWhere((v) => v.value == consentFlowUserGeography, orElse: () => ConsentFlowUserGeography.unknown);
    }

    dynamic appTrackingStatus = json['appTrackingStatus'];
    if (appTrackingStatus != null) {
      appTrackingStatus = AppTrackingStatus.values.firstWhere((v) => v.value == appTrackingStatus, orElse: () => AppTrackingStatus.unavailable);
    }

    return MaxConfiguration(consentDialogState, countryCode, isTestModeEnabled, consentFlowUserGeography, appTrackingStatus);
  }

  @override
  String toString() {
    return '[MaxConfiguration consentDialogState: $consentDialogState, countryCode: $countryCode'
        ', isTestModeEnabled: $isTestModeEnabled, consentFlowUserGeography: $consentFlowUserGeography'
        ', appTrackingStatus: $appTrackingStatus]';
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
      : code = CMPErrorCode.values.firstWhere((v) => v.value == json['code']),
        message = json['message'],
        cmpCode = json['cmpCode'],
        cmpMessage = json['cmpMessage'];

  @override
  String toString() {
    return '[MaxCMPError code: $code, message: $message, cmpCode: $cmpCode, cmpMessage: $cmpMessage]';
  }
}

/// Represents an ad waterfall, encapsulating various metadata such as total
/// latency, underlying ad responses, etc.
class MaxAdWaterfallInfo {
  /// The ad waterfall name.
  final String name;

  /// The ad waterfall test name.
  final String testName;

  /// The list of [MAAdapterResponseInfo] info objects relating to each ad in
  /// the waterfall, ordered by their position.
  final List<MaxNetworkResponse> networkResponses;

  /// The total latency in seconds for this waterfall to finish processing.
  final double latency;

  /// @nodoc
  MaxAdWaterfallInfo(this.name, this.testName, this.networkResponses, this.latency);

  /// @nodoc
  factory MaxAdWaterfallInfo.fromJson(Map<String, dynamic> json) {
    List<MaxNetworkResponse> networkResponseList = [];
    var networkResponses = json['networkResponses'];
    if (networkResponses is List) {
      for (var networkResponse in networkResponses) {
        if (networkResponse is Map) {
          networkResponseList.add(MaxNetworkResponse.fromJson(Map<String, dynamic>.from(networkResponse)));
        }
      }
    }

    double? latency = double.tryParse(json['latencyMillis'].toString());
    latency = latency ?? 0.0;

    return MaxAdWaterfallInfo(json['name'] ?? "", json['testName'] ?? "", networkResponseList, latency);
  }

  @override
  String toString() {
    return '[MaxAdWaterfallInfo name: $name, testName: $testName, networkResponses: $networkResponses, latency: $latency]';
  }
}

/// Represents an ad response in a waterfall.
class MaxNetworkResponse {
  /// The state of the ad that this [MAAdapterResponseInfo] object
  /// represents. For more info, see the [AdLoadState] enum.
  final AdLoadState adLoadState;

  /// The mediated network that this adapter response info object represents.
  final MaxMediatedNetworkInfo mediatedNetwork;

  /// The credentials used to load an ad from this adapter, as entered in the AppLovin MAX dashboard.
  final Map<String, dynamic> credentials;

  /// The amount of time the network took to load (either successfully or not)
  /// an ad, in seconds. If an attempt to load an ad has not been made (i.e. the
  /// loadState is [AdLoadState.adLoadNotAttempted]), the value will be -1.
  final double latency;

  /// The ad load error this network response resulted in. Will be null if an
  /// attempt to load an ad has not been made or an ad was loaded successfully
  /// (i.e. the loadState is NOT [AdLoadState.adFailedToLoad]).
  final MaxError? error;

  /// @nodoc
  MaxNetworkResponse(this.adLoadState, this.mediatedNetwork, this.credentials, this.latency, this.error);

  /// @nodoc
  factory MaxNetworkResponse.fromJson(Map<String, dynamic> json) {
    late AdLoadState adLoadState;
    try {
      adLoadState = AdLoadState.values.elementAt(json['adLoadState']);
    } catch (_) {
      adLoadState = AdLoadState.adLoaded;
    }

    late MaxMediatedNetworkInfo mediatedNetwork;
    var mediatedNetworkData = json['mediatedNetwork'];
    if (mediatedNetworkData is Map) {
      mediatedNetwork = MaxMediatedNetworkInfo.fromJson(Map<String, dynamic>.from(mediatedNetworkData));
    } else {
      mediatedNetwork = MaxMediatedNetworkInfo.fromJson({});
    }

    late Map<String, dynamic> credentials;
    var credentialsData = json['credentials'];
    if (credentialsData is Map) {
      credentials = Map<String, dynamic>.from(credentialsData);
    } else {
      credentials = {};
    }

    double? latency = double.tryParse(json['latencyMillis'].toString());
    latency ??= 0.0;

    MaxError? error;
    var errorData = json['error'];
    if (errorData is Map) {
      error = MaxError.fromJson(Map<String, dynamic>.from(errorData));
    }

    return MaxNetworkResponse(adLoadState, mediatedNetwork, credentials, latency, error);
  }

  @override
  String toString() {
    return '[MaxNetworkResponse adLoadState: $adLoadState, mediatedNetwork: $mediatedNetwork'
        ', credentials: $credentials, latency: $latency, error: $error]';
  }
}

/// Represents information for a mediated network.
class MaxMediatedNetworkInfo {
  /// The name of the mediated network.
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
      : name = json['name'] ?? "",
        adapterClassName = json['adapterClassName'] ?? "",
        adapterVersion = json['adapterVersion'] ?? "",
        sdkVersion = json['sdkVersion'] ?? "";

  @override
  String toString() {
    return '[MaxMediatedNetworkInfo name: $name, adapterClassName: $adapterClassName'
        ', adapterVersion: $adapterVersion, sdkVersion: $sdkVersion]';
  }
}
