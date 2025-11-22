import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/auth_service.dart';
import 'package:usdtmining/services/storage_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';
import 'package:usdtmining/widgets/mining_background.dart';
import 'package:usdtmining/screens/intro_video_screen.dart';
import 'package:usdtmining/screens/main_tabs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final TextEditingController _referralCodeController = TextEditingController();
  bool _showReferralInput = false;

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final referralCode = _referralCodeController.text.trim();
      final result = await authService.signInWithGoogle(
        referralCode: referralCode.isNotEmpty ? referralCode : null,
      );
      
      // Se il login è riuscito, naviga direttamente
      if (result != null && result.user != null && mounted) {
        // Verifica se l'utente ha già visto il video intro
        final hasSeenVideo = await StorageService.hasSeenIntroVideo();
        
        if (!mounted) return;
        
        // Rimuovi tutte le route precedenti e naviga
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => hasSeenVideo 
                ? const MainTabs() 
                : const IntroVideoScreen(),
          ),
          (route) => false, // Rimuovi tutte le route precedenti
        );
      } else if (result == null && mounted) {
        // L'utente ha annullato il login
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MiningBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00D9FF).withOpacity(0.3),
                            const Color(0xFF00D9FF).withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: Color(0xFF00D9FF),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(delay: 200.ms, duration: 600.ms),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'Bruno USDT Miner',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: const Color(0xFF00D9FF),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      'Start mining USDT today',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 32),
                    // Referral Code Toggle
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showReferralInput = !_showReferralInput;
                        });
                      },
                      icon: Icon(
                        _showReferralInput
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF00D9FF),
                      ),
                      label: Text(
                        _showReferralInput
                            ? 'Hide Referral Code'
                            : 'Have a Referral Code?',
                        style: const TextStyle(color: Color(0xFF00D9FF)),
                      ),
                    ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
                    // Referral Code Input
                    if (_showReferralInput)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: TextField(
                          controller: _referralCodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter referral code (optional)',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            filled: true,
                            fillColor: const Color(0xFF1E2749),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF00D9FF).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF00D9FF).withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF00D9FF),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: -0.1, end: 0),
                    const SizedBox(height: 32),
                    // Google Sign In Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9FF).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.g_mobiledata, size: 24);
                          },
                        ),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 60),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0A0E27),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 24),
                    // Info text
                    Text(
                      'By continuing you accept our Terms & Conditions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
                    const Spacer(),
                    // Features
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeature(Icons.security, 'Secure'),
                        _buildFeature(Icons.speed, 'Fast'),
                        _buildFeature(Icons.attach_money, 'Free'),
                      ],
                    ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const AppLoadingIndicator(
                  text: 'Signing in...',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2749),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF00D9FF), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
