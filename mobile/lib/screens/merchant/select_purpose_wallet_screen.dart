import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/purpose_wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/purpose_wallet_card.dart';

/// "Pay Merchant" (Dashboard quick action) -> Select Purpose Wallet -> the
/// existing Merchant List screen. Main Wallet is never offered here — only
/// [PurposeWalletModel]s are listed, matching every other merchant-payment
/// entry point in the app.
///
/// [onSelect] is null for that original tap-to-pay entry point (unchanged
/// default: push to Merchant List). The QR Merchant Payment flow passes a
/// callback that continues to the QR payment confirmation screen instead —
/// reusing this same wallet-picker UI rather than duplicating it.
class SelectPurposeWalletScreen extends ConsumerStatefulWidget {
  const SelectPurposeWalletScreen({super.key, this.onSelect});

  final void Function(BuildContext context, PurposeWalletModel wallet)? onSelect;

  @override
  ConsumerState<SelectPurposeWalletScreen> createState() => _SelectPurposeWalletScreenState();
}

class _SelectPurposeWalletScreenState extends ConsumerState<SelectPurposeWalletScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(walletProvider).dashboard == null) {
      ref.read(walletProvider.notifier).loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);
    final wallets = state.purposeWallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay a Merchant'),
        // Only the top-level entry point offers "scan a QR instead" — not
        // when this screen is reused mid-flow for QR payment's own wallet
        // selection step (widget.onSelect != null in that case).
        actions: widget.onSelect != null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan merchant QR',
                  onPressed: () => context.push('/qr/scan'),
                ),
              ],
      ),
      body: state.isLoading && state.dashboard == null
          ? const LoadingScreen()
          : wallets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No Purpose Wallets yet',
                      message: 'Create a Purpose Wallet and add money to it before paying a merchant.',
                      onRetry: () => ref.read(walletProvider.notifier).loadDashboard(),
                      retryLabel: 'Refresh',
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: wallets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    return PurposeWalletCard(
                      wallet: wallet,
                      onTap: () => widget.onSelect != null
                          ? widget.onSelect!(context, wallet)
                          : context.push('/merchants', extra: wallet),
                    );
                  },
                ),
    );
  }
}
