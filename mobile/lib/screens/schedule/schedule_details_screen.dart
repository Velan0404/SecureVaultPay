import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/scheduled_payment_model.dart';
import '../../providers/scheduled_payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/scheduled_payment_tile.dart';
import '../../widgets/secondary_button.dart';

/// Full detail view of one Scheduled Payment — Pause/Resume/Cancel (no
/// Payment PIN, since these only ever reduce what will be charged), an Edit
/// entry point, and a link to its Execution History.
class ScheduleDetailsScreen extends ConsumerStatefulWidget {
  const ScheduleDetailsScreen({super.key, required this.scheduleId});

  final String scheduleId;

  @override
  ConsumerState<ScheduleDetailsScreen> createState() => _ScheduleDetailsScreenState();
}

class _ScheduleDetailsScreenState extends ConsumerState<ScheduleDetailsScreen> {
  bool _isLoading = true;
  bool _isActing = false;
  String? _errorMessage;
  ScheduledPaymentModel? _schedule;

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
      final schedule = await ref.read(scheduledPaymentProvider.notifier).getOne(widget.scheduleId);
      if (mounted) setState(() => _schedule = schedule);
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _act(Future<ScheduledPaymentModel> Function() action, String successMessage) async {
    setState(() => _isActing = true);
    try {
      final updated = await action();
      if (mounted) {
        setState(() => _schedule = updated);
        showAppSnackBar(context, successMessage, isError: false);
      }
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this schedule?'),
        content: const Text('It will stop running immediately. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Keep it')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Cancel schedule')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isActing = true);
    try {
      await ref.read(scheduledPaymentProvider.notifier).cancel(widget.scheduleId);
      if (mounted) context.go('/schedule');
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Details'),
        actions: [
          if (schedule != null && schedule.status != 'CANCELLED' && schedule.status != 'COMPLETED')
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/schedule/${schedule.id}/edit', extra: schedule),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingScreen()
          : _errorMessage != null || schedule == null
              ? Center(child: Text(_errorMessage ?? 'Not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PremiumCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(iconForPaymentType(schedule.paymentType), color: AppColors.primaryRed),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(schedule.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                        Text(
                                          '${labelForPaymentType(schedule.paymentType)} · ${schedule.destinationName}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor(schedule.status).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      statusLabel(schedule.status),
                                      style: TextStyle(color: statusColor(schedule.status), fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              _DetailRow(label: 'Amount', value: CurrencyFormatter.format(schedule.amount)),
                              _DetailRow(label: 'Frequency', value: frequencyLabel(schedule)),
                              _DetailRow(
                                label: 'Next payment',
                                value: schedule.status == 'ACTIVE'
                                    ? DateFormat('d MMM yyyy').format(schedule.nextExecution.toLocal())
                                    : '—',
                              ),
                              if (schedule.lastExecution != null)
                                _DetailRow(
                                  label: 'Last payment',
                                  value: DateFormat('d MMM yyyy').format(schedule.lastExecution!.toLocal()),
                                ),
                              if (schedule.endDate != null)
                                _DetailRow(label: 'Ends', value: DateFormat('d MMM yyyy').format(schedule.endDate!.toLocal())),
                              if (schedule.note != null && schedule.note!.isNotEmpty)
                                _DetailRow(label: 'Note', value: schedule.note!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (schedule.status == 'ACTIVE' || schedule.status == 'PAUSED')
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  label: schedule.status == 'ACTIVE' ? 'Pause' : 'Resume',
                                  icon: schedule.status == 'ACTIVE' ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                  onPressed: _isActing
                                      ? null
                                      : () => schedule.status == 'ACTIVE'
                                          ? _act(() => ref.read(scheduledPaymentProvider.notifier).pause(schedule.id), 'Schedule paused.')
                                          : _act(() => ref.read(scheduledPaymentProvider.notifier).resume(schedule.id), 'Schedule resumed.'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SecondaryButton(
                                  label: 'Cancel',
                                  icon: Icons.close_rounded,
                                  onPressed: _isActing ? null : _cancel,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        SecondaryButton(
                          label: 'Execution History',
                          icon: Icons.history_rounded,
                          onPressed: () => context.push('/schedule/${schedule.id}/executions'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
