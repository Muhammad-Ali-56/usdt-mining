import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/services/referral_service.dart';
import 'package:usdtmining/services/storage_service.dart';
import 'package:usdtmining/screens/withdraw_screen.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';
import 'package:usdtmining/widgets/mining_background.dart';
import 'package:clipboard/clipboard.dart' as clipboard;
import 'package:share_plus/share_plus.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MiningBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2749),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF00D9FF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Manage your funds',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.1, end: 0),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00D9FF),
                labelColor: const Color(0xFF00D9FF),
                unselectedLabelColor: const Color(0xFFB0B8C4),
                tabs: const [
                  Tab(text: 'Mining'),
                  Tab(text: 'Referral'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    MiningTab(),
                    ReferralTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiningTab extends StatelessWidget {
  const MiningTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MiningService>(
      builder: (context, miningService, child) {
        final balance = miningService.currentBalance;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00D9FF).withOpacity(0.2),
                      const Color(0xFF00D9FF).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Mining Balance',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      NumberFormat.currency(symbol: '', decimalDigits: 5)
                          .format(balance),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: const Color(0xFF00D9FF),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'USDT',
                      style: TextStyle(
                        color: Color(0xFFB0B8C4),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(delay: 200.ms),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: balance >= 100
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WithdrawScreen(),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Withdraw'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: balance >= 100
                      ? const Color(0xFF00D9FF)
                      : Colors.grey,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
              if (balance < 100) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You must have at least 100 USDT to withdraw',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.orange,
                              ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ReferralTab extends StatefulWidget {
  const ReferralTab({super.key});

  @override
  State<ReferralTab> createState() => _ReferralTabState();
}

class _ReferralTabState extends State<ReferralTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReferralService>(
      builder: (context, referralService, child) {
        if (referralService.isLoading) {
          return const Center(
            child: AppLoadingIndicator(
              text: 'Loading referrals...',
        ),
      );
    }

        final referralCode = referralService.referralCode ?? 'Loading...';
        final referrals = referralService.referrals;
        final totalEarnings = referralService.totalReferralEarnings;
        final totalReferrals = referralService.totalReferrals;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Referral Code Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00D9FF).withOpacity(0.2),
                      const Color(0xFFB87EFF).withOpacity(0.15),
                    ],
                  ),
              borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withOpacity(0.3),
                    width: 2,
                  ),
            ),
            child: Column(
              children: [
                    Row(
                      children: [
                Container(
                          padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                            color: const Color(0xFF00D9FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            color: Color(0xFF00D9FF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Referral Code',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Share this code to earn rewards',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        await clipboard.FlutterClipboard.copy(referralCode);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral code copied!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0E27),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00D9FF).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                referralCode,
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                  color: const Color(0xFF00D9FF),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                        ),
                    textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.copy,
                              color: Color(0xFF00D9FF),
                              size: 24,
                            ),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await clipboard.FlutterClipboard.copy(referralCode);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Referral code copied!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy, size: 20),
                            label: const Text('Copy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2749),
                              foregroundColor: const Color(0xFF00D9FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: const Color(0xFF00D9FF).withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                // App store links
                                final androidLink = 'https://play.google.com/store/apps/details?id=com.easyranktools.usdtmining';
                                final iosLink = 'https://apps.apple.com/app/id<YOUR_APP_ID>'; // Replace <YOUR_APP_ID> with your actual App Store ID
                                final appLink = Platform.isAndroid ? androidLink : iosLink;
                                
                                final message = '''🚀 Join Bruno USDT Miner and start earning USDT!

Use my referral code to get bonus rewards:
$referralCode

Download now and start mining USDT! 💰

📱 Download the app: $appLink''';
                                await Share.share(
                                  message,
                                  subject: 'Join Bruno USDT Miner',
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error sharing: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.share, size: 20),
                            label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D9FF),
                              foregroundColor: const Color(0xFF0A0E27),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                ),
                const SizedBox(height: 8),
                Text(
                      'Tap code to copy or use buttons below',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: -0.1, end: 0),
          const SizedBox(height: 24),
              // Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2749),
                    borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00FF88).withOpacity(0.3),
                        ),
                  ),
                  child: Column(
                    children: [
                          const Icon(
                            Icons.group,
                            color: Color(0xFF00FF88),
                            size: 32,
                          ),
                      const SizedBox(height: 12),
                      Text(
                            'Total Referrals',
                            style: Theme
                                .of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                            '$totalReferrals',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              color: const Color(0xFF00FF88),
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2749),
                    borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                        ),
                  ),
                  child: Column(
                    children: [
                          const Icon(
                            Icons.trending_up,
                            color: Color(0xFFFFD700),
                            size: 32,
                          ),
                      const SizedBox(height: 12),
                      Text(
                        'Total Earnings',
                            style: Theme
                                .of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(symbol: '', decimalDigits: 2)
                                .format(totalEarnings),
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Text(
                        'USDT',
                        style: TextStyle(
                          color: Color(0xFFB0B8C4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
              .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              // Referrals List Header
              if (referrals.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Color(0xFF00D9FF),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Referrals',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms),
                const SizedBox(height: 16),
                // Referrals List
                ...referrals
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final referral = entry.value;
                  return _buildReferralCard(referral, index)
                      .animate()
                      .fadeIn(delay: Duration(
                      milliseconds: 500 + (index * 100)), duration: 400.ms)
                      .slideX(begin: -0.1, end: 0);
                }).toList(),
              ] else
                ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2749),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Referrals Yet',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share your referral code to invite friends and earn rewards!',
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms),
                ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferralCard(ReferralData referral, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2749),
            const Color(0xFF0A0E27),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar/Number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFFB87EFF)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.userName,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  referral.userEmail.isNotEmpty
                      ? referral.userEmail
                      : 'No email',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_formatDate(referral.joinedAt)}',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Reward Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFBF69)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: Color(0xFF0A0E27),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${referral.rewardEarned.toStringAsFixed(2)} USDT',
                  style: const TextStyle(
                    color: Color(0xFF0A0E27),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
