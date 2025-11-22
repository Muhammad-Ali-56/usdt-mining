import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/services/meta_analytics_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';

class FlipWinCard extends StatefulWidget {
  const FlipWinCard({super.key});

  @override
  State<FlipWinCard> createState() => _FlipWinCardState();
}

class _FlipWinCardState extends State<FlipWinCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _haloController;
  late Animation<double> _haloAnimation;
  bool _isFlipping = false;
  double? _lastReward;
  final MetaAnalyticsService _metaAnalytics = MetaAnalyticsService();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _haloAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _haloController, curve: Curves.easeInOut),
    );
  }

  // @override
  // void dispose() {
  //   _flipController.dispose();
  //   _haloController.dispose();
  //   super.dispose();
  // }

  Future<void> _onFlip(
      MiningService miningService,
      AdService adService,
      ) async {
    if (_isFlipping) return;

    if (!miningService.isFlipAndWinAvailable) {
      // Se bloccato, mostra rewarded ad
      if (adService.adsEnabled) {
        await adService.loadRewardedAd();
        final rewarded = await adService.showRewardedAd(
          onUserEarnedReward: (_, __) {},
        );
        if (rewarded) {
          await _metaAnalytics.logRewardAdWatched('flip_win_locked');
          await miningService.registerRewardedAd(source: 'flip_win_locked');
        }
      }
      final remaining = miningService.flipCooldownRemaining;
      if (remaining != null && remaining > Duration.zero) {
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes % 60;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Flip & Win available in ${hours}h ${minutes}m',
              ),
            ),
          );
        }
      }
      return;
    }

    setState(() {
      _isFlipping = true;
      _lastReward = null;
    });
    _showLoadingOverlay();

    try {
      // Esegui il flip
      await _flipController.forward(from: 0);
      
      // Ottieni la ricompensa
      final reward = await miningService.playFlipAndWin();
      
      // Nascondi il loading overlay IMMEDIATAMENTE dopo aver ottenuto il reward
      _hideLoadingOverlay();
      
      if (mounted) {
        setState(() {
          _lastReward = reward;
        });
      }

      // Attendi un po' per mostrare il risultato
      await Future.delayed(const Duration(milliseconds: 800));

      // Mostra dialogo animato con la ricompensa
      if (mounted && reward > 0) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            // Chiudi automaticamente il dialog dopo 2.5 secondi
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
            
            return Dialog(
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
                    const Icon(Icons.celebration, color: Color(0xFFFFBF69), size: 64)
                        .animate()
                        .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(duration: 1200.ms, delay: 400.ms),
                    const SizedBox(height: 16),
                    const Text(
                      'Flip & Win Reward',
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
                        'Awesome!',
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
            );
          },
        );
      }

      // Reset dopo il dialogo
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        _flipController.reset();
      }
    } catch (e) {
      debugPrint('Error in Flip & Win: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _hideLoadingOverlay();
      if (mounted) {
        setState(() {
          _isFlipping = false;
        });
      }
      // Assicurati che il controller sia resettato
      if (_flipController.isAnimating) {
        _flipController.reset();
      }
    }
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.7),
        child: const AppLoadingIndicator(
          text: 'Flipping card...',
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
    _flipController.dispose();
    _haloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MiningService, AdService>(
      builder: (context, miningService, adService, child) {
        final isReady = miningService.isFlipAndWinAvailable;
        final cooldownRemaining = miningService.flipCooldownRemaining;

        final baseGrad = isReady
            ? [
                const Color(0xFF1B254F),
                const Color(0xFF0E1634),
              ]
            : [
                const Color(0xFF14182C),
                const Color(0xFF0A0E20),
              ];

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: baseGrad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isReady
                  ? const Color(0xFF00FFC6).withOpacity(0.3)
                  : Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isReady
                    ? const Color(0xFF00FFC6).withOpacity(0.2)
                    : Colors.black.withOpacity(0.45),
                blurRadius: 32,
                spreadRadius: 3,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isReady)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                          const Color(0xFF00FFC6).withOpacity(0.05),
                        ],
                      ),
                    ),
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
                                colors: isReady
                                    ? [
                                        const Color(0xFF00FFC6).withOpacity(0.35),
                                        const Color(0xFF00D9FF).withOpacity(0.2),
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.08),
                                        Colors.white.withOpacity(0.05),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.casino_rounded,
                              color: isReady
                                  ? const Color(0xFF00FFC6)
                                  : Colors.white54,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Flip & Win',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isReady
                                ? [
                                    const Color(0xFF00FFC6).withOpacity(0.25),
                                    const Color(0xFF00D9FF).withOpacity(0.15),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isReady
                                ? const Color(0xFF00FFC6).withOpacity(0.5)
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isReady)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FFC6),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFC6).withOpacity(0.7),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                            else
                              Icon(
                                Icons.lock_clock,
                                color: Colors.white.withOpacity(0.6),
                                size: 16,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              isReady ? 'Ready' : 'Locked',
                              style: TextStyle(
                                color: isReady
                                    ? const Color(0xFF00FFC6)
                                    : Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
                    isReady
                        ? '🎴 Flip the lucky card to reveal instant crypto rewards and rare boosts.'
                        : cooldownRemaining != null && cooldownRemaining > Duration.zero
                            ? '🔒 Come back in ${_formatCooldown(cooldownRemaining)} to try your fortune again.'
                            : '🔒 Come back after cooldown to try your fortune again and unlock bonuses.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.72),
                          height: 1.4,
                          fontSize: 13,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _buildFlipArena(
                      context,
                      isReady,
                      miningService,
                      adService,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlipArena(
    BuildContext context,
    bool isReady,
    MiningService miningService,
    AdService adService,
  ) {
    return GestureDetector(
      onTap: () => _onFlip(miningService, adService),
      child: SizedBox(
        height: 220,
        child: AnimatedBuilder(
          animation: Listenable.merge([_haloController, _flipController]),
          builder: (context, child) {
            final haloScale = _haloAnimation.value;
            final value = _flipController.value;
            final angle = value * pi;
            final isFront = angle <= pi / 2;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(angle);

            return Stack(
              alignment: Alignment.center,
              children: [
                if (isReady)
                  Transform.scale(
                    scale: haloScale,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x3300FFC6),
                            Color(0x1300D9FF),
                            Colors.transparent,
                          ],
                          stops: [0.2, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: isFront
                      ? _buildCardFace(
                          context,
                          title: '🎯 Tap to Flip',
                          subtitle: 'Reveal your instant reward',
                          isReady: isReady,
                        )
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: _buildCardFace(
                            context,
                            title: _lastReward == null
                                ? '✨ Revealing...'
                                : _lastReward! > 0
                                    ? '🎉 +${_lastReward!.toStringAsFixed(2)} USDT'
                                    : '💫 Try Again Soon',
                            subtitle: _lastReward == null
                                ? 'Calculating your reward'
                                : _lastReward! > 0
                                    ? 'Bonus added to your balance!'
                                    : 'Next flip will be luckier',
                            highlight: _lastReward != null && _lastReward! > 0,
                            isReady: isReady,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFace(
      BuildContext context, {
        required String title,
        required String subtitle,
        required bool isReady,
        bool highlight = false,
      }) {
    final gradient = highlight
        ? const [
      Color(0xFF00E5FF),
      Color(0xFF00FFC6),
    ]
        : const [
      Color(0xFF1E2749),
      Color(0xFF141B35),
    ];
    final accent = highlight ? const Color(0xFF0A0E27) : Colors.white;
    final shadowColor =
    highlight ? const Color(0xFF00FFC6) : const Color(0xFF00D9FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: highlight
              ? const Color(0xFF00FFC6).withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(highlight ? 0.5 : 0.3),
            blurRadius: 30,
            spreadRadius: highlight ? 4 : 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated shimmer effect
          if (highlight || isReady)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Image with proper sizing - NO container background
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Image.asset(
                'assets/images/flip_card.png',
                fit: BoxFit.contain,
                color: highlight ? null : Colors.white.withOpacity(0.85),
                colorBlendMode: highlight ? null : BlendMode.modulate,
              ),
            ),
          ),

          // Text overlay at bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: highlight
                    ? Colors.white.withOpacity(0.95)
                    : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: highlight
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent.withOpacity(highlight ? 0.7 : 0.8),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCooldown(Duration duration) {
    if (duration <= Duration.zero) return '0s';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }
}