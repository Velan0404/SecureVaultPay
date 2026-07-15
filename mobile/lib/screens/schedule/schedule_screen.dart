import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// Scheduled Payments is a future-phase module — there is no backend or
/// business logic behind it yet. This screen is intentionally an honest
/// "coming soon" placeholder on the new design system rather than a
/// dummy-data UI pretending the feature works.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'Scheduled Payments — Coming Soon',
            message: 'Rent, EMIs, subscriptions, and recurring transfers will be schedulable here in a future phase.',
          ),
        ),
      ),
    );
  }
}
