import 'merchant_model.dart';

/// Result of `GET /qr/validate/:qrId` — the merchant a scanned QR resolves
/// to. Scanning never consumes the QR; only a successful payment does.
class QrValidationModel {
  const QrValidationModel({required this.qrId, required this.expiresAt, required this.merchant});

  final String qrId;
  final DateTime expiresAt;
  final MerchantModel merchant;

  factory QrValidationModel.fromJson(Map<String, dynamic> json) => QrValidationModel(
        qrId: json['qrId'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        merchant: MerchantModel.fromJson(json['merchant'] as Map<String, dynamic>),
      );
}
