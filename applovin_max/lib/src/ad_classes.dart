/// Represents an ad that has been served by AppLovin MAX.
class MaxAd {
  /// The ad unit ID for which this ad was loaded.
  final String adUnitId;
  /// The ad network from which this ad was loaded.
  final String networkName;
  /// The ad’s revenue amount, or 0 if no revenue amount exists.
  final double revenue;
  /// The creative ID tied to the ad, if any. You can report creative issues to the corresponding ad network using this ID.
  final String creativeId;
  /// The DSP network that provided the loaded ad when the ad is served through AppLovin Exchange.
  final String dspName;
  ///  The placement name that you assign when you integrate each ad format.
  final String placement;
  /// The underlying waterfall of ad responses.
  final Map<String, dynamic> waterfall;

  /// @nodoc
  MaxAd(this.adUnitId, this.networkName, this.revenue, this.creativeId, this.dspName, this.placement, this.waterfall);

  @override
  String toString() {
    return '[MaxAd adUnitId: $adUnitId, networkName: $networkName, revenue: $revenue, dspName: $dspName, creativeId: $creativeId, placement: $placement, waterfall: $waterfall]';
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
