import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

/// Router `extra` payload for `/merchants/payment-result` — shared by both
/// the Create-Payment-PIN-first and Enter-Payment-PIN paths, so the
/// success/failure UI is written once.
class MerchantPaymentResultArgs {
  const MerchantPaymentResultArgs.success({required this.merchantName, required this.amount})
      : success = true,
        errorMessage = null;

  const MerchantPaymentResultArgs.failed({required this.errorMessage})
      : success = false,
        merchantName = null,
        amount = null;

  final bool success;
  final String? merchantName;
  final String? amount;
  final String? errorMessage;
}

/// Payment Success / Payment Failed — the final step of the Merchant
/// Payment flow, reached after either the first-time Create+Confirm Payment
/// PIN path or the returning Enter Payment PIN path. Visually mirrors the
/// Transaction Authentication wizard's own success/failed steps.
class MerchantPaymentResultScreen extends StatelessWidget {
  const MerchantPaymentResultScreen({super.key, required this.args});

  final MerchantPaymentResultArgs args;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(args.success ? 'Payment Successful' : 'Payment Failed'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (args.success ? AppColors.success : AppColors.danger).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      args.success ? Icons.check_rounded : Icons.close_rounded,
                      color: args.success ? AppColors.success : AppColors.danger,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    args.success ? 'Payment Successful' : 'Payment Cancelled',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    args.success
                        ? '${CurrencyFormatter.format(args.amount!)} paid to ${args.merchantName}.'
                        : (args.errorMessage ?? 'This payment could not be completed.'),
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: args.success ? 'Done' : 'Try Again',
                    onPressed: () => args.success ? context.go('/dashboard') : context.pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
