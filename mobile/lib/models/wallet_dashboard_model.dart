import 'purpose_wallet_model.dart';
import 'wallet_transaction_model.dart';

class WalletDashboardModel {
  const WalletDashboardModel({
    required this.mainWalletBalance,
    required this.remainingMainWalletBalance,
    required this.totalWallets,
    required this.totalAllocated,
    required this.purposeWallets,
    required this.recentTransactions,
  });

  final String mainWalletBalance;
  final String remainingMainWalletBalance;
  final int totalWallets;
  final String totalAllocated;
  final List<PurposeWalletModel> purposeWallets;
  final List<WalletTransactionModel> recentTransactions;

  factory WalletDashboardModel.fromJson(Map<String, dynamic> json) => WalletDashboardModel(
        mainWalletBalance: json['mainWalletBalance'].toString(),
        remainingMainWalletBalance: json['remainingMainWalletBalance'].toString(),
        totalWallets: json['totalWallets'] as int,
        totalAllocated: json['totalAllocated'].toString(),
        purposeWallets: (json['purposeWallets'] as List)
            .map((e) => PurposeWalletModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentTransactions: (json['recentTransactions'] as List)
            .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
