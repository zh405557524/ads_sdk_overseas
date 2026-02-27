
import 'ads_sdk_overseas_platform_interface.dart';

class AdsSdkOverseas {
  Future<String?> getPlatformVersion() {
    return AdsSdkOverseasPlatform.instance.getPlatformVersion();
  }
}
