import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 80,
    this.alignment = Alignment.center,
    this.repeat = true,
    this.text,
    this.fullScreen = false,
  });

  final double size;
  final Alignment alignment;
  final bool repeat;
  final String? text;
  final bool fullScreen;


  @override
  Widget build(BuildContext context) {
    final lottieWidget = SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/anim/loading.json',
        repeat: repeat,
        fit: BoxFit.contain,
        frameRate: FrameRate.max,
      ),
    );

    // Se c'è testo o fullScreen, mostra container bello al centro dello schermo
    if (text != null || fullScreen) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A1A4F).withOpacity(0.95),
                const Color(0xFF16213E).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFB87EFF).withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB87EFF).withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 4,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                blurRadius: 50,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 60,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: fullScreen ? 120 : (size > 80 ? size : 120),
                height: fullScreen ? 120 : (size > 80 ? size : 120),
                child: Lottie.asset(
                  'assets/anim/loading.json',
                  repeat: repeat,
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                text ?? 'Loading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  decoration: TextDecoration.none
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please wait',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none

                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Altrimenti mostra solo l'animazione come prima
    return Align(
      alignment: alignment,
      child: lottieWidget,
    );
  }
}

