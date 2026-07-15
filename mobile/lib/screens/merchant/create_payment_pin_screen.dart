import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/merchant_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/centered_auth_scaffold.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import 'confirm_payment_pin_screen.dart';

/// Router `extra` payload for `/payment-pin/create` and `/payment-pin/enter`
/// — carries the payment details forward through the Payment PIN step so
/// the actual merchant payment can be executed once the PIN is ready.
class PaymentPinFlowArgs {
  const PaymentPinFlowArgs({required this.merchant, required this.wallet, required this.amount});

  final MerchantModel merchant;
  final PurposeWalletModel wallet;
  final String amount;
}

/// First merchant payment only — creating a brand new Payment PIN. Matches
/// the App PIN's Create screen design; unlike the App PIN, this is a
/// separate two-screen flow (Create, then Confirm) rather than one screen
/// managing both steps, and it authorizes money movement rather than
/// unlocking the app.
class CreatePaymentPinScreen extends StatefulWidget {
  const CreatePaymentPinScreen({super.key, required this.args});

  final PaymentPinFlowArgs args;

  @override
  State<CreatePaymentPinScreen> createState() => _CreatePaymentPinScreenState();
}

class _CreatePaymentPinScreenState extends State<CreatePaymentPinScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onCompleted(String pin) {
    context.push(
      '/payment-pin/confirm',
      extra: ConfirmPaymentPinArgs(merchant: widget.args.merchant, wallet: widget.args.wallet, amount: widget.args.amount, firstPin: pin),
    );
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
              Text('Create your Payment PIN', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Choose a 6-digit PIN to authorize payments of ${CurrencyFormatter.format(widget.args.amount)} to ${widget.args.merchant.merchantName}. '
                'This is separate from your App PIN.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              CodeInputField(controller: _pinController, obscureText: true, onCompleted: _onCompleted),
            ],
          ),
        ),
      ),
    );
  }
}
