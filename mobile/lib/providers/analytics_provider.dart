import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_charts_model.dart';
import '../models/analytics_dashboard_model.dart';
import '../models/analytics_range.dart';
import '../models/analytics_report_model.dart';
import '../models/insight_model.dart';
import '../models/purpose_wallet_analytics_model.dart';
import '../repositories/analytics_repository.dart';
import '../services/analytics_service.dart';
import 'auth_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.read(apiClientProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.read(analyticsServiceProvider)),
);

class AnalyticsState {
  const AnalyticsState({
    this.selectedRange = AnalyticsRange.last30Days,
    this.customStartDate,
    this.customEndDate,
    this.dashboard,
    this.wallets = const [],
    this.charts,
    this.insights = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final AnalyticsRange selectedRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final AnalyticsDashboardModel? dashboard;
  final List<PurposeWalletAnalyticsModel> wallets;
  final AnalyticsChartsModel? charts;
  final List<InsightModel> insights;
  final bool isLoading;
  final String? errorMessage;

  AnalyticsState copyWith({
    AnalyticsRange? selectedRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool clearCustomDates = false,
    AnalyticsDashboardModel? dashboard,
    List<PurposeWalletAnalyticsModel>? wallets,
    AnalyticsChartsModel? charts,
    List<InsightModel>? insights,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnalyticsState(
      selectedRange: selectedRange ?? this.selectedRange,
      customStartDate: clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate: clearCustomDates ? null : (customEndDate ?? this.customEndDate),
      dashboard: dashboard ?? this.dashboard,
      wallets: wallets ?? this.wallets,
      charts: charts ?? this.charts,
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(AnalyticsNotifier.new);

/// Drives every Analytics screen (Dashboard, Purpose Wallet Analytics,
/// Insights) off one shared range filter — changing the range reloads all
/// four datasets together in one `loadAll()`, which is what makes "Analytics
/// should refresh automatically" true: every screen reads from this same
/// state rather than fetching independently.
class AnalyticsNotifier extends Notifier<AnalyticsState> {
  // A getter, not a `late final` field assigned inside build() — see the
  // identical note on WalletNotifier._repository. This provider is
  // invalidated on every logout/login/register, and a `late final` field
  // throws LateInitializationError if build() reruns on the same instance
  // while a listener is still attached.
  AnalyticsRepository get _repository => ref.read(analyticsRepositoryProvider);

  @override
  AnalyticsState build() {
    return const AnalyticsState();
  }

  String get _rangeValue => state.selectedRange.apiValue;
  String? get _startDate => state.customStartDate?.toUtc().toIso8601String();
  String? get _endDate => state.customEndDate?.toUtc().toIso8601String();

  Future<void> setRange(AnalyticsRange range, {DateTime? customStart, DateTime? customEnd}) async {
    state = state.copyWith(
      selectedRange: range,
      customStartDate: customStart,
      customEndDate: customEnd,
      clearCustomDates: range != AnalyticsRange.custom,
    );
    await loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dashboard = await _repository.getDashboard(_rangeValue, startDate: _startDate, endDate: _endDate);
      final wallets = await _repository.getWallets(_rangeValue, startDate: _startDate, endDate: _endDate);
      final charts = await _repository.getCharts(_rangeValue, startDate: _startDate, endDate: _endDate);
      final insights = await _repository.getInsights(_rangeValue, startDate: _startDate, endDate: _endDate);
      state = state.copyWith(dashboard: dashboard, wallets: wallets, charts: charts, insights: insights, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load analytics. Check your connection and try again.');
    }
  }

  Future<AnalyticsReportModel> loadReport(String period, {DateTime? date}) {
    return _repository.getReport(period, date: date?.toUtc().toIso8601String());
  }
}
