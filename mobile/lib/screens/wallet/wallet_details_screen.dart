import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/wallet_icons.dart';
import '../../widgets/wallet_transaction_tile.dart';

class WalletDetailsScreen extends ConsumerStatefulWidget {
  const WalletDetailsScreen({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends ConsumerState<WalletDetailsScreen> {
  PurposeWalletModel? _wallet;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final wallet = await ref.read(walletRepositoryProvider).getPurposeWallet(widget.walletId);
      await ref.read(walletProvider.notifier).loadTransactions(purposeWalletId: widget.walletId);
      if (mounted) setState(() => _wallet = wallet);
    } on AppException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete wallet?'),
        content: Text('This will delete "${_wallet!.name}". You can only delete wallets with a zero balance.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(walletProvider.notifier).deletePurposeWallet(widget.walletId);
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(walletProvider).transactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(_wallet?.name ?? 'Wallet'),
        actions: _wallet == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/wallet/${widget.walletId}/edit', extra: _wallet),
                ),
                IconButton(
                  icon: _isDeleting
                      ? const LoadingIndicator(size: 18)
                      : const Icon(Icons.delete_outline),
                  onPressed: _isDeleting ? null : _confirmDelete,
                ),
              ],
      ),
      body: _isLoading
          ? const LoadingScreen()
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load wallet',
                      message: _loadError!,
                      onRetry: _load,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      FadeSlideIn(
                        child: PremiumCard.hero(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: WalletColors.fromHex(_wallet!.color).withValues(alpha: 0.22),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(WalletIcons.resolve(_wallet!.icon), color: WalletColors.fromHex(_wallet!.color)),
                              ),
                              const SizedBox(height: 16),
                              const Text('Wallet Balance', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(_wallet!.balance),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                              ),
                              if (_wallet!.purpose != null && _wallet!.purpose!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(_wallet!.purpose!, style: const TextStyle(color: Colors.white70)),
                              ],
                              if (_wallet!.spendingLimit != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Spending limit: ${CurrencyFormatter.format(_wallet!.spendingLimit!)}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 20),
                              PrimaryButton(
                                label: 'Transfer from Main Wallet',
                                onPressed: () => context.push('/wallet/transfer', extra: _wallet),
                              ),
                              const SizedBox(height: 12),
                              SecondaryButton(
                                label: 'Pay a Merchant',
                                icon: Icons.storefront_outlined,
                                onPressed: () => context.push('/merchants', extra: _wallet),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Transactions'),
                      const SizedBox(height: 8),
                      if (transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No transactions yet',
                            message: 'Transfers into this wallet will show up here.',
                          ),
                        )
                      else
                        ...transactions.map((tx) => WalletTransactionTile(transaction: tx)),
                    ],
                  ),
                ),
    );
  }
}
