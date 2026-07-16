import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/purpose_wallet_model.dart';
import '../../models/qr_validation_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/merchant_icons.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import 'qr_payment_confirm_screen.dart';

/// Router `extra` payload for `/qr/preview`.
class QrPreviewRouteArgs {
  const QrPreviewRouteArgs({required this.validation, this.preselectedWallet});

  final QrValidationModel validation;

  /// Set when the scan was started from Wallet Details (that wallet is
  /// implicit, same shortcut as the existing "Pay a Merchant" button there)
  /// — Continue skips Select Purpose Wallet and goes straight to Confirm.
  /// Null for the Dashboard/general "Scan QR" entry point (unchanged
  /// default: Continue goes to Select Purpose Wallet).
  final PurposeWalletModel? preselectedWallet;
}

/// Shown right after a successful `GET /qr/validate/:qrId` — confirms which
/// merchant the scanned QR resolves to before the user picks a Purpose
/// Wallet. Scanning never consumes the QR, so backing out here is always
/// safe and leaves it re-scannable.
class QrMerchantPreviewScreen extends StatelessWidget {
  const QrMerchantPreviewScreen({super.key, required this.args});

  final QrPreviewRouteArgs args;

  @override
  Widget build(BuildContext context) {
    final validation = args.validation;
    final merchant = validation.merchant;

    return Scaffold(
      appBar: AppBar(title: const Text('Merchant')),
      body: Padding(
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
                    Text(merchant.merchantName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      MerchantCategories.label(merchant.merchantCategory),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text('Scanned via QR code', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                final wallet = args.preselectedWallet;
                if (wallet != null) {
                  context.push('/qr/confirm', extra: QrPaymentConfirmArgs(validation: validation, wallet: wallet));
                } else {
                  context.push('/pay-merchant', extra: validation);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
