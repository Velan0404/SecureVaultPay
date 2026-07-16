import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/currency_formatter.dart';
import '../models/analytics_charts_model.dart';
import '../theme/app_theme.dart';

/// Income vs Expense — two categorical series, so a legend is always shown
/// (never color-alone). Reuses the app's existing success/danger semantic
/// colors rather than a fresh categorical pair — income is already "good"
/// everywhere else in this app, expense already reads as spend (the same
/// red used for PURPOSE_PAYMENT icons elsewhere) — and both are
/// direct-labeled with their exact amount, not just colored bars.
class IncomeVsExpenseChart extends StatelessWidget {
  const IncomeVsExpenseChart({super.key, required this.incomeVsExpense});

  final IncomeVsExpense incomeVsExpense;

  @override
  Widget build(BuildContext context) {
    final income = double.tryParse(incomeVsExpense.income) ?? 0;
    final expense = double.tryParse(incomeVsExpense.expenses) ?? 0;
    final maxY = ((income > expense ? income : expense) * 1.3).clamp(10, double.infinity).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
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
                      final label = value.toInt() == 0 ? 'Income' : 'Expense';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(toY: income, color: AppColors.success, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                ]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(toY: expense, color: AppColors.danger, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                ]),
              ],
            ),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Legend(color: AppColors.success, label: 'Income', value: CurrencyFormatter.format(incomeVsExpense.income)),
            _Legend(color: AppColors.danger, label: 'Expense', value: CurrencyFormatter.format(incomeVsExpense.expenses)),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}
