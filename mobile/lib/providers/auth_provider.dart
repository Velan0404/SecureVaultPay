import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/storage_keys.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/utils/pin_hasher.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/device_service.dart';
import '../services/secure_storage_service.dart';

const int kMaxPinAttempts = 5;

enum AuthStatus { unknown, unauthenticated, needsUnlock, onboarding, authenticated }

enum PinUnlockResult { success, incorrect, lockedOut, networkError }

class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final UserModel? user;

  static const initial = AuthState(status: AuthStatus.unknown);

  AuthState copyWith({AuthStatus? status, UserModel? user}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final deviceServiceProvider = Provider<DeviceService>(
  (ref) => DeviceService(ref.read(secureStorageServiceProvider)),
);

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.read(secureStorageServiceProvider));
  client.onUnauthorized = () => ref.read(authProvider.notifier).silentRefresh();
  return client;
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiClientProvider), ref.read(deviceServiceProvider)),
);

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  late final SecureStorageService _secureStorage;
  late final AuthService _authService;
  late final BiometricService _biometricService;

  @override
  AuthState build() {
    _secureStorage = ref.read(secureStorageServiceProvider);
    _authService = ref.read(authServiceProvider);
    _biometricService = ref.read(biometricServiceProvider);
    return AuthState.initial;
  }

  /// Called once at app start. Decides whether to show Login/Register or the
  /// App-Lock Gate, without making a network call yet.
  Future<void> bootstrap() async {
    final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    if (refreshToken == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    // A refresh token can exist without a local PIN yet if the app was killed
    // mid-onboarding (after register, before Create PIN completed).
    final hasLocalPin = await _secureStorage.read(StorageKeys.pinHash) != null;
    state = state.copyWith(status: hasLocalPin ? AuthStatus.needsUnlock : AuthStatus.onboarding);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(StorageKeys.biometricEnabled);
    return value == 'true';
  }

  Future<bool> canUseBiometrics() => _biometricService.isBiometricAvailable();

  /// Attempts a biometric unlock. Returns false if unavailable, declined,
  /// failed, or unreachable — the caller should then fall back to the PIN
  /// screen (which surfaces a proper error for the unreachable case).
  Future<bool> unlockWithBiometrics() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;

    final available = await _biometricService.isBiometricAvailable();
    if (!available) return false;

    final success = await _biometricService.authenticate();
    if (!success) return false;

    return (await _completeUnlock()) == PinUnlockResult.success;
  }

  Future<PinUnlockResult> unlockWithPin(String pin) async {
    final storedHash = await _secureStorage.read(StorageKeys.pinHash);
    final storedSalt = await _secureStorage.read(StorageKeys.pinSalt);

    if (storedHash != null && storedSalt != null && PinHasher.hash(pin, storedSalt) == storedHash) {
      await _secureStorage.write(StorageKeys.pinFailCount, '0');
      return _completeUnlock();
    }

    final currentCount = int.tryParse(await _secureStorage.read(StorageKeys.pinFailCount) ?? '0') ?? 0;
    final nextCount = currentCount + 1;
    await _secureStorage.write(StorageKeys.pinFailCount, nextCount.toString());

    if (nextCount >= kMaxPinAttempts) {
      final deviceId = await _secureStorage.read(StorageKeys.deviceId) ?? '';
      try {
        await _authService.reportPinLockout(deviceId);
      } catch (_) {
        // Best-effort — the local lockout still proceeds even if this call fails.
      }
      await logout();
      return PinUnlockResult.lockedOut;
    }

    return PinUnlockResult.incorrect;
  }

  /// The PIN/biometric itself may have been entered correctly on-device, but
  /// unlocking also confirms the session is still valid server-side. Those
  /// are different failure modes and must be handled differently:
  ///  - the server explicitly rejects the token (revoked/expired/invalid) →
  ///    the session really is dead, so force a full logout.
  ///  - any other error (no connectivity, DNS failure, timeout, etc.) → the
  ///    PIN/biometric was fine, we just couldn't reach the server. Don't wipe
  ///    a possibly-still-valid session over a transient network blip.
  Future<PinUnlockResult> _completeUnlock() async {
    try {
      final user = await _authService.checkSession();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return PinUnlockResult.success;
    } on AppException {
      await logout();
      return PinUnlockResult.incorrect;
    } catch (_) {
      return PinUnlockResult.networkError;
    }
  }

  /// New accounts always go through PIN/biometric onboarding on this device.
  Future<void> register({required String fullName, required String email, required String password}) async {
    final result = await _authService.register(fullName: fullName, email: email, password: password);
    await _secureStorage.saveSession(accessToken: result.accessToken, refreshToken: result.refreshToken);
    state = state.copyWith(status: AuthStatus.onboarding, user: result.user);
  }

  /// Existing accounts skip onboarding only if this specific device already
  /// has a local PIN set up (PIN/biometric are device-local, not account-wide).
  Future<void> login({required String email, required String password}) async {
    final result = await _authService.login(email: email, password: password);
    await _secureStorage.saveSession(accessToken: result.accessToken, refreshToken: result.refreshToken);
    final hasLocalPin = await _secureStorage.read(StorageKeys.pinHash) != null;
    state = state.copyWith(
      status: hasLocalPin ? AuthStatus.authenticated : AuthStatus.onboarding,
      user: result.user,
    );
  }

  /// Called after the Enable Biometric onboarding step finishes (or is skipped).
  void completeOnboarding() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<void> setPin(String pin) async {
    await _authService.setPin(pin);
    final salt = PinHasher.generateSalt();
    await _secureStorage.write(StorageKeys.pinSalt, salt);
    await _secureStorage.write(StorageKeys.pinHash, PinHasher.hash(pin, salt));
    await _secureStorage.write(StorageKeys.pinFailCount, '0');
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(StorageKeys.biometricEnabled, enabled.toString());
  }

  Future<void> forgotPassword(String email) => _authService.forgotPassword(email);

  Future<void> resetPassword({required String email, required String otp, required String newPassword}) {
    return _authService.resetPassword(email: email, otp: otp, newPassword: newPassword);
  }

  /// Invoked by [ApiClient.onUnauthorized] when an access token has expired.
  Future<bool> silentRefresh() async {
    final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    if (refreshToken == null) return false;

    try {
      final tokens = await _authService.refresh(refreshToken);
      await _secureStorage.saveSession(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// Keeps the backend's Device.fcmToken current when Firebase rotates the
  /// token. Only meaningful once a device/session actually exists server-side
  /// — if the user isn't authenticated yet, the fresh token is picked up
  /// naturally on the next register/login instead.
  Future<void> handleFcmTokenRefresh(String token) async {
    if (state.status != AuthStatus.authenticated) return;

    final deviceId = await _secureStorage.read(StorageKeys.deviceId);
    if (deviceId == null) return;

    try {
      await _authService.updateFcmToken(deviceId: deviceId, fcmToken: token);
    } catch (_) {
      // Best-effort — will be retried implicitly on the next login/refresh cycle.
    }
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    if (refreshToken != null) {
      try {
        await _authService.logout(refreshToken);
      } catch (_) {
        // Proceed with local logout regardless of network outcome.
      }
    }
    await _secureStorage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
