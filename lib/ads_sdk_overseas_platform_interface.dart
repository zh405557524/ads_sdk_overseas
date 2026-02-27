import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ads_sdk_overseas_method_channel.dart';

abstract class AdsSdkOverseasPlatform extends PlatformInterface {
  /// Constructs a AdsSdkOverseasPlatform.
  AdsSdkOverseasPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdsSdkOverseasPlatform _instance = MethodChannelAdsSdkOverseas();

  /// The default instance of [AdsSdkOverseasPlatform] to use.
  ///
  /// Defaults to [MethodChannelAdsSdkOverseas].
  static AdsSdkOverseasPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AdsSdkOverseasPlatform] when
  /// they register themselves.
  static set instance(AdsSdkOverseasPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
