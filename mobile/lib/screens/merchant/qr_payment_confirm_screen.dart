import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/purpose_wallet_model.dart';
import '../../models/qr_validation_model.dart';
import '../../providers/payment_pin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/merchant_icons.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wallet_icons.dart';
import 'create_payment_pin_screen.dart';

/// Router `extra` payload for `/qr/confirm` — bundles the validated QR
/// merchant and the Purpose Wallet chosen to fund it.
class QrPaymentConfirmArgs {
  const QrPaymentConfirmArgs({required this.validation, required this.wallet});

  final QrValidationModel validation;
  final PurposeWalletModel wallet;
}

/// QR Merchant Payment's counterpart to MerchantPaymentScreen — collects the
/// amount and shows a review before handing off to the Payment PIN step.
/// Structurally identical to the tap-to-pay Confirm screen; only carries a
/// `qrId` forward as well, so the eventual pay call goes through
/// POST /qr/:qrId/pay instead of POST /merchant/:id/pay.
class QrPaymentConfirmScreen extends ConsumerStatefulWidget {
  const QrPaymentConfirmScreen({super.key, required this.args});

  final QrPaymentConfirmArgs args;

  @override
  ConsumerState<QrPaymentConfirmScreen> createState() => _QrPaymentConfirmScreenState();
}

class _QrPaymentConfirmScreenState extends ConsumerState<QrPaymentConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isChecking = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChecking = true);
    final args = PaymentPinFlowArgs(
      merchant: widget.args.validation.merchant,
      wallet: widget.args.wallet,
      amount: _amountController.text.trim(),
      qrId: widget.args.validation.qrId,
    );
    try {
      final hasPaymentPin = await ref.read(paymentPinRepositoryProvider).hasPaymentPin();
      if (!mounted) return;
      context.push(hasPaymentPin ? '/payment-pin/enter' : '/payment-pin/create', extra: args);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = widget.args.validation.merchant;
    final wallet = widget.args.wallet;
    final walletColor = WalletColors.fromHex(wallet.color);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeSlideIn(
          child: Form(
            key: _formKey,
            child: PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Pay to', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(MerchantIcons.resolve(merchant.merchantLogo), color: AppColors.primaryRed),
                      const SizedBox(width: 10),
                      Text(merchant.merchantName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('From', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(WalletIcons.resolve(wallet.icon), color: walletColor),
                      const SizedBox(width: 10),
                      Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        '${CurrencyFormatter.format(wallet.balance)} available',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee), prefixText: '₹ '),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Amount is required.';
                      if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) {
                        return 'Enter a valid amount (up to 2 decimals).';
                      }
                      if (double.parse(value.trim()) <= 0) return 'Amount must be greater than zero.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(label: 'Continue', onPressed: _continue, isLoading: _isChecking),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
