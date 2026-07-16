import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw Personal Payment API access — every method returns decoded JSON,
/// untouched. Mapping into typed models is [PersonalPaymentRepository]'s job.
class PersonalPaymentService {
  PersonalPaymentService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getMyQr() {
    return _apiClient.get(ApiConstants.personalPaymentMyQr);
  }

  Future<Map<String, dynamic>> lookupReceiver({required String userId, String? secureVaultId}) async {
    final data = await _apiClient.get(ApiConstants.personalPaymentLookup(userId, secureVaultId: secureVaultId));
    return data['receiver'] as Map<String, dynamic>;
  }

  // phone must already be in international format (+91XXXXXXXXXX) — the
  // caller (PersonalPaymentRepository) is responsible for that conversion,
  // same rule registration already applies.
  Future<Map<String, dynamic>> searchByPhone(String phone) async {
    final data = await _apiClient.get(ApiConstants.personalPaymentSearch(phone));
    return data['receiver'] as Map<String, dynamic>;
  }

  // paymentPin authorizes the payment (same Payment PIN introduced in Phase
  // 5.1) — no fingerprint/OTP involved.
  Future<Map<String, dynamic>> pay({
    required String receiverId,
    required String purposeWalletId,
    required String amount,
    String? note,
    required String paymentPin,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.personalPaymentPay(receiverId),
      body: {
        'purposeWalletId': purposeWalletId,
        'amount': amount,
        'note': ?note,
        'paymentPin': paymentPin,
      },
    );
    return data['payment'] as Map<String, dynamic>;
  }
}
