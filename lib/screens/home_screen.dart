import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/auth_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/services/subscription_service.dart';
import 'package:usdtmining/widgets/flip_win_card.dart';
import 'package:usdtmining/widgets/mining_card.dart';
import 'package:usdtmining/widgets/mystery_box_card.dart';
import 'package:usdtmining/widgets/reward_card.dart';
import 'package:usdtmining/screens/premium_plans_screen.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';
import 'package:usdtmining/widgets/mining_background.dart';
import 'spin_wheel_screen.dart';

import '../models/subscription_plan.dart';

class _RecentPurchase {
  final String name;
  final String amount;
  final String city;

  _RecentPurchase(this.name, this.amount, this.city);
  
  // Factory constructor to generate random amount (min 100, max 10000)
  factory _RecentPurchase.withRandomAmount(String name, String city) {
    final random = Random();
    // Generate random amount between 100 and 10000
    final amount = (100 + random.nextDouble() * 9900);
    return _RecentPurchase(name, amount.toStringAsFixed(2), city);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<_RecentPurchase> _recentPurchases;
  late final ScrollController _tickerController;

  @override
  void initState() {
    super.initState();
    // Generate purchases with random amounts (min 100, max 10000)
    _recentPurchases = [
      _RecentPurchase.withRandomAmount('Aarav', 'Delhi'),
      _RecentPurchase.withRandomAmount('Aditi', 'Mumbai'),
      _RecentPurchase.withRandomAmount('Akash', 'Pune'),
      _RecentPurchase.withRandomAmount('Aman', 'Jaipur'),
      _RecentPurchase.withRandomAmount('Ananya', 'Kolkata'),
      _RecentPurchase.withRandomAmount('Arjun', 'Chennai'),
      _RecentPurchase.withRandomAmount('Bhavna', 'Surat'),
      _RecentPurchase.withRandomAmount('Chirag', 'Ahmedabad'),
      _RecentPurchase.withRandomAmount('Divya', 'Hyderabad'),
      _RecentPurchase.withRandomAmount('Esha', 'Indore'),
      _RecentPurchase.withRandomAmount('Farhan', 'Lucknow'),
      _RecentPurchase.withRandomAmount('Gauri', 'Nagpur'),
      _RecentPurchase.withRandomAmount('Harsh', 'Patna'),
      _RecentPurchase.withRandomAmount('Ishita', 'Bhopal'),
      _RecentPurchase.withRandomAmount('Jai', 'Noida'),
      _RecentPurchase.withRandomAmount('Karan', 'Chandigarh'),
      _RecentPurchase.withRandomAmount('Lavanya', 'Vadodara'),
      _RecentPurchase.withRandomAmount('Manish', 'Guwahati'),
      _RecentPurchase.withRandomAmount('Nisha', 'Kochi'),
      _RecentPurchase.withRandomAmount('Om', 'Coimbatore'),
      _RecentPurchase.withRandomAmount('Pooja', 'Vizag'),
      _RecentPurchase.withRandomAmount('Qadir', 'Agra'),
      _RecentPurchase.withRandomAmount('Rahul', 'Varanasi'),
      _RecentPurchase.withRandomAmount('Riya', 'Kota'),
      _RecentPurchase.withRandomAmount('Sanjay', 'Ranchi'),
      _RecentPurchase.withRandomAmount('Sneha', 'Mysuru'),
      _RecentPurchase.withRandomAmount('Tanvi', 'Thane'),
      _RecentPurchase.withRandomAmount('Varun', 'Aurangabad'),
      _RecentPurchase.withRandomAmount('Yash', 'Amritsar'),
      _RecentPurchase.withRandomAmount('Zoya', 'Jodhpur'),
      _RecentPurchase.withRandomAmount('Abhay', 'Nashik'),
      _RecentPurchase.withRandomAmount('Diya', 'Vijayawada'),
      _RecentPurchase.withRandomAmount('Ishan', 'Rajkot'),
      _RecentPurchase.withRandomAmount('Kavya', 'Madurai'),
      _RecentPurchase.withRandomAmount('Mira', 'Dehradun'),
      _RecentPurchase.withRandomAmount('Neha', 'Kanpur'),
      _RecentPurchase.withRandomAmount('Priya', 'Meerut'),
      _RecentPurchase.withRandomAmount('Rohan', 'Ghaziabad'),
      _RecentPurchase.withRandomAmount('Siya', 'Udaipur'),
      _RecentPurchase.withRandomAmount('Tarun', 'Jabalpur'),
      _RecentPurchase.withRandomAmount('Usha', 'Raipur'),
      _RecentPurchase.withRandomAmount('Veer', 'Durgapur'),
      _RecentPurchase.withRandomAmount('Waseem', 'Shillong'),
      _RecentPurchase.withRandomAmount('Xara', 'Imphal'),
      _RecentPurchase.withRandomAmount('Yuvraj', 'Gwalior'),
      _RecentPurchase.withRandomAmount('Zara', 'Allahabad'),
      _RecentPurchase.withRandomAmount('Ishaan', 'Jammu'),
      _RecentPurchase.withRandomAmount('Meera', 'Ajmer'),
      _RecentPurchase.withRandomAmount('Parth', 'Jamshedpur'),
      _RecentPurchase.withRandomAmount('Reyansh', 'Siliguri'),
    ];
    
    _tickerController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final miningService = Provider.of<MiningService>(context, listen: false);
      miningService.startMining();
      final adService = Provider.of<AdService>(context, listen: false);
      if (!adService.isInitialized) {
        adService.initialize();
      }
      _startTickerScroll();
    });
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  void _startTickerScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_tickerController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), _startTickerScroll);
        return;
      }
      final maxScroll = _tickerController.position.maxScrollExtent;
      if (maxScroll == 0) {
        Future.delayed(const Duration(milliseconds: 300), _startTickerScroll);
        return;
      }
      _tickerController
          .animateTo(
        maxScroll,
        duration: const Duration(seconds: 300),
        curve: Curves.linear,
      )
          .whenComplete(() {
        if (!mounted || !_tickerController.hasClients) return;
        _tickerController.jumpTo(0);
        _startTickerScroll();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MiningBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 8),
              _buildRecentPurchasesTicker(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       MiningCard()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.1, end: 0),
                      const SizedBox(height: 16),
                      Text(
                        'Daily Rewards',
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RewardCard(
                              title: 'Reward 1',
                              amount: '0.01 USDT',
                              icon: Icons.card_giftcard,
                              color: const Color(0xFF00D9FF),
                              rewardKey: 'reward1',
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 600.ms)
                                .slideY(begin: 0.1, end: 0),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RewardCard(
                              title: 'Reward 2',
                              amount: '0.02 USDT',
                              icon: Icons.stars,
                              color: const Color(0xFFFFD700),
                              rewardKey: 'reward2',
                            )
                                .animate()
                                .fadeIn(delay: 600.ms, duration: 600.ms)
                                .slideY(begin: 0.1, end: 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const MysteryBoxCard()
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),
                      const FlipWinCard()
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),
                      _buildPremiumBanner(context),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, child) {
        if (subscriptionService.currentTier != SubscriptionTier.free) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00FFCC),
                  Color(0xFF00D9FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.4),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars,
                  color: Color(0xFF0A0E27),
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium active',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF0A0E27),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No ads and accelerated mining!',
                        style: TextStyle(
                          color: Color(0xFF0A0E27),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0A0E27),
                ),
              ],
            ),
          );
        }

        final plan = planConfigs[subscriptionService.currentTier]!
            .displayName;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF283C86),
                Color(0xFF45A247),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF283C86).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rocket_launch, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upgrade Premium',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Remove every ad, speed up mining, and enjoy extra rewards.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Upgrade to unlock faster mining and more boosts.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 140),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF283C86),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: subscriptionService.isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PremiumPlansScreen(),
                                ),
                              );
                            },
                      child: subscriptionService.isLoading
                          ? const SizedBox(
                              height: 26,
                              width: 26,
                              child: AppLoadingIndicator(
                                size: 26,
                                alignment: Alignment.center,
                              ),
                            )
                          : const Text(
                              'Activate now',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.user;
        final displayName = user?.displayName ?? 'User';
        final photoUrl = user?.photoURL;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 40,
                      color: const Color(0xFF00D9FF),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 300.ms)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D9FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi,',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      displayName.split(' ').first,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SpinWheelScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/wallet.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentPurchasesTicker() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        controller: _tickerController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recentPurchases.length * 2,
        itemBuilder: (context, index) {
          final purchase = _recentPurchases[index % _recentPurchases.length];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${purchase.name} has withdrawn ${purchase.amount} USDT successfully',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
