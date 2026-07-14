import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Distinguishes *why* a biometric attempt failed so callers can show a
/// specific message instead of a generic "could not confirm" fallback.
enum BiometricFailureReason {
  none,
  noHardware,
  hardwareUnavailable,
  notEnrolled,
  noDeviceCredentials,
  temporaryLockout,
  permanentLockout,
  userCanceled,
  systemCanceled,
  notFragmentActivity,
  authFailed,
  unknown,
}

/// Hardware-adaptive biometric authentication — supports Face ID, Face Unlock,
/// or Fingerprint depending on what the device offers, via `local_auth`.
class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  BiometricFailureReason lastFailureReason = BiometricFailureReason.none;
  String? lastErrorDetail;

  Future<bool> isBiometricAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    debugPrint('[BiometricService] canCheckBiometrics=$canCheck isDeviceSupported=$isSupported');

    if (!canCheck || !isSupported) {
      lastFailureReason = BiometricFailureReason.noHardware;
      return false;
    }
    return true;
  }

  Future<List<BiometricType>> availableBiometrics() async {
    final types = await _auth.getAvailableBiometrics();
    debugPrint('[BiometricService] getAvailableBiometrics=$types');
    return types;
  }

  /// Returns true only on a genuine biometric success. No OS-passcode fallback —
  /// the app's own 6-digit PIN is the sole non-biometric fallback.
  Future<bool> authenticate({String reason = 'Unlock SecureVault Pay'}) async {
    lastFailureReason = BiometricFailureReason.none;
    lastErrorDetail = null;

    try {
      final result = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      debugPrint('[BiometricService] authenticate() -> $result');
      if (!result) {
        lastFailureReason = BiometricFailureReason.authFailed;
      }
      return result;
    } on LocalAuthException catch (e) {
      debugPrint(
        '[BiometricService] LocalAuthException code=${e.code.name} '
        'description=${e.description} details=${e.details}',
      );
      lastErrorDetail = e.description;
      lastFailureReason = _mapExceptionCode(e.code, e.description);
      return false;
    } catch (e, st) {
      debugPrint('[BiometricService] unexpected ${e.runtimeType}: $e');
      debugPrintStack(stackTrace: st);
      lastErrorDetail = e.toString();
      lastFailureReason = BiometricFailureReason.unknown;
      return false;
    }
  }

  BiometricFailureReason _mapExceptionCode(LocalAuthExceptionCode code, String? description) {
    switch (code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return BiometricFailureReason.noHardware;
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return BiometricFailureReason.hardwareUnavailable;
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return BiometricFailureReason.notEnrolled;
      case LocalAuthExceptionCode.noCredentialsSet:
        return BiometricFailureReason.noDeviceCredentials;
      case LocalAuthExceptionCode.temporaryLockout:
        return BiometricFailureReason.temporaryLockout;
      case LocalAuthExceptionCode.biometricLockout:
        return BiometricFailureReason.permanentLockout;
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.userRequestedFallback:
        return BiometricFailureReason.userCanceled;
      case LocalAuthExceptionCode.systemCanceled:
        return BiometricFailureReason.systemCanceled;
      case LocalAuthExceptionCode.uiUnavailable:
        // local_auth_android reuses uiUnavailable both for "no Activity" and
        // for "Activity is not a FragmentActivity" — the description tells
        // the two apart.
        if (description?.contains('FragmentActivity') ?? false) {
          return BiometricFailureReason.notFragmentActivity;
        }
        return BiometricFailureReason.unknown;
      case LocalAuthExceptionCode.authInProgress:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        return BiometricFailureReason.unknown;
    }
  }

  /// A user-facing message describing exactly why the last [authenticate]
  /// call (or [isBiometricAvailable] check) failed.
  String get failureMessage {
    switch (lastFailureReason) {
      case BiometricFailureReason.noHardware:
        return 'No biometric hardware is available on this device.';
      case BiometricFailureReason.hardwareUnavailable:
        return 'The fingerprint/face sensor is temporarily unavailable.';
      case BiometricFailureReason.notEnrolled:
        return 'No fingerprint or face is enrolled. Add one in your device settings first.';
      case BiometricFailureReason.noDeviceCredentials:
        return 'Set up a device PIN, pattern, or password before enabling biometrics.';
      case BiometricFailureReason.temporaryLockout:
        return 'Too many failed attempts. Try again in a moment.';
      case BiometricFailureReason.permanentLockout:
        return 'Biometrics are locked. Unlock your device with its PIN/pattern to reset this.';
      case BiometricFailureReason.userCanceled:
        return 'Biometric confirmation was cancelled.';
      case BiometricFailureReason.systemCanceled:
        return 'Biometric confirmation was interrupted.';
      case BiometricFailureReason.notFragmentActivity:
        return 'Biometric prompt is not supported by this app build.';
      case BiometricFailureReason.authFailed:
        return 'Fingerprint or face did not match.';
      case BiometricFailureReason.unknown:
        return lastErrorDetail == null
            ? 'An unexpected biometric error occurred.'
            : 'Biometric error: $lastErrorDetail';
      case BiometricFailureReason.none:
        return 'Could not confirm biometric login.';
    }
  }
}
