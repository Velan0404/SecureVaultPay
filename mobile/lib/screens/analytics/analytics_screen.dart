import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// Analytics (spending charts, category breakdowns) is a future-phase
/// module with no backend aggregation endpoints yet. Same honesty rule as
/// Schedule — a real placeholder, not fabricated charts.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Analytics — Coming Soon',
            message: 'Spending vs income trends and category breakdowns will appear here once the Analytics module is built.',
          ),
        ),
      ),
    );
  }
}
