import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Raw Analytics API access — every method returns decoded JSON, untouched.
/// Mapping into typed models is [AnalyticsRepository]'s job.
class AnalyticsService {
  AnalyticsService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getDashboard(String range, {String? startDate, String? endDate}) {
    return _apiClient.get(ApiConstants.analyticsDashboard(range, startDate: startDate, endDate: endDate));
  }

  Future<Map<String, dynamic>> getWallets(String range, {String? startDate, String? endDate}) {
    return _apiClient.get(ApiConstants.analyticsWallets(range, startDate: startDate, endDate: endDate));
  }

  Future<Map<String, dynamic>> getCharts(String range, {String? startDate, String? endDate}) {
    return _apiClient.get(ApiConstants.analyticsCharts(range, startDate: startDate, endDate: endDate));
  }

  Future<Map<String, dynamic>> getInsights(String range, {String? startDate, String? endDate}) {
    return _apiClient.get(ApiConstants.analyticsInsights(range, startDate: startDate, endDate: endDate));
  }

  Future<Map<String, dynamic>> getReport(String period, {String? date}) {
    return _apiClient.get(ApiConstants.analyticsReports(period, date: date));
  }
}
