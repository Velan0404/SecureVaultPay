import '../models/scheduled_payment_dashboard_model.dart';
import '../models/scheduled_payment_execution_model.dart';
import '../models/scheduled_payment_model.dart';
import '../services/scheduled_payment_service.dart';

/// Domain-facing layer over [ScheduledPaymentService] — maps its raw JSON
/// into typed models so [ScheduledPaymentNotifier] never touches a
/// `Map<String, dynamic>`.
class ScheduledPaymentRepository {
  ScheduledPaymentRepository(this._service);

  final ScheduledPaymentService _service;

  Future<ScheduledPaymentDashboardModel> getDashboard() async {
    return ScheduledPaymentDashboardModel.fromJson(await _service.getDashboard());
  }

  Future<List<ScheduledPaymentModel>> list({String? status}) async {
    final rows = await _service.list(status: status);
    return rows.map(ScheduledPaymentModel.fromJson).toList();
  }

  Future<ScheduledPaymentModel> getOne(String id) async {
    return ScheduledPaymentModel.fromJson(await _service.getOne(id));
  }

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
    final json = await _service.create(
      title: title,
      paymentType: paymentType,
      amount: amount,
      frequency: frequency,
      customIntervalDays: customIntervalDays,
      purposeWalletId: purposeWalletId,
      merchantId: merchantId,
      receiverUserId: receiverUserId,
      note: note,
      startDate: startDate.toUtc().toIso8601String(),
      endDate: endDate?.toUtc().toIso8601String(),
      paymentPin: paymentPin,
    );
    return ScheduledPaymentModel.fromJson(json);
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
  }) async {
    final json = await _service.update(
      id,
      title: title,
      amount: amount,
      frequency: frequency,
      customIntervalDays: customIntervalDays,
      endDate: endDate?.toUtc().toIso8601String(),
      note: note,
      purposeWalletId: purposeWalletId,
      paymentPin: paymentPin,
    );
    return ScheduledPaymentModel.fromJson(json);
  }

  Future<ScheduledPaymentModel> pause(String id) async {
    return ScheduledPaymentModel.fromJson(await _service.pause(id));
  }

  Future<ScheduledPaymentModel> resume(String id) async {
    return ScheduledPaymentModel.fromJson(await _service.resume(id));
  }

  Future<void> cancel(String id) => _service.cancel(id);

  Future<({List<ScheduledPaymentExecutionModel> executions, String? nextCursor})> listExecutions(
    String id, {
    String? cursor,
  }) async {
    final json = await _service.listExecutions(id, cursor: cursor);
    final executions = (json['executions'] as List)
        .map((e) => ScheduledPaymentExecutionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (executions: executions, nextCursor: json['nextCursor'] as String?);
  }
}
