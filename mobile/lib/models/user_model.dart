class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.biometricEnabled,
  });

  final String id;
  final String fullName;
  final String email;
  final bool biometricEnabled;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      );
}
