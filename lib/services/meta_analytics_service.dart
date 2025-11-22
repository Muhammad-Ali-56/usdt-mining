import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

class MetaAnalyticsService {
  MetaAnalyticsService._internal();

  static final MetaAnalyticsService _instance = MetaAnalyticsService._internal();
  factory MetaAnalyticsService() => _instance;

  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _facebookAppEvents.setAdvertiserTracking(enabled: true);
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      _initialized = true;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Meta analytics init failed: $e\n$stack');
      }
    }
  }

  Future<void> logAppOpen() async {
    await _safeLog(() => _facebookAppEvents.logEvent(name: 'app_open'));
  }

  Future<void> logTapMine({required double reward, required int combo}) async {
    await _safeLog(
      () => _facebookAppEvents.logEvent(
        name: 'tap_mine',
        parameters: {
          'reward': reward,
          'combo': combo,
        },
      ),
    );
  }

  Future<void> logRewardAdWatched(String placement) async {
    await _safeLog(
      () => _facebookAppEvents.logEvent(
        name: 'reward_ad_watched',
        parameters: {'placement': placement},
      ),
    );
  }

  Future<void> logMysteryBoxOpened(double reward) async {
    await _safeLog(
      () => _facebookAppEvents.logEvent(
        name: 'mystery_box_opened',
        parameters: {'reward': reward},
      ),
    );
  }

  Future<void> logFlipWinOutcome(double reward) async {
    await _safeLog(
      () => _facebookAppEvents.logEvent(
        name: 'flip_win_outcome',
        parameters: {'reward': reward},
      ),
    );
  }

  Future<void> _safeLog(Future<void> Function() action) async {
    try {
      await initialize();
      await action();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Meta analytics log failed: $e\n$stack');
      }
    }
  }
}

