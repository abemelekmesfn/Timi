class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final String accessCode;
  final bool isActive;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.accessCode,
    required this.isActive,
  });

  factory UserModel.fromPrefs(Map<String, String> data) {
    return UserModel(
      id: data["id"] ?? "",
      firstName: data["first_name"] ?? "",
      lastName: data["last_name"] ?? "",
      roles: (data["roles"] ?? "").split(',').where((e) => e.isNotEmpty).toList(),
      accessCode: data["access_code"] ?? "",
      isActive: data["is_active"] == "true",
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"] ?? "",
      firstName: json["first_name"] ?? "",
      lastName: json["last_name"] ?? "",
      roles: List<String>.from(json["roles"] ?? []),
      accessCode: json["access_code"] ?? "",
      isActive: json["is_active"] ?? true,
    );
  }

  String get fullName => "$firstName ${lastName.trim()}".trim();
}
