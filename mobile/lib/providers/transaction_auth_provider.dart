import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../repositories/transaction_auth_repository.dart';
import '../services/transaction_auth_service.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';

final transactionAuthServiceProvider = Provider<TransactionAuthService>(
  (ref) => TransactionAuthService(ref.read(apiClientProvider)),
);

final transactionAuthRepositoryProvider = Provider<TransactionAuthRepository>(
  (ref) => TransactionAuthRepository(ref.read(transactionAuthServiceProvider)),
);

enum TransactionAuthStep { fingerprint, otp, processing, success, failed }

const int kMaxFingerprintAttempts = 3;

class TransactionAuthState {
  const TransactionAuthState({
    this.step = TransactionAuthStep.fingerprint,
    this.sessionId,
    this.fingerprintAttempts = 0,
    this.maskedPhoneNumber = '',
    this.errorMessage,
    this.isProcessing = false,
  });

  final TransactionAuthStep step;
  final String? sessionId;
  final int fingerprintAttempts;
  final String maskedPhoneNumber;
  final String? errorMessage;
  final bool isProcessing;

  TransactionAuthState copyWith({
    TransactionAuthStep? step,
    String? sessionId,
    int? fingerprintAttempts,
    String? maskedPhoneNumber,
    String? errorMessage,
    bool clearError = false,
    bool? isProcessing,
  }) {
    return TransactionAuthState(
      step: step ?? this.step,
      sessionId: sessionId ?? this.sessionId,
      fingerprintAttempts: fingerprintAttempts ?? this.fingerprintAttempts,
      maskedPhoneNumber: maskedPhoneNumber ?? this.maskedPhoneNumber,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

final transactionAuthProvider =
    NotifierProvider.autoDispose<TransactionAuthNotifier, TransactionAuthState>(TransactionAuthNotifier.new);

/// Drives the Transaction Authentication wizard (Fingerprint -> OTP ->
/// Processing -> Success) that every Main Wallet -> Purpose Wallet transfer
/// must now pass through. Deliberately separate from [WalletNotifier] — this
/// is an additional, isolated security layer, not part of the Wallet
/// module's own state.
class TransactionAuthNotifier extends Notifier<TransactionAuthState> {
  late final TransactionAuthRepository _repository;

  @override
  TransactionAuthState build() {
    _repository = ref.read(transactionAuthRepositoryProvider);
    return const TransactionAuthState();
  }

  /// Starts a new session for this exact wallet + amount. Must be called
  /// before the screen shows the fingerprint prompt.
  Future<void> start({required String purposeWalletId, required String amount}) async {
    final device = await ref.read(deviceServiceProvider).currentDevice();
    final session = await _repository.start(deviceId: device.deviceId, purposeWalletId: purposeWalletId, amount: amount);
    state = state.copyWith(sessionId: session.sessionId);
  }

  /// Called after a LOCAL biometric success (BiometricService, unchanged) —
  /// tells the backend so it can gate the OTP step, then immediately
  /// requests the OTP.
  Future<void> onFingerprintSuccess() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    // Already progressed past this step (e.g. a duplicate fingerprint read
    // fired a second call while the first was still in flight) — a no-op,
    // not an error; the first call is already driving the OTP step forward.
    if (state.step != TransactionAuthStep.fingerprint) return;

    try {
      await _repository.confirmFingerprint(sessionId);
    } on AppException catch (e) {
      if (e.code == 'INVALID_SESSION_STATE') return;
      rethrow;
    }
    await _sendOtp();
  }

  /// Called after a LOCAL biometric failure. Fingerprint retry counting is
  /// entirely client-side (matches the existing PIN-lockout pattern) — the
  /// backend call is write-only telemetry, never a gate.
  Future<bool> onFingerprintFailure() async {
    final attempts = state.fingerprintAttempts + 1;
    state = state.copyWith(fingerprintAttempts: attempts);

    final sessionId = state.sessionId;
    if (sessionId != null) {
      try {
        await _repository.recordFingerprintFailure(sessionId, attempts);
      } catch (_) {
        // Best-effort telemetry — must never block the local retry/cancel decision.
      }
    }

    if (attempts >= kMaxFingerprintAttempts) {
      state = state.copyWith(
        step: TransactionAuthStep.failed,
        errorMessage: 'Too many incorrect fingerprint attempts. Transfer cancelled.',
      );
      return false;
    }
    return true;
  }

  Future<void> _sendOtp() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final masked = await _repository.sendOtp(sessionId);
      state = state.copyWith(step: TransactionAuthStep.otp, maskedPhoneNumber: masked, isProcessing: false);
    } on AppException catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.message, step: TransactionAuthStep.failed);
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Could not reach the server. Check your connection and try again.',
        step: TransactionAuthStep.failed,
      );
    }
  }

  Future<void> resendOtp() => _sendOtp();

  /// Verifies the OTP, then — only on success — executes the actual wallet
  /// transfer using this session as proof of authorization. Returns null on
  /// success, or a user-facing error message on failure (OTP or transfer).
  Future<String?> verifyOtpAndTransfer({
    required String code,
    required String purposeWalletId,
    required String amount,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return 'Session expired. Please start again.';

    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await _repository.verifyOtp(sessionId, code);
    } on AppException catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.message);
      return e.message;
    } catch (_) {
      const message = 'Could not reach the server. Check your connection and try again.';
      state = state.copyWith(isProcessing: false, errorMessage: message);
      return message;
    }

    state = state.copyWith(step: TransactionAuthStep.processing);
    try {
      await ref.read(walletProvider.notifier).transfer(
            purposeWalletId: purposeWalletId,
            amount: amount,
            transactionAuthSessionId: sessionId,
          );
      state = state.copyWith(step: TransactionAuthStep.success, isProcessing: false);
      return null;
    } on AppException catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.message, step: TransactionAuthStep.failed);
      return e.message;
    } catch (_) {
      const message = 'Could not reach the server. Check your connection and try again.';
      state = state.copyWith(isProcessing: false, errorMessage: message, step: TransactionAuthStep.failed);
      return message;
    }
  }
}
