import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/models/subscription_plan.dart';
import 'package:usdtmining/models/tap_feature.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/services/meta_analytics_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';

class MiningCard extends StatefulWidget {
  const MiningCard({super.key});

  @override
  State<MiningCard> createState() => _MiningCardState();
}

class _MiningCardState extends State<MiningCard> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _breathingController;
  late AnimationController _rewardController;
  late Animation<double> _glowAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rewardFade;
  late Animation<Offset> _rewardSlide;

  double _tapScale = 1.0;
  String? _rewardText;
  bool _isRechargingEnergy = false;
  bool _wasAutoMiningActive = false;
  final List<_CoinBurst> _coinBursts = [];
  final Random _coinRandom = Random();
  double _tapPadDiameter = 260;
  final MetaAnalyticsService _metaAnalytics = MetaAnalyticsService();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _rewardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      reverseDuration: const Duration(milliseconds: 350),
    );
    _glowAnimation =
        CurvedAnimation(parent: _glowController, curve: Curves.easeOut);
    _breathingAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    );
    final rewardCurve =
        CurvedAnimation(parent: _rewardController, curve: Curves.easeOut);
    _rewardFade =
        CurvedAnimation(parent: _rewardController, curve: Curves.easeOutQuad);
    _rewardSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: const Offset(0, -0.1),
    ).animate(rewardCurve);

    _rewardController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {
          _rewardText = null;
        });
      }
    });
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.7),
        child: const AppLoadingIndicator(
          text: 'Recharging energy...',
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideLoadingOverlay();
    _pulseController.dispose();
    _glowController.dispose();
    _breathingController.dispose();
    _rewardController.dispose();
    for (final burst in _coinBursts) {
      burst.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleTap(
    MiningService miningService,
    AdService adService,
  ) async {
    SystemSound.play(SystemSoundType.click);
    final reward = miningService.registerTap();

    setState(() {
      _tapScale = 1.0;
    });

    _glowController.forward(from: 0);
    if (reward > 0) {
      setState(() {
        _rewardText = '+${reward.toStringAsFixed(5)} USDT';
      });
      _rewardController.forward(from: 0);
      _emitCoins();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          _rewardController.reverse();
        }
      });
    } else if (miningService.isDailyTapLimitReached && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily tapping limit reached. Come back tomorrow!'),
        ),
      );
    } else if (miningService.isTapEnergyEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Energy depleted. Watch an ad to recharge!'),
        ),
      );
    }

    if (miningService.consumeTapAdPending()) {
      if (adService.adsEnabled) {
        final rewarded = await adService.showRewardedAd(
          onUserEarnedReward: (_, __) {
            miningService.addTapEnergy(
              miningService.tapEnergyRewardPerAd,
            );
          },
        );
        if (!rewarded) {
          miningService.addTapEnergy(miningService.tapEnergyRewardPerAd);
        }
      } else {
        miningService.addTapEnergy(miningService.tapEnergyRewardPerAd);
      }
    }
  }

  Future<void> _showRewardedBoost(
    BuildContext context,
    AdService adService,
    MiningService miningService,
  ) async {
    if (!adService.adsEnabled) {
      await miningService.applyBoost();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2x boost active for 1 hour!'),
        ),
      );
      return;
    }

    await adService.showInterstitialAd();
    final rewarded = await adService.showRewardedAd(
      onUserEarnedReward: (ad, reward) {
        miningService.applyBoost();
      },
    );
    if (!mounted) return;
    if (rewarded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2x boost active for 1 hour!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not available right now. Try again later.'),
        ),
      );
    }
  }

  void _emitCoins() {
    const coinCount = 6;
    final palette = [
      const Color(0xFFFFD700),
      const Color(0xFFFFB347),
      const Color(0xFF00FFCC),
    ];
    for (var i = 0; i < coinCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 650 + i * 40),
      );
      final radius = _tapPadDiameter / 2;
      final burst = _CoinBurst(
        controller: controller,
        horizontalShift:
            (_coinRandom.nextDouble() - 0.5) * radius * (1.2 + _coinRandom.nextDouble() * 0.4),
        verticalTravel: radius * (0.9 + _coinRandom.nextDouble() * 0.6),
        startAngle: _coinRandom.nextDouble() * pi,
        color: palette[_coinRandom.nextInt(palette.length)],
        initialScale: 0.7 + _coinRandom.nextDouble() * 0.4,
      );
      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.dispose();
          if (mounted) {
            setState(() {
              _coinBursts.remove(burst);
            });
          }
        }
      });
      setState(() {
        _coinBursts.add(burst);
      });
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MiningService>(
      builder: (context, miningService, child) {
        final balance = miningService.currentBalance;
        final isMining = miningService.isMining;
        final rate = miningService.miningRate;
        final startTime = miningService.miningStartTime;
        final boostMultiplier = miningService.boostMultiplier;
        final autoMiningActive = miningService.autoMiningActive;
        if (_wasAutoMiningActive && !autoMiningActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Auto mining session ended. Tap to restart!'),
              ),
            );
          });
        }
        _wasAutoMiningActive = autoMiningActive;
        final adService = Provider.of<AdService>(context, listen: false);

        Duration? elapsed;
        if (startTime != null) {
          elapsed = DateTime.now().difference(startTime);
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E2749),
                Color(0xFF2A3A5F),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9FF).withOpacity(0.25),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isMining
                                  ? Color.lerp(
                                      const Color(0xFF00FF88),
                                      const Color(0xFF00D9FF),
                                      _pulseController.value,
                                    )
                                  : Colors.grey,
                              boxShadow: isMining
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00FF88)
                                            .withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                        isMining ? 'Mining Active' : 'Mining Inactive',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isMining
                                  ? const Color(0xFF00FF88)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                                ),
                            ),
                      ),
                    ],
                    ),
                  ),
                  if (boostMultiplier > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 32),
                        child: IntrinsicHeight(
                          child: Container(
                      padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ],
                      ),
                      child: Row(
                              mainAxisSize: MainAxisSize.min,
                        children: [
                                const Icon(
                                  Icons.rocket_launch,
                                  size: 16,
                                  color: Color(0xFF0A0E27),
                                ),
                          const SizedBox(width: 4),
                          Text(
                            '${boostMultiplier}x BOOST',
                            style: const TextStyle(
                              color: Color(0xFF0A0E27),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'USDT Balance',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(symbol: '', decimalDigits: 5)
                          .format(balance),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: const Color(0xFF00D9FF),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'USDT',
                      style: TextStyle(
                        color: Color(0xFFB0B8C4),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildTapToMine(context, miningService, adService),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      Icons.speed,
                      'Mining Speed',
                      '${(rate * 86400).toStringAsFixed(5)} USDT/day',
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      Icons.access_time,
                      'Uptime',
                      elapsed != null
                          ? '${elapsed.inHours}h ${elapsed.inMinutes % 60}m'
                          : '0h 0m',
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      Icons.trending_up,
                      'Rate per second',
                      '${rate.toStringAsFixed(6)} USDT/s',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildEnergySection(context, miningService, adService),
              const SizedBox(height: 24),
              _buildFeatureSection(context, miningService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTapToMine(
    BuildContext context,
    MiningService miningService,
    AdService adService,
  ) {
    final comboCount = miningService.comboCount;
    final tapPreview = miningService.tapPreview;
    final isSubscribed = miningService.subscriptionTier != SubscriptionTier.free;
    final limitReached = miningService.isDailyTapLimitReached;
    final energyEmpty = miningService.isTapEnergyEmpty &&
        !miningService.unlimitedChargeActive;
    final canTap = !limitReached && !energyEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final desiredDiameter = availableWidth - 48;
        final circleDiameter =
            desiredDiameter.clamp(200.0, 260.0).toDouble();
        if (_tapPadDiameter != circleDiameter) {
          _tapPadDiameter = circleDiameter;
        }

        final innerDiameter = circleDiameter - 30;
        return Column(
          children: [
            GestureDetector(
              onTapDown: (_) {
                if (!canTap) return;
                setState(() {
                  _tapScale = 0.92;
                });
              },
              onTapCancel: () {
                if (!canTap) return;
                setState(() {
                  _tapScale = 1.0;
                });
              },
              onTapUp: (_) {
                if (!canTap) return;
                setState(() {
                  _tapScale = 1.0;
                });
              },
              onTap: canTap ? () => _handleTap(miningService, adService) : null,
              child: AnimatedScale(
                scale: _tapScale,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutBack,
                child: AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    final auraScale = 1 + (_breathingAnimation.value * 0.08);
                    final tilt = (_breathingAnimation.value - 0.5) * 0.12;
                    return Transform.scale(
                      scale: auraScale,
                      child: Transform.rotate(
                        angle: tilt,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: circleDiameter,
                    height: circleDiameter,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            final value = _glowAnimation.value;
                            final glowDiameter = circleDiameter - 20;
                            return Container(
                              width: glowDiameter + 90 * value,
                              height: glowDiameter + 90 * value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00D9FF)
                                    .withOpacity((1 - value) * 0.25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D9FF)
                                        .withOpacity((1 - value) * 0.45),
                                    blurRadius: 34 * (1 - value),
                                    spreadRadius: 14 * (1 - value),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Container(
                          width: innerDiameter,
                          height: innerDiameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: [
                                Color(0xFF00D9FF),
                                Color(0xFF008CFF),
                                Color(0xFF00D9FF),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D9FF).withOpacity(0.35),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF101B3A),
                                  Color(0xFF132E4D),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: innerDiameter * 0.5,
                                  height: innerDiameter * 0.5,
                                  child: Image.asset(
                                    'assets/images/character.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: innerDiameter * 0.07),
                                Text(
                                  'Tap to Mine',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  ),
                                  child: Text(
                                    'Combo x$comboCount',
                                    key: ValueKey(comboCount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: const Color(0xFF00FFCC),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!canTap)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(circleDiameter),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              limitReached
                                  ? 'Daily limit reached'
                                  : 'Charge depleted',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        if (_rewardText != null)
                          FadeTransition(
                            opacity: _rewardFade,
                            child: SlideTransition(
                              position: _rewardSlide,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FFCC).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFCC)
                                          .withOpacity(0.6),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _rewardText!,
                                  style: const TextStyle(
                                    color: Color(0xFF0A0E27),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ..._buildCoinBurstWidgets(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141F3D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instant reward',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${tapPreview.toStringAsFixed(5)} USDT',
                      style: const TextStyle(
                        color: Color(0xFF00FFCC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      ),
                      child: Text(
                        comboCount > 1
                            ? '+${((comboCount - 1) * 15)}% combo'
                            : 'Combo ready',
                        key: ValueKey(comboCount),
                        style: TextStyle(
                          color: comboCount > 1
                              ? const Color(0xFFFFB74D)
                              : Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSubscribed ? Icons.flash_on : Icons.flashlight_on,
                          color: isSubscribed
                              ? const Color(0xFFFFD54F)
                              : Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isSubscribed ? 'Premium boost' : 'Base boost',
                            style: TextStyle(
                              color: isSubscribed
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
      },
    );
  }

  List<Widget> _buildCoinBurstWidgets() {
    if (_coinBursts.isEmpty) return const [];
    final center = Offset(_tapPadDiameter / 2, _tapPadDiameter / 2);
    return _coinBursts
        .map(
          (burst) => AnimatedBuilder(
            animation: burst.controller,
            builder: (context, child) {
              final progress = Curves.easeOutCubic.transform(burst.controller.value);
              final lift = sin(progress * pi);
              final horizontalOffset = burst.horizontalShift * progress;
              final verticalOffset = -burst.verticalTravel * lift;
              final opacity = (1 - progress).clamp(0.0, 1.0);
              final scale = burst.initialScale + (1 - progress) * 0.3;
              return Positioned(
                left: center.dx + horizontalOffset - 14,
                top: center.dy + verticalOffset - 14,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: burst.startAngle + progress * pi / 2,
                    child: Transform.scale(
                      scale: scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              burst.color,
                              burst.color.withOpacity(0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: burst.color.withOpacity(0.45),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.monetization_on,
                            size: 18,
                            color: Color(0xFF0A0E27),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
        .toList();
  }

  Widget _buildEnergySection(
    BuildContext context,
    MiningService miningService,
    AdService adService,
  ) {
    final plan = planConfigs[miningService.subscriptionTier]!;
    final energyPercent = miningService.tapEnergyPercent.clamp(0.0, 1.0);
    final energyFull = energyPercent >= 0.995;
    final isUnlimited = miningService.unlimitedChargeActive;
    final energyLabel = isUnlimited
        ? 'Unlimited charge active'
        : 'Charge: ${miningService.tapEnergy.toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap Energy',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: energyPercent,
            minHeight: 10,
            backgroundColor: const Color(0xFF1A2548),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
                    energyLabel,
              style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Cost per tap: ${miningService.tapEnergyCostPerTap.toStringAsFixed(1)}%',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRechargingEnergy || isUnlimited || energyFull
                      ? null
                      : () => _watchEnergyAd(context, miningService, adService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: const Color(0xFF0A0E27),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Watch ad (+${miningService.tapEnergyRewardPerAd.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Plan: ${plan.displayName}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildFeatureSection(
    BuildContext context,
    MiningService miningService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap Boosts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 212,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: TapFeature.values.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final feature = TapFeature.values[index];
              return SizedBox(
                width: 210,
                child: _buildFeatureCard(context, miningService, feature)
                    .animate()
                    .fadeIn(duration: 250.ms, delay: (90 * index).ms)
                    .slideX(begin: 0.08, end: 0),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    MiningService miningService,
    TapFeature feature,
  ) {
    final plan = planConfigs[miningService.subscriptionTier]!;
    final usesLeft = miningService.featureUsesLeft(feature);
    final totalUses = plan.featureUsesPerDay;
    final isActive = miningService.isFeatureActive(feature);
    final remaining = miningService.featureRemaining(feature);
    final canActivate = usesLeft > 0 || isActive;

    final gradient = _featureGradient(feature, isActive);
    final borderColor = isActive
        ? gradient.colors.first.withOpacity(0.6)
        : Colors.white.withOpacity(0.12);

    return GestureDetector(
      onTap: canActivate
          ? () => _activateFeature(context, miningService, feature)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: gradient,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? gradient.colors.first.withOpacity(0.35)
                  : Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  height: 140,
                  width: 130,
                  child: Image.asset(
                    _featureAsset(feature),
                  ),
                ),
              ),
            ),
            Text(
              tapFeatureLabel(feature),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 12,
                    color:
                        isActive ? const Color(0xFF0A0E27) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              tapFeatureDescription(feature),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: isActive
                        ? const Color(0xFF0A0E27).withOpacity(0.7)
                        : Colors.white70,
                  ),
            ),
            const SizedBox(height:8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isActive
                    ? 'Active • ${_formatDuration(remaining)} left'
                    : 'Uses left: $usesLeft / $totalUses',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: isActive
                          ? const Color(0xFF0A0E27)
                          : usesLeft > 0
                              ? Colors.white
                              : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _featureGradient(TapFeature feature, bool isActive) {
    final activePalettes = {
      TapFeature.unlimitedCharge: [
        const Color(0xFF00FFB3),
        const Color(0xFF00D9FF),
      ],
      TapFeature.autoClick: [
        const Color(0xFF7F7FFF),
        const Color(0xFFBA68C8),
      ],
      TapFeature.clickBooster: [
        const Color(0xFFFFA726),
        const Color(0xFFFFD54F),
      ],
    };

    final inactivePalettes = {
      TapFeature.unlimitedCharge: [
        const Color(0xFF1E2A4A),
        const Color(0xFF162037),
      ],
      TapFeature.autoClick: [
        const Color(0xFF2A2550),
        const Color(0xFF1B1B3A),
      ],
      TapFeature.clickBooster: [
        const Color(0xFF402F1F),
        const Color(0xFF2A1E15),
      ],
    };

    final colors = isActive
        ? activePalettes[feature]!
        : inactivePalettes[feature]!;

    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _featureAsset(TapFeature feature) {
    switch (feature) {
      case TapFeature.unlimitedCharge:
        return 'assets/images/unlimited_charge.png';
      case TapFeature.autoClick:
        return 'assets/images/auto_click.png';
      case TapFeature.clickBooster:
        return 'assets/images/boost_tap.png';
    }
  }

  Future<void> _watchEnergyAd(
    BuildContext context,
    MiningService miningService,
    AdService adService,
  ) async {
    if (_isRechargingEnergy) return;
    setState(() {
      _isRechargingEnergy = true;
    });
    _showLoadingOverlay();

    try {
      bool rewarded = true;
      if (adService.adsEnabled) {
        rewarded = await adService.showRewardedAd(
          onUserEarnedReward: (_, __) {
            miningService.addTapEnergy(miningService.tapEnergyRewardPerAd);
          },
        );
      } else {
        miningService.addTapEnergy(miningService.tapEnergyRewardPerAd);
      }

      if (rewarded) {
        unawaited(
          _metaAnalytics.logRewardAdWatched('energy_recharge'),
        );
        await miningService.registerRewardedAd(
          source: 'energy_recharge',
        );
      }

      if (!rewarded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not available right now. Try again later.'),
          ),
        );
      }
    } finally {
      _hideLoadingOverlay();
      if (mounted) {
        setState(() {
          _isRechargingEnergy = false;
        });
      }
    }
  }

  Future<void> _activateFeature(
    BuildContext context,
    MiningService miningService,
    TapFeature feature,
  ) async {
    final success = await miningService.activateFeature(feature);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${tapFeatureLabel(feature)} activated for 2 minutes!'
              : 'No uses left today for ${tapFeatureLabel(feature)}.',
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0m 0s';
    final seconds = duration.inSeconds;
    if (seconds <= 0) return '0m 0s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${secs}s';
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF00D9FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
          value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF00D9FF),
                fontWeight: FontWeight.bold,
            ),
              ),
        ),
      ],
    );
  }
}

class _CoinBurst {
  _CoinBurst({
    required this.controller,
    required this.horizontalShift,
    required this.verticalTravel,
    required this.startAngle,
    required this.color,
    required this.initialScale,
  });

  final AnimationController controller;
  final double horizontalShift;
  final double verticalTravel;
  final double startAngle;
  final Color color;
  final double initialScale;
}
