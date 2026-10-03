import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Content-Type": "application/json"},
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token");
        if (token != null && token.isNotEmpty) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        String msg = e.message ?? "An unknown error occurred.";
        
        if (e.response != null) {
          if (e.response!.statusCode == 403) {
            msg = "Access Denied: You do not have permission for this action.";
          } else if (e.response!.data is Map && e.response!.data['detail'] != null) {
            msg = e.response!.data['detail'].toString();
          } else if (e.response!.data is Map && e.response!.data['error'] != null) {
            msg = e.response!.data['error'].toString();
          } else {
            msg = "Server Error (${e.response!.statusCode})";
          }
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          msg = "Connection timed out. Please check your network.";
        } else if (e.type == DioExceptionType.connectionError) {
          msg = "Server is unreachable. Please check your connection.";
        }

        // Throwing a custom string or exception makes UI error messages clean
        throw ApiException(msg);
      },
    ),
  );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
