import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';
import 'package:usdtmining/services/storage_service.dart';

class SpinWheelCard extends StatefulWidget {
  const SpinWheelCard({super.key});

  @override
  State<SpinWheelCard> createState() => _SpinWheelCardState();
}

class _SpinWheelCardState extends State<SpinWheelCard> with TickerProviderStateMixin {
  late final AnimationController _wheelController;
  Animation<double>? _spinAnimation;
  double _currentRotation = 0;
  bool _isSpinning = false;
  double? _lastReward;
  DateTime? _lastSpinDate;
  bool _spinDateLoaded = false;
  final Random _random = Random();
  Timer? _cooldownTimer;
  Duration? _cooldownRemaining;

  static const List<_WheelSlice> _slices = [
    _WheelSlice('0.01', 0.01, Color(0xFF00D9FF)),
    _WheelSlice('0.02', 0.02, Color(0xFFFFC857)),
    _WheelSlice('0.03', 0.03, Color(0xFF845EC2)),
    _WheelSlice('0.04', 0.04, Color(0xFFFF8066)),
    _WheelSlice('0.05', 0.05, Color(0xFF4B89DC)),
    _WheelSlice('0.06', 0.06, Color(0xFFFF6F91)),
    _WheelSlice('0.07', 0.07, Color(0xFF00C9A7)),
    _WheelSlice('0.08', 0.08, Color(0xFFFF9671)),
  ];

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
    _spinAnimation = Tween<double>(begin: 0, end: 0).animate(_wheelController)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _loadLastSpinDate();
  }

  Future<void> _loadLastSpinDate() async {
    final stored = await StorageService.getSpinWheelLastDate();
    if (!mounted) return;
    setState(() {
      _lastSpinDate = stored;
      _spinDateLoaded = true;
      _updateCooldown();
    });
    _startCooldownTimerIfNeeded();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _wheelController.dispose();
    super.dispose();
  }

  Future<void> _spinWheel(MiningService miningService, AdService adService) async {
    if (_isSpinning || !_spinDateLoaded) return;

    final today = DateTime.now();
    if (_lastSpinDate != null &&
        _lastSpinDate!.year == today.year &&
        _lastSpinDate!.month == today.month &&
        _lastSpinDate!.day == today.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Come back tomorrow for another spin!')),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _lastReward = null;
    });

    var rewarded = true;
    final shouldShowAd = adService.adsEnabled && _random.nextBool();
    if (shouldShowAd) {
      rewarded = await adService.showRewardedAd(onUserEarnedReward: (_, __) {});
    }

    if (!rewarded) {
      if (mounted) {
        setState(() => _isSpinning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not available right now. Please try again soon.')),
        );
      }
      return;
    }

    await miningService.registerRewardedAd(source: 'spin_wheel');

    final targetIndex = _random.nextInt(_slices.length);
    final sliceAngle = 2 * pi / _slices.length;
    final extraRotations = 4 + _random.nextInt(4);
    final targetRotation = _currentRotation + extraRotations * 2 * pi + (targetIndex * sliceAngle) + sliceAngle / 2;

    _spinAnimation = Tween<double>(begin: _currentRotation, end: targetRotation).animate(
      CurvedAnimation(
        parent: _wheelController,
        curve: const Cubic(0.12, 0.02, 0, 1),
      ),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _wheelController
        .forward(from: 0)
        .whenComplete(() async {
      final reward = _slices[targetIndex].amount;
      await miningService.creditBalance(reward);
      await StorageService.setSpinWheelLastDate(today);

      if (mounted) {
        setState(() {
          _currentRotation = targetRotation % (2 * pi);
          _lastReward = reward;
          _isSpinning = false;
          _lastSpinDate = today;
          _updateCooldown();
        });
      }
      _startCooldownTimerIfNeeded();
    });
  }

  void _updateCooldown() {
    if (_lastSpinDate == null) {
      _cooldownRemaining = null;
      return;
    }
    final nextAvailable = DateTime(
      _lastSpinDate!.year,
      _lastSpinDate!.month,
      _lastSpinDate!.day,
    ).add(const Duration(days: 1));
    final diff = nextAvailable.difference(DateTime.now());
    _cooldownRemaining = diff.isNegative ? null : diff;
  }

  void _startCooldownTimerIfNeeded() {
    _cooldownTimer?.cancel();
    _updateCooldown();
    if (_cooldownRemaining == null) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _updateCooldown();
        if (_cooldownRemaining == null) {
          _cooldownTimer?.cancel();
        }
      });
    });
  }

  String _cooldownText() {
    if (_cooldownRemaining == null) return '';
    final hours = _cooldownRemaining!.inHours;
    final minutes = _cooldownRemaining!.inMinutes % 60;
    final seconds = _cooldownRemaining!.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MiningService, AdService>(
      builder: (context, miningService, adService, child) {
        return Stack(
          children: [
            Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1F1D36),
                Color(0xFF3F3351),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                'Spin & Win Rewards',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Watch a rewarded ad to spin the wheel and grab instant USDT bonuses.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_spinDateLoaded)
                const Center(
                  child: AppLoadingIndicator(
                    text: 'Preparing spin wheel...',
                  ),
                )
              else ...[
                SizedBox(
                  height: 260,
                  width: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 4,
                        child: Container(
                          width: 24,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF6F91)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Align(
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.arrow_drop_down, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _spinAnimation ?? _wheelController,
                        builder: (context, child) {
                          final rotation = _spinAnimation?.value ?? _currentRotation;
                          return Transform.rotate(
                            angle: rotation,
                            child: child,
                          );
                        },
                        child: CustomPaint(
                          size: const Size(240, 240),
                          painter: _WheelPainter(_slices),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0E27),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'SPIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (!_spinDateLoaded || _isSpinning || _cooldownRemaining != null)
                        ? null
                        : () => _spinWheel(miningService, adService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F91),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      _cooldownRemaining != null
                          ? 'Next spin in ${_cooldownText()}'
                          : 'Watch Ad & Spin',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                if (_lastReward != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'You won +${_lastReward!.toStringAsFixed(2)} USDT!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
            // Loading overlay
            if (_isSpinning)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const AppLoadingIndicator(
                    text: 'Spinning wheel...',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WheelSlice {
  final String label;
  final double amount;
  final Color color;

  const _WheelSlice(this.label, this.amount, this.color);
}

class _WheelPainter extends CustomPainter {
  final List<_WheelSlice> slices;

  _WheelPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.3, 1],
      ).createShader(rect);

    canvas.drawCircle(center, radius, glowPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFFD700),
          Color(0xFFFF6F91),
          Color(0xFF00D9FF),
          Color(0xFFFFD700),
        ],
      ).createShader(rect);

    final dividerPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2;

    final paint = Paint()..style = PaintingStyle.fill;

    final angle = (2 * pi) / slices.length;
    double startAngle = -pi / 2;

    for (final slice in slices) {
      paint.color = slice.color;
      canvas.drawArc(rect, startAngle, angle, true, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: slice.label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textAngle = startAngle + angle / 2;
      final textRadius = size.width * 0.3;
      final textOffset = Offset(
        size.center(Offset.zero).dx + cos(textAngle) * textRadius - textPainter.width / 2,
        size.center(Offset.zero).dy + sin(textAngle) * textRadius - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      startAngle += angle;
    }

    startAngle = -pi / 2;
    for (int i = 0; i < slices.length; i++) {
      final x = center.dx + cos(startAngle) * radius;
      final y = center.dy + sin(startAngle) * radius;
      canvas.drawLine(center, Offset(x, y), dividerPaint);
      startAngle += angle;
    }

    canvas.drawCircle(center, radius - 3, rimPaint);
    canvas.drawCircle(center, radius * 0.25, Paint()..color = Colors.white.withOpacity(0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

