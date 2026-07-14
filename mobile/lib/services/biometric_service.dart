import 'package:local_auth/local_auth.dart';

/// Hardware-adaptive biometric authentication — supports Face ID, Face Unlock,
/// or Fingerprint depending on what the device offers, via `local_auth`.
class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isBiometricAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<List<BiometricType>> availableBiometrics() => _auth.getAvailableBiometrics();

  /// Returns true only on a genuine biometric success. No OS-passcode fallback —
  /// the app's own 6-digit PIN is the sole non-biometric fallback.
  Future<bool> authenticate({String reason = 'Unlock SecureVault Pay'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
