import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/currency_formatter.dart';
import '../models/analytics_charts_model.dart';
import '../theme/app_theme.dart';

/// Monthly Spending Line Chart — one series (expenses), single hue,
/// magnitude over time. Thin 2px line, rounded data points, a faint gradient
/// fill under the line, recessive gridlines, touch tooltip.
class MonthlySpendingLineChart extends StatelessWidget {
  const MonthlySpendingLineChart({super.key, required this.points});

  final List<MonthlySpendingPoint> points;

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
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10, double.infinity);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY.toDouble(),
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
                      _monthLabel(points[index].month),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        CurrencyFormatter.format(values[s.x.toInt()].toStringAsFixed(2)),
                        const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.primaryRed,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(radius: 4, color: AppColors.primaryRed, strokeWidth: 2, strokeColor: AppColors.surface),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryRed.withValues(alpha: 0.22), AppColors.primaryRed.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  static String _monthLabel(String yyyyMm) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = int.tryParse(yyyyMm.split('-').last) ?? 1;
    return labels[(month - 1).clamp(0, 11)];
  }
}
