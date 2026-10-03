import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  return UserService().getUsers();
});

final userProvider = FutureProvider<UserModel>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  try {
    // Try to get fresh permissions from backend
    final user = await UserService().getMe();
    
    // Save the fresh permissions back to prefs
    await prefs.setString("id", user.id);
    await prefs.setString("first_name", user.firstName);
    await prefs.setString("last_name", user.lastName);
    await prefs.setString("roles", user.roles.join(","));
    await prefs.setString("permissions", jsonEncode(user.permissions));
    await prefs.setString("access_code", user.accessCode);
    await prefs.setString("is_active", user.isActive.toString());
    
    return user;
  } catch (e) {
    // Fallback to local storage if offline
    return UserModel.fromPrefs({
      "id": prefs.getString("id") ?? "",
      "first_name": prefs.getString("first_name") ?? "",
      "last_name": prefs.getString("last_name") ?? "",
      "roles": prefs.getString("roles") ?? prefs.getString("role") ?? "",
      "permissions": prefs.getString("permissions") ?? "",
      "access_code": prefs.getString("access_code") ?? "",
      "is_active": prefs.getString("is_active") ?? "true",
    });
  }
});
