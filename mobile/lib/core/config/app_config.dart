import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for the backend API host.
///
/// This is the ONLY place in the app that decides which host the API client
/// talks to. Every network call goes through [ApiClient], which reads
/// [apiBaseUrl] from here — nothing else in the app should hardcode a host.
class AppConfig {
  AppConfig._();

  /// Your computer's local network IP address, used when running on a
  /// physical Android device connected to the same Wi-Fi network as the
  /// backend. Find it with `ipconfig` (Windows) or `ifconfig`/`ip a`
  /// (macOS/Linux), then update this one value — nothing else needs to change.
  ///
  /// Set to this machine's current Wi-Fi IPv4 address. DHCP can reassign it
  /// later (e.g. after reconnecting to Wi-Fi or restarting the router) — if
  /// physical-device requests start failing again, re-check with `ipconfig`
  /// and update this value.
  static const String localIp = '172.31.99.10';

  /// Port the backend listens on (see backend/.env `PORT`).
  static const int apiPort = 5000;

  static const String _emulatorHost = '10.0.2.2';

  static bool _isPhysicalDevice = true;
  static bool _initialized = false;

  /// Detects emulator vs. physical device. Must be awaited once at app
  /// startup, before any API call is made (see main.dart).
  static Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        _isPhysicalDevice = androidInfo.isPhysicalDevice;
      } catch (_) {
        // If detection fails for any reason, default to treating this as a
        // physical device — the safer assumption, since the emulator alias
        // (10.0.2.2) would never resolve on a real device anyway.
        _isPhysicalDevice = true;
      }
    }

    _initialized = true;
  }

  /// The full API base URL (e.g. `http://10.0.2.2:5000/api`).
  ///
  /// Resolution order:
  /// 1. `--dart-define=API_BASE_URL=...` — always wins, for production/staging builds.
  /// 2. Android Emulator — `http://10.0.2.2:$apiPort/api`.
  /// 3. Physical device (or any other platform) — `http://$localIp:$apiPort/api`.
  static String get apiBaseUrl {
    const productionOverride = String.fromEnvironment('API_BASE_URL');
    if (productionOverride.isNotEmpty) return productionOverride;

    final host = _isPhysicalDevice ? localIp : _emulatorHost;
    return 'http://$host:$apiPort/api';
  }
}
