enum PurposeWalletStatus { active, archived }

PurposeWalletStatus _statusFromJson(String value) =>
    value == 'ARCHIVED' ? PurposeWalletStatus.archived : PurposeWalletStatus.active;

class PurposeWalletModel {
  const PurposeWalletModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.purpose,
    required this.balance,
    this.spendingLimit,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// A Material Icons name (e.g. "shopping_cart"), resolved to an IconData by
  /// the UI layer — kept as a plain string here so this model has no
  /// Flutter/UI dependency.
  final String icon;

  /// Hex color, e.g. "#E53935".
  final String color;
  final String? purpose;
  final String balance;
  final String? spendingLimit;
  final PurposeWalletStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PurposeWalletModel.fromJson(Map<String, dynamic> json) => PurposeWalletModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        purpose: json['purpose'] as String?,
        balance: json['balance'].toString(),
        spendingLimit: json['spendingLimit']?.toString(),
        status: _statusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
