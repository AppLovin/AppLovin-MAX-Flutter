import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'applovin_max_platform_interface.dart';

/// An implementation of [ApplovinMaxPlatform] that uses method channels.
class MethodChannelApplovinMax extends ApplovinMaxPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('applovin_max');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
