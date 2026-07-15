import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Section Title ... action" row — used above every list/grid section
/// (Purpose Wallets, Recent Transactions, Upcoming Payments, ...). Extracted
/// once so every section header stays visually identical.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
            child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
