import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_theme.dart';

/// One icon-circle + label quick action — the row of "Load Money / Send
/// Money / QR Pay / Schedule"-style shortcuts on the Dashboard.
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
