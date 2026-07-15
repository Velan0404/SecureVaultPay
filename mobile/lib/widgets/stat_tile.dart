import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_theme.dart';

/// A single stat card — label, big value, optional trend line. Used in the
/// Dashboard's balance summary chips and the Analytics 2x2 grid.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendIsPositive = true,
    this.dark = false,
  });

  final String label;
  final String value;
  final String? trend;
  final bool trendIsPositive;

  /// True when placed on top of the hero gradient card (needs a translucent
  /// white tint instead of the standard dark surface).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.08) : AppColors.surfaceElevated,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: dark ? Colors.white54 : AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trendIsPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 12,
                  color: trendIsPositive ? AppColors.success : AppColors.danger,
                ),
                Text(
                  trend!,
                  style: TextStyle(
                    color: trendIsPositive ? AppColors.success : AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
