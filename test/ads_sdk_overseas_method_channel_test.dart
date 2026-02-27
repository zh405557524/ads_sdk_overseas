import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ads_sdk_overseas/ads_sdk_overseas_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAdsSdkOverseas platform = MethodChannelAdsSdkOverseas();
  const MethodChannel channel = MethodChannel('ads_sdk_overseas');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
