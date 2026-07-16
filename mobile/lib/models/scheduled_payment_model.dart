/// Mirrors `scheduledPayment.service.js`'s `toPublic()` shape. `paymentType`,
/// `frequency`, and `status` are kept as raw backend enum strings (same
/// choice `WalletTransactionModel.type` already makes) so new backend values
/// render without a Flutter-side model change.
class ScheduledPaymentModel {
  const ScheduledPaymentModel({
    required this.id,
    required this.title,
    required this.paymentType,
    required this.amount,
    required this.frequency,
    this.customIntervalDays,
    required this.purposeWalletId,
    this.merchantId,
    this.merchantName,
    this.merchantLogo,
    this.receiverUserId,
    this.receiverName,
    this.note,
    required this.startDate,
    required this.nextExecution,
    this.lastExecution,
    this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String paymentType;
  final String amount;
  final String frequency;
  final int? customIntervalDays;
  final String purposeWalletId;
  final String? merchantId;
  final String? merchantName;
  final String? merchantLogo;
  final String? receiverUserId;
  final String? receiverName;
  final String? note;
  final DateTime startDate;
  final DateTime nextExecution;
  final DateTime? lastExecution;
  final DateTime? endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The other party's display name, regardless of destination kind —
  /// mirrors the `payeeName` getter pattern already used by
  /// `ConfirmPaymentPinArgs`/`PaymentPinFlowArgs`.
  String get destinationName => merchantName ?? receiverName ?? 'Unknown';

  bool get isMerchantDestination => merchantId != null;

  factory ScheduledPaymentModel.fromJson(Map<String, dynamic> json) => ScheduledPaymentModel(
        id: json['id'] as String,
        title: json['title'] as String,
        paymentType: json['paymentType'] as String,
        amount: json['amount'].toString(),
        frequency: json['frequency'] as String,
        customIntervalDays: json['customIntervalDays'] as int?,
        purposeWalletId: json['purposeWalletId'] as String,
        merchantId: json['merchantId'] as String?,
        merchantName: json['merchantName'] as String?,
        merchantLogo: json['merchantLogo'] as String?,
        receiverUserId: json['receiverUserId'] as String?,
        receiverName: json['receiverName'] as String?,
        note: json['note'] as String?,
        startDate: DateTime.parse(json['startDate'] as String),
        nextExecution: DateTime.parse(json['nextExecution'] as String),
        lastExecution: json['lastExecution'] != null ? DateTime.parse(json['lastExecution'] as String) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
