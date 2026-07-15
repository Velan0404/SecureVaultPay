import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/secure_storage_service.dart';
import '../config/app_config.dart';
import '../constants/storage_keys.dart';
import '../errors/app_exception.dart';

/// Attempts a silent token refresh. Returns true if a new access token was
/// obtained, false if the session could no longer be refreshed.
typedef UnauthorizedHandler = Future<bool> Function();

class ApiClient {
  ApiClient(this._secureStorage);

  final SecureStorageService _secureStorage;

  /// Set by the auth layer at startup to avoid a circular dependency between
  /// this client and the auth provider that owns the refresh flow.
  UnauthorizedHandler? onUnauthorized;

  Future<Map<String, dynamic>> get(String path, {bool requiresAuth = true}) {
    return _send('GET', path, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, bool requiresAuth = true}) {
    return _send('POST', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body, bool requiresAuth = true}) {
    return _send('PATCH', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> delete(String path, {bool requiresAuth = true}) {
    return _send('DELETE', path, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await _secureStorage.read(StorageKeys.accessToken);
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final encodedBody = body != null ? jsonEncode(body) : null;
    late final http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
      case 'POST':
        response = await http.post(uri, headers: headers, body: encodedBody);
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: encodedBody);
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: encodedBody);
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    }

    final error = decoded['error'] as Map<String, dynamic>?;
    final errorCode = error?['code'] as String? ?? 'UNKNOWN_ERROR';
    final errorMessage = error?['message'] as String? ?? 'Something went wrong. Please try again.';

    if (errorCode == 'TOKEN_EXPIRED' && requiresAuth && !isRetry && onUnauthorized != null) {
      final refreshed = await onUnauthorized!();
      if (refreshed) {
        return _send(method, path, body: body, requiresAuth: requiresAuth, isRetry: true);
      }
    }

    throw AppException(code: errorCode, message: errorMessage, statusCode: response.statusCode);
  }
}
