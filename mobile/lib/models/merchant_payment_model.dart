class MerchantPaymentModel {
  const MerchantPaymentModel({
    required this.id,
    required this.purposeWalletId,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String purposeWalletId;
  final String merchantId;
  final String merchantName;
  final String amount;
  final DateTime createdAt;

  factory MerchantPaymentModel.fromJson(Map<String, dynamic> json) => MerchantPaymentModel(
        id: json['id'] as String,
        purposeWalletId: json['purposeWalletId'] as String,
        merchantId: json['merchantId'] as String,
        merchantName: json['merchantName'] as String,
        amount: json['amount'].toString(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
