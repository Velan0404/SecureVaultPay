/// `GET /analytics/dashboard` — the 8 Dashboard Analytics headline figures.
/// All amounts are decimal strings, same convention as every other model
/// (`WalletTransactionModel`, `PurposeWalletModel`, ...) — never a double.
class AnalyticsDashboardModel {
  const AnalyticsDashboardModel({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalTransfers,
    required this.totalMerchantPayments,
    required this.totalUserPayments,
    required this.totalScheduledPayments,
    required this.monthlySpending,
  });

  final String totalBalance;
  final String totalIncome;
  final String totalExpenses;
  final String totalTransfers;
  final String totalMerchantPayments;
  final String totalUserPayments;
  final String totalScheduledPayments;

  /// The current calendar month's expenses — always "this month", computed
  /// independently of whichever range filter is selected.
  final String monthlySpending;

  factory AnalyticsDashboardModel.fromJson(Map<String, dynamic> json) => AnalyticsDashboardModel(
        totalBalance: json['totalBalance'].toString(),
        totalIncome: json['totalIncome'].toString(),
        totalExpenses: json['totalExpenses'].toString(),
        totalTransfers: json['totalTransfers'].toString(),
        totalMerchantPayments: json['totalMerchantPayments'].toString(),
        totalUserPayments: json['totalUserPayments'].toString(),
        totalScheduledPayments: json['totalScheduledPayments'].toString(),
        monthlySpending: json['monthlySpending'].toString(),
      );
}
