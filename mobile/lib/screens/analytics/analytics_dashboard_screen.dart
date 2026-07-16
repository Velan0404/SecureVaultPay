import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/analytics_dashboard_model.dart';
import '../../models/analytics_range.dart';
import '../../models/insight_model.dart';
import '../../models/purpose_wallet_analytics_model.dart';
import '../../providers/analytics_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/income_vs_expense_chart.dart';
import '../../widgets/insight_tile.dart';
import '../../widgets/monthly_spending_line_chart.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/purpose_wallet_pie_chart.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/weekly_expense_bar_chart.dart';

/// Analytics Dashboard — real spending/income figures, 4 charts, and an
/// Insights preview, all driven by [analyticsProvider]'s shared range
/// filter. `dashboard == null` is only ever true right after logout/login
/// (see AuthNotifier's `ref.invalidate(analyticsProvider)`) or before the
/// very first load — never a stale previous account's data.
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(analyticsProvider).dashboard == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(analyticsProvider.notifier).loadAll());
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) {
      await ref.read(analyticsProvider.notifier).setRange(AnalyticsRange.custom, customStart: picked.start, customEnd: picked.end);
    }
  }

  Future<void> _onRangeSelected(AnalyticsRange? range) async {
    if (range == null) return;
    if (range == AnalyticsRange.custom) {
      await _pickCustomRange();
    } else {
      await ref.read(analyticsProvider.notifier).setRange(range);
    }
  }

  bool _isTrulyEmpty(AnalyticsDashboardModel d) {
    double parse(String v) => double.tryParse(v) ?? 0;
    return parse(d.totalIncome) == 0 &&
        parse(d.totalExpenses) == 0 &&
        parse(d.totalTransfers) == 0 &&
        parse(d.totalScheduledPayments) == 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final dashboard = state.dashboard;
    final charts = state.charts;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: state.isLoading && dashboard == null
          ? const _DashboardShimmer()
          : dashboard == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load analytics',
                      message: state.errorMessage ?? 'Something went wrong.',
                      onRetry: () => ref.read(analyticsProvider.notifier).loadAll(),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(analyticsProvider.notifier).loadAll(),
                  color: AppColors.primaryRed,
                  backgroundColor: AppColors.surface,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    children: [
                      FadeSlideIn(
                        child: DropdownButtonFormField<AnalyticsRange>(
                          initialValue: state.selectedRange,
                          decoration: const InputDecoration(labelText: 'Range'),
                          items: AnalyticsRange.values
                              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                              .toList(),
                          onChanged: state.isLoading ? null : _onRangeSelected,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(child: _HeroBalanceCard(dashboard: dashboard)),
                      if (_isTrulyEmpty(dashboard)) ...[
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: const EmptyState(
                            icon: Icons.auto_graph_outlined,
                            title: 'No transactions yet',
                            message: 'Start using SecureVault Pay to unlock insights — load demo money, create a\nPurpose Wallet, or make your first payment.',
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: _AchievementBadges(wallets: state.wallets, insights: state.insights),
                        ),
                        const SizedBox(height: 20),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _StatCard(index: 0, icon: Icons.storefront_outlined, label: 'Merchant Payments', value: dashboard.totalMerchantPayments),
                            _StatCard(index: 1, icon: Icons.send_rounded, label: 'User Payments', value: dashboard.totalUserPayments),
                            _StatCard(index: 2, icon: Icons.event_repeat_outlined, label: 'Scheduled Payments', value: dashboard.totalScheduledPayments),
                            _StatCard(index: 3, icon: Icons.calendar_month_outlined, label: 'This Month', value: dashboard.monthlySpending),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const SectionHeader(title: 'Monthly Spending'),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          child: PremiumCard(
                            child: charts == null ? const _ChartShimmer() : MonthlySpendingLineChart(points: charts.monthlySpending),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'Spending by Purpose Wallet'),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          child: PremiumCard(
                            child: charts == null
                                ? const _ChartShimmer()
                                : charts.purposeWalletBreakdown.isEmpty
                                    ? const EmptyState(
                                        icon: Icons.pie_chart_outline_rounded,
                                        title: 'No spending data',
                                        message: 'Make your first payment to view spending trends.',
                                      )
                                    : PurposeWalletPieChart(slices: charts.purposeWalletBreakdown),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionHeader(title: "This Week's Expenses"),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          child: PremiumCard(
                            child: charts == null ? const _ChartShimmer() : WeeklyExpenseBarChart(points: charts.weeklyExpense),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'Income vs Expense'),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          child: PremiumCard(
                            child: charts == null ? const _ChartShimmer() : IncomeVsExpenseChart(incomeVsExpense: charts.incomeVsExpense),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SectionHeader(
                          title: 'Insights',
                          actionLabel: 'View all',
                          onAction: () => context.push('/analytics/insights'),
                        ),
                        const SizedBox(height: 12),
                        if (state.insights.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No insights yet — check back after a bit more activity.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        else
                          ...state.insights.take(3).map((insight) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InsightTile(insight: insight),
                              )),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/analytics/wallets'),
                              icon: const Icon(Icons.pie_chart_outline_rounded, size: 18),
                              label: const Text('Wallet Analytics'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/analytics/report'),
                              icon: const Icon(Icons.summarize_outlined, size: 18),
                              label: const Text('Monthly Report'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// "Financial Overview" gradient hero — the same heroGradient/PremiumCard.hero
/// treatment the main Dashboard's balance card already uses, so Analytics
/// reads as one continuous design system rather than a bolted-on module.
class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.dashboard});

  final AnalyticsDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    return PremiumCard.hero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('Financial Overview', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Total Balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 4),
          _AnimatedCurrency(value: dashboard.totalBalance, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: StatTile(label: 'Income', value: CurrencyFormatter.format(dashboard.totalIncome), dark: true)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(label: 'Expenses', value: CurrencyFormatter.format(dashboard.totalExpenses), dark: true)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(label: 'Transfers', value: CurrencyFormatter.format(dashboard.totalTransfers), dark: true)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Counts up from 0 to the real value once on mount — an animated figure is
/// still the same real number, just presented with a little life.
class _AnimatedCurrency extends StatelessWidget {
  const _AnimatedCurrency({required this.value, required this.style});

  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final target = double.tryParse(value) ?? 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) => Text(CurrencyFormatter.format(animated.toStringAsFixed(2)), style: style),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.index, required this.icon, required this.label, required this.value});

  final int index;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: 80 + index * 60),
      child: PremiumCard.flat(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primaryRed, size: 16),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 2),
            Text(CurrencyFormatter.format(value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

/// Small, honest badges — each only renders when a real condition against
/// already-fetched data holds. Never decorative filler text.
class _AchievementBadges extends StatelessWidget {
  const _AchievementBadges({required this.wallets, required this.insights});

  final List<PurposeWalletAnalyticsModel> wallets;
  final List<InsightModel> insights;

  @override
  Widget build(BuildContext context) {
    final budgetedWallets = wallets.where((w) => w.spendingPercentage != null).toList();
    final onTrack = budgetedWallets.isNotEmpty && budgetedWallets.every((w) => w.spendingPercentage! < 90);
    final noSpendingSpikes = !insights.any((i) => i.type == 'TREND' && i.severity == 'WARNING');
    final noDormantWallets = wallets.isNotEmpty && !insights.any((i) => i.type == 'DORMANT');

    final badges = <Widget>[
      if (onTrack) const _Badge(icon: Icons.shield_outlined, label: 'On track with budgets'),
      if (noSpendingSpikes) const _Badge(icon: Icons.trending_flat_rounded, label: 'No spending spikes'),
      if (noDormantWallets) const _Badge(icon: Icons.bolt_outlined, label: 'All wallets active'),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: AppRadius.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.success, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ChartShimmer extends StatelessWidget {
  const _ChartShimmer();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 200, child: Center(child: ShimmerBox(width: 220, height: 120)));
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        ShimmerBox(height: 52, borderRadius: AppRadius.mdRadius),
        const SizedBox(height: 20),
        ShimmerBox(height: 180, borderRadius: AppRadius.xlRadius),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: const [ShimmerStatTile(), ShimmerStatTile(), ShimmerStatTile(), ShimmerStatTile()],
        ),
        const SizedBox(height: 20),
        const _ChartShimmer(),
      ],
    );
  }
}
