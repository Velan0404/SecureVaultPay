/// Endpoint paths only. The host (emulator alias / local IP / production
/// URL) lives in a single place: [AppConfig.apiBaseUrl].
class ApiConstants {
  ApiConstants._();

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String pinSet = '/auth/pin/set';
  static const String pinVerify = '/auth/pin/verify';
  static const String pinLockoutReport = '/auth/pin/lockout-report';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String checkSession = '/auth/check-session';
  static const String deviceFcmToken = '/auth/device/fcm-token';
}
