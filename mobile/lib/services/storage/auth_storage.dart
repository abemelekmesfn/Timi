import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _token = "token";

  Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_token, data["access"] ?? "");
    await prefs.setString("id", data["user"]["id"]);
    await prefs.setString("first_name", data["user"]["first_name"]);
    await prefs.setString("last_name", data["user"]["last_name"]);
    await prefs.setString("roles", (data["user"]["roles"] as List).join(","));
    await prefs.setString("access_code", data["user"]["access_code"]);
  }

  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
