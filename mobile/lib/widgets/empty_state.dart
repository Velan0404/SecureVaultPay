import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'primary_button.dart';

/// A reusable empty/coming-soon/error state — icon, title, description, and
/// an optional retry action. The same widget covers "no data yet" and
/// "couldn't load" so the app never needs two near-identical placeholders.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: AppColors.primaryRed),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          SizedBox(width: 160, child: PrimaryButton(label: retryLabel, onPressed: onRetry)),
        ],
      ],
    );
  }
}
