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

  static const String walletMain = '/wallet/main';
  static const String walletLoadDemo = '/wallet/main/load-demo';
  static const String walletPurpose = '/wallet/purpose';
  static const String walletTransfer = '/wallet/transfer';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletDashboard = '/wallet/dashboard';

  static const String transactionAuthPhone = '/transaction-auth/phone';
  static const String transactionAuthStart = '/transaction-auth/start';
  static String transactionAuthConfirmFingerprint(String sessionId) =>
      '/transaction-auth/$sessionId/confirm-fingerprint';
  static String transactionAuthFingerprintFailed(String sessionId) =>
      '/transaction-auth/$sessionId/fingerprint-failed';
  static String transactionAuthOtpSend(String sessionId) => '/transaction-auth/$sessionId/otp/send';
  static String transactionAuthOtpVerify(String sessionId) => '/transaction-auth/$sessionId/otp/verify';
}
