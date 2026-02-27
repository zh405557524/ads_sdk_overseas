import 'ads_sdk_overseas_platform_interface.dart';

export 'src/config/index.dart';
export 'src/ads_manager.dart';

class AdsSdkOverseas {
  Future<String?> getPlatformVersion() {
    return AdsSdkOverseasPlatform.instance.getPlatformVersion();
  }
}
