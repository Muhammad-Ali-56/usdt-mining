import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/services/storage_service.dart';
import 'package:usdtmining/widgets/ads/native_ad_panel.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';
import 'package:usdtmining/widgets/mining_background.dart';

class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> with TickerProviderStateMixin {
  int _adsWatched = 0;
  bool _isWatchingAd = false;
  bool _isBoosterWatching = false;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _loadAdsCount();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadAdsCount() async {
    final count = await StorageService.getBoostCount();
    if (mounted) {
      setState(() {
        _adsWatched = count % 2;
      });
    }
  }

  Future<void> _watchAd() async {
    if (_adsWatched >= 2) {
      _showCustomSnackBar(
        context,
        icon: Icons.schedule,
        message: 'Daily limit reached! Come back tomorrow for more boosts 🚀',
        color: const Color(0xFFFF6B35),
      );
      return;
    }

    setState(() => _isWatchingAd = true);

    final adService = Provider.of<AdService>(context, listen: false);
    var adCompleted = false;

    if (adService.adsEnabled) {
      adCompleted = await adService.showRewardedAd(
        onUserEarnedReward: (_, __) {},
      );
      if (!adCompleted) {
        if (mounted) {
          _showCustomSnackBar(
            context,
            icon: Icons.error_outline,
            message: 'Ad not available right now. Try again in a moment.',
            color: const Color(0xFFEF5350),
          );
        }
        setState(() => _isWatchingAd = false);
        return;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      adCompleted = true;
    }

    final miningService = Provider.of<MiningService>(context, listen: false);
    await miningService.registerRewardedAd(source: 'speed_boost');

    final newCount = _adsWatched + 1;
    if (mounted) {
      setState(() {
        _adsWatched = newCount;
        _isWatchingAd = false;
      });

      if (newCount == 2) {
        await miningService.applyBoost();
        if (mounted) {
          _showCustomSnackBar(
            context,
            icon: Icons.rocket_launch,
            message: '🔥 2x BOOST ACTIVATED! Mining at maximum speed for 1 hour!',
            color: const Color(0xFF00FF88),
          );
        }
      } else {
        _showCustomSnackBar(
          context,
          icon: Icons.check_circle,
          message: 'Progress saved! Just 1 more ad for 2x boost ($newCount/2)',
          color: const Color(0xFF00D9FF),
        );
      }
    }
  }

  Future<void> _watchBoosterAd() async {
    if (_isBoosterWatching) return;
    final miningService = Provider.of<MiningService>(context, listen: false);
    final adService = Provider.of<AdService>(context, listen: false);
    final initialProgress = miningService.boosterAdProgress;
    final boosterTarget = miningService.boosterAdTarget;

    setState(() => _isBoosterWatching = true);

    var rewarded = false;
    if (adService.adsEnabled) {
      rewarded = await adService.showRewardedAd(
        onUserEarnedReward: (_, __) {},
      );
      if (!rewarded) {
        if (mounted) {
          _showCustomSnackBar(
            context,
            icon: Icons.error_outline,
            message: 'Ad not available right now. Try again in a moment.',
            color: const Color(0xFFEF5350),
          );
        }
        setState(() => _isBoosterWatching = false);
        return;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      rewarded = true;
    }

    await miningService.registerRewardedAd(
      source: 'auto_mining_booster',
      incrementBooster: true,
    );

    if (mounted) {
      final progress = miningService.boosterAdProgress;
      final adsNeeded = progress == 0 ? boosterTarget : boosterTarget - progress;
      final isFullCharge = progress == 0 && initialProgress + 1 >= boosterTarget;

      _showCustomSnackBar(
        context,
        icon: isFullCharge ? Icons.electric_bolt : Icons.battery_charging_full,
        message: isFullCharge
            ? '⚡ MEGA BOOST! 24-hour auto mining activated!'
            : '+4 hours auto mining! $adsNeeded ads until mega boost.',
        color: isFullCharge ? const Color(0xFFFFD700) : const Color(0xFF00D9FF),
      );

      setState(() => _isBoosterWatching = false);
    }
  }

  void _showCustomSnackBar(
      BuildContext context, {
        required IconData icon,
        required String message,
        required Color color,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0m';
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return '0m';
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isLargeTablet = size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          MiningBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isTablet, isLargeTablet),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeTablet ? 32 : (isTablet ? 24 : 16),
                        vertical: isTablet ? 20 : 16,
                      ),
                      child: _buildContent(context, isTablet, isLargeTablet),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isWatchingAd || _isBoosterWatching)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: AppLoadingIndicator(
                text: _isWatchingAd ? 'Watching ad...' : 'Loading booster...',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet, bool isLargeTablet) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
          padding: EdgeInsets.all(isLargeTablet ? 28 : (isTablet ? 24 : 20)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E2749).withOpacity(0.95),
                const Color(0xFF2A3256).withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFFFFD700),
                const Color(0xFFFFA500),
                _pulseController.value,
              )!.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3 * _pulseController.value),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 18 : 14)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA726)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: const Color(0xFF0A0E27),
              size: isLargeTablet ? 40 : (isTablet ? 36 : 32),
            ),
          ),
          SizedBox(width: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFFFFA726)],
                  ).createShader(bounds),
                  child: Text(
                    'Boost Mining',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: isLargeTablet ? 32 : (isTablet ? 30 : 26),
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  'Watch ads • Earn rewards • Mine faster',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFFD700).withOpacity(0.9),
                    fontSize: isLargeTablet ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.3, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildContent(BuildContext context, bool isTablet, bool isLargeTablet) {
    return Consumer<MiningService>(
      builder: (context, miningService, _) {
        final boosterProgress = miningService.boosterAdProgress;
        final boosterTarget = miningService.boosterAdTarget;
        final boosterPercent = miningService.boosterAdProgressPercent.clamp(0.0, 1.0);
        final boosterRemaining = boosterProgress == 0 ? boosterTarget : boosterTarget - boosterProgress;
        final autoActive = miningService.autoMiningActive;
        final autoRemaining = miningService.autoMiningRemaining;
        final totalAds = miningService.totalRewardedAds;
        final nextWeekly = miningService.remainingAdsForWeeklyReward;
        final weeklyUnlocked = miningService.weeklyRewardEligible;
        final combo = miningService.comboCount;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLargeTablet ? 1000 : (isTablet ? 700 : 520)),
            child: Column(
              children: [
                _BoosterCard(
                  progress: boosterProgress,
                  target: boosterTarget,
                  percent: boosterPercent,
                  remaining: boosterRemaining,
                  isWatching: _isBoosterWatching,
                  onWatch: _isBoosterWatching ? null : _watchBoosterAd,
                  isTablet: isTablet,
                  isLargeTablet: isLargeTablet,
                  shimmerController: _shimmerController,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
                SizedBox(height: isLargeTablet ? 28 : (isTablet ? 24 : 20)),
                _buildActionCards(context, miningService, autoActive, isTablet, isLargeTablet),
                SizedBox(height: isLargeTablet ? 28 : (isTablet ? 24 : 20)),
                _buildStatsGrid(
                  context,
                  autoActive,
                  autoRemaining,
                  weeklyUnlocked,
                  nextWeekly,
                  totalAds,
                  combo,
                  isTablet,
                  isLargeTablet,
                ),
                SizedBox(height: isLargeTablet ? 32 : (isTablet ? 28 : 24)),
                NativeAdPanel(
                  height: isLargeTablet ? 350 : (isTablet ? 320 : 280),
                  borderRadius: 20,
                ),
                SizedBox(height: isLargeTablet ? 28 : (isTablet ? 24 : 20)),
                _InfoCard(isTablet: isTablet, isLargeTablet: isLargeTablet)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                SizedBox(height: isLargeTablet ? 80 : (isTablet ? 60 : 40)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCards(
      BuildContext context,
      MiningService miningService,
      bool autoActive,
      bool isTablet,
      bool isLargeTablet,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTablet && constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.sensors,
                  title: 'Auto Mining',
                  description: 'Mine automatically for 1 hour without interaction.',
                  buttonLabel: autoActive ? 'Active Now' : 'Start Session',
                  onTap: autoActive
                      ? null
                      : () async {
                    final started = await miningService.startAutoMiningSession();
                    if (!mounted) return;
                    _showCustomSnackBar(
                      context,
                      icon: started ? Icons.play_circle_filled : Icons.info,
                      message: started
                          ? '✨ Auto mining started! Relax while we mine for you.'
                          : 'Auto mining is already running.',
                      color: const Color(0xFF00FF88),
                    );
                  },
                  isTablet: isTablet,
                  isLargeTablet: isLargeTablet,
                  accentColor: const Color(0xFF00FF88),
                  headerAsset: 'assets/images/start_automine.png',
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .slideX(begin: -0.15, end: 0, curve: Curves.easeOutCubic),
              ),
              SizedBox(width: isLargeTablet ? 20 : 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.bolt_rounded,
                  title: 'Speed Boost',
                  description: 'Double your mining speed for the next hour.',
                  buttonLabel: _adsWatched >= 2 ? 'Daily Limit' : 'Activate (${_adsWatched}/2)',
                  onTap: (_adsWatched >= 2 || _isWatchingAd) ? null : _watchAd,
                  loading: _isWatchingAd,
                  isTablet: isTablet,
                  isLargeTablet: isLargeTablet,
                  accentColor: const Color(0xFFFFD700),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 500.ms)
                    .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _ActionCard(
                icon: Icons.sensors,
                title: 'Auto Mining',
                description: 'Mine automatically for 1 hour without interaction.',
                buttonLabel: autoActive ? 'Active Now' : 'Start Session',
                onTap: autoActive
                    ? null
                    : () async {
                  final started = await miningService.startAutoMiningSession();
                  if (!mounted) return;
                  _showCustomSnackBar(
                    context,
                    icon: started ? Icons.play_circle_filled : Icons.info,
                    message: started
                        ? '✨ Auto mining started! Relax while we mine for you.'
                        : 'Auto mining is already running.',
                    color: const Color(0xFF00FF88),
                  );
                },
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
                accentColor: const Color(0xFF00FF88),
                headerAsset: 'assets/images/start_automine.png',
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.bolt_rounded,
                title: 'Speed Boost',
                description: 'Double your mining speed for the next hour.',
                buttonLabel: _adsWatched >= 2 ? 'Daily Limit' : 'Activate (${_adsWatched}/2)',
                onTap: (_adsWatched >= 2 || _isWatchingAd) ? null : _watchAd,
                loading: _isWatchingAd,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
                accentColor: const Color(0xFFFFD700),
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 500.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatsGrid(
      BuildContext context,
      bool autoActive,
      Duration? autoRemaining,
      bool weeklyUnlocked,
      int nextWeekly,
      int totalAds,
      int combo,
      bool isTablet,
      bool isLargeTablet,
      ) {
    final stats = [
      _StatData(
        icon: Icons.auto_graph,
        title: 'Auto Mining',
        value: autoActive ? _formatDuration(autoRemaining) : 'Offline',
        accent: const Color(0xFF00FF88),
        subtitle: autoActive ? 'Mining in background' : 'Start a session',
      ),
      _StatData(
        icon: Icons.card_giftcard_rounded,
        title: 'Weekly Bonus',
        value: weeklyUnlocked ? 'Ready!' : '$nextWeekly left',
        accent: const Color(0xFFFF6B35),
        subtitle: '$totalAds total ads',
      ),
      _StatData(
        icon: Icons.whatshot_rounded,
        title: 'Combo Streak',
        value: '${combo}x',
        accent: const Color(0xFFFFD700),
        subtitle: 'Keep tapping!',
      ),
    ];

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index > 0 ? (isLargeTablet ? 16 : 12) : 0),
              child: _StatCard(
                icon: stat.icon,
                title: stat.title,
                value: stat.value,
                accent: stat.accent,
                subtitle: stat.subtitle,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
              )
                  .animate()
                  .fadeIn(delay: (200 + index * 50).ms, duration: 500.ms)
                  .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < stats.length - 1 ? 12 : 0),
            child: _StatCard(
              icon: stat.icon,
              title: stat.title,
              value: stat.value,
              accent: stat.accent,
              subtitle: stat.subtitle,
              isTablet: isTablet,
              isLargeTablet: isLargeTablet,
            )
                .animate()
                .fadeIn(delay: (200 + index * 50).ms, duration: 500.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          );
        }).toList(),
      );
    }
  }
}

class _StatData {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;
  final String? subtitle;

  _StatData({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    this.subtitle,
  });
}

class _BoosterCard extends StatelessWidget {
  const _BoosterCard({
    required this.progress,
    required this.target,
    required this.percent,
    required this.remaining,
    required this.isWatching,
    required this.onWatch,
    required this.isTablet,
    required this.isLargeTablet,
    required this.shimmerController,
  });

  final int progress;
  final int target;
  final double percent;
  final int remaining;
  final bool isWatching;
  final VoidCallback? onWatch;
  final bool isTablet;
  final bool isLargeTablet;
  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(isLargeTablet ? 36 : (isTablet ? 32 : 24)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1F2B4C),
                Color(0xFF152238),
                Color(0xFF0F1A2E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF00D9FF),
                const Color(0xFF00FF88),
                shimmerController.value,
              )!.withOpacity(0.6),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasImage = constraints.maxWidth > 500;

          if (hasImage) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoColumn(context)),
                SizedBox(width: isLargeTablet ? 24 : (isTablet ? 18 : 14)),
                SizedBox(
                  width: isLargeTablet ? 180 : (isTablet ? 150 : 120),
                  height: isLargeTablet ? 180 : (isTablet ? 150 : 120),
                  child: Image.asset(
                    'assets/images/start_automine.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            );
          }

          return _buildInfoColumn(context);
        },
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context) {
    final gap = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGauge(),
        SizedBox(height: gap),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D9FF), Color(0xFF00FF88)],
          ).createShader(bounds),
          child: Text(
            'Auto Mining Mega Boost',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: isLargeTablet ? 28 : (isTablet ? 26 : 22),
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: isLargeTablet ? 14 : (isTablet ? 12 : 10)),
        Text(
          remaining == 0
              ? '⚡ Full power! Enjoy 24 hours of automated mining ⚡'
              : '💎 $remaining ad${remaining == 1 ? '' : 's'} away from 24h mega boost 💎',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isLargeTablet ? 17 : (isTablet ? 16 : 14.5),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: gap),
        SizedBox(
          width: double.infinity,
          height: isLargeTablet ? 64 : (isTablet ? 60 : 54),
          child: ElevatedButton(
            onPressed: onWatch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: const Color(0xFF0A1226),
              elevation: 12,
              shadowColor: const Color(0xFF00D9FF).withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled_rounded, size: isLargeTablet ? 28 : 24),
                const SizedBox(width: 10),
                Text(
                  'Watch & Earn',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isLargeTablet ? 19 : (isTablet ? 18 : 16),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGauge() {
    final size = isLargeTablet ? 180.0 : (isTablet ? 160.0 : 140.0);
    final innerSize = isLargeTablet ? 130.0 : (isTablet ? 115.0 : 100.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: isLargeTablet ? 16 : (isTablet ? 14 : 12),
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(
                  const Color(0xFF00D9FF),
                  const Color(0xFF00FF88),
                  percent,
                )!,
              ),
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00D9FF).withOpacity(0.25),
                  const Color(0xFF00D9FF).withOpacity(0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF00D9FF), const Color(0xFF00FF88), percent)!,
                      Colors.white,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    '$progress/$target',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isLargeTablet ? 36 : (isTablet ? 32 : 28),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  'Ads watched',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: isLargeTablet ? 14 : (isTablet ? 13 : 11),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    required this.isTablet,
    required this.isLargeTablet,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;
  final String? subtitle;
  final bool isTablet;
  final bool isLargeTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLargeTablet ? 24 : (isTablet ? 20 : 18)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1D2642).withOpacity(0.95),
            const Color(0xFF151B32).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.3),
                  accent.withOpacity(0.15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: accent, size: isLargeTablet ? 26 : (isTablet ? 24 : 22)),
          ),
          SizedBox(width: isLargeTablet ? 18 : (isTablet ? 16 : 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: isLargeTablet ? 14 : (isTablet ? 13 : 12),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 5)),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [accent, Colors.white],
                  ).createShader(bounds),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isLargeTablet ? 22 : (isTablet ? 20 : 18),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 5)),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: isLargeTablet ? 13 : (isTablet ? 12 : 11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
    required this.isTablet,
    required this.isLargeTablet,
    required this.accentColor,
    this.loading = false,
    this.headerAsset,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onTap;
  final bool loading;
  final bool isTablet;
  final bool isLargeTablet;
  final Color accentColor;
  final String? headerAsset;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return Container(
      padding: EdgeInsets.all(isLargeTablet ? 26 : (isTablet ? 22 : 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1D2642).withOpacity(0.95),
            const Color(0xFF151B32).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withOpacity(isDisabled ? 0.15 : 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDisabled ? 0.05 : 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headerAsset != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildIconTitleRow()),
                SizedBox(width: isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                SizedBox(
                  width: isLargeTablet ? 140 : (isTablet ? 120 : 100),
                  height: isLargeTablet ? 140 : (isTablet ? 120 : 100),
                  child: Image.asset(
                    headerAsset!,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            )
          else
            _buildIconTitleRow(),
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          Text(
            description,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isLargeTablet ? 15 : (isTablet ? 14 : 13),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isLargeTablet ? 20 : (isTablet ? 18 : 16)),
          SizedBox(
            width: double.infinity,
            height: isLargeTablet ? 60 : (isTablet ? 56 : 52),
            child: ElevatedButton(
              onPressed: loading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.white.withOpacity(0.1) : accentColor,
                foregroundColor: isDisabled ? Colors.white38 : const Color(0xFF0A1226),
                elevation: isDisabled ? 0 : 8,
                shadowColor: accentColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isLargeTablet ? 18 : (isTablet ? 17 : 16),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTitleRow() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isLargeTablet ? 14 : (isTablet ? 12 : 10)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.3),
                accentColor.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: isLargeTablet ? 28 : (isTablet ? 26 : 24),
          ),
        ),
        SizedBox(width: isLargeTablet ? 18 : (isTablet ? 16 : 14)),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accentColor, Colors.white],
            ).createShader(bounds),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isLargeTablet ? 20 : (isTablet ? 19 : 18),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.isTablet,
    required this.isLargeTablet,
  });

  final bool isTablet;
  final bool isLargeTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLargeTablet ? 28 : (isTablet ? 24 : 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E2749).withOpacity(0.7),
            const Color(0xFF162038).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTablet) ...[
            Container(
              width: isLargeTablet ? 120 : 100,
              height: isLargeTablet ? 120 : 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Image.asset(
                'assets/images/start_automine.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: isLargeTablet ? 20 : 18),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF00FF88)],
                  ).createShader(bounds),
                  child: Text(
                    '💡 Pro Tips',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                Text(
                  'Watch ads to unlock powerful mining boosts and earn USDT faster. Combine auto-mining with speed boosts for maximum efficiency. Check back daily for fresh rewards!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isLargeTablet ? 15 : (isTablet ? 14 : 13),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}