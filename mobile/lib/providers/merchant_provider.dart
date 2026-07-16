import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/merchant_model.dart';
import '../models/merchant_payment_model.dart';
import '../repositories/merchant_repository.dart';
import '../services/merchant_service.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';

final merchantServiceProvider = Provider<MerchantService>((ref) => MerchantService(ref.read(apiClientProvider)));

final merchantRepositoryProvider = Provider<MerchantRepository>(
  (ref) => MerchantRepository(ref.read(merchantServiceProvider)),
);

class MerchantState {
  const MerchantState({
    this.merchants = const [],
    this.totalSpent,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<MerchantModel> merchants;
  final String? totalSpent;
  final bool isLoading;
  final String? errorMessage;

  MerchantState copyWith({
    List<MerchantModel>? merchants,
    String? totalSpent,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MerchantState(
      merchants: merchants ?? this.merchants,
      totalSpent: totalSpent ?? this.totalSpent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final merchantProvider = NotifierProvider<MerchantNotifier, MerchantState>(MerchantNotifier.new);

/// Drives the Merchant List/Details screens and executes the actual payment.
/// Deliberately separate from [WalletNotifier] — Merchant Payment is its own
/// module that only ever debits a Purpose Wallet (never Main Wallet, which
/// has no merchant-payment API to even call).
class MerchantNotifier extends Notifier<MerchantState> {
  // A getter, not a `late final` field assigned inside build() — see the
  // identical note on WalletNotifier._repository. Not currently invalidated
  // by AuthNotifier, but a plain field here would still be unsafe against
  // any future invalidation/dependency-change rebuild, so it's fixed
  // consistently across every Notifier in this audit.
  MerchantRepository get _repository => ref.read(merchantRepositoryProvider);

  @override
  MerchantState build() {
    return const MerchantState();
  }

  Future<void> loadMerchants({String? category}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final merchants = await _repository.listMerchants(category: category);
      state = state.copyWith(merchants: merchants, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  /// Best-effort — a dashboard/analytics stat failing to load must never
  /// block the rest of the screen.
  Future<void> loadTotalSpent() async {
    try {
      final total = await _repository.getTotalSpent();
      state = state.copyWith(totalSpent: total);
    } catch (_) {
      // Ignored — the caller can simply retry later.
    }
  }

  /// Executes the actual Purpose Wallet -> Merchant payment, authorized by
  /// the user's Payment PIN (Phase 5.1) — no fingerprint/OTP involved. Only
  /// ever called after the Payment PIN has been created/confirmed or
  /// entered (see payment_pin_provider.dart).
  Future<MerchantPaymentModel> pay({
    required String merchantId,
    required String purposeWalletId,
    required String amount,
    required String paymentPin,
  }) async {
    final payment = await _repository.pay(
      merchantId: merchantId,
      purposeWalletId: purposeWalletId,
      amount: amount,
      paymentPin: paymentPin,
    );
    // The Purpose Wallet balance and Transaction History just changed —
    // refresh the Wallet module's own state (unchanged, just re-read) so the
    // Dashboard and Wallet Details screens reflect it without a manual pull.
    await ref.read(walletProvider.notifier).refreshSilently();
    await loadTotalSpent();
    return payment;
  }
}
