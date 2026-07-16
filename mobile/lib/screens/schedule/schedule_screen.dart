import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/scheduled_payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/scheduled_payment_tile.dart';

/// Scheduled Payments — Rent, EMIs, subscriptions, and recurring transfers
/// the server executes automatically (scheduler.service.js), with no
/// Payment PIN prompt at execution time (only at creation/editing).
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(scheduledPaymentProvider.notifier).loadSchedules());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduledPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/schedule/create'),
          ),
        ],
      ),
      body: state.isLoading && state.schedules.isEmpty
          ? const LoadingScreen()
          : state.schedules.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'No Scheduled Payments yet',
                      message:
                          'Automate Rent, EMIs, subscriptions, and recurring transfers — set them up once and SecureVault Pay handles the rest.',
                      onRetry: () => context.push('/schedule/create'),
                      retryLabel: 'New Schedule',
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(scheduledPaymentProvider.notifier).loadSchedules(),
                  color: AppColors.primaryRed,
                  backgroundColor: AppColors.surface,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: state.schedules.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final schedule = state.schedules[index];
                      return FadeSlideIn(
                        child: PremiumCard.flat(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          onTap: () => context.push('/schedule/${schedule.id}'),
                          child: ScheduledPaymentTile(schedule: schedule),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
