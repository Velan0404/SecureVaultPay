import '../services/transaction_auth_service.dart';

class TransactionAuthSessionInfo {
  const TransactionAuthSessionInfo({required this.sessionId, required this.expiresAt});

  final String sessionId;
  final DateTime expiresAt;
}

/// Domain-facing layer over [TransactionAuthService] — keeps the provider
/// working with typed values instead of raw JSON maps.
class TransactionAuthRepository {
  TransactionAuthRepository(this._service);

  final TransactionAuthService _service;

  Future<void> setPhoneNumber(String phoneNumber) => _service.setPhoneNumber(phoneNumber);

  Future<TransactionAuthSessionInfo> start({
    required String deviceId,
    required String purposeWalletId,
    required String amount,
  }) async {
    final data = await _service.start(deviceId: deviceId, purposeWalletId: purposeWalletId, amount: amount);
    return TransactionAuthSessionInfo(
      sessionId: data['sessionId'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Future<void> confirmFingerprint(String sessionId) => _service.confirmFingerprint(sessionId);

  Future<void> recordFingerprintFailure(String sessionId, int attemptNumber) =>
      _service.recordFingerprintFailure(sessionId, attemptNumber);

  /// Returns the masked phone number (e.g. "+91******3210") the OTP was sent to.
  Future<String> sendOtp(String sessionId) async {
    final data = await _service.sendOtp(sessionId);
    return data['maskedPhoneNumber'] as String? ?? '';
  }

  Future<void> verifyOtp(String sessionId, String code) => _service.verifyOtp(sessionId, code);
}
