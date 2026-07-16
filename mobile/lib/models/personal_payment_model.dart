class PersonalPaymentModel {
  const PersonalPaymentModel({
    required this.id,
    required this.receiverId,
    required this.receiverName,
    required this.purposeWalletId,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String receiverId;
  final String receiverName;
  final String purposeWalletId;
  final String amount;
  final String? note;
  final DateTime createdAt;

  factory PersonalPaymentModel.fromJson(Map<String, dynamic> json) => PersonalPaymentModel(
        id: json['id'] as String,
        receiverId: json['receiverId'] as String,
        receiverName: json['receiverName'] as String,
        purposeWalletId: json['purposeWalletId'] as String,
        amount: json['amount'].toString(),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
