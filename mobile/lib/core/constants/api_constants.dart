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

  static const String merchantList = '/merchant';
  static const String merchantSpendingTotal = '/merchant/spending/total';
  static String merchantDetails(String id) => '/merchant/$id';
  static String merchantPay(String id) => '/merchant/$id/pay';

  static const String paymentPinStatus = '/payment-pin/status';
  static const String paymentPinCreate = '/payment-pin';

  static const String qrGenerateDemo = '/qr/demo';
  static String qrValidate(String qrId) => '/qr/validate/$qrId';
  static String qrPay(String qrId) => '/qr/$qrId/pay';

  static const String personalPaymentMyQr = '/personal-payment/my-qr';
  // Uri.encodeComponent is required here, not optional — a raw '+' in a
  // query string is interpreted as a literal space by Express's query
  // parser (the application/x-www-form-urlencoded convention), so an
  // unencoded "+919876543210" would arrive at the backend as " 919876543210".
  static String personalPaymentSearch(String phone) => '/personal-payment/search?phone=${Uri.encodeComponent(phone)}';
  static String personalPaymentLookup(String userId, {String? secureVaultId}) => secureVaultId != null
      ? '/personal-payment/lookup/$userId?secureVaultId=$secureVaultId'
      : '/personal-payment/lookup/$userId';
  static String personalPaymentPay(String receiverId) => '/personal-payment/$receiverId/pay';

  static const String scheduledPaymentDashboard = '/scheduled-payments/dashboard';
  static const String scheduledPaymentList = '/scheduled-payments';
  static const String scheduledPaymentCreate = '/scheduled-payments';
  static String scheduledPaymentDetails(String id) => '/scheduled-payments/$id';
  static String scheduledPaymentUpdate(String id) => '/scheduled-payments/$id';
  static String scheduledPaymentExecutions(String id, {String? cursor}) =>
      cursor != null ? '/scheduled-payments/$id/executions?cursor=$cursor' : '/scheduled-payments/$id/executions';
  static String scheduledPaymentPause(String id) => '/scheduled-payments/$id/pause';
  static String scheduledPaymentResume(String id) => '/scheduled-payments/$id/resume';
  static String scheduledPaymentCancel(String id) => '/scheduled-payments/$id';

  // Shared by every /analytics/* endpoint below — one place building the
  // range/startDate/endDate query string so the four callers can't drift.
  static String _rangeQuery(String range, {String? startDate, String? endDate}) {
    final params = {
      'range': range,
      'startDate': ?startDate,
      'endDate': ?endDate,
    };
    return params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
  }

  static String analyticsDashboard(String range, {String? startDate, String? endDate}) =>
      '/analytics/dashboard?${_rangeQuery(range, startDate: startDate, endDate: endDate)}';
  static String analyticsWallets(String range, {String? startDate, String? endDate}) =>
      '/analytics/wallets?${_rangeQuery(range, startDate: startDate, endDate: endDate)}';
  static String analyticsCharts(String range, {String? startDate, String? endDate}) =>
      '/analytics/charts?${_rangeQuery(range, startDate: startDate, endDate: endDate)}';
  static String analyticsInsights(String range, {String? startDate, String? endDate}) =>
      '/analytics/insights?${_rangeQuery(range, startDate: startDate, endDate: endDate)}';
  static String analyticsReports(String period, {String? date}) =>
      date != null ? '/analytics/reports?period=$period&date=${Uri.encodeComponent(date)}' : '/analytics/reports?period=$period';
}
