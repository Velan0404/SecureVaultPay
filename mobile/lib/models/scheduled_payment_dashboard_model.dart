import 'scheduled_payment_model.dart';

class ScheduledPaymentStats {
  const ScheduledPaymentStats({
    required this.activeCount,
    required this.pausedCount,
    required this.missedCount,
    required this.upcoming7DayTotal,
  });

  final int activeCount;
  final int pausedCount;
  final int missedCount;
  final String upcoming7DayTotal;

  factory ScheduledPaymentStats.fromJson(Map<String, dynamic> json) => ScheduledPaymentStats(
        activeCount: json['activeCount'] as int,
        pausedCount: json['pausedCount'] as int,
        missedCount: json['missedCount'] as int,
        upcoming7DayTotal: json['upcoming7DayTotal'].toString(),
      );
}

/// `GET /scheduled-payments/dashboard` — a small, independent aggregate read
/// directly by the Dashboard's Scheduled Payments block. Deliberately not
/// folded into `WalletDashboardModel` — see scheduledPaymentProvider.
class ScheduledPaymentDashboardModel {
  const ScheduledPaymentDashboardModel({
    required this.today,
    required this.upcoming,
    required this.missed,
    required this.stats,
  });

  final List<ScheduledPaymentModel> today;
  final List<ScheduledPaymentModel> upcoming;
  final List<ScheduledPaymentModel> missed;
  final ScheduledPaymentStats stats;

  factory ScheduledPaymentDashboardModel.fromJson(Map<String, dynamic> json) => ScheduledPaymentDashboardModel(
        today: (json['today'] as List).map((e) => ScheduledPaymentModel.fromJson(e as Map<String, dynamic>)).toList(),
        upcoming:
            (json['upcoming'] as List).map((e) => ScheduledPaymentModel.fromJson(e as Map<String, dynamic>)).toList(),
        missed: (json['missed'] as List).map((e) => ScheduledPaymentModel.fromJson(e as Map<String, dynamic>)).toList(),
        stats: ScheduledPaymentStats.fromJson(json['stats'] as Map<String, dynamic>),
      );
}
