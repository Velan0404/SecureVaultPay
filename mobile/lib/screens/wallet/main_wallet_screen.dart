import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/purpose_wallet_card.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/section_header.dart';

/// The "Wallets" tab root — shows the Main Vault balance plus the full
/// Purpose Wallet grid (the Dashboard only shows a 4-tile preview of this).
class MainWalletScreen extends ConsumerStatefulWidget {
  const MainWalletScreen({super.key});

  @override
  ConsumerState<MainWalletScreen> createState() => _MainWalletScreenState();
}

class _MainWalletScreenState extends ConsumerState<MainWalletScreen> {
  bool _isLoadingDemo = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(walletProvider).dashboard == null) {
      ref.read(walletProvider.notifier).loadDashboard();
    }
  }

  Future<void> _loadDemoMoney() async {
    setState(() => _isLoadingDemo = true);
    try {
      await ref.read(walletProvider.notifier).loadDemoMoney();
      if (mounted) showAppSnackBar(context, 'Demo money added to your Main Wallet.', isError: false);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoadingDemo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);
    final dashboard = state.dashboard;
    final wallets = state.purposeWallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        actions: [
          if (dashboard != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.16),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  '${dashboard.totalWallets} Active',
                  style: const TextStyle(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/wallet/create'),
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: state.isLoading && dashboard == null
          ? const LoadingScreen()
          : dashboard == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load Main Wallet',
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    children: [
                      FadeSlideIn(
                        child: PremiumCard.hero(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shield_outlined, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  const Text('MAIN VAULT', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.18),
                                      borderRadius: AppRadius.pillRadius,
                                    ),
                                    child: const Text(
                                      'Secured',
                                      style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text('Available Balance', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(dashboard.mainWalletBalance),
                                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 20),
                              if (double.tryParse(dashboard.mainWalletBalance) == 0)
                                PrimaryButton(label: 'Load Demo Wallet', onPressed: _loadDemoMoney, isLoading: _isLoadingDemo)
                              else
                                SecondaryButton(
                                  label: 'Transfer to a Purpose Wallet',
                                  icon: Icons.swap_horiz_rounded,
                                  onPressed: wallets.isEmpty ? null : () => context.push('/wallet/transfer'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SectionHeader(title: 'Purpose Wallets', actionLabel: '${wallets.length} wallets'),
                      const SizedBox(height: 12),
                      if (wallets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: EmptyState(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'No Purpose Wallets yet',
                            message: 'Tap the + button to create your first wallet.',
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wallets.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (context, index) {
                            final wallet = wallets[index];
                            return PurposeWalletCard(wallet: wallet, onTap: () => context.push('/wallet/${wallet.id}'));
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
