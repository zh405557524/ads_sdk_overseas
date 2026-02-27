import 'package:flutter_test/flutter_test.dart';
import 'package:ads_sdk_overseas/ads_sdk_overseas.dart';
import 'package:ads_sdk_overseas/ads_sdk_overseas_platform_interface.dart';
import 'package:ads_sdk_overseas/ads_sdk_overseas_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdsSdkOverseasPlatform
    with MockPlatformInterfaceMixin
    implements AdsSdkOverseasPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AdsSdkOverseasPlatform initialPlatform = AdsSdkOverseasPlatform.instance;

  test('$MethodChannelAdsSdkOverseas is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAdsSdkOverseas>());
  });

  test('getPlatformVersion', () async {
    AdsSdkOverseas adsSdkOverseasPlugin = AdsSdkOverseas();
    MockAdsSdkOverseasPlatform fakePlatform = MockAdsSdkOverseasPlatform();
    AdsSdkOverseasPlatform.instance = fakePlatform;

    expect(await adsSdkOverseasPlugin.getPlatformVersion(), '42');
  });
}
