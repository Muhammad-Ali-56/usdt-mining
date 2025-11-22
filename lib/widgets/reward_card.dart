import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/storage_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/meta_analytics_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';

class RewardCard extends StatefulWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final String rewardKey;

  const RewardCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.rewardKey,
  });

  @override
  State<RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<RewardCard> {
  int _clickCount = 0;
  bool _isLoading = false;
  final MetaAnalyticsService _metaAnalytics = MetaAnalyticsService();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadClickCount();
  }

  Future<void> _loadClickCount() async {
    final count = widget.rewardKey == 'reward1'
        ? await StorageService.getDailyReward1()
        : await StorageService.getDailyReward2();
    setState(() {
      _clickCount = count;
    });
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.7),
        child: const AppLoadingIndicator(
          text: 'Claiming reward...',
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
    super.dispose();
  }

  Future<void> _claimReward(AdService adService) async {
    if (_clickCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You reached the daily limit of 10 rewards'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _showLoadingOverlay();

    try {
      // Pre-carica l'ad mentre mostra il loading
      bool rewarded = true;
      if (adService.adsEnabled) {
        await adService.loadRewardedAd();
        rewarded = await adService.showRewardedAd(
          onUserEarnedReward: (_, __) {},
        );
      }

      if (!rewarded) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rewarded ad not available. Please try again later.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _metaAnalytics.logRewardAdWatched('daily_reward_${widget.rewardKey}');

      // Incrementa contatore
      final newCount = _clickCount + 1;
      if (widget.rewardKey == 'reward1') {
        await StorageService.setDailyReward1(newCount);
      } else {
        await StorageService.setDailyReward2(newCount);
      }

      // Add reward to balance and energy
      final miningService = Provider.of<MiningService>(context, listen: false);
      final rewardAmount = double.parse(widget.amount.split(' ')[0]);
      await miningService.creditBalance(rewardAmount, forceSync: true);
      miningService.addTapEnergy(miningService.tapEnergyRewardPerAd);
      await miningService.registerRewardedAd(
        source: 'daily_reward_${widget.rewardKey}',
      );

      setState(() {
        _clickCount = newCount;
      });

      // Mostra dialog animato con la ricompensa
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
                    Icon(Icons.star_rounded, color: widget.color, size: 64)
                        .animate()
                        .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(duration: 1200.ms, delay: 400.ms),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        decoration: TextDecoration.none,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      '+${widget.amount}',
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        decoration: TextDecoration.none,
                      ),
                    )
                        .animate()
                        .scale(delay: 400.ms, duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(duration: 1500.ms, delay: 500.ms),
                    const SizedBox(height: 12),
                    const Text(
                      'Added to your balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
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
    } catch (e) {
      debugPrint('Error claiming daily reward: $e');
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _clickCount >= 10;

    final adService = Provider.of<AdService>(context, listen: false);

    return GestureDetector(
      onTap: isDisabled || _isLoading ? null : () => _claimReward(adService),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withOpacity(0.2),
              widget.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 40,
              color: widget.color,
            )
                .animate(target: isDisabled ? 0 : 1)
                .scale(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 300),
                ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.amount,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.3)
                    : widget.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${10 - _clickCount}/10',
                style: TextStyle(
                  color: isDisabled ? Colors.grey : widget.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
