import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:usdtmining/models/subscription_plan.dart';
import 'package:usdtmining/models/tap_feature.dart';
import 'package:usdtmining/services/storage_service.dart';
import 'package:usdtmining/services/notification_service.dart';
import 'package:usdtmining/services/leaderboard_service.dart';
import 'package:usdtmining/services/meta_analytics_service.dart';

class MiningService extends ChangeNotifier {
  MiningService() {
    _loadMiningData();
  }

  static const double _tapBaseReward = 0.00003;
  static const double _comboBonusStep = 0.12;
  static const int _comboResetSeconds = 3;
  static const Duration _flipCooldown = Duration(hours: 24);
  static const double _tapDailyLimit = 5.0;
  static const int _tapAdThreshold = 50;
  static const double _tapEnergyCapacity = 100;
  static const Duration _featureDuration = Duration(minutes: 2);
  static const Duration _autoMiningDuration = Duration(hours: 1);
  static const int _boosterAdsTarget = 6;
  static const Duration _boosterAdAutoMining = Duration(hours: 4);
  static const Duration _boosterFullAutoMining = Duration(hours: 24);
  static const Duration _weeklyAutoMiningReward = Duration(days: 7);
  static const Duration _energyRegenInterval = Duration(minutes: 1);

  final Random _random = Random();

  Timer? _miningTimer;
  Timer? _autoClickTimer;

  double _currentBalance = 0.0;
  double _baseMiningRate = planConfigs[SubscriptionTier.free]!.miningRate;
  double _subscriptionMultiplier = 1.0;
  double _autoMiningMultiplier = 1.0;
  DateTime? _miningStartTime;
  bool _isMining = false;
  int _boostMultiplier = 1;

  int _comboCount = 0;
  DateTime? _lastTapTime;
  double _lastTapReward = 0;

  DateTime? _mysteryBoxLastOpened;
  DateTime? _flipLastPlayed;

  SubscriptionTier _subscriptionTier = SubscriptionTier.free;

  String? _tapDailyDate;
  double _tapDailyAmount = 0;
  int _tapDailyCount = 0;
  int _tapAdCounter = 0;
  bool _tapAdPending = false;
  bool _dailyTapLimitReached = false;

  double _tapEnergy = _tapEnergyCapacity;
  String? _tapEnergyDate;

  String? _featureUsageDate;
  Map<TapFeature, int> _featureUsage = {
    TapFeature.unlimitedCharge: 0,
    TapFeature.autoClick: 0,
    TapFeature.clickBooster: 0,
  };

  DateTime? _unlimitedChargeUntil;
  DateTime? _autoClickUntil;
  DateTime? _clickBoosterUntil;
  DateTime? _autoMiningUntil;
  LeaderboardService? _leaderboardService;
  DateTime? _lastLeaderboardSync;
  bool _isSyncingLeaderboard = false;
  final MetaAnalyticsService _metaAnalytics = MetaAnalyticsService();
  int _boosterAdProgress = 0;
  int _totalRewardedAds = 0;
  int _weeklyAutoMiningClaims = 0;
  DateTime? _lastEnergyRegen;

  double get currentBalance => _currentBalance;
  double get miningRate =>
      (_baseMiningRate * _boostMultiplier * _subscriptionMultiplier * _autoMiningMultiplier);
  DateTime? get miningStartTime => _miningStartTime;
  bool get isMining => _isMining;
  int get boostMultiplier => _boostMultiplier;
  int get comboCount => _comboCount;
  double get lastTapReward => _lastTapReward;
  SubscriptionTier get subscriptionTier => _subscriptionTier;
  bool get isSubscriptionActive => _subscriptionTier != SubscriptionTier.free;

  PlanConfig get _plan => planConfigs[_subscriptionTier]!;

  bool get isDailyTapLimitReached => _dailyTapLimitReached;
  bool get isTapAdPending => _tapAdPending;
  bool consumeTapAdPending() {
    if (!_tapAdPending) return false;
    _tapAdPending = false;
    notifyListeners();
    return true;
  }

  double get tapEnergy => _isUnlimitedChargeActive ? _tapEnergyCapacity : _tapEnergy;
  double get tapEnergyPercent =>
      (_isUnlimitedChargeActive ? _tapEnergyCapacity : _tapEnergy) / _tapEnergyCapacity;
  bool get isTapEnergyEmpty => !_isUnlimitedChargeActive && _tapEnergy <= 0;

  double get tapDailyAmount => _tapDailyAmount;
  int get tapDailyCount => _tapDailyCount;
  double get tapEnergyRewardPerAd => _plan.tapEnergyAdReward;
  double get tapEnergyCostPerTap => _plan.tapEnergyCostPerTap;
  int get boosterAdProgress => _boosterAdProgress;
  double get boosterAdProgressPercent =>
      _boosterAdsTarget == 0 ? 0 : _boosterAdProgress / _boosterAdsTarget;
  int get boosterAdTarget => _boosterAdsTarget;
  int get totalRewardedAds => _totalRewardedAds;
  int get remainingAdsForWeeklyReward {
    if (_totalRewardedAds == 0) return 100;
    final remainder = _totalRewardedAds % 100;
    if (remainder == 0) return 0;
    return 100 - remainder;
  }
  bool get weeklyRewardEligible =>
      _totalRewardedAds > 0 && _totalRewardedAds % 100 == 0;

  bool get autoMiningActive =>
      _autoMiningUntil != null && _autoMiningUntil!.isAfter(DateTime.now());
  Duration? get autoMiningRemaining {
    if (!autoMiningActive) return Duration.zero;
    return _autoMiningUntil!.difference(DateTime.now());
  }

  Duration? get timeUntilNextMysteryBox {
    if (_mysteryBoxLastOpened == null) return Duration.zero;
    // Aggiungi esattamente 24 ore all'ultima apertura
    final nextAvailable = _mysteryBoxLastOpened!.add(const Duration(hours: 24));
    final now = DateTime.now();
    final diff = nextAvailable.difference(now);
    // Se è scaduto o uguale a zero, ritorna Duration.zero (disponibile)
    if (diff.isNegative || diff == Duration.zero) {
      return Duration.zero;
    }
    return diff;
  }

  bool get isMysteryBoxAvailable {
    final timeRemaining = timeUntilNextMysteryBox;
    return timeRemaining == null || timeRemaining == Duration.zero;
  }

  Duration? get flipCooldownRemaining {
    if (_flipLastPlayed == null) return null;
    // Calcola esattamente 24 ore dall'ultimo gioco
    final nextAvailable = _flipLastPlayed!.add(const Duration(hours: 24));
    final now = DateTime.now();
    final elapsed = now.difference(_flipLastPlayed!);
    
    // Se sono passate almeno 24 ore, è disponibile
    if (elapsed >= _flipCooldown) {
      return null; // Disponibile
    }
    
    // Calcola il tempo rimanente
    final remaining = nextAvailable.difference(now);
    if (remaining.isNegative || remaining == Duration.zero) {
      return null; // Disponibile
    }
    return remaining;
  }

  bool get isFlipAndWinAvailable {
    final cooldown = flipCooldownRemaining;
    return cooldown == null || cooldown == Duration.zero;
  }

  bool get unlimitedChargeActive => _isUnlimitedChargeActive;
  bool get autoClickActive => _isAutoClickActive;
  bool get clickBoosterActive => _isClickBoosterActive;

  Duration? get unlimitedChargeRemaining => _remainingTime(_unlimitedChargeUntil);
  Duration? get autoClickRemaining => _remainingTime(_autoClickUntil);
  Duration? get clickBoosterRemaining => _remainingTime(_clickBoosterUntil);

  int featureUsesLeft(TapFeature feature) {
    final used = _featureUsage[feature] ?? 0;
    return (_plan.featureUsesPerDay - used).clamp(0, _plan.featureUsesPerDay);
  }

  double get tapPreview {
    final int comboSteps =
        (_comboCount > 0 ? (_comboCount - 1) : 0).clamp(0, 4);
    final comboBonus = 1 + comboSteps * _comboBonusStep;
    final booster = _isClickBoosterActive ? _plan.clickBoosterMultiplier : 1.0;
    return _tapBaseReward * comboBonus * _boostMultiplier * _subscriptionMultiplier * booster;
  }

  Future<void> _loadMiningData() async {
    _currentBalance = await StorageService.getMiningBalance();
    _baseMiningRate = await StorageService.getMiningRate();
    final savedStartTime = await StorageService.getMiningStartTime();
    _mysteryBoxLastOpened = await StorageService.getMysteryBoxLastOpened();
    _flipLastPlayed = await StorageService.getFlipLastPlayed();
    _tapDailyDate = await StorageService.getTapDailyDate();
    _tapDailyAmount = await StorageService.getTapDailyAmount();
    _tapDailyCount = await StorageService.getTapDailyCount();
    _tapAdCounter = await StorageService.getTapAdCounter();
    _tapEnergy = await StorageService.getTapEnergy();
    _tapEnergyDate = await StorageService.getTapEnergyDate();
    _featureUsageDate = await StorageService.getFeatureUsageDate();
    final usageData = await StorageService.getFeatureUsageData();
    _featureUsage = {
      for (final feature in TapFeature.values)
        feature: usageData[feature.name] ?? 0,
    };
    final expiryData = await StorageService.getFeatureExpiryData();
    _unlimitedChargeUntil =
        expiryData['unlimitedCharge'] != null ? DateTime.tryParse(expiryData['unlimitedCharge']!) : null;
    _autoClickUntil =
        expiryData['autoClick'] != null ? DateTime.tryParse(expiryData['autoClick']!) : null;
    _clickBoosterUntil =
        expiryData['clickBooster'] != null ? DateTime.tryParse(expiryData['clickBooster']!) : null;
    _autoMiningUntil = await StorageService.getAutoMiningUntil();
    _boosterAdProgress = await StorageService.getAutoMiningBoosterProgress();
    _totalRewardedAds = await StorageService.getTotalRewardedAds();
    _weeklyAutoMiningClaims = await StorageService.getWeeklyAutoMiningClaims();
    _lastEnergyRegen = DateTime.now();

    _dailyTapLimitReached = _tapDailyAmount >= _tapDailyLimit;
    
    if (savedStartTime != null) {
      _miningStartTime = savedStartTime;
      final now = DateTime.now();
      final elapsed = now.difference(savedStartTime).inSeconds;
      final additionalEarned = elapsed * miningRate;
      _currentBalance += additionalEarned;
      await _persistBalance(forceSync: true);
      _miningStartTime = now;
      await StorageService.setMiningStartTime(_miningStartTime!);
      _startMining();
    } else {
      _startMining();
    }
    
    _cleanupExpiredStates();
    _ensureAutoClickTimer();
    notifyListeners();
  }

  void _startMining() {
    if (_isMining) return;
    
    _isMining = true;
    if (_miningStartTime == null) {
      _miningStartTime = DateTime.now();
      StorageService.setMiningStartTime(_miningStartTime!);
    }

    DateTime? lastUpdateTime = DateTime.now();

    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      final timeDiff = now.difference(lastUpdateTime!).inSeconds;
      if (timeDiff <= 0) return;

      _cleanupExpiredStates();
      
      final earnedThisSecond = timeDiff * miningRate;
      _currentBalance += earnedThisSecond;
      lastUpdateTime = now;
      _regenerateEnergy(now, timeDiff);
      
      await _persistBalance();
      notifyListeners();
    });
  }

  void startMining() {
    if (!_isMining) {
      _startMining();
    }
  }

  void stopMining() {
    _miningTimer?.cancel();
    _isMining = false;
    notifyListeners();
  }

  Future<void> applyBoost() async {
    final boostCount = await StorageService.getBoostCount();
    await StorageService.setBoostCount(boostCount + 1);
    
    _boostMultiplier = 2;
    notifyListeners();
    unawaited(_metaAnalytics.logRewardAdWatched('boost'));
    
    Timer(const Duration(hours: 1), () {
      _boostMultiplier = 1;
      notifyListeners();
    });
  }

  Future<void> creditBalance(double amount, {bool forceSync = true}) async {
    if (amount == 0) return;
    _currentBalance += amount;
    await _persistBalance(forceSync: forceSync);
    notifyListeners();
  }

  Future<void> registerRewardedAd({
    String source = 'generic',
    bool incrementBooster = false,
    Duration? autoMiningDuration,
  }) async {
    _totalRewardedAds += 1;
    await StorageService.setTotalRewardedAds(_totalRewardedAds);

    final completedMilestones = _totalRewardedAds ~/ 100;
    if (completedMilestones > _weeklyAutoMiningClaims) {
      _weeklyAutoMiningClaims = completedMilestones;
      await StorageService.setWeeklyAutoMiningClaims(_weeklyAutoMiningClaims);
      await startCustomAutoMining(_weeklyAutoMiningReward, force: true);
    }

    if (incrementBooster) {
      await _incrementBoosterProgress();
    }

    if (autoMiningDuration != null) {
      await startCustomAutoMining(autoMiningDuration, force: true);
    }
    if (!incrementBooster) {
      notifyListeners();
    }
  }

  double registerTap({bool isAuto = false}) {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';

    _ensureDailyTallies(now, dayKey);
    _ensureEnergyDate(now, dayKey);

    if (_dailyTapLimitReached || _tapDailyAmount >= _tapDailyLimit) {
      _dailyTapLimitReached = true;
      _lastTapReward = 0;
      notifyListeners();
      return 0;
    }

    final autoClickBypassesEnergy = isAuto && _isAutoClickActive;
    if (!_isUnlimitedChargeActive && _tapEnergy <= 0 && !autoClickBypassesEnergy) {
      _lastTapReward = 0;
      notifyListeners();
      return 0;
    }

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 120) {
      return 0;
    }

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inSeconds <= _comboResetSeconds) {
      _comboCount += 1;
    } else {
      _comboCount = 1;
    }

    final int comboSteps = (_comboCount - 1).clamp(0, 4);
    final comboBonus = 1 + comboSteps * _comboBonusStep;
    final booster = _isClickBoosterActive ? _plan.clickBoosterMultiplier : 1.0;
    final reward = _tapBaseReward * comboBonus * _boostMultiplier * booster;
    final totalReward = reward * _subscriptionMultiplier;

    final remaining = _tapDailyLimit - _tapDailyAmount;
    if (remaining <= 0) {
      _dailyTapLimitReached = true;
      _lastTapReward = 0;
      notifyListeners();
      return 0;
    }

    double effectiveReward = totalReward;
    if (effectiveReward > remaining) {
      effectiveReward = remaining;
    }

    if (effectiveReward <= 0) {
      _dailyTapLimitReached = true;
      _lastTapReward = 0;
      notifyListeners();
      return 0;
    }

    _currentBalance += effectiveReward;
    _lastTapReward = effectiveReward;
    _lastTapTime = now;
    _tapDailyAmount += effectiveReward;
    _tapDailyCount += 1;
    if (!isAuto) {
      _tapAdCounter += 1;
      if (_tapAdCounter >= _tapAdThreshold) {
        _tapAdPending = true;
        _tapAdCounter = 0;
      }
    }
    if (_tapDailyAmount >= _tapDailyLimit) {
      _dailyTapLimitReached = true;
    }

    if (!autoClickBypassesEnergy || _tapEnergy > 0) {
      _consumeTapEnergy();
    }

    unawaited(_persistBalance(forceSync: !isAuto));
    if (!isAuto && effectiveReward > 0) {
      unawaited(_metaAnalytics.logTapMine(
        reward: double.parse(effectiveReward.toStringAsFixed(6)),
        combo: _comboCount,
      ));
    }
    StorageService.setTapDailyAmount(_tapDailyAmount);
    StorageService.setTapDailyCount(_tapDailyCount);
    StorageService.setTapAdCounter(_tapAdCounter);
    StorageService.setTapEnergy(_tapEnergy);

    notifyListeners();

    return effectiveReward;
  }

  Future<double> openMysteryBox() async {
    if (!isMysteryBoxAvailable) {
      throw StateError('Mystery box not available right now.');
    }

    final minReward = 0.01;
    final maxReward = 0.09;
    final reward = double.parse(
      (minReward + _random.nextDouble() * (maxReward - minReward)).toStringAsFixed(4),
    );

    // Salva il timestamp esatto di quando viene aperto (per cooldown di 24 ore)
    _mysteryBoxLastOpened = DateTime.now();
    await StorageService.setMysteryBoxLastOpened(_mysteryBoxLastOpened!);
    await creditBalance(reward, forceSync: true);
    unawaited(_metaAnalytics.logMysteryBoxOpened(reward));
    notifyListeners(); // Aggiorna la UI per mostrare il nuovo stato
    return reward;
  }

  Future<double> playFlipAndWin() async {
    final remaining = flipCooldownRemaining;
    if (remaining != null && remaining > Duration.zero) {
      throw StateError('Flip & Win is still on cooldown.');
    }
    // Reward da 0.01 a 0.09 USDT (sempre vincente)
    final minReward = 0.01;
    final maxReward = 0.09;
    final reward = double.parse(
      (minReward + _random.nextDouble() * (maxReward - minReward)).toStringAsFixed(4),
    );
    await creditBalance(reward, forceSync: true);
    // Salva il timestamp esatto di quando viene giocato (per cooldown di 24 ore)
    _flipLastPlayed = DateTime.now();
    await StorageService.setFlipLastPlayed(_flipLastPlayed!);
    notifyListeners(); // Aggiorna la UI per mostrare il nuovo stato
    unawaited(_metaAnalytics.logFlipWinOutcome(reward));
    return reward;
  }

  void updateSubscriptionTier(SubscriptionTier tier) {
    if (_subscriptionTier == tier) return;
    _subscriptionTier = tier;
    _applyPlanConfig();
    notifyListeners();
  }

  void addTapEnergy(double percent) {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    _ensureEnergyDate(now, dayKey);
    if (_isUnlimitedChargeActive) return;
    _tapEnergy = (_tapEnergy + percent).clamp(0, _tapEnergyCapacity);
    StorageService.setTapEnergy(_tapEnergy);
    notifyListeners();
  }

  Future<bool> activateFeature(TapFeature feature) async {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    _ensureFeatureUsage(now, dayKey);

    if (featureUsesLeft(feature) <= 0) {
      return false;
    }

    switch (feature) {
      case TapFeature.unlimitedCharge:
        _unlimitedChargeUntil = now.add(_featureDuration);
        break;
      case TapFeature.autoClick:
        _autoClickUntil = now.add(_featureDuration);
        _ensureAutoClickTimer();
        break;
      case TapFeature.clickBooster:
        _clickBoosterUntil = now.add(_featureDuration);
        break;
    }

    _featureUsage[feature] = (_featureUsage[feature] ?? 0) + 1;
    await _persistFeatureUsage();
    await _persistFeatureExpiry();
    notifyListeners();
    return true;
  }

  Future<bool> startAutoMiningSession() async {
    return startCustomAutoMining(_autoMiningDuration, force: false);
  }

  Future<bool> startCustomAutoMining(
    Duration duration, {
    bool force = true,
  }) async {
    final now = DateTime.now();
    final proposed = now.add(duration);
    if (autoMiningActive && !force) {
      return false;
    }
    if (_autoMiningUntil != null && _autoMiningUntil!.isAfter(now)) {
      if (force) {
        final extended = _autoMiningUntil!.add(duration);
        _autoMiningUntil = extended.isAfter(proposed) ? extended : proposed;
      } else {
        _autoMiningUntil = proposed;
      }
    } else {
      _autoMiningUntil = proposed;
    }
    _autoMiningMultiplier = 1.35;
    await StorageService.setAutoMiningUntil(_autoMiningUntil);
    await NotificationService.showNotification(
      id: 100,
      title: 'Auto mining',
      body:
          'Auto mining active until ${_autoMiningUntil!.toLocal().toString().split(".").first}.',
    );
    notifyListeners();
    return true;
  }

  double getTotalBalance() => _currentBalance;

  @override
  void dispose() {
    _miningTimer?.cancel();
    _autoClickTimer?.cancel();
    super.dispose();
  }

  void attachLeaderboardService(LeaderboardService service) {
    _leaderboardService = service;
    unawaited(_syncLeaderboard(force: true));
  }

  void _applyPlanConfig() {
    _baseMiningRate = _plan.miningRate;
    StorageService.setMiningRate(_baseMiningRate);
    // energy consumption adapts per plan during tap.
  }

  Future<void> _persistBalance({bool forceSync = false}) async {
    await StorageService.setMiningBalance(_currentBalance);
    await _syncLeaderboard(force: forceSync);
  }

  Future<void> _syncLeaderboard({bool force = false}) async {
    final service = _leaderboardService;
    if (service == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    if (!force &&
        _lastLeaderboardSync != null &&
        now.difference(_lastLeaderboardSync!).inSeconds < 10) {
      return;
    }
    if (_isSyncingLeaderboard) {
      return;
    }

    _isSyncingLeaderboard = true;
    try {
      await service.updateCurrentUserEarnings(_currentBalance);
      _lastLeaderboardSync = now;
    } catch (error) {
      debugPrint('Leaderboard sync failed: $error');
    } finally {
      _isSyncingLeaderboard = false;
    }
  }

  void _regenerateEnergy(DateTime now, int elapsedSeconds) {
    if (_isUnlimitedChargeActive) return;
    if (_tapEnergy >= _tapEnergyCapacity) {
      _lastEnergyRegen = now;
      return;
    }
    _lastEnergyRegen ??= now;
    final diff = now.difference(_lastEnergyRegen!);
    if (diff.inSeconds < _energyRegenInterval.inSeconds) return;
    final minutes = diff.inMinutes;
    if (minutes <= 0) return;
    _tapEnergy = (_tapEnergy + minutes).clamp(0, _tapEnergyCapacity);
    _lastEnergyRegen = _lastEnergyRegen!.add(Duration(minutes: minutes));
    StorageService.setTapEnergy(_tapEnergy);
  }

  Future<void> _incrementBoosterProgress() async {
    _boosterAdProgress = (_boosterAdProgress + 1).clamp(0, _boosterAdsTarget);
    if (_boosterAdProgress >= _boosterAdsTarget) {
      _boosterAdProgress = 0;
      await StorageService.setAutoMiningBoosterProgress(0);
      await startCustomAutoMining(_boosterFullAutoMining, force: true);
    } else {
      await StorageService.setAutoMiningBoosterProgress(_boosterAdProgress);
      await startCustomAutoMining(_boosterAdAutoMining, force: true);
    }
    notifyListeners();
  }

  void _consumeTapEnergy() {
    if (_isUnlimitedChargeActive) return;
    final cost = _plan.tapEnergyCostPerTap;
    _tapEnergy = (_tapEnergy - cost).clamp(0, _tapEnergyCapacity);
    if (_tapEnergy <= 0) {
      _tapEnergy = 0;
    }
  }

  void _ensureDailyTallies(DateTime now, String dayKey) {
    if (_tapDailyDate == dayKey) return;
    _tapDailyDate = dayKey;
    _tapDailyAmount = 0;
    _tapDailyCount = 0;
    _tapAdCounter = 0;
    _tapAdPending = false;
    _dailyTapLimitReached = false;
    StorageService.setTapDailyDate(dayKey);
    StorageService.setTapDailyAmount(0);
    StorageService.setTapDailyCount(0);
    StorageService.setTapAdCounter(0);
  }

  void _ensureEnergyDate(DateTime now, String dayKey) {
    if (_tapEnergyDate == dayKey) return;
    _tapEnergyDate = dayKey;
    _tapEnergy = _tapEnergyCapacity;
    StorageService.setTapEnergyDate(dayKey);
    StorageService.setTapEnergy(_tapEnergyCapacity);
  }

  void _ensureFeatureUsage(DateTime now, String dayKey) {
    if (_featureUsageDate == dayKey) return;
    _featureUsageDate = dayKey;
    _featureUsage = {
      for (final feature in TapFeature.values) feature: 0,
    };
    StorageService.setFeatureUsageDate(dayKey);
    _persistFeatureUsage();
  }

  void _ensureAutoClickTimer() {
    if (!_isAutoClickActive) {
      _autoClickTimer?.cancel();
      _autoClickTimer = null;
      return;
    }
    if (_autoClickTimer != null) return;
    final interval = _plan.autoClickInterval;
    _autoClickTimer = Timer.periodic(interval, (timer) {
      if (!_isAutoClickActive) {
        timer.cancel();
        _autoClickTimer = null;
        return;
      }
      registerTap(isAuto: true);
    });
  }

  void _cleanupExpiredStates() {
    final now = DateTime.now();
    bool expiriesChanged = false;
    if (_unlimitedChargeUntil != null &&
        now.isAfter(_unlimitedChargeUntil!)) {
      _unlimitedChargeUntil = null;
      expiriesChanged = true;
    }
    if (_autoClickUntil != null && now.isAfter(_autoClickUntil!)) {
      _autoClickUntil = null;
      _autoClickTimer?.cancel();
      _autoClickTimer = null;
      expiriesChanged = true;
    }
    if (_clickBoosterUntil != null && now.isAfter(_clickBoosterUntil!)) {
      _clickBoosterUntil = null;
      expiriesChanged = true;
    }
    var stateChanged = expiriesChanged;
    if (_autoMiningUntil != null && now.isAfter(_autoMiningUntil!)) {
      _autoMiningUntil = null;
      _autoMiningMultiplier = 1.0;
      StorageService.setAutoMiningUntil(null);
      NotificationService.showNotification(
        id: 101,
        title: 'Auto mining ended',
        body: '1-hour mining boost has finished. Tap to start again.',
      );
      stateChanged = true;
    }
    if (expiriesChanged) {
      _persistFeatureExpiry();
    }
    if (stateChanged) {
      notifyListeners();
    }
  }

  bool get _isUnlimitedChargeActive =>
      _unlimitedChargeUntil != null && _unlimitedChargeUntil!.isAfter(DateTime.now());
  bool get _isAutoClickActive =>
      _autoClickUntil != null && _autoClickUntil!.isAfter(DateTime.now());
  bool get _isClickBoosterActive =>
      _clickBoosterUntil != null && _clickBoosterUntil!.isAfter(DateTime.now());

  Duration? _remainingTime(DateTime? until) {
    if (until == null) return null;
    final diff = until.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  Future<void> _persistFeatureUsage() async {
    final map = {
      for (final entry in _featureUsage.entries) entry.key.name: entry.value,
    };
    await StorageService.setFeatureUsageData(map);
  }

  Future<void> _persistFeatureExpiry() async {
    final data = <String, String>{};
    if (_unlimitedChargeUntil != null) {
      data['unlimitedCharge'] = _unlimitedChargeUntil!.toIso8601String();
    }
    if (_autoClickUntil != null) {
      data['autoClick'] = _autoClickUntil!.toIso8601String();
    }
    if (_clickBoosterUntil != null) {
      data['clickBooster'] = _clickBoosterUntil!.toIso8601String();
    }
    await StorageService.setFeatureExpiryData(data);
  }

  Duration? featureRemaining(TapFeature feature) {
    switch (feature) {
      case TapFeature.unlimitedCharge:
        return _remainingTime(_unlimitedChargeUntil);
      case TapFeature.autoClick:
        return _remainingTime(_autoClickUntil);
      case TapFeature.clickBooster:
        return _remainingTime(_clickBoosterUntil);
    }
  }

  bool isFeatureActive(TapFeature feature) {
    switch (feature) {
      case TapFeature.unlimitedCharge:
        return unlimitedChargeActive;
      case TapFeature.autoClick:
        return autoClickActive;
      case TapFeature.clickBooster:
        return clickBoosterActive;
    }
  }
}
