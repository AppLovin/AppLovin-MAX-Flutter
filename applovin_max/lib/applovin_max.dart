import 'applovin_max_platform_interface.dart';

class ApplovinMax {
  Future<String?> getPlatformVersion() {
    return ApplovinMaxPlatform.instance.getPlatformVersion();
  }
}
