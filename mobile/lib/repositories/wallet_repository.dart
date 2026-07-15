import '../models/main_wallet_model.dart';
import '../models/purpose_wallet_model.dart';
import '../models/wallet_dashboard_model.dart';
import '../models/wallet_transaction_model.dart';
import '../services/wallet_service.dart';

/// Domain-facing wallet layer — maps [WalletService]'s raw JSON into typed
/// models so [WalletNotifier] never touches a `Map<String, dynamic>`.
class WalletRepository {
  WalletRepository(this._service);

  final WalletService _service;

  Future<MainWalletModel> getMainWallet() async {
    return MainWalletModel.fromJson(await _service.getMainWallet());
  }

  Future<MainWalletModel> loadDemoMoney() async {
    return MainWalletModel.fromJson(await _service.loadDemoMoney());
  }

  Future<List<PurposeWalletModel>> listPurposeWallets() async {
    final wallets = await _service.listPurposeWallets();
    return wallets.map(PurposeWalletModel.fromJson).toList();
  }

  Future<PurposeWalletModel> getPurposeWallet(String id) async {
    return PurposeWalletModel.fromJson(await _service.getPurposeWallet(id));
  }

  Future<PurposeWalletModel> createPurposeWallet({
    required String name,
    required String icon,
    required String color,
    String? purpose,
    String? spendingLimit,
  }) async {
    final json = await _service.createPurposeWallet(
      name: name,
      icon: icon,
      color: color,
      purpose: purpose,
      spendingLimit: spendingLimit,
    );
    return PurposeWalletModel.fromJson(json);
  }

  Future<PurposeWalletModel> updatePurposeWallet(
    String id, {
    String? name,
    String? icon,
    String? color,
    String? purpose,
    String? spendingLimit,
  }) async {
    final json = await _service.updatePurposeWallet(
      id,
      name: name,
      icon: icon,
      color: color,
      purpose: purpose,
      spendingLimit: spendingLimit,
    );
    return PurposeWalletModel.fromJson(json);
  }

  Future<void> deletePurposeWallet(String id) {
    return _service.deletePurposeWallet(id);
  }

  Future<void> transfer({
    required String purposeWalletId,
    required String amount,
    required String transactionAuthSessionId,
  }) {
    return _service.transfer(
      purposeWalletId: purposeWalletId,
      amount: amount,
      transactionAuthSessionId: transactionAuthSessionId,
    );
  }

  Future<({List<WalletTransactionModel> transactions, String? nextCursor})> listTransactions({
    String? purposeWalletId,
    String? cursor,
  }) async {
    final data = await _service.listTransactions(purposeWalletId: purposeWalletId, cursor: cursor);
    final transactions = (data['transactions'] as List)
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (transactions: transactions, nextCursor: data['nextCursor'] as String?);
  }

  Future<WalletDashboardModel> getDashboard() async {
    return WalletDashboardModel.fromJson(await _service.getDashboard());
  }
}
