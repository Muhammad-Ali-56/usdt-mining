import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget che aggiunge uno sfondo decorativo animato correlato al mining
/// Può essere usato in tutte le schermate dell'app
class MiningBackground extends StatefulWidget {
  final Widget child;
  final bool showPattern;

  const MiningBackground({
    super.key,
    required this.child,
    this.showPattern = true,
  });

  @override
  State<MiningBackground> createState() => _MiningBackgroundState();
}

class _MiningBackgroundState extends State<MiningBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0E27),
            Color(0xFF1A1F3A),
            Color(0xFF0F1535),
            Color(0xFF050A1E),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          if (widget.showPattern)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MiningPatternPainter(_controller.value),
                  size: Size.infinite,
                );
              },
            ),
          widget.child,
        ],
      ),
    );
  }
}

/// Pattern decorativo animato che simula particelle/mining activity

class _MiningPatternPainter extends CustomPainter {
  final double animationValue;
  final _random = math.Random(42); // Seed fisso per pattern consistente

  _MiningPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Grid pattern animato (mining grid)
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color = const Color(0xFF00D9FF).withOpacity(0.02 + (math.sin(animationValue * 2 * math.pi) * 0.01));

    const gridSize = 80.0;
    final gridOffset = (animationValue * gridSize) % gridSize;
    
    for (double x = -gridSize + gridOffset; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (double y = -gridSize + gridOffset; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Particelle animate che si muovono lentamente (simbolo di mining/dati processati)
    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    for (int i = 0; i < 120; i++) {
      final seed = (i * 1000).toDouble();
      final random = math.Random(seed.toInt());
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      
      // Movimento circolare lento
      final angle = animationValue * 2 * math.pi + (i * 0.1);
      final radius = 15.0 + random.nextDouble() * 25.0;
      final x = baseX + math.cos(angle) * radius;
      final y = baseY + math.sin(angle) * radius * 0.3;
      
      // Pulsazione dell'opacità
      final pulse = (math.sin(animationValue * 4 * math.pi + i) + 1) / 2;
      final opacity = 0.03 + pulse * 0.12;
      final particleRadius = 1.0 + random.nextDouble() * 2.5 + pulse * 1.0;

      particlePaint.color = const Color(0xFF00D9FF).withOpacity(opacity);

      // Disegna particella con glow animato
      if (x >= 0 && x <= size.width && y >= 0 && y <= size.height) {
        canvas.drawCircle(Offset(x, y), particleRadius, particlePaint);
      }
    }

    // Linee animate che pulsano (blockchain-like pattern)
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 25; i++) {
      final seed = (i * 2000).toDouble();
      final random = math.Random(seed.toInt());
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      
      // Movimento delle linee
      final offsetX = math.cos(animationValue * 2 * math.pi + i) * 20;
      final offsetY = math.sin(animationValue * 2 * math.pi + i * 0.5) * 20;
      
      final startX = baseX + offsetX;
      final startY = baseY + offsetY;
      final endX = startX + (random.nextDouble() - 0.5) * 80 + math.cos(animationValue * math.pi) * 30;
      final endY = startY + (random.nextDouble() - 0.5) * 80 + math.sin(animationValue * math.pi) * 30;

      // Pulsazione dell'opacità
      final pulse = (math.sin(animationValue * 6 * math.pi + i) + 1) / 2;
      linePaint.color = const Color(0xFF00D9FF).withOpacity(0.02 + pulse * 0.03);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }

    // Cerchi concentrici animati che pulsano (simbolo di blockchain/mining)
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 15; i++) {
      final seed = (i * 3000).toDouble();
      final random = math.Random(seed.toInt());
      final centerX = random.nextDouble() * size.width;
      final centerY = random.nextDouble() * size.height;
      
      // Pulsazione del raggio
      final pulse = (math.sin(animationValue * 3 * math.pi + i) + 1) / 2;
      final baseRadius = 25.0 + random.nextDouble() * 60.0;
      final radius = baseRadius + pulse * 15.0;

      // Pulsazione dell'opacità
      final opacityPulse = (math.cos(animationValue * 2 * math.pi + i) + 1) / 2;
      circlePaint.color = const Color(0xFFFFD700).withOpacity(0.03 + opacityPulse * 0.04);

      canvas.drawCircle(Offset(centerX, centerY), radius, circlePaint);

      // Cerchio interno che pulsa in controfase
      if (random.nextDouble() > 0.4) {
        final innerRadius = radius * (0.5 + pulse * 0.2);
        circlePaint.color = const Color(0xFFFFD700).withOpacity(0.02 + (1 - opacityPulse) * 0.03);
        canvas.drawCircle(
          Offset(centerX, centerY),
          innerRadius,
          circlePaint,
        );
      }
    }

    // Particelle che si muovono verso punti centrali (simbolo di mining)
    final miningParticlePaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final miningCenters = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.5),
    ];

    for (int centerIndex = 0; centerIndex < miningCenters.length; centerIndex++) {
      final center = miningCenters[centerIndex];
      final random = math.Random(centerIndex * 5000);
      
      for (int i = 0; i < 20; i++) {
        final angle = (animationValue * 2 * math.pi) + (i * math.pi * 2 / 20) + (centerIndex * math.pi / 3);
        final distance = 30.0 + random.nextDouble() * 100.0 + math.sin(animationValue * 4 * math.pi) * 20.0;
        
        final x = center.dx + math.cos(angle) * distance;
        final y = center.dy + math.sin(angle) * distance;
        
        // Particelle più brillanti quando sono più vicine al centro
        final normalizedDistance = (distance / 130.0).clamp(0.0, 1.0);
        final opacity = (1 - normalizedDistance) * 0.15 + 0.05;
        final radius = 1.5 + (1 - normalizedDistance) * 2.0;
        
        miningParticlePaint.color = const Color(0xFF00D9FF).withOpacity(opacity);

        if (x >= 0 && x <= size.width && y >= 0 && y <= size.height) {
          canvas.drawCircle(Offset(x, y), radius, miningParticlePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiningPatternPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

