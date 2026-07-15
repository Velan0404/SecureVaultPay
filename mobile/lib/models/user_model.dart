class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.biometricEnabled,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final bool biometricEnabled;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      );
}
