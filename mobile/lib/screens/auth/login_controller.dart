import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/api/api_service.dart';
import '../../services/storage/auth_storage.dart';

class LoginController {
  Future<bool> login(String code) async {
    try {
      final response = await ApiService.dio.post(
        "/auth/login/",
        data: {"access_code": code},
      );

      await AuthStorage().saveSession(response.data);

      return true;
    } on DioException catch (e) {
      debugPrint("DIO ERROR: ${e.message}");
      if (e.response != null) {
        debugPrint("DIO RESPONSE: ${e.response?.data}");
      }
      return false;
    } catch (e) {
      debugPrint("UNKNOWN ERROR: $e");
      return false;
    }
  }
}
