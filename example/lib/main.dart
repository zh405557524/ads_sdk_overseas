import 'package:flutter/material.dart';
import 'package:ads_sdk_overseas/ads_sdk_overseas.dart';

import 'pages/ads_demo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adsManager = AdsManager();
  await adsManager.initialize(const AdsConfig(
    androidAppId: 'ca-app-pub-3940256099942544~3347511713',
    iosAppId: 'ca-app-pub-3940256099942544~1458002511',
    splashAdUnitId: 'ca-app-pub-3940256099942544/9257395921',
    bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111',
    interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
    rewardedVideoAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
    nativeAdUnitId: 'ca-app-pub-3940256099942544/2247696110',
    feedAdUnitId: 'ca-app-pub-3940256099942544/2247696110',
    provider: 'google',
  ));
  runApp(MaterialApp(
    title: 'Ads SDK Overseas Example',
    home: AdsDemoPage(adsManager: adsManager),
  ));
}
