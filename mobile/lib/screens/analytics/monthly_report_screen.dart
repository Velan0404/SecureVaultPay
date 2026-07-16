import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/analytics_report_model.dart';
import '../../providers/analytics_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/shimmer_box.dart';

const _periods = ['DAILY', 'WEEKLY', 'MONTHLY'];

/// Daily/Weekly/Monthly Reports — the same 6 figures as the Dashboard
/// totals, resolved against a specific calendar period instead of an
/// open-ended range preset.
class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  String _period = 'MONTHLY';
  DateTime _date = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  AnalyticsReportModel? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final report = await ref.read(analyticsProvider.notifier).loadReport(_period, date: _date);
      if (mounted) setState(() => _report = report);
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _period,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: _periods
                        .map((p) => DropdownMenuItem(value: p, child: Text(p[0] + p.substring(1).toLowerCase())))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _period = value);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(DateFormat('d MMM yyyy').format(_date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerBox(width: 140, height: 12),
                          const Divider(height: 28),
                          for (var i = 0; i < 6; i += 1) ...[
                            Row(
                              children: [
                                ShimmerBox(width: 30, height: 30, borderRadius: BorderRadius.circular(999)),
                                const SizedBox(width: 12),
                                const Expanded(child: ShimmerBox(height: 14)),
                                const SizedBox(width: 12),
                                const ShimmerBox(width: 60, height: 14),
                              ],
                            ),
                            if (i != 5) const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    )
                  : _errorMessage != null || _report == null
                      ? Center(
                          child: EmptyState(
                            icon: Icons.error_outline,
                            title: 'Could not load report',
                            message: _errorMessage ?? 'Something went wrong.',
                            onRetry: _load,
                          ),
                        )
                      : FadeSlideIn(
                          child: PremiumCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat('d MMM').format(_report!.startDate.toLocal())} – ${DateFormat('d MMM yyyy').format(_report!.endDate.toLocal().subtract(const Duration(days: 1)))}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                const Divider(height: 28),
                                _ReportRow(icon: Icons.arrow_downward_rounded, iconColor: AppColors.success, label: 'Income', value: _report!.totalIncome),
                                _ReportRow(icon: Icons.arrow_upward_rounded, iconColor: AppColors.danger, label: 'Expenses', value: _report!.totalExpenses),
                                _ReportRow(icon: Icons.swap_horiz_rounded, iconColor: AppColors.info, label: 'Transfers', value: _report!.totalTransfers),
                                _ReportRow(icon: Icons.storefront_outlined, iconColor: AppColors.categoryTeal, label: 'Merchant Payments', value: _report!.totalMerchantPayments),
                                _ReportRow(icon: Icons.send_rounded, iconColor: AppColors.categoryBlue, label: 'Personal Payments', value: _report!.totalUserPayments),
                                _ReportRow(icon: Icons.event_repeat_outlined, iconColor: AppColors.categoryGold, label: 'Scheduled Payments', value: _report!.totalScheduledPayments),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.icon, required this.iconColor, required this.label, required this.value});

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(CurrencyFormatter.format(value), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
