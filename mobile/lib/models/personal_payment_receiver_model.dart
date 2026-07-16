/// Result of `GET /personal-payment/lookup/:userId` (scanned Personal QR)
/// or `GET /personal-payment/search` (Phase 7.1 — search by mobile number)
/// — one shared shape for both ways of resolving a Person-to-Person payment
/// destination, so the payment flow after either one is identical. Whichever
/// endpoint doesn't populate [secureVaultId]/[profileImage] simply parses
/// them as null.
class PersonalPaymentReceiverModel {
  const PersonalPaymentReceiverModel({
    required this.userId,
    required this.fullName,
    this.maskedPhoneNumber,
    this.secureVaultId,
    this.profileImage,
  });

  final String userId;
  final String fullName;
  final String? maskedPhoneNumber;
  final String? secureVaultId;
  final String? profileImage;

  factory PersonalPaymentReceiverModel.fromJson(Map<String, dynamic> json) => PersonalPaymentReceiverModel(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        maskedPhoneNumber: json['maskedPhoneNumber'] as String?,
        secureVaultId: json['secureVaultId'] as String?,
        profileImage: json['profileImage'] as String?,
      );
}
