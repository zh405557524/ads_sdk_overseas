import 'package:flutter/material.dart';
import 'package:ads_sdk_overseas/ads_sdk_overseas.dart';

/// 广告演示页：6 种广告入口与展示区
class AdsDemoPage extends StatefulWidget {
  final AdsManager adsManager;

  const AdsDemoPage({super.key, required this.adsManager});

  @override
  State<AdsDemoPage> createState() => _AdsDemoPageState();
}

class _AdsDemoPageState extends State<AdsDemoPage> {
  Widget? _bannerWidget;
  Widget? _nativeWidget;
  Widget? _feedWidget;
  bool _loadingBanner = false;
  bool _loadingNative = false;
  bool _loadingFeed = false;

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSplash() async {
    _showSnackBar('开屏广告加载中…');
    try {
      await widget.adsManager.loadAndShowSplashAd();
      if (mounted) _showSnackBar('开屏广告已关闭');
    } catch (e) {
      if (mounted) {
        _showSnackBar('开屏广告失败: $e');
      }
    }
  }

  Future<void> _onBanner() async {
    setState(() => _loadingBanner = true);
    try {
      final w = await widget.adsManager.loadBannerAd();
      if (mounted) {
        setState(() {
          _bannerWidget = w;
          _loadingBanner = false;
        });
      }
      _showSnackBar('横幅广告已加载');
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBanner = false);
        _showSnackBar('横幅广告失败: $e');
      }
    }
  }

  Future<void> _onInterstitial() async {
    _showSnackBar('插屏广告加载中…');
    try {
      await widget.adsManager.loadAndShowInterstitialAd();
      if (mounted) {
        _showSnackBar('插屏广告已关闭');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('插屏广告失败: $e');
      }
    }
  }

  Future<void> _onRewarded() async {
    _showSnackBar('激励视频加载中…');
    try {
      final rewarded = await widget.adsManager.loadAndShowRewardedVideoAd();
      if (mounted) {
        _showSnackBar(rewarded ? '已获得奖励' : '未获得奖励');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('激励视频失败: $e');
      }
    }
  }

  Future<void> _onNative() async {
    setState(() => _loadingNative = true);
    try {
      final w = await widget.adsManager.loadNativeAd();
      if (mounted) {
        setState(() {
          _nativeWidget = w;
          _loadingNative = false;
        });
      }
      _showSnackBar('原生广告已加载');
    } catch (e) {
      if (mounted) {
        setState(() => _loadingNative = false);
        _showSnackBar('原生广告失败: $e');
      }
    }
  }

  Future<void> _onFeed() async {
    setState(() => _loadingFeed = true);
    try {
      final w = await widget.adsManager.loadFeedAd();
      if (mounted) {
        setState(() {
          _feedWidget = w;
          _loadingFeed = false;
        });
      }
      _showSnackBar('信息流广告已加载');
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFeed = false);
        _showSnackBar('信息流广告失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('广告 SDK 演示')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('全屏/弹窗类'),
          ElevatedButton(onPressed: _onSplash, child: const Text('开屏广告')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _onInterstitial, child: const Text('插屏广告')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _onRewarded, child: const Text('激励视频')),
          const SizedBox(height: 24),
          _section('横幅'),
          ElevatedButton(
            onPressed: _loadingBanner ? null : _onBanner,
            child: Text(_loadingBanner ? '加载中…' : '加载横幅广告'),
          ),
          if (_bannerWidget != null) ...[
            const SizedBox(height: 8),
            SizedBox(height: 50, child: _bannerWidget),
          ],
          const SizedBox(height: 24),
          _section('原生广告'),
          ElevatedButton(
            onPressed: _loadingNative ? null : _onNative,
            child: Text(_loadingNative ? '加载中…' : '加载原生广告'),
          ),
          if (_nativeWidget != null) ...[
            const SizedBox(height: 8),
            SizedBox(height: 120, child: _nativeWidget),
          ],
          const SizedBox(height: 24),
          _section('信息流'),
          ElevatedButton(
            onPressed: _loadingFeed ? null : _onFeed,
            child: Text(_loadingFeed ? '加载中…' : '加载信息流广告'),
          ),
          if (_feedWidget != null) ...[
            const SizedBox(height: 8),
            SizedBox(height: 120, child: _feedWidget),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
