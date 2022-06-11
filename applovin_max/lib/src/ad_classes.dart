class MaxAd {
  final String adUnitId;
  final String networkName;
  final String revenue;
  final String placement;
  final String creativeId;

  MaxAd(this.adUnitId, this.networkName, this.revenue, this.placement, this.creativeId);

  @override
  String toString() {
    return "[MaxAd adUnitId: " +
        adUnitId +
        ", networkName: " +
        networkName +
        ", revenue: " +
        revenue +
        ", placement: " +
        placement +
        ", creativeId: " +
        creativeId +
        "]";
  }
}

class MaxReward {
  final int amount;
  final String label;

  MaxReward(this.amount, this.label);

  @override
  String toString() {
    return "[MaxReward amount: " + amount.toString() + ", label: " + label + "]";
  }
}

class MaxError {
  final int code;
  final String message;

  MaxError(this.code, this.message);

  @override
  String toString() {
    return "[MaxError code: " + code.toString() + ", message: " + message + "]";
  }
}
