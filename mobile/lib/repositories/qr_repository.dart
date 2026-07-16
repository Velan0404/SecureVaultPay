import '../models/demo_qr_model.dart';
import '../models/merchant_payment_model.dart';
import '../models/qr_validation_model.dart';
import '../services/qr_service.dart';

/// Domain-facing layer over [QrService] — maps its raw JSON into typed
/// models so [QrNotifier] never touches a `Map<String, dynamic>`.
class QrRepository {
  QrRepository(this._service);

  final QrService _service;

  Future<DemoQrModel> generateDemo(String merchantId) async {
    return DemoQrModel.fromJson(await _service.generateDemo(merchantId));
  }

  Future<QrValidationModel> validate(String qrId) async {
    return QrValidationModel.fromJson(await _service.validate(qrId));
  }

  Future<MerchantPaymentModel> pay({
    required String qrId,
    required String purposeWalletId,
    required String amount,
    required String paymentPin,
  }) async {
    final json = await _service.pay(qrId: qrId, purposeWalletId: purposeWalletId, amount: amount, paymentPin: paymentPin);
    return MerchantPaymentModel.fromJson(json);
  }
}
