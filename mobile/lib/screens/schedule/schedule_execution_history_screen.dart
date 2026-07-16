import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/scheduled_payment_execution_model.dart';
import '../../providers/scheduled_payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

/// Paginated log of every cron-tick attempt at one Scheduled Payment —
/// what actually happened, and why, for a specific due cycle.
class ScheduleExecutionHistoryScreen extends ConsumerStatefulWidget {
  const ScheduleExecutionHistoryScreen({super.key, required this.scheduleId});

  final String scheduleId;

  @override
  ConsumerState<ScheduleExecutionHistoryScreen> createState() => _ScheduleExecutionHistoryScreenState();
}

class _ScheduleExecutionHistoryScreenState extends ConsumerState<ScheduleExecutionHistoryScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _nextCursor;
  final List<ScheduledPaymentExecutionModel> _executions = [];

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
      final result = await ref.read(scheduledPaymentProvider.notifier).listExecutions(widget.scheduleId);
      if (mounted) {
        setState(() {
          _executions
            ..clear()
            ..addAll(result.executions);
          _nextCursor = result.nextCursor;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await ref.read(scheduledPaymentProvider.notifier).listExecutions(widget.scheduleId, cursor: _nextCursor);
      if (mounted) {
        setState(() {
          _executions.addAll(result.executions);
          _nextCursor = result.nextCursor;
        });
      }
    } catch (_) {
      // Best-effort — the user can pull again by scrolling; no snackbar spam.
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Execution History')),
      body: _isLoading
          ? const LoadingScreen()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(icon: Icons.error_outline, title: 'Could not load history', message: _errorMessage!, onRetry: _load),
                  ),
                )
              : _executions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyState(
                          icon: Icons.history_rounded,
                          title: 'No executions yet',
                          message: 'Once this schedule\'s next payment date arrives, every attempt will show up here.',
                        ),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) _loadMore();
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _executions.length + (_nextCursor != null ? 1 : 0),
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= _executions.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: LoadingIndicator(size: 24)),
                            );
                          }
                          final execution = _executions[index];
                          final isSuccess = execution.status == 'SUCCESS';
                          return Container(
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: (isSuccess ? AppColors.success : AppColors.danger).withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                  color: isSuccess ? AppColors.success : AppColors.danger,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                isSuccess ? 'Payment successful' : 'Payment failed',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                isSuccess
                                    ? DateFormat('d MMM yyyy, h:mm a').format(execution.executedAt.toLocal())
                                    : '${execution.failureReason ?? 'Unknown reason'} · ${DateFormat('d MMM yyyy').format(execution.executedAt.toLocal())}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              trailing: Text(CurrencyFormatter.format(execution.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
