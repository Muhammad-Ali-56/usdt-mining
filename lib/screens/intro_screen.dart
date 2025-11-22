import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:usdtmining/screens/login_screen.dart';
import 'package:usdtmining/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/widgets/mining_background.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPage> _pages = [
    IntroPage(
      title: 'Welcome to\nBruno USDT Miner',
      description: 'Start mining USDT easily and securely',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF00D9FF),
    ),
    IntroPage(
      title: 'Automatic Mining',
      description: 'Your mining continues 24/7 even when the app is closed',
      icon: Icons.speed,
      color: const Color(0xFFFFD700),
    ),
    IntroPage(
      title: 'Earn with Referrals',
      description: 'Share the app and earn rewards for each new user',
      icon: Icons.people,
      color: const Color(0xFF00FF88),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MiningBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              _buildPageIndicator(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _currentPage == _pages.length - 1
                    ? _buildGetStartedButton()
                    : _buildNextButton(),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(IntroPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  page.color.withOpacity(0.3),
                  page.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: page.color,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: page.color,
                  fontWeight: FontWeight.bold,
                ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, delay: 400.ms),
          const SizedBox(height: 24),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                ),
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          width: _currentPage == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentPage == index
                ? const Color(0xFF00D9FF)
                : Colors.grey.withOpacity(0.3),
          ),
        ).animate().scale(duration: 300.ms),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: const Color(0xFF00D9FF),
      ),
      child: const Text('Next'),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: () async {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.markFirstTimeDone();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF0A0E27),
      ),
      child: const Text(
        'Get Started',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }
}

class IntroPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  IntroPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
