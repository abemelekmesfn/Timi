import 'api/api_service.dart';
import '../models/user_model.dart';

class UserService {
  Future<List<UserModel>> getUsers() async {
    final res = await ApiService.dio.get("/users/");

    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> createUser({
    required String firstName,
    required String lastName,
    required List<String> roles,
    required String accessCode,
  }) async {
    final res = await ApiService.dio.post(
      "/users/",
      data: {
        "first_name": firstName,
        "last_name": lastName,
        "roles": roles,
        "access_code": accessCode,
      },
    );

    return UserModel.fromJson(res.data);
  }

  Future<void> updateUser({
    required String id,
    required String firstName,
    required String lastName,
    required List<String> roles,
    required String accessCode,
    required bool isActive,
  }) async {
    await ApiService.dio.put(
      "/users/$id/",
      data: {
        "first_name": firstName,
        "last_name": lastName,
        "roles": roles,
        "access_code": accessCode,
        "is_active": isActive,
      },
    );
  }
}
