class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.source,
    this.destination,
    this.description,
    required this.status,
    this.purposeWalletId,
    required this.createdAt,
  });

  final String id;

  /// Raw backend enum value (WALLET_CREATED, WALLET_UPDATED, WALLET_DELETED,
  /// DEMO_LOAD, MAIN_TO_PURPOSE, ...). Kept as a string — new values the
  /// backend adds for future modules render without a Flutter-side update.
  final String type;
  final String amount;
  final String? source;
  final String? destination;
  final String? description;
  final String status;
  final String? purposeWalletId;
  final DateTime createdAt;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) => WalletTransactionModel(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: json['amount'].toString(),
        source: json['source'] as String?,
        destination: json['destination'] as String?,
        description: json['description'] as String?,
        status: json['status'] as String,
        purposeWalletId: json['purposeWalletId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
