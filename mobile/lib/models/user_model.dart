import 'dart:convert';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final Map<String, dynamic> permissions;
  final String accessCode;
  final bool isActive;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.permissions,
    required this.accessCode,
    required this.isActive,
  });

  factory UserModel.fromPrefs(Map<String, String> data) {
    Map<String, dynamic> perms = {};
    if (data["permissions"] != null && data["permissions"]!.isNotEmpty) {
      try {
        perms = jsonDecode(data["permissions"]!);
      } catch (_) {}
    }
    
    return UserModel(
      id: data["id"] ?? "",
      firstName: data["first_name"] ?? "",
      lastName: data["last_name"] ?? "",
      roles: (data["roles"] ?? "").split(',').where((e) => e.isNotEmpty).toList(),
      permissions: perms,
      accessCode: data["access_code"] ?? "",
      isActive: data["is_active"] == "true",
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json["roles"] is List) {
      parsedRoles = (json["roles"] as List).map((e) => e.toString()).toList();
    } else if (json["roles"] is String) {
      parsedRoles = (json["roles"] as String).split(',').where((e) => e.isNotEmpty).toList();
    }

    Map<String, dynamic> parsedPerms = {};
    if (json["permissions"] is Map) {
      parsedPerms = Map<String, dynamic>.from(json["permissions"]);
    } else if (json["permissions"] is String) {
      try {
        parsedPerms = jsonDecode(json["permissions"]);
      } catch (_) {}
    }

    return UserModel(
      id: json["id"]?.toString() ?? "",
      firstName: json["first_name"]?.toString() ?? "",
      lastName: json["last_name"]?.toString() ?? "",
      roles: parsedRoles,
      permissions: parsedPerms,
      accessCode: json["access_code"]?.toString() ?? "",
      isActive: json["is_active"] == true || json["is_active"] == "true",
    );
  }

  String get fullName => "$firstName ${lastName.trim()}".trim();
}
