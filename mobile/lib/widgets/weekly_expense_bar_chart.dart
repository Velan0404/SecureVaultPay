import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/currency_formatter.dart';
import '../models/analytics_charts_model.dart';
import '../theme/app_theme.dart';

/// Weekly Expense Bar Chart — one bar per day, last 7 days. Single hue,
/// rounded top corners, thin bars with a visible gap between them, recessive
/// gridlines, touch tooltip.
class WeeklyExpenseBarChart extends StatelessWidget {
  const WeeklyExpenseBarChart({super.key, required this.points});

  final List<WeeklyExpensePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.every((p) => (double.tryParse(p.total) ?? 0) == 0)) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No spending data — make your first payment to view spending trends.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final values = points.map((p) => double.tryParse(p.total) ?? 0).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue <= 0 ? 10 : maxValue * 1.2).toDouble();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _dayLabel(points[index].date),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                CurrencyFormatter.format(values[group.x].toStringAsFixed(2)),
                const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    color: AppColors.primaryRed,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  static String _dayLabel(String yyyyMmDd) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final date = DateTime.parse(yyyyMmDd);
    return labels[date.weekday - 1];
  }
}
