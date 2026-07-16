/// `GET /analytics/reports` — a Daily/Weekly/Monthly summary. Shares the
/// exact same 6 figures as the Dashboard totals (see
/// `AnalyticsDashboardModel`), just resolved against a discrete calendar
/// period instead of an open-ended range preset.
class AnalyticsReportModel {
  const AnalyticsReportModel({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalTransfers,
    required this.totalMerchantPayments,
    required this.totalUserPayments,
    required this.totalScheduledPayments,
  });

  /// 'DAILY' | 'WEEKLY' | 'MONTHLY'.
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final String totalIncome;
  final String totalExpenses;
  final String totalTransfers;
  final String totalMerchantPayments;
  final String totalUserPayments;
  final String totalScheduledPayments;

  factory AnalyticsReportModel.fromJson(Map<String, dynamic> json) => AnalyticsReportModel(
        period: json['period'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        totalIncome: json['totalIncome'].toString(),
        totalExpenses: json['totalExpenses'].toString(),
        totalTransfers: json['totalTransfers'].toString(),
        totalMerchantPayments: json['totalMerchantPayments'].toString(),
        totalUserPayments: json['totalUserPayments'].toString(),
        totalScheduledPayments: json['totalScheduledPayments'].toString(),
      );
}
