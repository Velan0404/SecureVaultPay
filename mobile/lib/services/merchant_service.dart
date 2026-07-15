import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw Merchant API access — every method returns decoded JSON, untouched.
/// Mapping that JSON into typed models is [MerchantRepository]'s job.
class MerchantService {
  MerchantService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> listMerchants({String? category}) async {
    final path = (category == null || category.isEmpty)
        ? ApiConstants.merchantList
        : '${ApiConstants.merchantList}?category=$category';
    final data = await _apiClient.get(path);
    return (data['merchants'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getMerchant(String id) async {
    final data = await _apiClient.get(ApiConstants.merchantDetails(id));
    return data['merchant'] as Map<String, dynamic>;
  }

  // paymentPin authorizes the payment (Phase 5.1) — verified server-side on
  // every call, never fingerprint/OTP. The backend rejects this call
  // outright without a correct Payment PIN.
  Future<Map<String, dynamic>> pay({
    required String merchantId,
    required String purposeWalletId,
    required String amount,
    required String paymentPin,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.merchantPay(merchantId),
      body: {
        'purposeWalletId': purposeWalletId,
        'amount': amount,
        'paymentPin': paymentPin,
      },
    );
    return data['payment'] as Map<String, dynamic>;
  }

  Future<String> getTotalSpent() async {
    final data = await _apiClient.get(ApiConstants.merchantSpendingTotal);
    return data['totalSpent'].toString();
  }
}
