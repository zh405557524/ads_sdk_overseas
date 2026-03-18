# ads_sdk_overseas

海外广告 SDK，基于 Google Mobile Ads（AdMob），提供开屏、横幅、插屏、激励视频、原生、信息流等广告能力。

---

## 依赖添加

在应用的 `pubspec.yaml` 中增加：

```yaml
dependencies:
  ads_sdk_overseas: ^0.0.1  # 或使用 path 引用本地
```

然后执行：

```bash
flutter pub get
```

---

## 平台配置

### Android

在 `android/app/src/main/AndroidManifest.xml` 的 `<application>` 内添加 AdMob 应用 ID（与 [AdsConfig](#初始化) 中的 `androidAppId` 保持一致或在此写死）：

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

将 `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` 替换为你在 AdMob 后台创建的 Android 应用 ID。

### iOS

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~zzzzzzzzzz</string>
```

将字符串替换为你在 AdMob 后台创建的 iOS 应用 ID。

---

## 初始化

在 `main()` 中、`runApp()` 之前完成 SDK 初始化，并传入 [AdsConfig](lib/src/config/ads_config.dart)（包含 App ID 与各广告位 ID）：

```dart
import 'package:ads_sdk_overseas/ads_sdk_overseas.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adsManager = AdsManager();
  await adsManager.initialize(const AdsConfig(
    androidAppId: 'ca-app-pub-xxx~android',
    iosAppId: 'ca-app-pub-xxx~ios',
    splashAdUnitId: 'ca-app-pub-xxx/开屏广告位ID',
    bannerAdUnitId: 'ca-app-pub-xxx/横幅广告位ID',
    interstitialAdUnitId: 'ca-app-pub-xxx/插屏广告位ID',
    rewardedVideoAdUnitId: 'ca-app-pub-xxx/激励视频广告位ID',
    nativeAdUnitId: 'ca-app-pub-xxx/原生广告位ID',
    feedAdUnitId: 'ca-app-pub-xxx/信息流广告位ID',
    provider: 'google',
  ));
  runApp(MyApp(adsManager: adsManager));
}
```

- 未使用的广告类型可传 `null`（如只做开屏则其余可为 `null`）。
- 测试时可使用 [Google 官方测试 ID](https://developers.google.com/admob/android/test-ads)。

---

## 广告类型与使用

| 类型       | 方法 | 说明 |
|------------|------|------|
| 开屏       | `loadAndShowSplashAd()` | 加载并全屏展示，关闭后返回 |
| 横幅       | `loadBannerAd()` | 返回 Widget，需嵌入布局 |
| 插屏       | `loadAndShowInterstitialAd()` | 加载并弹窗展示 |
| 激励视频   | `loadAndShowRewardedVideoAd()` | 加载并播放，返回是否获得奖励 |
| 原生       | `loadNativeAd()` | 返回 Widget，可嵌入任意位置 |
| 信息流     | `loadFeedAd()` | 返回 Widget，适合列表内展示 |

### 开屏广告

```dart
try {
  await adsManager.loadAndShowSplashAd();
  // 用户关闭开屏后继续
} catch (e) {
  // 加载或展示失败
}
```

### 横幅广告

```dart
try {
  final bannerWidget = await adsManager.loadBannerAd();
  // 将 bannerWidget 放入 Column、Stack 等
  return Column(children: [bannerWidget, ...]);
} catch (e) {
  // 加载失败
}
```

### 插屏广告

```dart
try {
  await adsManager.loadAndShowInterstitialAd();
  // 用户关闭插屏后继续
} catch (e) {
  // 加载或展示失败
}
```

### 激励视频

```dart
try {
  final rewarded = await adsManager.loadAndShowRewardedVideoAd();
  if (rewarded) {
    // 用户看完广告，发放奖励
  } else {
    // 未看完或未获得奖励
  }
} catch (e) {
  // 加载或展示失败
}
```

### 原生 / 信息流广告

```dart
try {
  final nativeWidget = await adsManager.loadNativeAd();
  // 或 final feedWidget = await adsManager.loadFeedAd();
  // 将返回的 Widget 放入列表或布局
  return SizedBox(height: 120, child: nativeWidget);
} catch (e) {
  // 加载失败
}
```

---

## 示例工程

`example` 目录为完整演示应用，包含上述 6 种广告的调用与展示。运行示例：

```bash
cd example && flutter run
```

---

## 注意事项

1. **先初始化再调用**：所有广告相关方法需在 `AdsManager.initialize(AdsConfig)` 成功之后调用，否则会抛出 `StateError`。
2. **主线程**：初始化与广告调用建议在 UI 线程（Flutter 主 isolate）执行。
3. **错误处理**：加载/展示可能失败（网络、填充、配置等），请对接口做 try-catch 并做友好提示或降级。
4. **上架前替换 ID**：正式环境请将测试广告位 ID 与 App ID 替换为 AdMob 后台申请的真实 ID。
