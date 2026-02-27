import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ads_sdk_overseas_platform_interface.dart';

/// An implementation of [AdsSdkOverseasPlatform] that uses method channels.
class MethodChannelAdsSdkOverseas extends AdsSdkOverseasPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ads_sdk_overseas');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
