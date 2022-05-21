import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'applovin_max_method_channel.dart';

abstract class ApplovinMaxPlatform extends PlatformInterface {
  /// Constructs a ApplovinMaxPlatform.
  ApplovinMaxPlatform() : super(token: _token);

  static final Object _token = Object();

  static ApplovinMaxPlatform _instance = MethodChannelApplovinMax();

  /// The default instance of [ApplovinMaxPlatform] to use.
  ///
  /// Defaults to [MethodChannelApplovinMax].
  static ApplovinMaxPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ApplovinMaxPlatform] when
  /// they register themselves.
  static set instance(ApplovinMaxPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
