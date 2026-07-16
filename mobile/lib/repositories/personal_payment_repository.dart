import '../models/personal_payment_model.dart';
import '../models/personal_payment_receiver_model.dart';
import '../models/user_qr_model.dart';
import '../services/personal_payment_service.dart';

/// Domain-facing layer over [PersonalPaymentService] — maps its raw JSON
/// into typed models so [PersonalPaymentNotifier] never touches a
/// `Map<String, dynamic>`.
class PersonalPaymentRepository {
  PersonalPaymentRepository(this._service);

  final PersonalPaymentService _service;

  Future<UserQrModel> getMyQr() async {
    return UserQrModel.fromJson(await _service.getMyQr());
  }

  Future<PersonalPaymentReceiverModel> lookupReceiver({required String userId, String? secureVaultId}) async {
    return PersonalPaymentReceiverModel.fromJson(
      await _service.lookupReceiver(userId: userId, secureVaultId: secureVaultId),
    );
  }

  /// [phone] must already be in international format (+91XXXXXXXXXX) — see
  /// SearchUserScreen, which builds it the same way register_screen.dart
  /// does (fixed +91 prefix, 10-digit national number).
  Future<PersonalPaymentReceiverModel> searchByPhone(String phone) async {
    return PersonalPaymentReceiverModel.fromJson(await _service.searchByPhone(phone));
  }

  Future<PersonalPaymentModel> pay({
    required String receiverId,
    required String purposeWalletId,
    required String amount,
    String? note,
    required String paymentPin,
  }) async {
    final json = await _service.pay(
      receiverId: receiverId,
      purposeWalletId: purposeWalletId,
      amount: amount,
      note: note,
      paymentPin: paymentPin,
    );
    return PersonalPaymentModel.fromJson(json);
  }
}
