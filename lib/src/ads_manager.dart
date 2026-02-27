import 'package:flutter/widgets.dart';

import 'config/index.dart';
import 'ad_provider.dart';
import 'google/index.dart';

/// 广告管理类，对外统一入口。提供初始化及 6 种广告类型（开屏、横幅、插屏、激励视频、原生、信息流）的加载/展示方法。
class AdsManager {
  AdProvider? _provider;

  /// 初始化 SDK，传入 [AdsConfig]（含 App ID、各广告位 ID 等）。
  /// 根据 [AdsConfig.provider] 选择内部实现，当前仅支持 "google"。
  Future<void> initialize(AdsConfig config) async {
    switch (config.provider) {
      case 'google':
        _provider = GoogleAdProvider();
        break;
      default:
        throw ArgumentError('Unsupported provider: ${config.provider}');
    }
    await _provider!.initialize(config);
  }

  AdProvider get _p {
    final p = _provider;
    if (p == null) throw StateError('AdsManager not initialized. Call initialize(AdsConfig) first.');
    return p;
  }

  /// 开屏广告：加载并展示
  Future<void> loadAndShowSplashAd() => _p.loadAndShowSplashAd();

  /// 横幅广告：加载并返回可嵌入的 Widget
  Future<Widget> loadBannerAd() => _p.loadBannerAd();

  /// 插屏广告：加载并展示
  Future<void> loadAndShowInterstitialAd() => _p.loadAndShowInterstitialAd();

  /// 激励视频：加载、展示，返回是否获得奖励
  Future<bool> loadAndShowRewardedVideoAd() => _p.loadAndShowRewardedVideoAd();

  /// 原生广告：加载并返回可嵌入的 Widget
  Future<Widget> loadNativeAd() => _p.loadNativeAd();

  /// 信息流广告：加载并返回可嵌入列表的 Widget
  Future<Widget> loadFeedAd() => _p.loadFeedAd();
}
