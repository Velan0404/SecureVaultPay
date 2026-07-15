import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> saveSession({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  /// Ends the current session (tokens only). Deliberately leaves the PIN
  /// hash/salt and biometric-enabled flag intact — those represent this
  /// device's setup, not the session, so logging out (by choice or after a
  /// lockout) must never force the user through Create PIN again on their
  /// next login. [StorageKeys.deviceId] is left alone for the same reason.
  /// The fail counter does reset here: a fresh login is a legitimate new
  /// start for that throttle, whether this logout was voluntary or the
  /// result of a lockout.
  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.write(key: StorageKeys.pinFailCount, value: '0');
  }

  /// Wipes this device's PIN/biometric setup entirely — for an explicit PIN
  /// reset, a new device, or a reinstall (the last two never need to call
  /// this in practice, since a fresh secure-storage keystore has nothing to
  /// wipe already). Also called at the start of every fresh registration, so
  /// a new account never inherits a previous account's leftover PIN on a
  /// shared device.
  Future<void> resetDeviceSetup() async {
    await _storage.delete(key: StorageKeys.pinHash);
    await _storage.delete(key: StorageKeys.pinSalt);
    await _storage.delete(key: StorageKeys.pinFailCount);
    await _storage.delete(key: StorageKeys.biometricEnabled);
  }

  /// Device state vs. account state: setup is complete once both the PIN
  /// hash and salt exist — deliberately not a separate stored flag, which
  /// could drift out of sync with the PIN itself. Checking both (not just
  /// the hash) matches how [setPin] always writes them together and rules
  /// out ever treating a partial/corrupt write as a complete setup.
  Future<bool> isDeviceSetupComplete() async {
    final hash = await read(StorageKeys.pinHash);
    final salt = await read(StorageKeys.pinSalt);
    return hash != null && salt != null;
  }
}
