import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:usdtmining/models/subscription_plan.dart';
import 'package:usdtmining/services/subscription_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';
import 'package:usdtmining/widgets/mining_background.dart';

class PremiumPlansScreen extends StatelessWidget {
  const PremiumPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: const Color(0xFF1A1F3A),
      ),
      body: Stack(
        children: [
          MiningBackground(
            child: SafeArea(
              child: Consumer<SubscriptionService>(
            builder: (context, subscriptionService, child) {
              final tiers = subscriptionService.availableTiers;
              final currentTier = subscriptionService.currentTier;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Unlock realistic mining perks',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the experience that matches your goals. Each plan boosts mining speed and unlocks more daily boosts.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (!subscriptionService.isAvailable) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'In-app purchases not available on this device.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ...tiers.map(
                      (tier) => _PlanCard(
                        tier: tier,
                        config: planConfigs[tier]!,
                        isCurrent: tier == currentTier,
                        isProcessing: subscriptionService.isLoading,
                        productDetails: tier == SubscriptionTier.free
                            ? null
                            : subscriptionService.getProductForTier(tier),
                        onSelect: () async {
                          if (subscriptionService.isLoading) return;
                          
                          if (tier == SubscriptionTier.free) {
                            await subscriptionService.selectTier(tier);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Free plan activated.'),
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          } else {
                            // Acquisto reale
                            final success = await subscriptionService.purchaseSubscription(tier);
                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Processing purchase for ${planConfigs[tier]!.displayName}...',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Purchase could not be completed. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        if (subscriptionService.isLoading) return;
                        await subscriptionService.restorePurchases();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Restoring purchases...'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore Purchases'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            },
              ),
            ),
          ),

          // Loading overlay
          Consumer<SubscriptionService>(
            builder: (context, subscriptionService, child) {
              if (!subscriptionService.isLoading) return const SizedBox.shrink();
              return Container(
                color: Colors.black.withOpacity(0.7),
                child: const AppLoadingIndicator(
                  text: 'Processing purchase...',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tier,
    required this.config,
    required this.isCurrent,
    required this.isProcessing,
    required this.onSelect,
    this.productDetails,
  });

  final SubscriptionTier tier;
  final PlanConfig config;
  final bool isCurrent;
  final bool isProcessing;
  final VoidCallback onSelect;
  final ProductDetails? productDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final accent = tier == SubscriptionTier.free
        ? const Color(0xFF607D8B)
        : tier == SubscriptionTier.starter
            ? const Color(0xFF00D9FF)
            : tier == SubscriptionTier.pro
                ? const Color(0xFFFFC107)
                : const Color(0xFFAB47BC);

    final miningPerDay = (config.miningRate * 86400).toStringAsFixed(5);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.25),
            accent.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.displayName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      config.description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitRow(
            textTheme,
            accent,
            Icons.speed,
            'Mining rate: $miningPerDay USDT/day',
          ),
          _buildBenefitRow(
            textTheme,
            accent,
            Icons.extension,
            'Boost uses: ${config.featureUsesPerDay} per feature daily',
          ),
          _buildBenefitRow(
            textTheme,
            accent,
            Icons.bolt,
            'Energy from ads: +${config.tapEnergyAdReward.toStringAsFixed(0)}%',
          ),
          _buildBenefitRow(
            textTheme,
            accent,
            Icons.touch_app,
            'Energy cost per tap: ${config.tapEnergyCostPerTap.toStringAsFixed(1)}%',
          ),
          _buildBenefitRow(
            textTheme,
            accent,
            Icons.auto_mode,
            'Auto click interval: ${config.autoClickInterval.inMilliseconds} ms',
          ),
          if (tier != SubscriptionTier.free && productDetails != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    productDetails!.price,
                    style: textTheme.titleLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/month',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isProcessing || isCurrent ? null : onSelect,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: accent,
              foregroundColor: const Color(0xFF0A0E27),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isCurrent
                  ? 'Current plan'
                  : tier == SubscriptionTier.free
                      ? 'Select plan'
                      : 'Subscribe Now',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    return card
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildBenefitRow(
    TextTheme textTheme,
    Color accent,
    IconData icon,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

