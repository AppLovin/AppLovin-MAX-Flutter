class MaxAd {
  final String adUnitId;
  final String networkName;
  final String revenue;
  final String creativeId;
  final String dspName;

  String? placement;

  MaxAd(this.adUnitId, this.networkName, this.revenue, this.creativeId, this.dspName, this.placement);

  @override
  String toString() {
    return '[MaxAd adUnitId: $adUnitId, networkName: $networkName, revenue: $revenue, dspName: $dspName, creativeId: $creativeId, placement: $placement!]';
  }
}

class MaxReward {
  final int amount;
  final String label;

  MaxReward(this.amount, this.label);

  @override
  String toString() {
    return '[MaxReward amount: $amount, label: $label]';
  }
}

class MaxError {
  final int code;
  final String message;

  MaxError(this.code, this.message);

  @override
  String toString() {
    return '[MaxError code: $code, message: $message]';
  }
}
