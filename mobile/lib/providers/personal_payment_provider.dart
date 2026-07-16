import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/personal_payment_model.dart';
import '../models/personal_payment_receiver_model.dart';
import '../models/user_qr_model.dart';
import '../repositories/personal_payment_repository.dart';
import '../services/personal_payment_service.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';

final personalPaymentServiceProvider = Provider<PersonalPaymentService>(
  (ref) => PersonalPaymentService(ref.read(apiClientProvider)),
);

final personalPaymentRepositoryProvider = Provider<PersonalPaymentRepository>(
  (ref) => PersonalPaymentRepository(ref.read(personalPaymentServiceProvider)),
);

class PersonalPaymentState {
  const PersonalPaymentState();
}

final personalPaymentProvider =
    NotifierProvider<PersonalPaymentNotifier, PersonalPaymentState>(PersonalPaymentNotifier.new);

/// Drives Personal QR (My QR + user-to-user payment). Deliberately separate
/// from MerchantNotifier/QrNotifier — Personal Payment always moves money
/// into another user's Main Wallet, never a Merchant.
class PersonalPaymentNotifier extends Notifier<PersonalPaymentState> {
  late final PersonalPaymentRepository _repository;

  @override
  PersonalPaymentState build() {
    _repository = ref.read(personalPaymentRepositoryProvider);
    return const PersonalPaymentState();
  }

  Future<UserQrModel> getMyQr() => _repository.getMyQr();

  Future<PersonalPaymentReceiverModel> lookupReceiver({required String userId, String? secureVaultId}) =>
      _repository.lookupReceiver(userId: userId, secureVaultId: secureVaultId);

  /// [phone] must already be in international format (+91XXXXXXXXXX).
  Future<PersonalPaymentReceiverModel> searchByPhone(String phone) => _repository.searchByPhone(phone);

  /// Executes the actual Purpose Wallet -> another user's Main Wallet
  /// payment, authorized by the sender's Payment PIN — no fingerprint/OTP
  /// involved.
  Future<PersonalPaymentModel> pay({
    required String receiverId,
    required String purposeWalletId,
    required String amount,
    String? note,
    required String paymentPin,
  }) async {
    final payment = await _repository.pay(
      receiverId: receiverId,
      purposeWalletId: purposeWalletId,
      amount: amount,
      note: note,
      paymentPin: paymentPin,
    );
    // Same post-payment refresh MerchantNotifier.pay()/QrNotifier.pay() do —
    // the sender's Purpose Wallet balance and Transaction History just
    // changed.
    await ref.read(walletProvider.notifier).refreshSilently();
    return payment;
  }
}
