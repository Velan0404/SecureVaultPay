/// Result of `POST /qr/demo` — a freshly minted, single-use, time-boxed demo
/// QR for one merchant. [payload] is the exact string to encode into a
/// scannable QR image (see DemoMerchantQrScreen); the scanner decodes it
/// back into this same JSON shape client-side to extract [qrId].
class DemoQrModel {
  const DemoQrModel({required this.qrId, required this.payload, required this.expiresAt});

  final String qrId;
  final String payload;
  final DateTime expiresAt;

  factory DemoQrModel.fromJson(Map<String, dynamic> json) => DemoQrModel(
        qrId: json['qrId'] as String,
        payload: json['payload'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}
