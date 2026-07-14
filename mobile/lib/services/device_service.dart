import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/constants/storage_keys.dart';
import '../models/device_info_model.dart';
import 'secure_storage_service.dart';

class DeviceService {
  DeviceService(this._secureStorage);

  final SecureStorageService _secureStorage;

  String get _platform => Platform.isIOS ? 'IOS' : 'ANDROID';

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(StorageKeys.deviceId);
    if (existing != null) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final deviceId = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await _secureStorage.write(StorageKeys.deviceId, deviceId);
    return deviceId;
  }

  Future<DeviceInfoModel> currentDevice() async {
    final deviceId = await _getOrCreateDeviceId();

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      fcmToken = null;
    }

    return DeviceInfoModel(
      deviceId: deviceId,
      deviceName: Platform.operatingSystem,
      platform: _platform,
      fcmToken: fcmToken,
    );
  }
}
