import 'package:flutter/widgets.dart';

import 'config/index.dart';

/// 广告提供商抽象接口，定义各类型广告的加载/展示契约。
/// 具体实现由 [GoogleAdProvider] 等提供。
abstract class AdProvider {
  /// 使用 [AdsConfig] 初始化底层 SDK
  Future<void> initialize(AdsConfig config);

  /// 开屏广告：加载并展示
  Future<void> loadAndShowSplashAd();

  /// 横幅广告：加载并返回可嵌入的 Widget
  Future<Widget> loadBannerAd();

  /// 插屏广告：加载并展示
  Future<void> loadAndShowInterstitialAd();

  /// 激励视频：加载、展示，返回是否获得奖励
  Future<bool> loadAndShowRewardedVideoAd();

  /// 原生广告：加载并返回可嵌入的 Widget
  Future<Widget> loadNativeAd();

  /// 信息流广告：加载并返回可嵌入列表的 Widget
  Future<Widget> loadFeedAd();
}
