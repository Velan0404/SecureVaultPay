/// One entry from `GET /analytics/insights` — a rule-generated observation
/// over real transaction data (never fabricated).
class InsightModel {
  const InsightModel({required this.id, required this.type, required this.severity, required this.message});

  final String id;

  /// Raw backend type string (BUDGET_WARNING, BUDGET_INFO, TREND, DORMANT,
  /// UPCOMING_PAYMENT) — kept as a string so new insight types the backend
  /// adds render without a Flutter-side model change.
  final String type;

  /// 'WARNING' | 'INFO'.
  final String severity;
  final String message;

  factory InsightModel.fromJson(Map<String, dynamic> json) => InsightModel(
        id: json['id'] as String,
        type: json['type'] as String,
        severity: json['severity'] as String,
        message: json['message'] as String,
      );
}
