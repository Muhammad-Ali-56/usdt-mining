import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/services/meta_analytics_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';

class MysteryBoxCard extends StatefulWidget {
  const MysteryBoxCard({super.key});

  @override
  State<MysteryBoxCard> createState() => _MysteryBoxCardState();
}

class _MysteryBoxCardState extends State<MysteryBoxCard>
    with TickerProviderStateMixin {
  late AnimationController _boxController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _lidAnimation;
  late AnimationController _idleController;
  late Animation<double> _idleBounce;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late ConfettiController _confettiController;

  bool _isOpening = false;
  double? _reward;
  final MetaAnalyticsService _metaAnalytics = MetaAnalyticsService();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _boxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _lidAnimation = CurvedAnimation(
      parent: _boxController,
      curve: Curves.easeOutBack,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _boxController,
      curve: Curves.elasticOut,
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _idleBounce = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOut,
      ),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _hideLoadingOverlay();
    _boxController.dispose();
    _idleController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _openBox(
    MiningService miningService,
    AdService adService,
  ) async {
    if (_isOpening) return;

    if (!miningService.isMysteryBoxAvailable) {
      // Se bloccato, mostra rewarded ad
      if (adService.adsEnabled) {
        await adService.loadRewardedAd();
        final rewarded = await adService.showRewardedAd(
          onUserEarnedReward: (_, __) {},
        );
        if (rewarded) {
          await _metaAnalytics.logRewardAdWatched('mystery_box_locked');
          await miningService.registerRewardedAd(source: 'mystery_box_locked');
        }
      }
      final remaining = miningService.timeUntilNextMysteryBox ?? Duration.zero;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Next mystery box in ${_formatDuration(remaining)}')),
        );
      }
      return;
    }

    var lidOpened = false;
    try {
      setState(() {
        _isOpening = true;
        _reward = null;
      });
      _showLoadingOverlay();

      await _boxController.forward(from: 0);
      lidOpened = true;
      final reward = await miningService.openMysteryBox();
      
      // Nascondi il loading overlay IMMEDIATAMENTE dopo aver ottenuto il reward
      _hideLoadingOverlay();
      
      _confettiController.play();
      setState(() => _reward = reward);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141B2D),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard, color: Color(0xFFFFBF69), size: 64)
                        .animate()
                        .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(duration: 1200.ms, delay: 400.ms),
                    const SizedBox(height: 16),
                    const Text(
                      'Mystery Reward',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      '+${reward.toStringAsFixed(4)} USDT',
                      style: const TextStyle(
                        color: Color(0xFFFFBF69),
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    )
                        .animate()
                        .scale(delay: 400.ms, duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(duration: 1500.ms, delay: 500.ms),
                    const SizedBox(height: 12),
                    const Text(
                      'Added to your balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBF69),
                        foregroundColor: const Color(0xFF0A0E27),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Great!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 2500));
      await _boxController.reverse();
      lidOpened = false;
    } on StateError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (lidOpened) {
        await _boxController.reverse();
      }
      _hideLoadingOverlay();
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.7),
        child: const AppLoadingIndicator(
          text: 'Opening mystery box...',
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildMysteryBoxVisual(bool available) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final boxSize = (maxWidth * 0.55).clamp(140.0, 180.0);
        final imageSize = boxSize * 0.85;
        final glowSize = boxSize * 0.9;
        final sparkleRadius = boxSize * 0.45;

        return AnimatedBuilder(
          animation: Listenable.merge([_boxController, _idleController, _glowController]),
          builder: (context, child) {
            final open = _lidAnimation.value;
            final bounce = _idleBounce.value * (1 - open);
            final scale = 1 + (_scaleAnimation.value * 0.06);
            final glowIntensity = _glowAnimation.value;
            final baseGlow = available ? 0.3 : 0.0;
            final glowOpacity = baseGlow + (open * 0.6) + (available ? glowIntensity * 0.2 : 0);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    if (available)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.35 * glowIntensity),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: const Color(0xFFB87EFF).withOpacity(0.25 * glowIntensity),
                                blurRadius: 45,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Pulsing inner glow
                    Positioned(
                      top: (boxSize - glowSize) / 2 + bounce,
                      child: Container(
                        width: glowSize,
                        height: glowSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: available
                                ? [
                              const Color(0xFFFFD700).withOpacity(glowOpacity),
                              const Color(0xFFB87EFF).withOpacity(glowOpacity * 0.5),
                              Colors.transparent,
                            ]
                                : [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Mystery box image
                    Positioned(
                      top: (boxSize - imageSize) / 2 + bounce,
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: available
                              ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                              : null,
                        ),
                        child: Image.asset(
                          'assets/images/mystry_box.png',
                          fit: BoxFit.contain,
                          color: available ? null : Colors.white.withOpacity(0.3),
                          colorBlendMode: available ? null : BlendMode.modulate,
                        ),
                      ),
                    ),

                    // Lock overlay
                    if (!available)
                      Positioned(
                        top: boxSize * 0.35,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white54,
                            size: boxSize * 0.2,
                          ),
                        ),
                      ),

                    // Sparkle particles
                    if (available && !_isOpening)
                      ..._buildSparkles(bounce, boxSize, sparkleRadius),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildSparkles(double bounce, double boxSize, double radius) {
    return List.generate(6, (index) {
      final angle = (index * pi * 2 / 6);
      final x = cos(angle) * radius;
      final y = sin(angle) * radius - bounce * 0.5;
      final sparkleSize = (boxSize * 0.03).clamp(4.0, 6.0);

      return Positioned(
        left: boxSize / 2 + x,
        top: boxSize / 2 + y,
        child: Container(
          width: sparkleSize,
          height: sparkleSize,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.8),
                blurRadius: 6,
                spreadRadius: 1.5,
              ),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 600.ms, delay: Duration(milliseconds: index * 100))
            .fadeOut(duration: 600.ms, delay: Duration(milliseconds: 400 + index * 100)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MiningService, AdService>(
      builder: (context, miningService, adService, child) {
        final available = miningService.isMysteryBoxAvailable;
        final cooldown = miningService.timeUntilNextMysteryBox ?? Duration.zero;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: available
                  ? [
                const Color(0xFF2A1A4F),
                const Color(0xFF16213E),
              ]
                  : [
                const Color(0xFF1A1F3A),
                const Color(0xFF0F1419),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: available
                  ? const Color(0xFFB87EFF).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: available
                    ? const Color(0xFFB87EFF).withOpacity(0.25)
                    : Colors.black.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: available
                    ? const Color(0xFFFFD700).withOpacity(0.15)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              if (available)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                          const Color(0xFFB87EFF).withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),

              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.03,
                  numberOfParticles: 20,
                  maxBlastForce: 40,
                  minBlastForce: 10,
                  gravity: 0.3,
                  colors: const [
                    Color(0xFFFFD700),
                    Color(0xFF00FFCC),
                    Color(0xFFB87EFF),
                    Color(0xFFFF6B9D),
                    Color(0xFF00D9FF),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: available
                                    ? [
                                  const Color(0xFFB87EFF).withOpacity(0.3),
                                  const Color(0xFFFFD700).withOpacity(0.2),
                                ]
                                    : [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.card_giftcard_rounded,
                              color: available
                                  ? const Color(0xFFFFD700)
                                  : Colors.white38,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Mystery Box',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: available
                                ? [
                              const Color(0xFF00FFCC).withOpacity(0.25),
                              const Color(0xFF00D9FF).withOpacity(0.15),
                            ]
                                : [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: available
                                ? const Color(0xFF00FFCC).withOpacity(0.4)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (available)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FFCC),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFCC).withOpacity(0.7),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                            else
                              Icon(
                                Icons.lock_clock,
                                size: 16,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              available ? 'Available' : 'Locked',
                              style: TextStyle(
                                color: available
                                    ? const Color(0xFF00FFCC)
                                    : Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    available
                        ? '✨ Available now! Open the box to get your surprise reward.'
                        : '🔒 Available again in ${_formatDuration(cooldown)}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.75),
                          height: 1.4,
                          fontSize: 13,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => _openBox(miningService, adService),
                      child: _buildMysteryBoxVisual(available),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!available)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Next box in ${_formatDuration(cooldown)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openBox(miningService, adService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBF69),
                        foregroundColor: const Color(0xFF0A0E27),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        available ? 'Open Mystery Box' : 'Available in ${_formatDuration(cooldown)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_reward != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00FFCC),
                              Color(0xFF00D9FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFCC).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFF0A0E27),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+${_reward!.toStringAsFixed(2)} USDT',
                              style: const TextStyle(
                                color: Color(0xFF0A0E27),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut)
                          .shimmer(duration: 1200.ms, delay: 300.ms),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) return '0s';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }



}



