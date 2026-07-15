class MainWalletModel {
  const MainWalletModel({
    required this.id,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Kept as the raw decimal string from the backend (e.g. "97500.00") —
  /// never parsed to double until the moment it's formatted for display, so
  /// no floating-point rounding error can creep into a money value.
  final String balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MainWalletModel.fromJson(Map<String, dynamic> json) => MainWalletModel(
        id: json['id'] as String,
        balance: json['balance'].toString(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
