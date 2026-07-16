import '../models/analytics_charts_model.dart';
import '../models/analytics_dashboard_model.dart';
import '../models/analytics_report_model.dart';
import '../models/insight_model.dart';
import '../models/purpose_wallet_analytics_model.dart';
import '../services/analytics_service.dart';

/// Domain-facing layer over [AnalyticsService] — maps its raw JSON into
/// typed models so [AnalyticsNotifier] never touches a `Map<String, dynamic>`.
class AnalyticsRepository {
  AnalyticsRepository(this._service);

  final AnalyticsService _service;

  Future<AnalyticsDashboardModel> getDashboard(String range, {String? startDate, String? endDate}) async {
    return AnalyticsDashboardModel.fromJson(await _service.getDashboard(range, startDate: startDate, endDate: endDate));
  }

  Future<List<PurposeWalletAnalyticsModel>> getWallets(String range, {String? startDate, String? endDate}) async {
    final json = await _service.getWallets(range, startDate: startDate, endDate: endDate);
    return (json['wallets'] as List).map((e) => PurposeWalletAnalyticsModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AnalyticsChartsModel> getCharts(String range, {String? startDate, String? endDate}) async {
    return AnalyticsChartsModel.fromJson(await _service.getCharts(range, startDate: startDate, endDate: endDate));
  }

  Future<List<InsightModel>> getInsights(String range, {String? startDate, String? endDate}) async {
    final json = await _service.getInsights(range, startDate: startDate, endDate: endDate);
    return (json['insights'] as List).map((e) => InsightModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AnalyticsReportModel> getReport(String period, {String? date}) async {
    return AnalyticsReportModel.fromJson(await _service.getReport(period, date: date));
  }
}
