enum MerchantStatus { active, inactive }

MerchantStatus _statusFromJson(String value) => value == 'INACTIVE' ? MerchantStatus.inactive : MerchantStatus.active;

class MerchantModel {
  const MerchantModel({
    required this.id,
    required this.merchantName,
    required this.merchantCategory,
    required this.merchantCode,
    this.merchantLogo,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String merchantName;

  /// Raw backend enum value (GROCERY, FOOD, FUEL, ...) — kept as a string so
  /// new categories the backend adds render without a Flutter-side update.
  final String merchantCategory;
  final String merchantCode;

  /// A Material Icons name (e.g. "shopping_cart"), resolved to an IconData by
  /// the UI layer — see MerchantIcons. Keeps this model free of any Flutter
  /// dependency, matching PurposeWalletModel's `icon` field.
  final String? merchantLogo;
  final MerchantStatus status;
  final DateTime createdAt;

  factory MerchantModel.fromJson(Map<String, dynamic> json) => MerchantModel(
        id: json['id'] as String,
        merchantName: json['merchantName'] as String,
        merchantCategory: json['merchantCategory'] as String,
        merchantCode: json['merchantCode'] as String,
        merchantLogo: json['merchantLogo'] as String?,
        status: _statusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
