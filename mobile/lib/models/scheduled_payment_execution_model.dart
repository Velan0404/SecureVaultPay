/// One row from `GET /scheduled-payments/:id/executions` — a single cron
/// tick's attempt at a due schedule.
class ScheduledPaymentExecutionModel {
  const ScheduledPaymentExecutionModel({
    required this.id,
    required this.scheduledFor,
    required this.executedAt,
    required this.status,
    required this.amount,
    this.failureReason,
    this.paymentId,
  });

  final String id;
  final DateTime scheduledFor;
  final DateTime executedAt;
  final String status; // SUCCESS | FAILED
  final String amount;
  final String? failureReason;
  final String? paymentId;

  factory ScheduledPaymentExecutionModel.fromJson(Map<String, dynamic> json) => ScheduledPaymentExecutionModel(
        id: json['id'] as String,
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        executedAt: DateTime.parse(json['executedAt'] as String),
        status: json['status'] as String,
        amount: json['amount'].toString(),
        failureReason: json['failureReason'] as String?,
        paymentId: json['paymentId'] as String?,
      );
}
