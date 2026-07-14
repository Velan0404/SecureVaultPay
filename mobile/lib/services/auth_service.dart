import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/auth_result.dart';
import '../models/user_model.dart';
import 'device_service.dart';

class AuthService {
  AuthService(this._apiClient, this._deviceService);

  final ApiClient _apiClient;
  final DeviceService _deviceService;

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final device = await _deviceService.currentDevice();
    final data = await _apiClient.post(
      ApiConstants.register,
      body: {'fullName': fullName, 'email': email, 'password': password, 'device': device.toJson()},
      requiresAuth: false,
    );
    return AuthResult.fromJson(data);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final device = await _deviceService.currentDevice();
    final data = await _apiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password, 'device': device.toJson()},
      requiresAuth: false,
    );
    return AuthResult.fromJson(data);
  }

  Future<({String accessToken, String refreshToken})> refresh(String refreshToken) async {
    final data = await _apiClient.post(
      ApiConstants.refresh,
      body: {'refreshToken': refreshToken},
      requiresAuth: false,
    );
    return (accessToken: data['accessToken'] as String, refreshToken: data['refreshToken'] as String);
  }

  Future<void> logout(String refreshToken) {
    return _apiClient.post(
      ApiConstants.logout,
      body: {'refreshToken': refreshToken},
      requiresAuth: false,
    );
  }

  Future<void> logoutAll() {
    return _apiClient.post(ApiConstants.logoutAll);
  }

  Future<void> setPin(String pin) {
    return _apiClient.post(ApiConstants.pinSet, body: {'pin': pin});
  }

  Future<void> verifyPin(String pin) {
    return _apiClient.post(ApiConstants.pinVerify, body: {'pin': pin});
  }

  Future<void> reportPinLockout(String deviceId) {
    return _apiClient.post(ApiConstants.pinLockoutReport, body: {'deviceId': deviceId});
  }

  Future<void> forgotPassword(String email) {
    return _apiClient.post(ApiConstants.forgotPassword, body: {'email': email}, requiresAuth: false);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _apiClient.post(
      ApiConstants.resetPassword,
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
      requiresAuth: false,
    );
  }

  Future<UserModel> checkSession() async {
    final data = await _apiClient.get(ApiConstants.checkSession);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> updateFcmToken({required String deviceId, required String fcmToken}) {
    return _apiClient.patch(ApiConstants.deviceFcmToken, body: {'deviceId': deviceId, 'fcmToken': fcmToken});
  }
}
