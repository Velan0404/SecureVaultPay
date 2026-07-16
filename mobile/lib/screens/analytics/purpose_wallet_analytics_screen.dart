import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/purpose_wallet_analytics_model.dart';
import '../../providers/analytics_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/wallet_icons.dart';

/// Purpose Wallet Analytics — the 6 figures per wallet (current balance,
/// total deposited, total spent, remaining budget, spending percentage,
/// transaction count), for whichever range is selected on the Analytics
/// Dashboard (shares [analyticsProvider]'s state, no separate fetch).
class PurposeWalletAnalyticsScreen extends ConsumerStatefulWidget {
  const PurposeWalletAnalyticsScreen({super.key});

  @override
  ConsumerState<PurposeWalletAnalyticsScreen> createState() => _PurposeWalletAnalyticsScreenState();
}

class _PurposeWalletAnalyticsScreenState extends ConsumerState<PurposeWalletAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(analyticsProvider).dashboard == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(analyticsProvider.notifier).loadAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purpose Wallet Analytics')),
      body: state.isLoading && state.wallets.isEmpty
          ? ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => const _WalletAnalyticsShimmerCard(),
            )
          : state.wallets.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No wallet analytics',
                      message: 'Create your first Purpose Wallet to see its spending analytics here.',
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.wallets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => FadeSlideIn(
                    delay: Duration(milliseconds: index * 60),
                    child: _WalletAnalyticsCard(wallet: state.wallets[index]),
                  ),
                ),
    );
  }
}

class _WalletAnalyticsCard extends StatelessWidget {
  const _WalletAnalyticsCard({required this.wallet});

  final PurposeWalletAnalyticsModel wallet;

  @override
  Widget build(BuildContext context) {
    final color = WalletColors.fromHex(wallet.color);
    final spendingPercentage = wallet.spendingPercentage;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(WalletIcons.resolve(wallet.icon), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${wallet.transactionCount} transaction${wallet.transactionCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(CurrencyFormatter.format(wallet.currentBalance), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Deposited', value: CurrencyFormatter.format(wallet.totalDeposited))),
              Expanded(child: _Stat(label: 'Spent', value: CurrencyFormatter.format(wallet.totalSpent))),
            ],
          ),
          if (wallet.remainingBudget != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Remaining Budget',
                    value: CurrencyFormatter.format(wallet.remainingBudget!),
                  ),
                ),
                Text(
                  '${spendingPercentage!.toStringAsFixed(0)}% used',
                  style: TextStyle(
                    color: spendingPercentage >= 90 ? AppColors.danger : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (spendingPercentage / 100).clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) => ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(spendingPercentage >= 90 ? AppColors.danger : color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Same footprint as [_WalletAnalyticsCard] so the list doesn't reflow once
/// real figures replace the shimmer.
class _WalletAnalyticsShimmerCard extends StatelessWidget {
  const _WalletAnalyticsShimmerCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 44, height: 44, borderRadius: BorderRadius.circular(999)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 100, height: 14),
                    SizedBox(height: 6),
                    ShimmerBox(width: 70, height: 10),
                  ],
                ),
              ),
              const ShimmerBox(width: 60, height: 14),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: const [
              Expanded(child: ShimmerBox(width: 60, height: 24)),
              Expanded(child: ShimmerBox(width: 60, height: 24)),
            ],
          ),
        ],
      ),
    );
  }
}
