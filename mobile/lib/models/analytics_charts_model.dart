/// One point on the Monthly Spending Line Chart.
class MonthlySpendingPoint {
  const MonthlySpendingPoint({required this.month, required this.total});

  /// 'YYYY-MM'.
  final String month;
  final String total;

  factory MonthlySpendingPoint.fromJson(Map<String, dynamic> json) => MonthlySpendingPoint(
        month: json['month'] as String,
        total: json['total'].toString(),
      );
}

/// One bar on the Weekly Expense Bar Chart (one per day, last 7 days).
class WeeklyExpensePoint {
  const WeeklyExpensePoint({required this.date, required this.total});

  /// 'YYYY-MM-DD'.
  final String date;
  final String total;

  factory WeeklyExpensePoint.fromJson(Map<String, dynamic> json) => WeeklyExpensePoint(
        date: json['date'] as String,
        total: json['total'].toString(),
      );
}

/// One slice of the Purpose Wallet Pie Chart.
class PurposeWalletBreakdownSlice {
  const PurposeWalletBreakdownSlice({
    required this.walletId,
    required this.name,
    required this.color,
    required this.value,
  });

  final String walletId;
  final String name;

  /// Hex color, e.g. "#E53935" — same convention as `PurposeWalletModel.color`.
  final String color;
  final String value;

  factory PurposeWalletBreakdownSlice.fromJson(Map<String, dynamic> json) => PurposeWalletBreakdownSlice(
        walletId: json['walletId'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        value: json['value'].toString(),
      );
}

class IncomeVsExpense {
  const IncomeVsExpense({required this.income, required this.expenses});

  final String income;
  final String expenses;

  factory IncomeVsExpense.fromJson(Map<String, dynamic> json) => IncomeVsExpense(
        income: json['income'].toString(),
        expenses: json['expenses'].toString(),
      );
}

/// `GET /analytics/charts` — all 4 chart datasets in one round trip, since
/// they're consumed together on the Analytics Dashboard screen.
class AnalyticsChartsModel {
  const AnalyticsChartsModel({
    required this.monthlySpending,
    required this.purposeWalletBreakdown,
    required this.weeklyExpense,
    required this.incomeVsExpense,
  });

  final List<MonthlySpendingPoint> monthlySpending;
  final List<PurposeWalletBreakdownSlice> purposeWalletBreakdown;
  final List<WeeklyExpensePoint> weeklyExpense;
  final IncomeVsExpense incomeVsExpense;

  factory AnalyticsChartsModel.fromJson(Map<String, dynamic> json) => AnalyticsChartsModel(
        monthlySpending: (json['monthlySpending'] as List)
            .map((e) => MonthlySpendingPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        purposeWalletBreakdown: (json['purposeWalletBreakdown'] as List)
            .map((e) => PurposeWalletBreakdownSlice.fromJson(e as Map<String, dynamic>))
            .toList(),
        weeklyExpense: (json['weeklyExpense'] as List)
            .map((e) => WeeklyExpensePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        incomeVsExpense: IncomeVsExpense.fromJson(json['incomeVsExpense'] as Map<String, dynamic>),
      );
}
