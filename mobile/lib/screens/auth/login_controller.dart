import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/api/api_service.dart';
import '../../services/storage/auth_storage.dart';

class LoginController {
  Future<bool> login(String code) async {
    int retries = 3;
    while (retries > 0) {
      try {
        final response = await ApiService.dio.post(
          "/auth/login/",
          data: {"access_code": code},
        );

        await AuthStorage().saveSession(response.data);
        return true;
      } on DioException catch (e) {
        // If it's a 400 or 401, the code is actually invalid. No need to retry.
        if (e.response != null && (e.response!.statusCode == 400 || e.response!.statusCode == 401)) {
          return false;
        }
        
        // Otherwise it might be a stale socket from hot reload or a timeout.
        debugPrint("DIO ERROR on login (Retries left: $retries): ${e.message}");
        retries--;
        if (retries == 0) {
          throw Exception("Network error: ${e.message}");
        }
        // Wait a bit before retrying
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint("UNKNOWN ERROR: $e");
        throw Exception(e.toString());
      }
    }
    return false;
  }
}
