/// Mirrors the backend's range presets (`resolveRange` in
/// `backend/src/utils/dateRange.js`) — every Analytics screen filters
/// through this same shared enum.
enum AnalyticsRange { today, last7Days, last30Days, last90Days, thisYear, custom }

extension AnalyticsRangeX on AnalyticsRange {
  String get apiValue => switch (this) {
        AnalyticsRange.today => 'TODAY',
        AnalyticsRange.last7Days => 'LAST_7_DAYS',
        AnalyticsRange.last30Days => 'LAST_30_DAYS',
        AnalyticsRange.last90Days => 'LAST_90_DAYS',
        AnalyticsRange.thisYear => 'THIS_YEAR',
        AnalyticsRange.custom => 'CUSTOM',
      };

  String get label => switch (this) {
        AnalyticsRange.today => 'Today',
        AnalyticsRange.last7Days => 'Last 7 Days',
        AnalyticsRange.last30Days => 'Last 30 Days',
        AnalyticsRange.last90Days => 'Last 90 Days',
        AnalyticsRange.thisYear => 'This Year',
        AnalyticsRange.custom => 'Custom Range',
      };
}
