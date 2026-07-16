/// Result of `GET /personal-payment/my-qr` — this user's own permanent
/// Personal QR identity. Unlike a Merchant QR, this never expires and is
/// never consumed; it's generated once (lazily, server-side) and reused.
class UserQrModel {
  const UserQrModel({
    required this.payload,
    required this.userId,
    required this.secureVaultId,
    required this.fullName,
    this.phoneNumber,
  });

  final String payload;
  final String userId;
  final String secureVaultId;
  final String fullName;
  final String? phoneNumber;

  factory UserQrModel.fromJson(Map<String, dynamic> json) => UserQrModel(
        payload: json['payload'] as String,
        userId: json['userId'] as String,
        secureVaultId: json['secureVaultId'] as String,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String?,
      );
}
