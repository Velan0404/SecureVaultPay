import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/merchant_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/merchant_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/merchant_icons.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/wallet_icons.dart';

/// Entry point for "Choose Purpose Wallet -> Merchant List" — always bound to
/// one already-selected Purpose Wallet (pushed from Wallet Details). Main
/// Wallet is never reachable here since only a [PurposeWalletModel] is ever
/// accepted, and every downstream screen carries this same wallet forward.
class MerchantListScreen extends ConsumerStatefulWidget {
  const MerchantListScreen({super.key, required this.wallet});

  final PurposeWalletModel wallet;

  @override
  ConsumerState<MerchantListScreen> createState() => _MerchantListScreenState();
}

class _MerchantListScreenState extends ConsumerState<MerchantListScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(merchantProvider.notifier).loadMerchants();
      ref.read(merchantProvider.notifier).loadTotalSpent();
    });
  }

  void _selectCategory(String? category) {
    setState(() => _selectedCategory = category);
    ref.read(merchantProvider.notifier).loadMerchants(category: category);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantProvider);
    final walletColor = WalletColors.fromHex(widget.wallet.color);

    return Scaffold(
      appBar: AppBar(title: const Text('Pay a Merchant')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: FadeSlideIn(
              child: PremiumCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: walletColor.withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: Icon(WalletIcons.resolve(widget.wallet.icon), color: walletColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Paying from', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(widget.wallet.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Available', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(widget.wallet.balance),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (state.totalSpent != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total spent to merchants: ${CurrencyFormatter.format(state.totalSpent!)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(label: 'All', selected: _selectedCategory == null, onTap: () => _selectCategory(null)),
                const SizedBox(width: 8),
                ...MerchantCategories.all.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: MerchantCategories.label(category),
                      selected: _selectedCategory == category,
                      onTap: () => _selectCategory(category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.isLoading && state.merchants.isEmpty
                ? const LoadingScreen()
                : state.errorMessage != null && state.merchants.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: EmptyState(
                            icon: Icons.error_outline,
                            title: 'Could not load merchants',
                            message: state.errorMessage!,
                            onRetry: () => ref.read(merchantProvider.notifier).loadMerchants(category: _selectedCategory),
                          ),
                        ),
                      )
                    : state.merchants.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: EmptyState(
                                icon: Icons.storefront_outlined,
                                title: 'No merchants in this category',
                                message: 'Try a different category.',
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: state.merchants.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.95,
                            ),
                            itemBuilder: (context, index) {
                              final merchant = state.merchants[index];
                              return _MerchantCard(
                                merchant: merchant,
                                onTap: () => context.push('/merchants/${merchant.id}', extra: widget.wallet),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryRed : AppColors.surfaceElevated,
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.merchant, required this.onTap});

  final MerchantModel merchant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(MerchantIcons.resolve(merchant.merchantLogo), color: AppColors.primaryRed, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              merchant.merchantName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              MerchantCategories.label(merchant.merchantCategory),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
