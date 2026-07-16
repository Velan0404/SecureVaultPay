import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw QR API access — every method returns decoded JSON, untouched. Mapping
/// into typed models is [QrRepository]'s job.
class QrService {
  QrService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> generateDemo(String merchantId) {
    return _apiClient.post(ApiConstants.qrGenerateDemo, body: {'merchantId': merchantId});
  }

  Future<Map<String, dynamic>> validate(String qrId) {
    return _apiClient.get(ApiConstants.qrValidate(qrId));
  }

  // paymentPin authorizes the payment (same Payment PIN introduced in Phase
  // 5.1) — no fingerprint/OTP involved.
  Future<Map<String, dynamic>> pay({
    required String qrId,
    required String purposeWalletId,
    required String amount,
    required String paymentPin,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.qrPay(qrId),
      body: {'purposeWalletId': purposeWalletId, 'amount': amount, 'paymentPin': paymentPin},
    );
    return data['payment'] as Map<String, dynamic>;
  }
}
