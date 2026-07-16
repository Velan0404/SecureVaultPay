import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/analytics_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/insight_tile.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/shimmer_box.dart';

/// Full Insights list — every rule-generated observation for the range
/// selected on the Analytics Dashboard (shares [analyticsProvider]'s state).
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(analyticsProvider).dashboard == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(analyticsProvider.notifier).loadAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: state.isLoading && state.insights.isEmpty && state.dashboard == null
          ? ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => const _InsightShimmerTile(),
            )
          : state.insights.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.insights_outlined,
                      title: 'No insights yet',
                      message: 'Once you have more wallet activity, useful observations about your spending will show up here.',
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.insights.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => FadeSlideIn(
                    delay: Duration(milliseconds: index * 60),
                    child: InsightTile(insight: state.insights[index]),
                  ),
                ),
    );
  }
}

class _InsightShimmerTile extends StatelessWidget {
  const _InsightShimmerTile();

  @override
  Widget build(BuildContext context) {
    return PremiumCard.flat(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ShimmerBox(width: 36, height: 36, borderRadius: BorderRadius.circular(999)),
          const SizedBox(width: 12),
          const Expanded(child: ShimmerBox(height: 14)),
        ],
      ),
    );
  }
}
