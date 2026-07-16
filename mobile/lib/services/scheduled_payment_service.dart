import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw Scheduled Payment API access — every method returns decoded JSON,
/// untouched. Mapping into typed models is [ScheduledPaymentRepository]'s job.
class ScheduledPaymentService {
  ScheduledPaymentService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getDashboard() {
    return _apiClient.get(ApiConstants.scheduledPaymentDashboard);
  }

  Future<List<Map<String, dynamic>>> list({String? status}) async {
    final path = status != null ? '${ApiConstants.scheduledPaymentList}?status=$status' : ApiConstants.scheduledPaymentList;
    final data = await _apiClient.get(path);
    return (data['schedules'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    final data = await _apiClient.get(ApiConstants.scheduledPaymentDetails(id));
    return data['schedule'] as Map<String, dynamic>;
  }

  // paymentPin authorizes creation only — the same Payment PIN as every
  // other payment module. Automatic execution never asks again.
  Future<Map<String, dynamic>> create({
    required String title,
    required String paymentType,
    required String amount,
    required String frequency,
    int? customIntervalDays,
    required String purposeWalletId,
    String? merchantId,
    String? receiverUserId,
    String? note,
    required String startDate,
    String? endDate,
    required String paymentPin,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.scheduledPaymentCreate,
      body: {
        'title': title,
        'paymentType': paymentType,
        'amount': amount,
        'frequency': frequency,
        'customIntervalDays': ?customIntervalDays,
        'purposeWalletId': purposeWalletId,
        'merchantId': ?merchantId,
        'receiverUserId': ?receiverUserId,
        'note': ?note,
        'startDate': startDate,
        'endDate': ?endDate,
        'paymentPin': paymentPin,
      },
    );
    return data['schedule'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id, {
    String? title,
    String? amount,
    String? frequency,
    int? customIntervalDays,
    String? endDate,
    String? note,
    String? purposeWalletId,
    required String paymentPin,
  }) async {
    final data = await _apiClient.patch(
      ApiConstants.scheduledPaymentUpdate(id),
      body: {
        'title': ?title,
        'amount': ?amount,
        'frequency': ?frequency,
        'customIntervalDays': ?customIntervalDays,
        'endDate': ?endDate,
        'note': ?note,
        'purposeWalletId': ?purposeWalletId,
        'paymentPin': paymentPin,
      },
    );
    return data['schedule'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pause(String id) async {
    final data = await _apiClient.post(ApiConstants.scheduledPaymentPause(id));
    return data['schedule'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resume(String id) async {
    final data = await _apiClient.post(ApiConstants.scheduledPaymentResume(id));
    return data['schedule'] as Map<String, dynamic>;
  }

  Future<void> cancel(String id) {
    return _apiClient.delete(ApiConstants.scheduledPaymentCancel(id));
  }

  Future<Map<String, dynamic>> listExecutions(String id, {String? cursor}) {
    return _apiClient.get(ApiConstants.scheduledPaymentExecutions(id, cursor: cursor));
  }
}
