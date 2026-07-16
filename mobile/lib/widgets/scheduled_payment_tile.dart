import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/currency_formatter.dart';
import '../models/scheduled_payment_model.dart';
import '../theme/app_theme.dart';

IconData iconForPaymentType(String paymentType) {
  switch (paymentType) {
    case 'RENT':
      return Icons.home_outlined;
    case 'ELECTRICITY':
      return Icons.bolt_outlined;
    case 'WATER':
      return Icons.water_drop_outlined;
    case 'INTERNET':
      return Icons.wifi;
    case 'MOBILE_RECHARGE':
      return Icons.sim_card_outlined;
    case 'SUBSCRIPTION':
      return Icons.subscriptions_outlined;
    case 'EMI':
      return Icons.account_balance_outlined;
    case 'INSURANCE':
      return Icons.shield_outlined;
    case 'SAVINGS':
      return Icons.savings_outlined;
    case 'CUSTOM':
    default:
      return Icons.event_repeat_outlined;
  }
}

String labelForPaymentType(String paymentType) {
  switch (paymentType) {
    case 'RENT':
      return 'Rent';
    case 'ELECTRICITY':
      return 'Electricity';
    case 'WATER':
      return 'Water';
    case 'INTERNET':
      return 'Internet';
    case 'MOBILE_RECHARGE':
      return 'Mobile Recharge';
    case 'SUBSCRIPTION':
      return 'Subscription';
    case 'EMI':
      return 'EMI';
    case 'INSURANCE':
      return 'Insurance';
    case 'SAVINGS':
      return 'Savings';
    case 'CUSTOM':
    default:
      return 'Custom';
  }
}

String frequencyLabel(ScheduledPaymentModel schedule) {
  switch (schedule.frequency) {
    case 'DAILY':
      return 'Daily';
    case 'WEEKLY':
      return 'Weekly';
    case 'MONTHLY':
      return 'Monthly';
    case 'YEARLY':
      return 'Yearly';
    case 'CUSTOM':
      return 'Every ${schedule.customIntervalDays ?? '?'} days';
    default:
      return schedule.frequency;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'ACTIVE':
      return AppColors.success;
    case 'PAUSED':
      return AppColors.categoryGold;
    case 'COMPLETED':
      return AppColors.textSecondary;
    case 'CANCELLED':
      return AppColors.danger;
    default:
      return AppColors.textSecondary;
  }
}

String statusLabel(String status) {
  switch (status) {
    case 'ACTIVE':
      return 'Active';
    case 'PAUSED':
      return 'Paused';
    case 'COMPLETED':
      return 'Completed';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status;
  }
}

/// One row in the Scheduled Payments list, the Dashboard's Scheduled
/// Payments block, and (read-only) Schedule Details — mirrors
/// WalletTransactionTile's icon/label-by-type helper-function pattern.
class ScheduledPaymentTile extends StatelessWidget {
  const ScheduledPaymentTile({super.key, required this.schedule, this.onTap});

  final ScheduledPaymentModel schedule;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(iconForPaymentType(schedule.paymentType), color: AppColors.primaryRed, size: 20),
      ),
      title: Text(schedule.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${schedule.destinationName} · ${frequencyLabel(schedule)}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(CurrencyFormatter.format(schedule.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor(schedule.status).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              schedule.status == 'ACTIVE'
                  ? DateFormat('d MMM').format(schedule.nextExecution.toLocal())
                  : statusLabel(schedule.status),
              style: TextStyle(color: statusColor(schedule.status), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
