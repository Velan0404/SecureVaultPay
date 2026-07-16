import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/currency_formatter.dart';
import '../models/wallet_transaction_model.dart';
import '../theme/app_theme.dart';

IconData _iconFor(String type) {
  switch (type) {
    case 'DEMO_LOAD':
      return Icons.add_card_outlined;
    case 'MAIN_TO_PURPOSE':
    case 'PURPOSE_TO_MAIN':
      return Icons.swap_horiz;
    case 'WALLET_CREATED':
      return Icons.add_circle_outline;
    case 'WALLET_UPDATED':
      return Icons.edit_outlined;
    case 'WALLET_DELETED':
      return Icons.delete_outline;
    case 'PURPOSE_PAYMENT':
      return Icons.storefront_outlined;
    case 'PERSONAL_PAYMENT_SENT':
      return Icons.arrow_upward_outlined;
    case 'PERSONAL_PAYMENT_RECEIVED':
      return Icons.arrow_downward_outlined;
    case 'REFUND':
      return Icons.replay_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

String _labelFor(String type) {
  switch (type) {
    case 'DEMO_LOAD':
      return 'Demo money loaded';
    case 'MAIN_TO_PURPOSE':
      return 'Transfer to wallet';
    case 'PURPOSE_TO_MAIN':
      return 'Transfer to Main Wallet';
    case 'WALLET_CREATED':
      return 'Wallet created';
    case 'WALLET_UPDATED':
      return 'Wallet updated';
    case 'WALLET_DELETED':
      return 'Wallet deleted';
    case 'PURPOSE_PAYMENT':
      return 'Payment';
    case 'PERSONAL_PAYMENT_SENT':
      return 'Money sent';
    case 'PERSONAL_PAYMENT_RECEIVED':
      return 'Money received';
    case 'REFUND':
      return 'Refund';
    case 'ADJUSTMENT':
      return 'Adjustment';
    default:
      return type;
  }
}

/// Whether this transaction actually moved money (drives whether an amount
/// is shown at all — a WALLET_CREATED/UPDATED/DELETED log entry has a zero
/// amount by design and shouldn't render "₹0.00" next to it).
bool _movesMoney(WalletTransactionModel tx) => double.tryParse(tx.amount) != 0;

class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({super.key, required this.transaction});

  final WalletTransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final showsAmount = _movesMoney(transaction);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.secondaryRed.withValues(alpha: 0.14), shape: BoxShape.circle),
        child: Icon(_iconFor(transaction.type), color: AppColors.secondaryRed, size: 20),
      ),
      title: Text(transaction.description ?? _labelFor(transaction.type), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        DateFormat('d MMM yyyy, h:mm a').format(transaction.createdAt.toLocal()),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: showsAmount
          ? Text(
              CurrencyFormatter.format(transaction.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}
