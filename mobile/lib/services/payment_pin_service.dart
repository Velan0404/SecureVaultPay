import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw Payment PIN API access. The Payment PIN is a separate credential from
/// the App PIN (which only unlocks the app) — this one authorizes Merchant
/// Payments, verified server-side on every payment (see MerchantService.pay).
class PaymentPinService {
  PaymentPinService(this._apiClient);

  final ApiClient _apiClient;

  Future<bool> status() async {
    final data = await _apiClient.get(ApiConstants.paymentPinStatus);
    return data['hasPaymentPin'] as bool;
  }

  Future<void> create(String pin) {
    return _apiClient.post(ApiConstants.paymentPinCreate, body: {'pin': pin});
  }
}
