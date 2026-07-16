import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/personal_payment_receiver_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/payment_pin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wallet_icons.dart';
import '../merchant/create_payment_pin_screen.dart';

/// Router `extra` payload for `/personal-payment/confirm`.
class PersonalPaymentConfirmArgs {
  const PersonalPaymentConfirmArgs({required this.receiver, required this.wallet});

  final PersonalPaymentReceiverModel receiver;
  final PurposeWalletModel wallet;
}

/// Personal Payment's counterpart to QrPaymentConfirmScreen — collects the
/// amount and an optional note, shows a review, then hands off to the
/// Payment PIN step. Structurally identical to the Merchant/QR Confirm
/// screens; only carries a receiver (not a merchant/qrId) forward.
class PersonalPaymentConfirmScreen extends ConsumerStatefulWidget {
  const PersonalPaymentConfirmScreen({super.key, required this.args});

  final PersonalPaymentConfirmArgs args;

  @override
  ConsumerState<PersonalPaymentConfirmScreen> createState() => _PersonalPaymentConfirmScreenState();
}

class _PersonalPaymentConfirmScreenState extends ConsumerState<PersonalPaymentConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isChecking = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChecking = true);
    final note = _noteController.text.trim();
    final args = PaymentPinFlowArgs(
      wallet: widget.args.wallet,
      amount: _amountController.text.trim(),
      personalTarget: PersonalPaymentTarget(
        receiverId: widget.args.receiver.userId,
        receiverName: widget.args.receiver.fullName,
        note: note.isEmpty ? null : note,
      ),
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
    final wallet = widget.args.wallet;
    final receiver = widget.args.receiver;
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
                      CircleAvatar(
                        backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
                        child: Text(
                          receiver.fullName.isNotEmpty ? receiver.fullName[0].toUpperCase() : 'S',
                          style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(receiver.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 140,
                    decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.edit_note_outlined)),
                  ),
                  const SizedBox(height: 12),
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
