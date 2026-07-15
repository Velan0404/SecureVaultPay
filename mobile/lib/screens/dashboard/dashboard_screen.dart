import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/purpose_wallet_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/wallet_transaction_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(walletProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(walletProvider);
    final dashboard = state.dashboard;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: FadeSlideIn(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Good day 👋', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            user?.fullName ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _RoundIconButton(icon: Icons.notifications_none_rounded, onTap: () => context.go('/profile')),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(gradient: AppColors.buttonGradient, shape: BoxShape.circle),
                        child: Text(
                          (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'S').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: state.isLoading && dashboard == null
                  ? const LoadingScreen()
                  : dashboard == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: EmptyState(
                              icon: Icons.error_outline,
                              title: 'Could not load your wallets',
                              message: state.errorMessage ?? 'Something went wrong.',
                              onRetry: () => ref.read(walletProvider.notifier).loadDashboard(),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(walletProvider.notifier).loadDashboard(),
                          color: AppColors.primaryRed,
                          backgroundColor: AppColors.surface,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            children: [
                              FadeSlideIn(
                                child: PremiumCard.hero(
                                  onTap: () => context.go('/wallet/main'),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.shield_outlined, color: Colors.white70, size: 16),
                                          const SizedBox(width: 6),
                                          const Text('Total Balance', style: TextStyle(color: Colors.white70)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withValues(alpha: 0.18),
                                              borderRadius: AppRadius.pillRadius,
                                            ),
                                            child: const Text(
                                              'Secure',
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        CurrencyFormatter.format(dashboard.mainWalletBalance),
                                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          StatTile(label: 'Wallets', value: '${dashboard.totalWallets}', dark: true),
                                          const SizedBox(width: 10),
                                          StatTile(
                                            label: 'Allocated',
                                            value: CurrencyFormatter.format(dashboard.totalAllocated),
                                            dark: true,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.add_rounded,
                                      label: 'Add Wallet',
                                      color: AppColors.primaryRed,
                                      onTap: () => context.push('/wallet/create'),
                                    ),
                                  ),
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.swap_horiz_rounded,
                                      label: 'Transfer',
                                      color: AppColors.info,
                                      onTap: dashboard.purposeWallets.isEmpty ? null : () => context.push('/wallet/transfer'),
                                    ),
                                  ),
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.history_rounded,
                                      label: 'History',
                                      color: AppColors.categoryPurple,
                                      onTap: () => context.push('/wallet/transactions'),
                                    ),
                                  ),
                                  Expanded(
                                    child: QuickActionButton(
                                      icon: Icons.calendar_month_rounded,
                                      label: 'Schedule',
                                      color: AppColors.categoryGold,
                                      onTap: () => context.go('/schedule'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              SectionHeader(
                                title: 'Purpose Wallets',
                                actionLabel: 'View all',
                                onAction: () => context.go('/wallet/main'),
                              ),
                              const SizedBox(height: 12),
                              if (dashboard.purposeWallets.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: EmptyState(
                                    icon: Icons.account_balance_wallet_outlined,
                                    title: 'No Purpose Wallets yet',
                                    message: 'Create one to start organizing money for groceries, travel, savings, and more.',
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: dashboard.purposeWallets.length.clamp(0, 4),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.95,
                                  ),
                                  itemBuilder: (context, index) {
                                    final wallet = dashboard.purposeWallets[index];
                                    return PurposeWalletCard(
                                      wallet: wallet,
                                      onTap: () => context.push('/wallet/${wallet.id}'),
                                    );
                                  },
                                ),
                              const SizedBox(height: 26),
                              SectionHeader(
                                title: 'Recent Transactions',
                                actionLabel: 'See all',
                                onAction: () => context.push('/wallet/transactions'),
                              ),
                              if (dashboard.recentTransactions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('No activity yet.', style: TextStyle(color: AppColors.textSecondary)),
                                )
                              else
                                ...dashboard.recentTransactions.take(5).map((tx) => WalletTransactionTile(transaction: tx)),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}
