import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/currency_formatter.dart';
import '../models/analytics_charts_model.dart';
import '../theme/app_theme.dart';
import 'wallet_icons.dart';

/// Purpose Wallet Pie Chart — categorical identity, one slice per wallet.
/// Each wallet already carries its own persistent color (chosen once at
/// creation, unrelated to any chart), so slices reuse that color directly
/// rather than assigning a fresh categorical palette — "color follows the
/// entity," and it's the same color that wallet already renders as
/// everywhere else in the app. A legend (name + amount) is always shown
/// alongside the chart, since user-picked wallet colors aren't guaranteed to
/// be distinguishable from one another at a glance.
class PurposeWalletPieChart extends StatelessWidget {
  const PurposeWalletPieChart({super.key, required this.slices});

  final List<PurposeWalletBreakdownSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
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

    final total = slices.fold<double>(0, (sum, s) => sum + (double.tryParse(s.value) ?? 0));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 42,
                  sections: [
                    for (final slice in slices)
                      PieChartSectionData(
                        value: double.tryParse(slice.value) ?? 0,
                        color: WalletColors.fromHex(slice.color),
                        radius: 26,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
              Text(CurrencyFormatter.format(total.toStringAsFixed(2)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices
                .map(
                  (slice) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: WalletColors.fromHex(slice.color), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(slice.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                        Text(CurrencyFormatter.format(slice.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
