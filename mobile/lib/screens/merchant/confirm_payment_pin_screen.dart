import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/merchant_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../providers/merchant_provider.dart';
import '../../providers/payment_pin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/centered_auth_scaffold.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import 'merchant_payment_result_screen.dart';

/// Router `extra` payload for `/payment-pin/confirm`.
class ConfirmPaymentPinArgs {
  const ConfirmPaymentPinArgs({required this.merchant, required this.wallet, required this.amount, required this.firstPin});

  final MerchantModel merchant;
  final PurposeWalletModel wallet;
  final String amount;
  final String firstPin;
}

/// Second half of first-time Payment PIN setup — re-entering the PIN to
/// confirm it, then (only once it's stored) completing this exact merchant
/// payment in one step, matching Part 4's "Store securely -> Complete
/// Payment -> Success" flow.
class ConfirmPaymentPinScreen extends ConsumerStatefulWidget {
  const ConfirmPaymentPinScreen({super.key, required this.args});

  final ConfirmPaymentPinArgs args;

  @override
  ConsumerState<ConfirmPaymentPinScreen> createState() => _ConfirmPaymentPinScreenState();
}

class _ConfirmPaymentPinScreenState extends ConsumerState<ConfirmPaymentPinScreen> {
  final _pinController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _onCompleted(String pin) async {
    if (pin != widget.args.firstPin) {
      showAppSnackBar(context, 'PINs do not match.');
      // Pop back to Create Payment PIN so the user starts the pair over —
      // matches the App PIN's own mismatch handling in spirit.
      context.pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(paymentPinRepositoryProvider).createPaymentPin(pin);
      final payment = await ref.read(merchantProvider.notifier).pay(
            merchantId: widget.args.merchant.id,
            purposeWalletId: widget.args.wallet.id,
            amount: widget.args.amount,
            paymentPin: pin,
          );
      if (mounted) {
        context.push(
          '/merchants/payment-result',
          extra: MerchantPaymentResultArgs.success(merchantName: widget.args.merchant.merchantName, amount: payment.amount),
        );
      }
    } on AppException catch (e) {
      if (mounted) context.push('/merchants/payment-result', extra: MerchantPaymentResultArgs.failed(errorMessage: e.message));
    } catch (_) {
      if (mounted) {
        context.push(
          '/merchants/payment-result',
          extra: const MerchantPaymentResultArgs.failed(errorMessage: 'Could not reach the server. Check your connection and try again.'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CenteredAuthScaffold(
      child: FadeSlideIn(
        child: PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.secondaryRed.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.password_outlined, color: AppColors.secondaryRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Confirm your Payment PIN', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Re-enter your 6-digit Payment PIN to confirm.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              if (_isSaving)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: LoadingIndicator()))
              else
                CodeInputField(controller: _pinController, obscureText: true, onCompleted: _onCompleted),
            ],
          ),
        ),
      ),
    );
  }
}
