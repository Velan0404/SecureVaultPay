import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw Transaction Authentication API access — the additional fingerprint +
/// OTP security layer required before any Main Wallet -> Purpose Wallet
/// transfer. Every method returns decoded JSON; [TransactionAuthRepository]
/// maps it into typed values.
class TransactionAuthService {
  TransactionAuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> setPhoneNumber(String phoneNumber) {
    return _apiClient.patch(ApiConstants.transactionAuthPhone, body: {'phoneNumber': phoneNumber});
  }

  Future<Map<String, dynamic>> start({
    required String deviceId,
    required String purposeWalletId,
    required String amount,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.transactionAuthStart,
      body: {'deviceId': deviceId, 'purposeWalletId': purposeWalletId, 'amount': amount},
    );
    return data;
  }

  Future<void> confirmFingerprint(String sessionId) {
    return _apiClient.post(ApiConstants.transactionAuthConfirmFingerprint(sessionId));
  }

  Future<void> recordFingerprintFailure(String sessionId, int attemptNumber) {
    return _apiClient.post(
      ApiConstants.transactionAuthFingerprintFailed(sessionId),
      body: {'attemptNumber': attemptNumber},
    );
  }

  Future<Map<String, dynamic>> sendOtp(String sessionId) {
    return _apiClient.post(ApiConstants.transactionAuthOtpSend(sessionId));
  }

  Future<void> verifyOtp(String sessionId, String code) {
    return _apiClient.post(ApiConstants.transactionAuthOtpVerify(sessionId), body: {'code': code});
  }
}
