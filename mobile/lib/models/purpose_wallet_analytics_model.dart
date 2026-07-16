/// One entry from `GET /analytics/wallets` — the 6 Purpose Wallet Analytics
/// figures for a single wallet. `remainingBudget`/`spendingPercentage` are
/// null when the wallet has no `spendingLimit` set.
class PurposeWalletAnalyticsModel {
  const PurposeWalletAnalyticsModel({
    required this.walletId,
    required this.name,
    required this.icon,
    required this.color,
    required this.currentBalance,
    required this.totalDeposited,
    required this.totalSpent,
    this.remainingBudget,
    this.spendingPercentage,
    required this.transactionCount,
  });

  final String walletId;
  final String name;
  final String icon;
  final String color;
  final String currentBalance;
  final String totalDeposited;
  final String totalSpent;
  final String? remainingBudget;
  final double? spendingPercentage;
  final int transactionCount;

  factory PurposeWalletAnalyticsModel.fromJson(Map<String, dynamic> json) => PurposeWalletAnalyticsModel(
        walletId: json['walletId'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        currentBalance: json['currentBalance'].toString(),
        totalDeposited: json['totalDeposited'].toString(),
        totalSpent: json['totalSpent'].toString(),
        remainingBudget: json['remainingBudget']?.toString(),
        spendingPercentage:
            json['spendingPercentage'] != null ? double.tryParse(json['spendingPercentage'].toString()) : null,
        transactionCount: json['transactionCount'] as int,
      );
}
