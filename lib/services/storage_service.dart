import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFirstTime = 'first_time';
  static const String _keyMiningBalance = 'mining_balance';
  static const String _keyReferralBalance = 'referral_balance';
  static const String _keyDailyReward1 = 'daily_reward_1';
  static const String _keyDailyReward2 = 'daily_reward_2';
  static const String _keyMiningStartTime = 'mining_start_time';
  static const String _keyMiningRate = 'mining_rate';
  static const String _keyBoostCount = 'boost_count';
  static const String _keyReferralCode = 'referral_code';
  static const String _keyTotalEarned = 'total_earned';
  static const String _keyReferralIncome = 'referral_income';
  static const String _keySharesCount = 'shares_count';
  static const String _keyMysteryBoxLastOpened = 'mystery_box_last_opened';
  static const String _keySubscriptionActive = 'subscription_active';
  static const String _keyFlipLastPlayed = 'flip_last_played';
  static const String _keyTapDailyDate = 'tap_daily_date';
  static const String _keyTapDailyAmount = 'tap_daily_amount';
  static const String _keyTapDailyCount = 'tap_daily_count';
  static const String _keyTapAdCounter = 'tap_ad_counter';
  static const String _keyTapEnergy = 'tap_energy';
  static const String _keyTapEnergyDate = 'tap_energy_date';
  static const String _keyFeatureUsageDate = 'feature_usage_date';
  static const String _keyFeatureUsageData = 'feature_usage_data';
  static const String _keyFeatureExpiryData = 'feature_expiry_data';
  static const String _keyAutoMiningUntil = 'auto_mining_until';
  static const String _keySubscriptionTier = 'subscription_tier';
  static const String _keyAutoMiningBoosterProgress = 'auto_mining_booster_progress';
  static const String _keyTotalRewardedAds = 'total_rewarded_ads';
  static const String _keyWeeklyAutoMiningClaims = 'weekly_auto_mining_claims';
  static const String _keySpinWheelLastDate = 'spin_wheel_last_date';
  static const String _keyIntroVideoSeen = 'intro_video_seen';

  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstTime) ?? true;
  }

  static Future<void> setFirstTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstTime, value);
  }

  static Future<double> getMiningBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMiningBalance) ?? 0.0;
  }

  static Future<void> setMiningBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMiningBalance, balance);
  }

  static Future<double> getReferralBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyReferralBalance) ?? 0.0;
  }

  static Future<void> setReferralBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyReferralBalance, balance);
  }

  static Future<int> getDailyReward1() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyReward1) ?? 0;
  }

  static Future<void> setDailyReward1(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyReward1, count);
  }

  static Future<int> getDailyReward2() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyReward2) ?? 0;
  }

  static Future<void> setDailyReward2(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyReward2, count);
  }

  static Future<DateTime?> getMiningStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyMiningStartTime);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  static Future<void> setMiningStartTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMiningStartTime, time.millisecondsSinceEpoch);
  }

  static Future<double> getMiningRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMiningRate) ?? 0.00001; // Molto lento: 0.00001 USDT/secondo
  }

  static Future<void> setMiningRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMiningRate, rate);
  }

  static Future<int> getBoostCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBoostCount) ?? 0;
  }

  static Future<void> setBoostCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBoostCount, count);
  }

  static Future<String> getReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReferralCode) ?? '';
  }

  static Future<void> setReferralCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReferralCode, code);
  }

  static Future<double> getTotalEarned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTotalEarned) ?? 0.0;
  }

  static Future<void> setTotalEarned(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTotalEarned, amount);
  }

  static Future<double> getReferralIncome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyReferralIncome) ?? 0.0;
  }

  static Future<void> setReferralIncome(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyReferralIncome, amount);
  }

  static Future<int> getSharesCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySharesCount) ?? 0;
  }

  static Future<void> setSharesCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySharesCount, count);
  }

  static Future<DateTime?> getMysteryBoxLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyMysteryBoxLastOpened);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  static Future<void> setMysteryBoxLastOpened(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyMysteryBoxLastOpened,
      time.millisecondsSinceEpoch,
    );
  }

  static Future<bool> getSubscriptionActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySubscriptionActive) ?? false;
  }

  static Future<void> setSubscriptionActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySubscriptionActive, value);
  }

  static Future<DateTime?> getFlipLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyFlipLastPlayed);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  static Future<void> setFlipLastPlayed(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyFlipLastPlayed,
      time.millisecondsSinceEpoch,
    );
  }

  static Future<DateTime?> getSpinWheelLastDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keySpinWheelLastDate);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  static Future<void> setSpinWheelLastDate(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySpinWheelLastDate, time.millisecondsSinceEpoch);
  }

  static Future<String?> getTapDailyDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTapDailyDate);
  }

  static Future<void> setTapDailyDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTapDailyDate, date);
  }

  static Future<double> getTapDailyAmount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTapDailyAmount) ?? 0.0;
  }

  static Future<void> setTapDailyAmount(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTapDailyAmount, amount);
  }

  static Future<int> getTapDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTapDailyCount) ?? 0;
  }

  static Future<void> setTapDailyCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTapDailyCount, count);
  }

  static Future<int> getTapAdCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTapAdCounter) ?? 0;
  }

  static Future<void> setTapAdCounter(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTapAdCounter, count);
  }

  static Future<double> getTapEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTapEnergy) ?? 100.0;
  }

  static Future<void> setTapEnergy(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTapEnergy, value);
  }

  static Future<String?> getTapEnergyDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTapEnergyDate);
  }

  static Future<void> setTapEnergyDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTapEnergyDate, date);
  }

  static Future<Map<String, int>> getFeatureUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFeatureUsageData);
    if (jsonString == null) return {};
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  static Future<void> setFeatureUsageData(Map<String, int> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFeatureUsageData, json.encode(data));
  }

  static Future<String?> getFeatureUsageDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFeatureUsageDate);
  }

  static Future<void> setFeatureUsageDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFeatureUsageDate, date);
  }

  static Future<Map<String, String>> getFeatureExpiryData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFeatureExpiryData);
    if (jsonString == null) return {};
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  static Future<void> setFeatureExpiryData(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFeatureExpiryData, json.encode(data));
  }

  static Future<DateTime?> getAutoMiningUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyAutoMiningUntil);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  static Future<void> setAutoMiningUntil(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove(_keyAutoMiningUntil);
    } else {
      await prefs.setInt(_keyAutoMiningUntil, time.millisecondsSinceEpoch);
    }
  }

  static Future<String?> getSubscriptionTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubscriptionTier);
  }

  static Future<void> setSubscriptionTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubscriptionTier, tier);
  }

  static Future<int> getAutoMiningBoosterProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoMiningBoosterProgress) ?? 0;
  }

  static Future<void> setAutoMiningBoosterProgress(int progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoMiningBoosterProgress, progress);
  }

  static Future<int> getTotalRewardedAds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalRewardedAds) ?? 0;
  }

  static Future<void> setTotalRewardedAds(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalRewardedAds, count);
  }

  static Future<int> getWeeklyAutoMiningClaims() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWeeklyAutoMiningClaims) ?? 0;
  }

  static Future<void> setWeeklyAutoMiningClaims(int claims) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWeeklyAutoMiningClaims, claims);
  }

  static Future<bool> hasSeenIntroVideo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIntroVideoSeen) ?? false;
  }

  static Future<void> setIntroVideoSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroVideoSeen, seen);
  }
}



