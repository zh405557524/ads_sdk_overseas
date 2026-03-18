import 'dart:async' as async;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/index.dart';
import '../ad_provider.dart';

enum _AdElementType {
  splash,
}

class _AdElementNode {
  /// 广告类型（当前仅用于开屏）。
  final _AdElementType type;

  /// 广告对象。由于不同广告类型对象不同，这里用 Object 承载。
  /// 开屏广告场景下为 [AppOpenAd]。
  final Object ad;

  /// 创建/加载完成时间，用于 4 小时有效期判断。
  final DateTime createdAt;

  /// 该节点的唯一标识（用于排查/调试，或未来扩展时做去重/追踪）。
  final int token;

  /// 是否已被关闭（dismiss、failedToShow、或被 closeSplashAd 主动关闭）。
  bool isClosed;

  /// 单链表 next 指针（最新节点通常在头部）。
  _AdElementNode? next;

  _AdElementNode({
    required this.type,
    required this.ad,
    required this.createdAt,
    required this.token,
    this.isClosed = false,
    this.next,
  });
}

/// Google 广告实现，内部使用 [google_mobile_ads]。
class GoogleAdProvider implements AdProvider {
  AdsConfig? _config;

  /// 开屏广告缓存队列（单链表实现）。
  ///
  /// - 头节点：最早进入队列的广告（优先被取出使用）
  /// - 尾节点：最新进入队列的广告（追加到队尾）
  _AdElementNode? _splashHead;
  _AdElementNode? _splashTail;

  /// 用于标识“本次 loadAndShowSplashAd 调用”的请求 id（自增）。
  int _splashRequestSeq = 0;

  /// 当前仍然有效的请求 id。
  /// - 每次进入 loadAndShowSplashAd 会设置为当次 requestId
  /// - 调用 closeSplashAd 会将其置空，表示当前调用已失效，后续异步流程不应再触发展示
  int? _activeSplashRequestId;

  /// 当前正在展示（或即将展示）的开屏广告实例。
  ///
  /// 用于支持 closeSplashAd() 主动关闭广告：
  /// - 不影响队列缓存（队列里的是“未展示”的广告）
  /// - 只关闭当前这次正在展示的实例
  AppOpenAd? _showingSplashAd;

  static const Duration _splashValidDuration = Duration(hours: 4);

  /// 开屏广告缓存上限，防止无限增长（淘汰链表尾部）。
  static const int _maxSplashCacheSize = 5;

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

  /// 判断某次调用（requestId）是否仍然有效。
  bool _isSplashRequestActive(int requestId) => _activeSplashRequestId == requestId;

  /// 主动关闭当前正在展示的开屏广告（如果存在）。
  void _closeShowingSplashAd() {
    final ad = _showingSplashAd;
    _showingSplashAd = null;
    if (ad == null) return;
    try {
      ad.dispose();
    } catch (_) {
      // 容错：重复 dispose 或平台异常不应导致崩溃。
    }
  }

  /// 判定节点是否已过期开屏广告有效期。
  bool _isSplashExpired(_AdElementNode node, DateTime now) {
    return now.difference(node.createdAt) >= _splashValidDuration;
  }

  /// 释放节点中持有的广告对象。
  ///
  /// 注意：有些 SDK 实现可能在重复 dispose 时抛错，这里做容错，
  /// 避免因为竞态（比如 close 与回调同时触发）导致崩溃。
  void _disposeSplashNodeAd(_AdElementNode node) {
    final ad = node.ad;
    if (ad is AppOpenAd) {
      try {
        ad.dispose();
      } catch (_) {
        // dispose 重复调用在某些实现下可能抛错，这里做容错处理。
      }
    }
  }

  /// 将节点从链表中移除，并在移除时释放广告对象。
  _AdElementNode? _removeSplashNode({
    required _AdElementNode? prev,
    required _AdElementNode current,
  }) {
    final next = current.next;
    _disposeSplashNodeAd(current);
    if (prev == null) {
      _splashHead = next;
    } else {
      prev.next = next;
    }
    if (_splashTail == current) {
      _splashTail = prev;
    }
    current.next = null;
    return next;
  }

  /// 将节点追加到队列尾部。
  void _enqueueSplashNode(_AdElementNode node) {
    node.next = null;
    final tail = _splashTail;
    if (tail == null) {
      _splashHead = node;
      _splashTail = node;
    } else {
      tail.next = node;
      _splashTail = node;
    }
  }

  /// 清理链表中的无效节点：已关闭、已过期，并裁剪链表长度，避免无限缓存。
  ///
  /// 清理策略：
  /// - `isClosed == true`：不会再展示，直接移除
  /// - 超过 4 小时：认为已过期，直接移除
  /// - 超过缓存上限：从尾部开始淘汰
  void _pruneSplashList() {
    final now = DateTime.now();
    _AdElementNode? prev;
    var current = _splashHead;
    var kept = 0;

    while (current != null) {
      final shouldRemove = current.isClosed || _isSplashExpired(current, now);
      if (shouldRemove) {
        current = _removeSplashNode(prev: prev, current: current);
        continue;
      }

      kept += 1;
      if (kept > _maxSplashCacheSize) {
        // 超出最大缓存数量，淘汰尾部剩余节点（从当前节点开始都移除）。
        while (current != null) {
          current = _removeSplashNode(prev: prev, current: current);
        }
        break;
      }

      prev = current;
      current = current.next;
    }
  }

  /// 遍历队列，取出一个当前可用的开屏广告节点。
  ///
  /// 规则（按你的描述实现成队列语义）：
  /// - 遍历队列找到第一个可用广告，**取到就从队列移除并返回**
  /// - 过程中发现失效广告（已关闭/已过期/类型不对/对象不对）会直接从队列移除
  /// - 若取不到可用广告，返回 null
  _AdElementNode? _dequeueUsableSplashNode() {
    final now = DateTime.now();
    _AdElementNode? prev;
    var current = _splashHead;

    while (current != null) {
      final validType = current.type == _AdElementType.splash;
      final validAd = current.ad is AppOpenAd;
      final expired = _isSplashExpired(current, now);
      final invalid = current.isClosed || expired || !validType || !validAd;

      if (invalid) {
        current = _removeSplashNode(prev: prev, current: current);
        continue;
      }

      // 命中可用广告：从队列移除，但不 dispose（因为要拿去展示）。
      final next = current.next;
      if (prev == null) {
        _splashHead = next;
      } else {
        prev.next = next;
      }
      if (_splashTail == current) {
        _splashTail = prev;
      }
      current.next = null;
      return current;
    }

    return null;
  }

  @override
  Future<bool> loadAndShowSplashAd() async {
    final id = _c.splashAdUnitId;
    if (id == null || id.isEmpty) throw StateError('splashAdUnitId not set in AdsConfig');

    // 本次调用的 requestId：用于判断是否被 closeSplashAd 标记失效。
    final requestId = ++_splashRequestSeq;
    _activeSplashRequestId = requestId;

    // 先做一次清理：移除过期/关闭节点，并裁剪长度，避免队列无限增长。
    _pruneSplashList();

    // 1) 遍历队列取出一个可用广告（取到就出队）。
    final cached = _dequeueUsableSplashNode();
    if (cached != null && cached.ad is AppOpenAd) {
      final completer = _AdCompleter<bool>();
      final ad = cached.ad as AppOpenAd;

      // 2) 缓存广告不为 null，直接展示（展示前仍需要判断是否被 close 置为失效）。
      if (!_isSplashRequestActive(requestId) || cached.isClosed || _isSplashExpired(cached, DateTime.now())) {
        // 当前调用已失效：不展示，把广告重新加入队列以便下次复用。
        _enqueueSplashNode(cached);
        _pruneSplashList();
        completer.complete(false);
        return completer.future;
      }

      _showingSplashAd = ad;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          cached.isClosed = true;
          if (identical(_showingSplashAd, a)) _showingSplashAd = null;
          a.dispose();
          completer.complete(true);
        },
        onAdFailedToShowFullScreenContent: (a, e) {
          cached.isClosed = true;
          if (identical(_showingSplashAd, a)) _showingSplashAd = null;
          a.dispose();
          completer.complete(false);
        },
      );

      try {
        ad.show();
      } catch (_) {
        cached.isClosed = true;
        if (identical(_showingSplashAd, ad)) _showingSplashAd = null;
        _disposeSplashNodeAd(cached);
        completer.complete(false);
      }
      return completer.future;
    }

    // 3) 缓存中拿不到广告，则去加载广告。
    final completer = _AdCompleter<bool>();
    final nodeToken = DateTime.now().microsecondsSinceEpoch;
    AppOpenAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          // 4) 加载成功后：先构建节点（此时是否展示取决于 request 是否仍有效）。
          final node = _AdElementNode(
            type: _AdElementType.splash,
            ad: ad,
            createdAt: DateTime.now(),
            token: nodeToken,
          );

          // 若调用了 closeSplashAd，说明当前 loadAndShowSplashAd 已失效，不能展示：仅加入队列缓存。
          if (!_isSplashRequestActive(requestId)) {
            _enqueueSplashNode(node);
            _pruneSplashList();
            completer.complete(false);
            return;
          }

          // 当前调用仍有效：直接展示。展示结束后广告失效（不入队）。
          _showingSplashAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              node.isClosed = true;
              if (identical(_showingSplashAd, a)) _showingSplashAd = null;
              a.dispose();
              completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (a, e) {
              node.isClosed = true;
              if (identical(_showingSplashAd, a)) _showingSplashAd = null;
              a.dispose();
              completer.complete(false);
            },
          );

          try {
            ad.show();
          } catch (_) {
            node.isClosed = true;
            if (identical(_showingSplashAd, ad)) _showingSplashAd = null;
            ad.dispose();
            completer.complete(false);
          }
        },
        onAdFailedToLoad: (e) => completer.complete(false),
      ),
    );
    return completer.future;
  }

  @override
  void closeSplashAd() {
    // 仅标记当前调用已失效：不对队列做任何处理。
    _activeSplashRequestId = null;

    // 如果当前存在正在展示的广告，则需要主动关闭。
    _closeShowingSplashAd();
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
