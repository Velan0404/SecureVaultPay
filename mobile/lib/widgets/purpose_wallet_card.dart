import 'package:flutter/material.dart';

import '../core/utils/currency_formatter.dart';
import '../models/purpose_wallet_model.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import 'wallet_icons.dart';

/// A single Purpose Wallet card — icon, name, balance, and an optional
/// spending-limit progress bar. Used on the Dashboard grid and inside the
/// Main Wallet screen's wallet list.
class PurposeWalletCard extends StatelessWidget {
  const PurposeWalletCard({super.key, required this.wallet, this.onTap});

  final PurposeWalletModel wallet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = WalletColors.fromHex(wallet.color);
    final limit = double.tryParse(wallet.spendingLimit ?? '');
    final balance = double.tryParse(wallet.balance) ?? 0;
    final progress = (limit != null && limit > 0) ? (balance / limit).clamp(0.0, 1.0) : null;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(WalletIcons.resolve(wallet.icon), color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              wallet.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(wallet.balance),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.divider,
                  color: progress >= 1 ? AppColors.accentCrimson : color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'of ${CurrencyFormatter.format(wallet.spendingLimit!)} limit',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
