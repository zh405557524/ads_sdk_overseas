import 'dart:async' as async;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/index.dart';
import '../ad_provider.dart';

/// Google 广告实现，内部使用 [google_mobile_ads]。
class GoogleAdProvider implements AdProvider {
  AdsConfig? _config;

  @override
  Future<void> initialize(AdsConfig config) async {
    _config = config;
    await MobileAds.instance.initialize();
  }

  AdsConfig get _c {
    final c = _config;
    if (c == null) throw StateError('AdsManager not initialized. Call initialize(AdsConfig) first.');
    return c;
  }

  @override
  Future<void> loadAndShowSplashAd() async {
    final id = _c.splashAdUnitId;
    if (id == null || id.isEmpty) throw StateError('splashAdUnitId not set in AdsConfig');
    final completer = _AdCompleter<void>();
    AppOpenAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              completer.complete();
            },
            onAdFailedToShowFullScreenContent: (a, e) {
              a.dispose();
              completer.completeError(e);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (e) => completer.completeError(e),
      ),
    );
    return completer.future;
  }

  @override
  Future<Widget> loadBannerAd() async {
    final id = _c.bannerAdUnitId;
    if (id == null || id.isEmpty) throw StateError('bannerAdUnitId not set in AdsConfig');
    final completer = _AdCompleter<BannerAd>();
    final ad = BannerAd(
      adUnitId: id,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) => completer.complete(loadedAd as BannerAd),
        onAdFailedToLoad: (_, e) => completer.completeError(e),
      ),
    );
    ad.load();
    final loaded = await completer.future;
    return _BannerAdWidget(ad: loaded);
  }

  @override
  Future<void> loadAndShowInterstitialAd() async {
    final id = _c.interstitialAdUnitId;
    if (id == null || id.isEmpty) throw StateError('interstitialAdUnitId not set in AdsConfig');
    final completer = _AdCompleter<void>();
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              completer.complete();
            },
            onAdFailedToShowFullScreenContent: (a, e) {
              a.dispose();
              completer.completeError(e);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (e) => completer.completeError(e),
      ),
    );
    return completer.future;
  }

  @override
  Future<bool> loadAndShowRewardedVideoAd() async {
    final id = _c.rewardedVideoAdUnitId;
    if (id == null || id.isEmpty) throw StateError('rewardedVideoAdUnitId not set in AdsConfig');
    final completer = _AdCompleter<bool>();
    var rewarded = false;
    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              if (!completer.isCompleted) completer.complete(rewarded);
            },
            onAdFailedToShowFullScreenContent: (a, e) {
              a.dispose();
              if (!completer.isCompleted) completer.completeError(e);
            },
          );
          ad.show(onUserEarnedReward: (_, reward) {
            rewarded = true;
          });
        },
        onAdFailedToLoad: (e) => completer.completeError(e),
      ),
    );
    return completer.future;
  }

  @override
  Future<Widget> loadNativeAd() async {
    final id = _c.nativeAdUnitId;
    if (id == null || id.isEmpty) throw StateError('nativeAdUnitId not set in AdsConfig');
    return _loadNativeAdWidget(id);
  }

  @override
  Future<Widget> loadFeedAd() async {
    final id = _c.feedAdUnitId ?? _c.nativeAdUnitId;
    if (id == null || id.isEmpty) throw StateError('feedAdUnitId or nativeAdUnitId not set in AdsConfig');
    return _loadNativeAdWidget(id);
  }

  Future<Widget> _loadNativeAdWidget(String adUnitId) async {
    final completer = _AdCompleter<NativeAd>();
    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) => completer.complete(loadedAd as NativeAd),
        onAdFailedToLoad: (_, e) => completer.completeError(e),
      ),
      nativeAdOptions: NativeAdOptions(
        mediaAspectRatio: MediaAspectRatio.landscape,
      ),
    );
    ad.load();
    final loaded = await completer.future;
    return _NativeAdWidget(ad: loaded);
  }
}

class _AdCompleter<T> {
  final _c = async.Completer<T>();
  bool _done = false;
  bool get isCompleted => _done;
  void complete([T? v]) {
    if (!_done) {
      _done = true;
      _c.complete(v);
    }
  }
  void completeError(Object e) {
    if (!_done) {
      _done = true;
      _c.completeError(e);
    }
  }
  Future<T> get future => _c.future;
}

class _BannerAdWidget extends StatefulWidget {
  final BannerAd ad;

  const _BannerAdWidget({required this.ad});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  @override
  void dispose() {
    widget.ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.ad.size.width.toDouble(),
      height: widget.ad.size.height.toDouble(),
      child: AdWidget(ad: widget.ad),
    );
  }
}

class _NativeAdWidget extends StatefulWidget {
  final NativeAd ad;

  const _NativeAdWidget({required this.ad});

  @override
  State<_NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<_NativeAdWidget> {
  @override
  void dispose() {
    widget.ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdWidget(ad: widget.ad);
  }
}
