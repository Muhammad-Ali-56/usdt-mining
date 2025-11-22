import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/leaderboard_service.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboardService = context.read<LeaderboardService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1F3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<LeaderboardEntry>>(
            stream: leaderboardService.leaderboardStream(limit: 100),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: AppLoadingIndicator(
                    text: 'Loading leaderboard...',
                  ),
                );
              }

              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return _buildEmptyState(context);
              }

              final top = users.take(3).toList();
              final topTenList = users.take(10).toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Top Miners',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms),
                    const SizedBox(height: 24),
                    _buildTopRow(context, top),
                    const SizedBox(height: 32),
                    _buildLeaderboardTable(context, topTenList),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, List<LeaderboardEntry> top) {
    if (top.isEmpty) {
      return const SizedBox.shrink();
    }

    final widgets = <Widget>[];
    if (top.length > 1) {
      widgets.add(
        Expanded(
          child: _buildTop3Card(context, top[1], 2, Colors.grey)
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
        ),
      );
    }

    widgets.add(
      Expanded(
        child: _buildTop3Card(context, top[0], 1, const Color(0xFFFFD700))
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0),
      ),
    );

    if (top.length > 2) {
      widgets.add(
        Expanded(
          child: _buildTop3Card(context, top[2], 3, const Color(0xFFCD7F32))
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildLeaderboardTable(
    BuildContext context,
    List<LeaderboardEntry> ranked,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF11182F),
            Color(0xFF0B0F1F),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: const Color(0xFF00D9FF),
              ),
              const SizedBox(width: 12),
              Text(
                'Top 10 Rankings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (ranked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Start mining to secure your spot!',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white60),
              ),
            ),
          ...List.generate(
            ranked.length,
            (index) => _buildLeaderboardRow(
              context,
              ranked[index],
              index + 1,
            )
                .animate()
                .fadeIn(delay: (120 * index).ms, duration: 400.ms)
                .slideY(begin: 0.08, end: 0),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group, size: 56, color: Color(0xFF00D9FF)),
          const SizedBox(height: 16),
          Text(
            'No miners yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start mining to appear on the leaderboard!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Card(BuildContext context, LeaderboardEntry user, int rank, Color medalColor) {
    final isFirst = rank == 1;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(isFirst ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            medalColor.withOpacity(0.3),
            medalColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: medalColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor.withOpacity(0.3),
            ),
            child: Icon(
              rank == 1
                  ? Icons.emoji_events
                  : rank == 2
                      ? Icons.military_tech
                      : Icons.workspace_premium,
              color: medalColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '#$rank',
            style: TextStyle(
              color: medalColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: '', decimalDigits: 2).format(user.earnings),
            style: TextStyle(
              color: medalColor,
              fontSize: isFirst ? 16 : 14,
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
    );
  }

  Widget _buildLeaderboardRow(
    BuildContext context,
    LeaderboardEntry user,
    int rank,
  ) {
    final NumberFormat formatter = NumberFormat.compactCurrency(
      symbol: '',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF171F38),
        border: Border.all(
          color: rank <= 10
              ? const Color(0xFF00D9FF).withOpacity(0.2)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: rank <= 10
                    ? [
                        const Color(0xFF00D9FF),
                        const Color(0xFF00FFC6),
                      ]
                    : [
                        Colors.white24,
                        Colors.white10,
                      ],
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Color(0xFF0A0E27),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(user.earnings)} USDT',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF00FFC6),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '+${NumberFormat('#,##0.00').format(user.earnings)}',
              style: const TextStyle(
                color: Color(0xFF00D9FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
