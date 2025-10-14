import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> requestOtp(String email) async {
    try {
      final response = await _dio.post(
        "/auth/resend-otp",
        data: {"email": email},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data["error"] ?? e.message,
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateEmail({
    required String oldEmail,
    required String newEmail,
  }) async {
    try {
      final response = await _dio.patch(
        "/auth/update-email",
        data: {"oldEmail": oldEmail, "newEmail": newEmail},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data["error"] ?? e.message,
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<bool> checkTokenWithBackend(Dio dio, String token) async {
    try {
      final response = await dio.get(
        "/auth/check-token",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
