import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/merchant_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/merchant_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/merchant_icons.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import 'merchant_payment_screen.dart';

/// Merchant info + "Pay Now" — the wallet that will fund the payment was
/// already chosen on the previous screen and is only ever carried forward,
/// never re-selected here.
class MerchantDetailsScreen extends ConsumerStatefulWidget {
  const MerchantDetailsScreen({super.key, required this.merchantId, required this.wallet});

  final String merchantId;
  final PurposeWalletModel wallet;

  @override
  ConsumerState<MerchantDetailsScreen> createState() => _MerchantDetailsScreenState();
}

class _MerchantDetailsScreenState extends ConsumerState<MerchantDetailsScreen> {
  bool _isLoading = true;
  String? _loadError;
  MerchantModel? _merchant;

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
      final merchant = await ref.read(merchantRepositoryProvider).getMerchant(widget.merchantId);
      if (mounted) setState(() => _merchant = merchant);
    } on AppException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_merchant?.merchantName ?? 'Merchant'),
        actions: _merchant == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.qr_code_2_outlined),
                  tooltip: 'Show demo QR',
                  onPressed: () => context.push('/merchants/${widget.merchantId}/qr', extra: _merchant),
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
                      title: 'Could not load merchant',
                      message: _loadError!,
                      onRetry: _load,
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final merchant = _merchant!;
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FadeSlideIn(
                            child: PremiumCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(MerchantIcons.resolve(merchant.merchantLogo), color: AppColors.primaryRed, size: 28),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    merchant.merchantName,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    MerchantCategories.label(merchant.merchantCategory),
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Paying from ${widget.wallet.name}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          PrimaryButton(
                            label: 'Pay Now',
                            onPressed: () => context.push(
                              '/merchants/${widget.merchantId}/pay',
                              extra: MerchantPaymentRouteArgs(merchant: merchant, wallet: widget.wallet),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
