import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/demo_qr_model.dart';
import '../models/merchant_payment_model.dart';
import '../models/qr_validation_model.dart';
import '../repositories/qr_repository.dart';
import '../services/qr_service.dart';
import 'auth_provider.dart';
import 'merchant_provider.dart';
import 'wallet_provider.dart';

final qrServiceProvider = Provider<QrService>((ref) => QrService(ref.read(apiClientProvider)));

final qrRepositoryProvider = Provider<QrRepository>((ref) => QrRepository(ref.read(qrServiceProvider)));

class QrState {
  const QrState();
}

final qrProvider = NotifierProvider<QrNotifier, QrState>(QrNotifier.new);

/// Drives the QR Merchant Payment flow. Deliberately separate from
/// [MerchantNotifier] — QR handling is only "how did we identify the
/// merchant"; the actual money movement is still the existing
/// merchantService.pay() on the backend, reused unchanged.
class QrNotifier extends Notifier<QrState> {
  late final QrRepository _repository;

  @override
  QrState build() {
    _repository = ref.read(qrRepositoryProvider);
    return const QrState();
  }

  Future<DemoQrModel> generateDemo(String merchantId) => _repository.generateDemo(merchantId);

  Future<QrValidationModel> validate(String qrId) => _repository.validate(qrId);

  /// Executes the actual QR-authorized Purpose Wallet -> Merchant payment,
  /// authorized by the user's Payment PIN — no fingerprint/OTP involved.
  Future<MerchantPaymentModel> pay({
    required String qrId,
    required String purposeWalletId,
    required String amount,
    required String paymentPin,
  }) async {
    final payment = await _repository.pay(
      qrId: qrId,
      purposeWalletId: purposeWalletId,
      amount: amount,
      paymentPin: paymentPin,
    );
    // Same post-payment refresh MerchantNotifier.pay() does — the Purpose
    // Wallet balance and Transaction History just changed via the same
    // underlying merchantService.pay() call.
    await ref.read(walletProvider.notifier).refreshSilently();
    await ref.read(merchantProvider.notifier).loadTotalSpent();
    return payment;
  }
}
