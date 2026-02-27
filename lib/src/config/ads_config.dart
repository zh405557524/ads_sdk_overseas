/// 广告 SDK 配置，承载 App ID、各广告位 ID 及 provider 类型。
class AdsConfig {
  /// Android 端 AdMob/Ad Manager 应用 ID
  final String androidAppId;

  /// iOS 端 AdMob/Ad Manager 应用 ID
  final String iosAppId;

  /// 开屏广告位 ID
  final String? splashAdUnitId;

  /// 横幅广告位 ID
  final String? bannerAdUnitId;

  /// 插屏广告位 ID
  final String? interstitialAdUnitId;

  /// 激励视频广告位 ID
  final String? rewardedVideoAdUnitId;

  /// 原生广告位 ID
  final String? nativeAdUnitId;

  /// 信息流广告位 ID（可与原生共用同格式，不同投放位）
  final String? feedAdUnitId;

  /// 广告提供商，如 "google"，预留扩展其他网络
  final String provider;

  const AdsConfig({
    required this.androidAppId,
    required this.iosAppId,
    this.splashAdUnitId,
    this.bannerAdUnitId,
    this.interstitialAdUnitId,
    this.rewardedVideoAdUnitId,
    this.nativeAdUnitId,
    this.feedAdUnitId,
    this.provider = 'google',
  });
}
