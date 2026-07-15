import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../providers/merchant_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/centered_auth_scaffold.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import 'create_payment_pin_screen.dart';
import 'merchant_payment_result_screen.dart';

/// Returning merchant payments — the Payment PIN already exists, so this is
/// the only step between "Review Payment" and the payment executing. An
/// incorrect PIN lets the user retry in place (like an incorrect OTP);
/// every other failure (insufficient balance, inactive merchant, ...)
/// surfaces on the shared Payment Failed screen instead.
class EnterPaymentPinScreen extends ConsumerStatefulWidget {
  const EnterPaymentPinScreen({super.key, required this.args});

  final PaymentPinFlowArgs args;

  @override
  ConsumerState<EnterPaymentPinScreen> createState() => _EnterPaymentPinScreenState();
}

class _EnterPaymentPinScreenState extends ConsumerState<EnterPaymentPinScreen> {
  final _pinController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _onCompleted(String pin) async {
    setState(() => _isVerifying = true);
    try {
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
      if (!mounted) return;
      if (e.code == 'INVALID_PAYMENT_PIN') {
        showAppSnackBar(context, e.message);
        _pinController.clear();
        setState(() => _isVerifying = false);
      } else {
        context.push('/merchants/payment-result', extra: MerchantPaymentResultArgs.failed(errorMessage: e.message));
      }
    } catch (_) {
      if (mounted) {
        context.push(
          '/merchants/payment-result',
          extra: const MerchantPaymentResultArgs.failed(errorMessage: 'Could not reach the server. Check your connection and try again.'),
        );
      }
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
                decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.password_outlined, color: AppColors.primaryRed, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Enter your Payment PIN', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Authorize this payment to ${widget.args.merchant.merchantName}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_isVerifying)
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
