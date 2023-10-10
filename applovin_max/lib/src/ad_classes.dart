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
  final Map<String, dynamic> waterfall;

  /// An instance of [MaxNativeAd], available only for native ads
  final MaxNativeAd? nativeAd;

  /// @nodoc
  MaxAd(this.adUnitId, this.networkName, this.revenue, this.revenuePrecision, this.creativeId, this.dspName, this.placement, this.waterfall, this.nativeAd);

  @override
  String toString() {
    return '[MaxAd adUnitId: $adUnitId, networkName: $networkName, revenue: $revenue, revenuePrecision: $revenuePrecision, dspName: $dspName, creativeId: $creativeId, placement: $placement, waterfall: $waterfall, nativeAd: $nativeAd]';
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
  MaxNativeAd(
      {this.title,
      this.advertiser,
      this.body,
      this.callToAction,
      this.starRating,
      this.mediaContentAspectRatio,
      this.isIconImageAvailable = false,
      this.isMediaViewAvailable = false,
      this.isOptionsViewAvailable = false});

  /// @nodoc
  MaxNativeAd.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        advertiser = json['advertiser'],
        body = json['body'],
        callToAction = json['callToAction'],
        starRating = json['starRating'],
        mediaContentAspectRatio = json['mediaContentAspectRatio'],
        isIconImageAvailable = (json['isIconImageAvailable'].runtimeType == int) ? (json['isIconImageAvailable'] == 1) : json['isIconImageAvailable'],
        isOptionsViewAvailable = (json['isOptionsViewAvailable'].runtimeType == int) ? (json['isOptionsViewAvailable'] == 1) : json['isOptionsViewAvailable'],
        isMediaViewAvailable = (json['isMediaViewAvailable'].runtimeType == int) ? (json['isMediaViewAvailable'] == 1) : json['isMediaViewAvailable'];

  @override
  String toString() {
    return '[MaxNativeAd title: $title, advertiser: $advertiser, body: $body, callToAction: $callToAction, '
        'starRating: $starRating, mediaContentAspectRatio: $mediaContentAspectRatio, '
        'isIconImageAvailable: $isIconImageAvailable, isMediaViewAvailable: $isMediaViewAvailable, isOptionsViewAvailable: $isOptionsViewAvailable]';
  }
}

/// Encapsulates various data for MAX load and display errors.
class MaxError {
  /// The error code for the error.
  final int code;

  /// The error message for the error.
  final String message;

  /// The underlying waterfall of ad responses.
  final Map<String, dynamic> waterfall;

  /// @nodoc
  MaxError(this.code, this.message, this.waterfall);

  @override
  String toString() {
    return '[MaxError code: $code, message: $message, waterfall: $waterfall]';
  }
}
