import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  return UserService().getUsers();
});

final userProvider = FutureProvider<UserModel>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  return UserModel.fromPrefs({
    "id": prefs.getString("id") ?? "",
    "first_name": prefs.getString("first_name") ?? "",
    "last_name": prefs.getString("last_name") ?? "",
    "roles": prefs.getString("roles") ?? prefs.getString("role") ?? "",
    "access_code": prefs.getString("access_code") ?? "",
    "is_active": prefs.getString("is_active") ?? "true",
  });
});
