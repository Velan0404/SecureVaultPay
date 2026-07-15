import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/purpose_wallet_model.dart';
import '../models/wallet_dashboard_model.dart';
import '../models/wallet_transaction_model.dart';
import '../repositories/wallet_repository.dart';
import '../services/wallet_service.dart';
import 'auth_provider.dart';

final walletServiceProvider = Provider<WalletService>((ref) => WalletService(ref.read(apiClientProvider)));

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.read(walletServiceProvider)),
);

class WalletState {
  const WalletState({
    this.dashboard,
    this.transactions = const [],
    this.nextTransactionCursor,
    this.isLoading = false,
    this.isLoadingTransactions = false,
    this.errorMessage,
  });

  final WalletDashboardModel? dashboard;
  final List<WalletTransactionModel> transactions;
  final String? nextTransactionCursor;
  final bool isLoading;
  final bool isLoadingTransactions;
  final String? errorMessage;

  List<PurposeWalletModel> get purposeWallets => dashboard?.purposeWallets ?? const [];

  WalletState copyWith({
    WalletDashboardModel? dashboard,
    List<WalletTransactionModel>? transactions,
    String? nextTransactionCursor,
    bool clearNextTransactionCursor = false,
    bool? isLoading,
    bool? isLoadingTransactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WalletState(
      dashboard: dashboard ?? this.dashboard,
      transactions: transactions ?? this.transactions,
      nextTransactionCursor:
          clearNextTransactionCursor ? null : (nextTransactionCursor ?? this.nextTransactionCursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingTransactions: isLoadingTransactions ?? this.isLoadingTransactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

class WalletNotifier extends Notifier<WalletState> {
  late final WalletRepository _repository;

  @override
  WalletState build() {
    _repository = ref.read(walletRepositoryProvider);
    return const WalletState();
  }

  /// Loads (or refreshes) everything the Dashboard and Main Wallet screens
  /// need in one call — the backend's `/wallet/dashboard` endpoint already
  /// aggregates main balance, purpose wallets, and recent transactions.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dashboard = await _repository.getDashboard();
      state = state.copyWith(dashboard: dashboard, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  /// Re-fetches the dashboard silently (no loading flag) — used after a
  /// create/edit/delete/transfer so the screen reflects the new state
  /// without flashing a spinner over content the user is already looking at.
  Future<void> refreshSilently() async {
    try {
      final dashboard = await _repository.getDashboard();
      state = state.copyWith(dashboard: dashboard);
    } catch (_) {
      // Best-effort — the next explicit loadDashboard() will surface any
      // persistent error.
    }
  }

  Future<void> loadDemoMoney() async {
    await _repository.loadDemoMoney();
    await refreshSilently();
  }

  Future<PurposeWalletModel> createPurposeWallet({
    required String name,
    required String icon,
    required String color,
    String? purpose,
    String? spendingLimit,
  }) async {
    final wallet = await _repository.createPurposeWallet(
      name: name,
      icon: icon,
      color: color,
      purpose: purpose,
      spendingLimit: spendingLimit,
    );
    await refreshSilently();
    return wallet;
  }

  Future<PurposeWalletModel> updatePurposeWallet(
    String id, {
    String? name,
    String? icon,
    String? color,
    String? purpose,
    String? spendingLimit,
  }) async {
    final wallet = await _repository.updatePurposeWallet(
      id,
      name: name,
      icon: icon,
      color: color,
      purpose: purpose,
      spendingLimit: spendingLimit,
    );
    await refreshSilently();
    return wallet;
  }

  Future<void> deletePurposeWallet(String id) async {
    await _repository.deletePurposeWallet(id);
    await refreshSilently();
  }

  Future<void> transfer({required String purposeWalletId, required String amount}) async {
    await _repository.transfer(purposeWalletId: purposeWalletId, amount: amount);
    await refreshSilently();
  }

  Future<void> loadTransactions({String? purposeWalletId}) async {
    state = state.copyWith(isLoadingTransactions: true, clearNextTransactionCursor: true);
    final result = await _repository.listTransactions(purposeWalletId: purposeWalletId);
    state = state.copyWith(
      transactions: result.transactions,
      nextTransactionCursor: result.nextCursor,
      isLoadingTransactions: false,
    );
  }

  Future<void> loadMoreTransactions({String? purposeWalletId}) async {
    final cursor = state.nextTransactionCursor;
    if (cursor == null || state.isLoadingTransactions) return;

    state = state.copyWith(isLoadingTransactions: true);
    final result = await _repository.listTransactions(purposeWalletId: purposeWalletId, cursor: cursor);
    state = state.copyWith(
      transactions: [...state.transactions, ...result.transactions],
      nextTransactionCursor: result.nextCursor,
      isLoadingTransactions: false,
    );
  }
}
