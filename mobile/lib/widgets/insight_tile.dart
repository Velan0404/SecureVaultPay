import 'package:flutter/material.dart';

import '../models/insight_model.dart';
import '../theme/app_theme.dart';
import 'premium_card.dart';

IconData _iconForInsightType(String type) {
  switch (type) {
    case 'BUDGET_WARNING':
    case 'BUDGET_INFO':
      return Icons.pie_chart_outline_rounded;
    case 'TREND':
      return Icons.trending_up_rounded;
    case 'DORMANT':
      return Icons.bedtime_outlined;
    case 'UPCOMING_PAYMENT':
      return Icons.calendar_today_outlined;
    default:
      return Icons.insights_outlined;
  }
}

Color _colorForSeverity(String severity) => severity == 'WARNING' ? AppColors.categoryGold : AppColors.info;

/// One insight — reused by the Analytics Dashboard's preview (top 3) and the
/// full Insights screen. Severity drives color only as an accent; the icon
/// and message text always carry the meaning too (never color-alone).
class InsightTile extends StatelessWidget {
  const InsightTile({super.key, required this.insight});

  final InsightModel insight;

  @override
  Widget build(BuildContext context) {
    final color = _colorForSeverity(insight.severity);
    return PremiumCard.flat(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(_iconForInsightType(insight.type), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(insight.message, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
