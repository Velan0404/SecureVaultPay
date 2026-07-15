import '../models/merchant_model.dart';
import '../models/merchant_payment_model.dart';
import '../services/merchant_service.dart';

/// Domain-facing merchant layer — maps [MerchantService]'s raw JSON into
/// typed models so [MerchantNotifier] never touches a `Map<String, dynamic>`.
class MerchantRepository {
  MerchantRepository(this._service);

  final MerchantService _service;

  Future<List<MerchantModel>> listMerchants({String? category}) async {
    final merchants = await _service.listMerchants(category: category);
    return merchants.map(MerchantModel.fromJson).toList();
  }

  Future<MerchantModel> getMerchant(String id) async {
    return MerchantModel.fromJson(await _service.getMerchant(id));
  }

  Future<MerchantPaymentModel> pay({
    required String merchantId,
    required String purposeWalletId,
    required String amount,
    required String paymentPin,
  }) async {
    final json = await _service.pay(
      merchantId: merchantId,
      purposeWalletId: purposeWalletId,
      amount: amount,
      paymentPin: paymentPin,
    );
    return MerchantPaymentModel.fromJson(json);
  }

  Future<String> getTotalSpent() => _service.getTotalSpent();
}
