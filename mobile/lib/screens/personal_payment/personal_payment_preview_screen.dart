import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/personal_payment_receiver_model.dart';
import '../../models/purpose_wallet_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import 'personal_payment_confirm_screen.dart';

/// Router `extra` payload for `/personal-payment/preview`.
class PersonalPaymentScanArgs {
  const PersonalPaymentScanArgs({required this.receiver, this.preselectedWallet});

  final PersonalPaymentReceiverModel receiver;

  /// Set when the scan was started from Wallet Details (that wallet is
  /// implicit, same shortcut QrMerchantPreviewScreen uses) — Continue skips
  /// straight to Confirm instead of Select Purpose Wallet.
  final PurposeWalletModel? preselectedWallet;
}

/// Shown right after a successful `GET /personal-payment/lookup/:userId` —
/// confirms which SecureVault Pay user the scanned Personal QR resolves to
/// before the sender picks a Purpose Wallet. Scanning never mutates
/// anything (Personal QR is permanent, not single-use), so backing out here
/// is always safe.
class PersonalPaymentPreviewScreen extends StatelessWidget {
  const PersonalPaymentPreviewScreen({super.key, required this.args});

  final PersonalPaymentScanArgs args;

  @override
  Widget build(BuildContext context) {
    final receiver = args.receiver;
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
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
                      child: Text(
                        receiver.fullName.isNotEmpty ? receiver.fullName[0].toUpperCase() : 'S',
                        style: const TextStyle(color: AppColors.primaryRed, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(receiver.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    if (receiver.maskedPhoneNumber != null) ...[
                      const SizedBox(height: 6),
                      Text(receiver.maskedPhoneNumber!, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text('Scanned via Personal QR', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                  context.push(
                    '/personal-payment/confirm',
                    extra: PersonalPaymentConfirmArgs(receiver: receiver, wallet: wallet),
                  );
                } else {
                  context.push('/personal-payment/select-wallet', extra: receiver);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
