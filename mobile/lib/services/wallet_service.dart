import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw wallet API access — every method returns decoded JSON, untouched.
/// Mapping that JSON into typed models is [WalletRepository]'s job.
class WalletService {
  WalletService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getMainWallet() async {
    final data = await _apiClient.get(ApiConstants.walletMain);
    return data['wallet'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loadDemoMoney() async {
    final data = await _apiClient.post(ApiConstants.walletLoadDemo);
    return data['wallet'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listPurposeWallets() async {
    final data = await _apiClient.get(ApiConstants.walletPurpose);
    return (data['wallets'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getPurposeWallet(String id) async {
    final data = await _apiClient.get('${ApiConstants.walletPurpose}/$id');
    return data['wallet'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPurposeWallet({
    required String name,
    required String icon,
    required String color,
    String? purpose,
    String? spendingLimit,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.walletPurpose,
      body: {
        'name': name,
        'icon': icon,
        'color': color,
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
        if (spendingLimit != null && spendingLimit.isNotEmpty) 'spendingLimit': spendingLimit,
      },
    );
    return data['wallet'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePurposeWallet(
    String id, {
    String? name,
    String? icon,
    String? color,
    String? purpose,
    String? spendingLimit,
  }) async {
    final data = await _apiClient.patch(
      '${ApiConstants.walletPurpose}/$id',
      body: {
        'name': ?name,
        'icon': ?icon,
        'color': ?color,
        'purpose': ?purpose,
        'spendingLimit': ?spendingLimit,
      },
    );
    return data['wallet'] as Map<String, dynamic>;
  }

  Future<void> deletePurposeWallet(String id) {
    return _apiClient.delete('${ApiConstants.walletPurpose}/$id');
  }

  // transactionAuthSessionId proves fingerprint + Twilio OTP were already
  // completed (see TransactionAuthenticationScreen) — the backend rejects
  // this call outright without a verified session for this exact wallet and
  // amount.
  Future<Map<String, dynamic>> transfer({
    required String purposeWalletId,
    required String amount,
    required String transactionAuthSessionId,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.walletTransfer,
      body: {
        'purposeWalletId': purposeWalletId,
        'amount': amount,
        'transactionAuthSessionId': transactionAuthSessionId,
      },
    );
    return data['transfer'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listTransactions({String? purposeWalletId, String? cursor}) {
    final query = <String, String>{
      'purposeWalletId': ?purposeWalletId,
      'cursor': ?cursor,
    };
    final path = query.isEmpty
        ? ApiConstants.walletTransactions
        : '${ApiConstants.walletTransactions}?${Uri(queryParameters: query).query}';
    return _apiClient.get(path);
  }

  Future<Map<String, dynamic>> getDashboard() {
    return _apiClient.get(ApiConstants.walletDashboard);
  }
}
