import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  AdService();

  static const String _defaultBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _defaultNativeTestId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _defaultInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _defaultRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  bool _initialized = false;
  bool _adsEnabled = true;
  bool _loadingRemoteConfig = false;

  BannerAd? _bannerAd;
  NativeAd? _nativeAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  String? _bannerUnitId;
  String? _nativeUnitId;
  String? _interstitialUnitId;
  String? _rewardedUnitId;

  bool get isInitialized => _initialized;
  bool get adsEnabled => _adsEnabled;
  bool get isRewardedAdLoaded => _rewardedAd != null;
  BannerAd? get bannerAd => _bannerAd;
  NativeAd? get nativeAd => _nativeAd;
  String get bannerUnitId => _resolveUnitId(_bannerUnitId, _defaultBannerTestId);
  String get nativeUnitId => _resolveUnitId(_nativeUnitId, _defaultNativeTestId);
  String get interstitialUnitId =>
      _resolveUnitId(_interstitialUnitId, _defaultInterstitialTestId);
  String get rewardedUnitId =>
      _resolveUnitId(_rewardedUnitId, _defaultRewardedTestId);

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    await _loadRemoteConfig();
    _initialized = true;
    if (_adsEnabled) {
      await Future.wait([
        loadBannerAd(),
        loadNativeAd(),
        loadInterstitialAd(),
        loadRewardedAd(),
      ]);
    }
  }

  Future<void> _loadRemoteConfig() async {
    if (_loadingRemoteConfig) return;
    _loadingRemoteConfig = true;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults({
        // Note: App ID must be in AndroidManifest.xml (Android) and Info.plist (iOS)
        // Remote Config is only used for Ad Unit IDs, not App ID
        'admob_banner_id': _defaultBannerTestId,
        'admob_native_id': _defaultNativeTestId,
        'admob_interstitial_id': _defaultInterstitialTestId,
        'admob_rewarded_id': _defaultRewardedTestId,
      });
      await remoteConfig.fetchAndActivate();
      
      _bannerUnitId = _resolveUnitId(
        remoteConfig.getString('admob_banner_id'),
        _defaultBannerTestId,
      );
      _nativeUnitId = _resolveUnitId(
        remoteConfig.getString('admob_native_id'),
        _defaultNativeTestId,
      );
      _interstitialUnitId = _resolveUnitId(
        remoteConfig.getString('admob_interstitial_id'),
        _defaultInterstitialTestId,
      );
      _rewardedUnitId = _resolveUnitId(
        remoteConfig.getString('admob_rewarded_id'),
        _defaultRewardedTestId,
      );
    } finally {
      _loadingRemoteConfig = false;
    }
  }

  void updateAdsEnabled(bool enabled) {
    if (_adsEnabled == enabled) return;
    _adsEnabled = enabled;
    if (!_adsEnabled) {
      _disposeAd(_bannerAd);
      _disposeAd(_nativeAd);
      _interstitialAd?.dispose();
      _rewardedAd?.dispose();
      _bannerAd = null;
      _nativeAd = null;
      _interstitialAd = null;
      _rewardedAd = null;
    } else if (_initialized) {
      loadBannerAd();
      loadNativeAd();
      loadInterstitialAd();
      loadRewardedAd();
    }
    notifyListeners();
  }

  Future<void> loadBannerAd() async {
    if (!_adsEnabled) return;
    await _bannerAd?.dispose();
    final ad = BannerAd(
      adUnitId: _bannerUnitId ?? _defaultBannerTestId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAd = ad as BannerAd;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          notifyListeners();
        },
      ),
    );
    await ad.load();
    _bannerAd = ad;
  }

  Future<void> loadNativeAd() async {
    if (!_adsEnabled) return;
    await _nativeAd?.dispose();
    final ad = NativeAd(
      adUnitId: _nativeUnitId ?? _defaultNativeTestId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeAd = ad as NativeAd;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
          notifyListeners();
        },
      ),
    );
    await ad.load();
    _nativeAd = ad;
  }

  Future<void> loadInterstitialAd() async {
    if (!_adsEnabled) return;
    await _interstitialAd?.dispose();
    await InterstitialAd.load(
      adUnitId: _interstitialUnitId ?? _defaultInterstitialTestId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> loadRewardedAd() async {
    if (!_adsEnabled) return;
    await _rewardedAd?.dispose();
    await RewardedAd.load(
      adUnitId: _rewardedUnitId ?? _defaultRewardedTestId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (!_adsEnabled) return;
    final ad = _interstitialAd;
    if (ad == null) {
      await loadInterstitialAd();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
      },
    );
    await ad.show();
  }

  Future<bool> showRewardedAd({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async {
    if (!_adsEnabled) return false;
    
    // Assicurati che l'ad sia caricato prima di mostrarlo
    if (_rewardedAd == null) {
      await loadRewardedAd();
      
      // Aspetta fino a 10 secondi che l'ad venga caricato
      var attempts = 0;
      while (_rewardedAd == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      // Se dopo 10 secondi l'ad non è ancora caricato, ritorna false
      if (_rewardedAd == null) {
        return false;
      }
    }
    
    final ad = _rewardedAd!;
    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
      },
    );
    await ad.show(onUserEarnedReward: (adWithoutView, reward) {
      rewarded = true;
      onUserEarnedReward(adWithoutView, reward);
    });
    return rewarded;
  }

  void _disposeAd(Ad? ad) {
    ad?.dispose();
  }

  String _resolveUnitId(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  @override
  void dispose() {
    _disposeAd(_bannerAd);
    _disposeAd(_nativeAd);
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}

