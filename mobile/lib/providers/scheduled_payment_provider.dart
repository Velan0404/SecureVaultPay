import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scheduled_payment_dashboard_model.dart';
import '../models/scheduled_payment_execution_model.dart';
import '../models/scheduled_payment_model.dart';
import '../repositories/scheduled_payment_repository.dart';
import '../services/scheduled_payment_service.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';

final scheduledPaymentServiceProvider = Provider<ScheduledPaymentService>(
  (ref) => ScheduledPaymentService(ref.read(apiClientProvider)),
);

final scheduledPaymentRepositoryProvider = Provider<ScheduledPaymentRepository>(
  (ref) => ScheduledPaymentRepository(ref.read(scheduledPaymentServiceProvider)),
);

class ScheduledPaymentState {
  const ScheduledPaymentState({
    this.dashboard,
    this.schedules = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final ScheduledPaymentDashboardModel? dashboard;
  final List<ScheduledPaymentModel> schedules;
  final bool isLoading;
  final String? errorMessage;

  ScheduledPaymentState copyWith({
    ScheduledPaymentDashboardModel? dashboard,
    List<ScheduledPaymentModel>? schedules,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScheduledPaymentState(
      dashboard: dashboard ?? this.dashboard,
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final scheduledPaymentProvider =
    NotifierProvider<ScheduledPaymentNotifier, ScheduledPaymentState>(ScheduledPaymentNotifier.new);

/// Drives Scheduled Payments (Rent, EMI, Subscriptions, ...) — automated
/// recurring Purpose Wallet -> Merchant/User payments executed server-side
/// by scheduler.service.js, never by this app directly.
class ScheduledPaymentNotifier extends Notifier<ScheduledPaymentState> {
  // A getter, not a `late final` field assigned inside build() — see the
  // identical note on WalletNotifier._repository. This provider is
  // invalidated on every logout/login/register, and a `late final` field
  // throws LateInitializationError if build() reruns on the same instance
  // while a listener is still attached.
  ScheduledPaymentRepository get _repository => ref.read(scheduledPaymentRepositoryProvider);

  @override
  ScheduledPaymentState build() {
    return const ScheduledPaymentState();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dashboard = await _repository.getDashboard();
      state = state.copyWith(dashboard: dashboard, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load scheduled payments.');
    }
  }

  Future<void> loadSchedules({String? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final schedules = await _repository.list(status: status);
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load scheduled payments.');
    }
  }

  Future<ScheduledPaymentModel> getOne(String id) => _repository.getOne(id);

  Future<ScheduledPaymentModel> create({
    required String title,
    required String paymentType,
    required String amount,
    required String frequency,
    int? customIntervalDays,
    required String purposeWalletId,
    String? merchantId,
    String? receiverUserId,
    String? note,
    required DateTime startDate,
    DateTime? endDate,
    required String paymentPin,
  }) async {
    final schedule = await _repository.create(
      title: title,
      paymentType: paymentType,
      amount: amount,
      frequency: frequency,
      customIntervalDays: customIntervalDays,
      purposeWalletId: purposeWalletId,
      merchantId: merchantId,
      receiverUserId: receiverUserId,
      note: note,
      startDate: startDate,
      endDate: endDate,
      paymentPin: paymentPin,
    );
    // Not money-critical, but keeps the wallet list/spending figures fresh
    // in case the caller navigates straight back to Dashboard/Wallet.
    await ref.read(walletProvider.notifier).refreshSilently();
    return schedule;
  }

  Future<ScheduledPaymentModel> update(
    String id, {
    String? title,
    String? amount,
    String? frequency,
    int? customIntervalDays,
    DateTime? endDate,
    String? note,
    String? purposeWalletId,
    required String paymentPin,
  }) {
    return _repository.update(
      id,
      title: title,
      amount: amount,
      frequency: frequency,
      customIntervalDays: customIntervalDays,
      endDate: endDate,
      note: note,
      purposeWalletId: purposeWalletId,
      paymentPin: paymentPin,
    );
  }

  Future<ScheduledPaymentModel> pause(String id) => _repository.pause(id);

  Future<ScheduledPaymentModel> resume(String id) => _repository.resume(id);

  Future<void> cancel(String id) => _repository.cancel(id);

  Future<({List<ScheduledPaymentExecutionModel> executions, String? nextCursor})> listExecutions(
    String id, {
    String? cursor,
  }) {
    return _repository.listExecutions(id, cursor: cursor);
  }
}
